## Búho de vigilancia — permanece en una posición fija y rota sobre su propio eje.
## Cada 60 segundos realiza un vuelo circular de exploración antes de volver a su anclaje.
## Detecta al jugador únicamente dentro de su cono de visión y emite una alarma
## que alerta a los enemigos cercanos (Jabalíes y Zorros).
extends CharacterBody2D

# ─── Exportables ───────────────────────────────────────────────────────────────
@export var rotation_speed: float = 45.0
@export var detection_radius: float = 250.0
@export var cone_angle: float = 60.0
@export var explore_cooldown: float = 60.0
@export var patrol_radius: float = 200.0
@export var patrol_speed: float = 100.0

# ─── Estado interno ────────────────────────────────────────────────────────────
enum State { WATCH, EXPLORE }
var current_state: State = State.WATCH

var _player: Node2D = null
var _player_stealthed: bool = false
var _alerted: bool = false

var _explore_timer: float = 0.0
var _anchor_position: Vector2
var _orbit_angle: float = 0.0
var _investigate_timer: float = 0.0
var _noise_target: Vector2 = Vector2.ZERO
var _is_investigating_noise: bool = false

var _ring_radius: float = 0.0
var _ring_max_radius: float = 40.0
var _ring_alpha: float = 1.0

# ─── Nodos hijos ───────────────────────────────────────────────────────────────
@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _detection: Area2D = $DetectionArea
@onready var _detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var _alert_ring: Line2D = get_node_or_null("AlertRing")

# ─── Godot lifecycle ───────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("enemy")
	add_to_group("non_lethal")

	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_LIGHT_ONLY
	material = mat
	_anim.material = mat

	_detection.body_entered.connect(_on_detection_entered)
	_detection.body_exited.connect(_on_detection_exited)

	_anchor_position = global_position

	if _detection_shape and _detection_shape.shape is CircleShape2D:
		_detection_shape.shape.radius = detection_radius

	if _alert_ring:
		var ring_mat := CanvasItemMaterial.new()
		ring_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		_alert_ring.material = ring_mat
		_setup_alert_ring()

func _physics_process(delta: float) -> void:
	# Detección acústica — solo si no está alertado ni en sigilo
	var player = _get_player_node()
	if player and not player.is_dead and not _alerted and not _player_stealthed:
		var dist := global_position.distance_to(player.global_position)
		if dist <= player.current_noise_radius:
			_is_investigating_noise = true
			_investigate_timer = 2.0
			_noise_target = player.global_position

	# Cooldown de exploración
	if current_state == State.WATCH and not _alerted and not _is_investigating_noise:
		_explore_timer += delta
		if _explore_timer >= explore_cooldown:
			_start_explore()

	# Prioridad 1: alertado → apuntar al player
	if _alerted and _player:
		var to_player := (_player.global_position - global_position).normalized()
		global_rotation = lerp_angle(global_rotation, to_player.angle() + PI / 2.0, 10.0 * delta)
		velocity = Vector2.ZERO
	# Prioridad 2: escuchó ruido → girar a investigar
	elif _is_investigating_noise:
		var to_noise := (_noise_target - global_position).normalized()
		global_rotation = lerp_angle(global_rotation, to_noise.angle() + PI / 2.0, 8.0 * delta)
		velocity = Vector2.ZERO
		_investigate_timer -= delta
		if _investigate_timer <= 0.0:
			_is_investigating_noise = false
	# Prioridad 3: comportamiento normal
	else:
		match current_state:
			State.WATCH:
				velocity = Vector2.ZERO
				global_rotation += deg_to_rad(rotation_speed) * delta
			State.EXPLORE:
				_do_explore(delta)

	# Detección visual — ignorar si en sigilo u oculto
	if _player and not _player.is_dead and not _player.is_hidden() and not _player_stealthed and _is_player_in_cone() and _has_line_of_sight():
		if not _alerted:
			_alerted = true
			_is_investigating_noise = false
			_ring_radius = 0.0
			_ring_alpha = 1.0
			if _alert_ring:
				_alert_ring.visible = true
			get_tree().call_group("enemy", "on_player_spotted", _player.global_position)
	else:
		_alerted = false

	_update_alert_ring(delta)

	# Animación: el búho rota físicamente con global_rotation,
	# así que solo necesita "fly" o "idle" sin sufijos de dirección
	var anim_name := "fly" if current_state == State.EXPLORE else "idle"
	if _anim.animation != anim_name:
		_anim.play(anim_name)

	queue_redraw()

