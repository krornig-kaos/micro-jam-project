## Zorro — enemigo que patrulla y persigue al player si lo detecta.
## Si el player está en sigilo no lo detecta.
extends CharacterBody2D

@export var patrol_speed: float = 80.0
@export var chase_speed: float = 160.0
@export var detection_radius: float = 150.0
@export var patrol_points: Array[Vector2] = []
@export var investigate_duration: float = 3.0

enum State { PATROL, CHASE, INVESTIGATE }
var current_state: State = State.PATROL
var _patrol_index: int = 0
var _player: Node2D = null
var _player_stealthed: bool = false
var _last_known_position: Vector2 = Vector2.ZERO
var _investigate_timer: float = 0.0

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _detection: Area2D = $DetectionArea

func _ready() -> void:
	add_to_group("enemy")
	_detection.body_entered.connect(_on_detection_entered)
	_detection.body_exited.connect(_on_detection_exited)
	if patrol_points.is_empty():
		patrol_points = [global_position, global_position + Vector2(100, 0)]

func _physics_process(_delta: float) -> void:
	match current_state:
		State.PATROL:
			_do_patrol()
			# Si el jugador está dentro de la zona pero no lo detectábamos antes (ej. estaba oculto tras una pared)
			if _player and not _player_stealthed and _has_line_of_sight():
				current_state = State.CHASE
		State.CHASE:
			_do_chase()
			# Si el jugador se oculta detrás de un obstáculo mientras es perseguido
			if not _has_line_of_sight():
				if _player:
					_last_known_position = _player.global_position
				else:
					_last_known_position = global_position
				_investigate_timer = investigate_duration
				current_state = State.INVESTIGATE
		State.INVESTIGATE:
			_do_investigate(_delta)
			if _player and not _player_stealthed and _has_line_of_sight():
				current_state = State.CHASE
	
	# Rotar el cono de visión en la dirección del movimiento
	if velocity.length_squared() > 10.0:
		_detection.rotation = velocity.angle()
		
	move_and_slide()
	_check_collisions()

func _check_collisions() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider and collider.is_in_group("player"):
			if collider.has_method("take_hit"):
				collider.take_hit()

func _do_patrol() -> void:
	if patrol_points.is_empty():
		return
	var target := patrol_points[_patrol_index]
	var dir := (target - global_position).normalized()
	velocity = dir * patrol_speed
	if global_position.distance_to(target) < 10.0:
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
	_anim.flip_h = velocity.x < 0
	_anim.play("walk")

func _do_chase() -> void:
	if not _player:
		current_state = State.PATROL
		return
	var dir := (_player.global_position - global_position).normalized()
	velocity = dir * chase_speed
	_anim.flip_h = velocity.x < 0
	_anim.play("run")

func _do_investigate(delta: float) -> void:
	var distance := global_position.distance_to(_last_known_position)
	if distance > 10.0:
		# Move towards last known position
		var dir := (_last_known_position - global_position).normalized()
		velocity = dir * chase_speed
		_anim.flip_h = velocity.x < 0
		_anim.play("run")
	else:
		# Arrived at position, wait and countdown timer
		velocity = Vector2.ZERO
		_anim.play("walk")  # Use walk as idle animation
		_investigate_timer -= delta
		if _investigate_timer <= 0.0:
			current_state = State.PATROL

func _on_detection_entered(body: Node) -> void:
	print("_on_detection_entered: ", body.is_in_group("player"), "name: ", body.name)
	if body.is_in_group("player"):
		_player = body
		# Realizar raycast para verificar línea de visión inmediata
		if not _player_stealthed and _has_line_of_sight():
			current_state = State.CHASE

func _on_detection_exited(body: Node) -> void:
	print("_on_detection_exited: ", body.is_in_group("player"), "name: ", body.name)
	if body.is_in_group("player"):
		if current_state == State.CHASE:
			_last_known_position = body.global_position
			_investigate_timer = investigate_duration
			current_state = State.INVESTIGATE
		_player = null

## Comprueba si hay línea de visión directa con el player (sin obstáculos en medio)
func _has_line_of_sight() -> bool:
	if not _player:
		return false
		
	var space_state := get_world_2d().direct_space_state
	# Configurar parámetros del Raycast
	var query := PhysicsRayQueryParameters2D.create(global_position, _player.global_position)
	# Excluir al propio zorro de la colisión del rayo
	query.exclude = [get_rid()]
	# El rayo debe chocar con terreno/obstáculos (capa 1) y con el player (capa 2)
	query.collision_mask = 1 | 2
	
	var result := space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		# Si lo primero con lo que choca el rayo es el player, hay línea de visión
		if collider == _player:
			return true
	return false

## Llamado por el player cuando activa/desactiva sigilo
func on_player_stealthed(is_stealthed: bool) -> void:
	_player_stealthed = is_stealthed
	if is_stealthed:
		if _player:
			_last_known_position = _player.global_position
		_investigate_timer = investigate_duration
		current_state = State.INVESTIGATE
		velocity = Vector2.ZERO
	elif _player and global_position.distance_to(_player.global_position) < detection_radius:
		current_state = State.CHASE

## Llamado por alarmas (ej. el Búho) para avisar de la última posición del jugador
func on_player_spotted(spotted_position: Vector2) -> void:
	# Solo investiga si no está actualmente persiguiendo de forma directa
	if current_state != State.CHASE:
		_last_known_position = spotted_position
		_investigate_timer = investigate_duration
		current_state = State.INVESTIGATE
