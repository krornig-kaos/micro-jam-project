## Zorro — enemigo que patrulla y persigue al player si lo detecta.
## Si el player está en sigilo no lo detecta.
extends CharacterBody2D

@export var patrol_speed: float = 80.0
@export var chase_speed: float = 160.0
@export var detection_radius: float = 150.0
@export var patrol_capsule_length: float = 180.0
@export var patrol_capsule_radius: float = 30.0
@export var investigate_duration: float = 3.0

enum State { PATROL, CHASE, INVESTIGATE }
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
	
	# Hacer que el enemigo solo sea visible bajo la luz (invisible en sombras)
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_LIGHT_ONLY
	_anim.material = mat
	
	_detection.body_entered.connect(_on_detection_entered)
	_detection.body_exited.connect(_on_detection_exited)
	
	_patrol_center = global_position

func _physics_process(_delta: float) -> void:
	# Detección acústica (Oído)
	var player = _get_player_node()
	if player and not player.is_dead:
		var dist := global_position.distance_to(player.global_position)
		if dist <= player.current_noise_radius:
			# Si escucha ruido y no está persiguiendo, va a investigar la fuente del sonido
			if current_state != State.CHASE:
				_last_known_position = player.global_position
				_investigate_timer = investigate_duration
				current_state = State.INVESTIGATE

	match current_state:
		State.PATROL:
			_do_patrol()
			# Detección visual (solo si el jugador no está oculto en un arbusto)
			if _player and not _player.is_dead and not _player.is_hidden() and _has_line_of_sight():
				current_state = State.CHASE
		State.CHASE:
			_do_chase()
			# Si el jugador se oculta (en arbusto o detrás de un muro)
			if not _has_line_of_sight() or (_player and _player.is_hidden()):
				if _player:
					_last_known_position = _player.global_position
				else:
					_last_known_position = global_position
				_investigate_timer = investigate_duration
				current_state = State.INVESTIGATE
		State.INVESTIGATE:
			_do_investigate(_delta)
			# Detección visual al investigar
			if _player and not _player.is_dead and not _player.is_hidden() and _has_line_of_sight():
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
	var delta := get_physics_process_delta_time()
	var L := patrol_capsule_length
	var R := patrol_capsule_radius
	
	# Calcular el perímetro total de la pista de carreras
	var P := 4.0 * L + 2.0 * PI * R
	if P <= 0.0:
		return
		
	# Incrementar el progreso lineal
	_patrol_progress = fmod(_patrol_progress + patrol_speed * delta, P)
	
	# Determinar la posición en base al segmento de la cápsula
	var local_pos := Vector2.ZERO
	var s := _patrol_progress
	
	if s < 2.0 * L:
		# Recta superior (movimiento hacia la derecha)
		local_pos.x = -L + s
		local_pos.y = -R
	elif s < 2.0 * L + PI * R:
		# Curva derecha (giro de 180 grados hacia abajo)
		var s_arc := s - 2.0 * L
		var angle := -PI / 2.0 + (s_arc / R)
		local_pos.x = L + R * cos(angle)
		local_pos.y = R * sin(angle)
	elif s < 4.0 * L + PI * R:
		# Recta inferior (movimiento hacia la izquierda)
		var s_seg := s - (2.0 * L + PI * R)
		local_pos.x = L - s_seg
		local_pos.y = R
	else:
		# Curva izquierda (giro de 180 grados hacia arriba)
		var s_arc := s - (4.0 * L + PI * R)
		var angle := PI / 2.0 + (s_arc / R)
		local_pos.x = -L + R * cos(angle)
		local_pos.y = R * sin(angle)
		
	var target := _patrol_center + local_pos
	var dir := (target - global_position).normalized()
	velocity = dir * patrol_speed
	
	_anim.flip_h = velocity.x < 0
	_anim.play("walk")

func _do_chase() -> void:
	if not _player:
		current_state = State.PATROL
		return
	var dir := (_player.global_position - global_position).normalized()
	var velocity_dir := dir
	
	# Esquivar obstáculos: Si choca de frente, deflectar el movimiento hacia un lado
	if get_slide_collision_count() > 0:
		var collision := get_slide_collision(0)
		var normal := collision.get_normal()
		if dir.dot(normal) < -0.7:
			velocity_dir = Vector2(-normal.y, normal.x)
			
	velocity = velocity_dir * chase_speed
	_anim.flip_h = velocity.x < 0
	_anim.play("run")

func _do_investigate(delta: float) -> void:
	# Decrementar el temporizador siempre para evitar quedar atascado permanentemente
	_investigate_timer -= delta
	if _investigate_timer <= 0.0:
		current_state = State.PATROL
		return

	var distance := global_position.distance_to(_last_known_position)
	if distance > 10.0:
		# Moverse hacia la última posición conocida del jugador
		var dir := (_last_known_position - global_position).normalized()
		var velocity_dir := dir
		
		# Esquivar obstáculos: Si choca de frente, deflectar el movimiento hacia un lado
		if get_slide_collision_count() > 0:
			var collision := get_slide_collision(0)
			var normal := collision.get_normal()
			if dir.dot(normal) < -0.7:
				velocity_dir = Vector2(-normal.y, normal.x)
				
		velocity = velocity_dir * chase_speed
		_anim.flip_h = velocity.x < 0
		_anim.play("run")
	else:
		# Llegó a la posición, se detiene e investiga quieto
		velocity = Vector2.ZERO
		_anim.play("walk")  # Usar animación de caminar como idle provisional

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

func _get_player_node() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

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
