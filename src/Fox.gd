## Zorro — enemigo que patrulla y persigue al player si lo detecta.
## Si el player está en sigilo no lo detecta.
extends CharacterBody2D

@export var patrol_speed: float = 100.0
@export var chase_speed: float = 160.0
@export var detection_radius: float = 150.0
@export var patrol_capsule_length: float = 180.0
@export var patrol_capsule_radius: float = 30.0
@export var investigate_duration: float = 3.0

enum State { PATROL, CHASE, INVESTIGATE, IDLE }
var current_state: State = State.PATROL
var _patrol_center: Vector2
var _patrol_progress: float = 0.0
var _player: Node2D = null
var _player_stealthed: bool = false
var _last_known_position: Vector2 = Vector2.ZERO
var _investigate_timer: float = 0.0

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _detection: Area2D = $DetectionArea

func _ready() -> void:
	add_to_group("enemy")
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_LIGHT_ONLY
	material = mat
	_anim.material = mat
	_detection.body_entered.connect(_on_detection_entered)
	_detection.body_exited.connect(_on_detection_exited)
	_patrol_center = global_position

func _physics_process(_delta: float) -> void:
	# Si el player está muerto, volver a patrullar
	if _player and _player.is_dead:
		_player = null
		velocity = Vector2.ZERO
		current_state = State.PATROL
		_play_animation("walk", Vector2.ZERO)
		move_and_slide()
		queue_redraw()
		return

	# Detección acústica solo si el player NO está en sigilo
	var player = _get_player_node()
	if player and not player.is_dead and not _player_stealthed:
		var dist := global_position.distance_to(player.global_position)
		if dist <= player.current_noise_radius:
			if current_state != State.CHASE:
				_last_known_position = player.global_position
				_investigate_timer = investigate_duration
				current_state = State.INVESTIGATE

	match current_state:
		State.PATROL:
			_do_patrol()
			if _player and not _player.is_dead and not _player.is_hidden() and not _player_stealthed and _has_line_of_sight():
				current_state = State.CHASE
		State.CHASE:
			_do_chase()
			if not _has_line_of_sight() or (_player and _player.is_hidden()) or _player_stealthed:
				if _player:
					_last_known_position = _player.global_position
				else:
					_last_known_position = global_position
				_investigate_timer = investigate_duration
				current_state = State.INVESTIGATE
		State.INVESTIGATE:
			_do_investigate(_delta)
			if _player and not _player.is_dead and not _player.is_hidden() and not _player_stealthed and _has_line_of_sight():
				current_state = State.CHASE
		State.IDLE:
			velocity = Vector2.ZERO
			_play_animation("walk", Vector2.ZERO)

	if velocity.length_squared() > 10.0:
		_detection.rotation = velocity.angle()

	move_and_slide()
	_check_collisions()
	queue_redraw()

func _check_collisions() -> void:
	if _player_stealthed:
		return
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider and collider.is_in_group("player"):
			if collider.has_method("is_hidden") and collider.is_hidden():
				return
			if collider.has_method("take_hit"):
				collider.take_hit()

func _do_patrol() -> void:
	var delta := get_physics_process_delta_time()
	var L := patrol_capsule_length
	var R := patrol_capsule_radius
	var P := 4.0 * L + 2.0 * PI * R
	if P <= 0.0:
		return
	_patrol_progress = fmod(_patrol_progress + patrol_speed * delta, P)
	var local_pos := Vector2.ZERO
	var s := _patrol_progress
	if s < 2.0 * L:
		local_pos.x = -L + s
		local_pos.y = -R
	elif s < 2.0 * L + PI * R:
		var s_arc := s - 2.0 * L
		var angle := -PI / 2.0 + (s_arc / R)
		local_pos.x = L + R * cos(angle)
		local_pos.y = R * sin(angle)
	elif s < 4.0 * L + PI * R:
		var s_seg := s - (2.0 * L + PI * R)
		local_pos.x = L - s_seg
		local_pos.y = R
	else:
		var s_arc := s - (4.0 * L + PI * R)
		var angle := PI / 2.0 + (s_arc / R)
		local_pos.x = -L + R * cos(angle)
		local_pos.y = R * sin(angle)
	var target := _patrol_center + local_pos
	var dir := (target - global_position).normalized()
	velocity = _steer_around_obstacles(dir) * patrol_speed
	_play_animation("walk", velocity)