func _start_explore() -> void:
	current_state = State.EXPLORE
	_explore_timer = 0.0
	_orbit_angle = -PI / 2.0

func _end_explore() -> void:
	current_state = State.WATCH
	global_position = _anchor_position
	velocity = Vector2.ZERO

func _do_explore(delta: float) -> void:
	var center := _anchor_position + Vector2(0.0, patrol_radius)
	var angular_speed := patrol_speed / patrol_radius
	_orbit_angle += angular_speed * delta
	var target_position := center + Vector2(cos(_orbit_angle), sin(_orbit_angle)) * patrol_radius
	global_position = target_position
	var tangent := Vector2(-sin(_orbit_angle), cos(_orbit_angle))
	velocity = tangent * patrol_speed
	global_rotation = tangent.angle() + PI / 2.0
	if _orbit_angle >= 3.0 * PI / 2.0:
		_end_explore()

func _is_player_in_cone() -> bool:
	if not _player:
		return false
	var to_player := (_player.global_position - global_position).normalized()
	var facing_dir := Vector2.UP.rotated(global_rotation)
	var angle := facing_dir.angle_to(to_player)
	return absf(angle) <= deg_to_rad(cone_angle / 2.0)

func _setup_alert_ring() -> void:
	if not _alert_ring:
		return
	_alert_ring.visible = false
	var points: Array[Vector2] = []
	var steps := 32
	for i in range(steps + 1):
		var theta := (float(i) / steps) * TAU
		points.append(Vector2(cos(theta), sin(theta)))
	_alert_ring.points = PackedVector2Array(points)
	_alert_ring.top_level = true

func _update_alert_ring(delta: float) -> void:
	if _alert_ring and _alert_ring.visible:
		_alert_ring.global_position = global_position + Vector2(0, -16)
		_ring_radius += 120.0 * delta
		_ring_alpha = maxf(0.0, 1.0 - (_ring_radius / _ring_max_radius))
		_alert_ring.scale = Vector2(_ring_radius, _ring_radius)
		_alert_ring.default_color = Color(1.0, 0.0, 0.0, _ring_alpha)
		if _ring_alpha <= 0.0:
			if _alerted:
				_ring_radius = 0.0
				_ring_alpha = 1.0
			else:
				_alert_ring.visible = false

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

func _on_detection_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player = body

func _on_detection_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player = null
		_alerted = false

func on_player_stealthed(is_stealthed: bool) -> void:
	_player_stealthed = is_stealthed
	if is_stealthed:
		_alerted = false
		if _alert_ring:
			_alert_ring.visible = false

func on_player_touched(player_node: Node2D) -> void:
	if not _alerted and not _player_stealthed:
		_alerted = true
		_ring_radius = 0.0
		_ring_alpha = 1.0
		if _alert_ring:
			_alert_ring.visible = true
		get_tree().call_group("enemy", "on_player_spotted", player_node.global_position)

func _get_player_node() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func _draw() -> void:
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	var steps := 16
	var start_angle := -PI / 2.0 - deg_to_rad(cone_angle / 2.0)
	var end_angle := -PI / 2.0 + deg_to_rad(cone_angle / 2.0)
	for i in range(steps + 1):
		var angle = start_angle + (float(i) / steps) * (end_angle - start_angle)
		points.append(Vector2(cos(angle), sin(angle)) * detection_radius)
	var color := Color(1.0, 0.9, 0.2, 0.08)
	if _alerted:
		color = Color(1.0, 0.1, 0.1, 0.16)
	draw_polygon(points, [color])
