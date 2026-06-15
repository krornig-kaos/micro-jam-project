## Jabalí — patrulla buscando al player. Al detectarlo, embiste con aceleración agresiva.
## Si falla la embestida o golpea un obstáculo, se queda aturdido brevemente.
extends CharacterBody2D

# ─── Señales ───────────────────────────────────────────────────────────────────
signal charging
signal stunned
signal footstep_heavy
signal grunt

@export var patrol_speed: float = 60.0
@export var charge_speed: float = 260.0
@export var detection_radius: float = 100.0
@export var charge_duration: float = 1.0
@export var stun_duration: float = 1.5
@export var patrol_capsule_length: float = 160.0
@export var patrol_capsule_radius: float = 25.0

enum State { PATROL, WINDUP, CHARGE, STUN }
var current_state: State = State.PATROL

var _patrol_center: Vector2
var _patrol_progress: float = 0.0
var _player: Node2D = null
var _player_stealthed: bool = false
var _state_timer: float = 0.0
var _charge_direction: Vector2 = Vector2.ZERO

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _detection: Area2D = $DetectionArea

var _charge_sound_node: AudioStreamPlayer2D = null

func _ready() -> void:
	add_to_group("enemy")
	
	# Conectar señales de audio
	charging.connect(func(): _charge_sound_node = AudioManager.play_sfx("boar_charge", global_position, 0.0, 0.9, 1.1, 900.0))
	stunned.connect(func(): 
		AudioManager.play_sfx("boar_stun", global_position, 0.0, 0.9, 1.1, 500.0)
		if _charge_sound_node:
			AudioManager.stop_sfx(_charge_sound_node)
			_charge_sound_node = null
	)
	footstep_heavy.connect(func(): AudioManager.play_sfx("boar_gallop", global_position, -2.0, 0.8, 1.0, 450.0))
	grunt.connect(func(): AudioManager.play_sfx("boar_patrol", global_position, -4.0, 0.9, 1.1, 400.0))
	
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_LIGHT_ONLY
	material = mat
	_anim.material = mat
	_detection.body_entered.connect(_on_detection_entered)
	_detection.body_exited.connect(_on_detection_exited)
	_patrol_center = global_position

var _grunt_timer: float = 0.0
var _footstep_timer: float = 0.0

func _physics_process(delta: float) -> void:
	# Si el player está muerto, volver a patrullar limpiamente
	if _player and _player.is_dead:
		_player = null
		velocity = Vector2.ZERO
		modulate = Color.WHITE
		current_state = State.PATROL
		_play_animation("walk", Vector2.ZERO)
		move_and_slide()
		queue_redraw()
		return

	if _state_timer > 0.0:
		_state_timer -= delta

	match current_state:
		State.PATROL:
			_do_patrol()
			
			# Gruñidos aleatorios en patrulla
			_grunt_timer -= delta
			if _grunt_timer <= 0.0:
				grunt.emit()
				_grunt_timer = randf_range(3.0, 7.0)
				
			# Detección visual — ignorar si está en sigilo u oculto
			if _player and not _player.is_dead and not _player.is_hidden() and not _player_stealthed and _has_line_of_sight():
				_start_windup()
			else:
				# Detección acústica — ignorar si está en sigilo
				if not _player_stealthed:
					var player = _get_player_node()
					if player and not player.is_dead:
						var dist := global_position.distance_to(player.global_position)
						if dist <= player.current_noise_radius:
							_charge_direction = (player.global_position - global_position).normalized()
							_anim.flip_h = _charge_direction.x < 0
							current_state = State.WINDUP
							_state_timer = 0.4
		State.WINDUP:
			velocity = Vector2.ZERO
			_play_animation("idle", _charge_direction)
			if _state_timer <= 0.0:
				_start_charge()
		State.CHARGE:
			_do_charge(delta)
			
			# Pasos pesados al cargar
			_footstep_timer -= delta
			if _footstep_timer <= 0.0:
				footstep_heavy.emit()
				_footstep_timer = 0.2
		State.STUN:
			velocity = Vector2.ZERO
			_play_animation("idle", Vector2.ZERO)
			modulate.g = 0.5
			modulate.b = 0.5
	if _state_timer <= 0.0:
		modulate = Color.WHITE
		current_state = State.PATROL
		if _charge_sound_node:
			AudioManager.stop_sfx(_charge_sound_node)
			_charge_sound_node = null


	if velocity.length_squared() > 10.0:
		_detection.rotation = velocity.angle()

	move_and_slide()
	_check_collisions()
	queue_redraw()

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
	velocity = dir * patrol_speed
	_play_animation("walk", velocity)