func _do_chase() -> void:
	if not _player:
		current_state = State.PATROL
		return
	var dir := (_player.global_position - global_position).normalized()
	velocity = _steer_around_obstacles(dir) * chase_speed
	_play_animation("run", velocity)

func _do_investigate(delta: float) -> void:
	_investigate_timer -= delta
	if _investigate_timer <= 0.0:
		current_state = State.PATROL
		return
	var distance := global_position.distance_to(_last_known_position)
	if distance > 10.0:
		var dir := (_last_known_position - global_position).normalized()
		velocity = _steer_around_obstacles(dir) * chase_speed
		_play_animation("run", velocity)
	else:
		velocity = Vector2.ZERO
		_play_animation("walk", Vector2.ZERO)

## Devuelve una dirección corregida para rodear obstáculos.
## Rota el vector deseado en incrementos hasta encontrar espacio libre.
func _steer_around_obstacles(desired_dir: Vector2) -> Vector2:
	if get_slide_collision_count() == 0:
		return desired_dir

	# Calcular la normal promedio de todas las colisiones activas
	var avg_normal := Vector2.ZERO
	for i in get_slide_collision_count():
		avg_normal += get_slide_collision(i).get_normal()
	avg_normal = avg_normal.normalized()

	# Si no choca de frente, no hace falta corregir
	if desired_dir.dot(avg_normal) >= -0.3:
		return desired_dir

	# Probar rotaciones en ambos sentidos hasta encontrar dirección libre
	for deg in [30, 60, 90, 120, 150]:
		var rad := deg_to_rad(float(deg))
		for sign in [1, -1]:
			var candidate := desired_dir.rotated(rad * sign)
			if candidate.dot(avg_normal) > 0.0:
				return candidate

	# Último recurso: deslizarse por la superficie
	return Vector2(-avg_normal.y, avg_normal.x)

func _on_detection_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player = body
		if not _player_stealthed and not body.is_hidden() and _has_line_of_sight():
			current_state = State.CHASE

func _on_detection_exited(body: Node) -> void:
	if body.is_in_group("player"):
		if current_state == State.CHASE:
			_last_known_position = body.global_position
		_investigate_timer = investigate_duration
		current_state = State.INVESTIGATE

func _play_animation(animation_base: String, dir: Vector2) -> void:
	var anim_name: String
	if dir != Vector2.ZERO:
		if absf(dir.x) >= absf(dir.y):
			_anim.flip_h = dir.x < 0.0
		var suffix: String
		if absf(dir.x) >= absf(dir.y):
			suffix = "_side"
		else:
			suffix = "_up" if dir.y < 0.0 else "_down"
		anim_name = animation_base + suffix
	else:
		anim_name = animation_base
	if _anim.sprite_frames.has_animation(anim_name) and _anim.animation != anim_name:
		_anim.play(anim_name)

func _has_line_of_sight() -> bool:
	if not _player:
		return false
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, _player.global_position)
	query.exclude = [get_rid()]
	query.collision_mask = 1 | 2
	var result := space_state.intersect_ray(query)
	if result:
		if result.collider == _player:
			return true
	return false

func _get_player_node() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func on_player_stealthed(is_stealthed: bool) -> void:
	_player_stealthed = is_stealthed
	if is_stealthed:
		if _player:
			_last_known_position = _player.global_position
		_investigate_timer = investigate_duration
		current_state = State.INVESTIGATE
		velocity = Vector2.ZERO
	elif _player and not _player.is_dead and global_position.distance_to(_player.global_position) < detection_radius:
		current_state = State.CHASE

func on_player_spotted(spotted_position: Vector2) -> void:
	if current_state != State.CHASE:
		_last_known_position = spotted_position
		_investigate_timer = investigate_duration
		current_state = State.INVESTIGATE

func _draw() -> void:
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	var steps := 12
	var radius := 120.0
	var half_angle := deg_to_rad(40.0)
	var base_angle := _detection.rotation
	var start_angle := base_angle - half_angle
	var end_angle := base_angle + half_angle
	for i in range(steps + 1):
		var angle = start_angle + (float(i) / steps) * (end_angle - start_angle)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	var color := Color(1.0, 0.65, 0.1, 0.05)
	if current_state == State.CHASE:
		color = Color(1.0, 0.1, 0.1, 0.15)
	elif current_state == State.INVESTIGATE:
		color = Color(1.0, 0.85, 0.1, 0.08)
	draw_polygon(points, [color])