func _start_windup() -> void:
	current_state = State.WINDUP
	_state_timer = 0.4
	if _player:
		_charge_direction = (_player.global_position - global_position).normalized()
		_anim.flip_h = _charge_direction.x < 0

func _start_charge() -> void:
	current_state = State.CHARGE
	_state_timer = charge_duration
	charging.emit()
	if _player:
		_charge_direction = (_player.global_position - global_position).normalized()

func _do_charge(_delta: float) -> void:
	if _player and not _player_stealthed:
		var desired_dir := (_player.global_position - global_position).normalized()
		_charge_direction = lerp(_charge_direction, desired_dir, 0.05).normalized()

	velocity = _charge_direction * charge_speed
	_play_animation("run", velocity)

	# Si choca contra una pared se aturde
	if get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var collider := collision.get_collider()
			if collider and not collider.is_in_group("player"):
				_trigger_stun()
				return

	if _state_timer <= 0.0:
		_trigger_stun()

func _trigger_stun() -> void:
	current_state = State.STUN
	_state_timer = stun_duration
	velocity = Vector2.ZERO
	stunned.emit()

func _check_collisions() -> void:
	# En sigilo el jabalí no daña al player aunque lo toque
	if _player_stealthed:
		return
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider and collider.is_in_group("player"):
			# Tampoco daña si está oculto en arbusto
			if collider.has_method("is_hidden") and collider.is_hidden():
				return
			if collider.has_method("take_hit"):
				collider.take_hit()

func _has_line_of_sight() -> bool:
	if not _player:
		return false
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, _player.global_position)
	query.exclude = [get_rid()]
	query.collision_mask = 1 | 2
	var result := space_state.intersect_ray(query)
	if result:
		return result.collider == _player
	return false

func _get_player_node() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func _play_animation(animation_base: String, dir: Vector2) -> void:
	var anim_name: String
	if dir != Vector2.ZERO:
		# flip_h solo cuando el movimiento es predominantemente horizontal
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
	# Solo cambiar si la animación es diferente a la actual
	if _anim.sprite_frames.has_animation(anim_name) and _anim.animation != anim_name:
		_anim.play(anim_name)

func _on_detection_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player = body

func _on_detection_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player = null

func on_player_stealthed(is_stealthed: bool) -> void:
	_player_stealthed = is_stealthed
	if is_stealthed and current_state == State.CHARGE:
		# Si entra en sigilo durante una carga, el jabalí se aturde
		_trigger_stun()

func on_player_spotted(spotted_position: Vector2) -> void:
	if current_state == State.PATROL:
		_charge_direction = (spotted_position - global_position).normalized()
		current_state = State.WINDUP
		_state_timer = 0.4
		_play_animation("idle", _charge_direction)

func _draw() -> void:
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	var steps := 12
	var radius := 100.0
	var half_angle := deg_to_rad(45.0)
	var base_angle := _detection.rotation
	var start_angle := base_angle - half_angle
	var end_angle := base_angle + half_angle
	for i in range(steps + 1):
		var angle = start_angle + (float(i) / steps) * (end_angle - start_angle)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	var color := Color(1.0, 0.5, 0.1, 0.05)
	if current_state == State.CHARGE:
		color = Color(1.0, 0.1, 0.1, 0.15)
	elif current_state == State.WINDUP:
		color = Color(1.0, 0.8, 0.1, 0.1)
	draw_polygon(points, [color])
