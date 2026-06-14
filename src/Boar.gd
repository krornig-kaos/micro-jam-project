## Jabalí — patrulla buscando al player. Al detectarlo, embiste con aceleración agresiva.
## Si falla la embestida o golpea un obstáculo, se queda aturdido brevemente.
extends CharacterBody2D

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

func _ready() -> void:
	add_to_group("enemy")
	
	# Hacer que el enemigo y su cono de visión solo sean visibles bajo la luz (invisible en sombras)
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_LIGHT_ONLY
	material = mat
	_anim.material = mat
	
	_detection.body_entered.connect(_on_detection_entered)
	_detection.body_exited.connect(_on_detection_exited)
	
	_patrol_center = global_position

func _physics_process(delta: float) -> void:
	if _state_timer > 0.0:
		_state_timer -= delta

	match current_state:
		State.PATROL:
			_do_patrol()
			# Detección visual (solo si el jugador no está en un arbusto)
			if _player and not _player.is_dead and not _player.is_hidden() and _has_line_of_sight():
				_start_windup()
			else:
				# Detección acústica (Oído)
				var player = _get_player_node()
				if player and not player.is_dead:
					var dist := global_position.distance_to(player.global_position)
					if dist <= player.current_noise_radius:
						# Alerta acústica: se detiene y orienta su carga hacia el ruido!
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
		State.STUN:
			velocity = Vector2.ZERO
			_play_animation("idle", Vector2.ZERO)
			# Efecto visual de aturdimiento parpadeando opcional
			modulate.g = 0.5
			modulate.b = 0.5
			if _state_timer <= 0.0:
				modulate = Color.WHITE
				current_state = State.PATROL
				
	# Rotar el cono de visión en la dirección del movimiento
	if velocity.length_squared() > 10.0:
		_detection.rotation = velocity.angle()
		
	move_and_slide()
	_check_collisions()
	
	# Solicitar redibujado del cono de visión
	queue_redraw()

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
	
	_play_animation("walk", velocity)

func _start_windup() -> void:
	current_state = State.WINDUP
	_state_timer = 0.4 # Pausa corta de preparación
	if _player:
		_charge_direction = (_player.global_position - global_position).normalized()
		_anim.flip_h = _charge_direction.x < 0

func _start_charge() -> void:
	current_state = State.CHARGE
	_state_timer = charge_duration
	if _player:
		_charge_direction = (_player.global_position - global_position).normalized()

func _do_charge(_delta: float) -> void:
	# Ajustar levemente la dirección hacia el jugador para que no sea 100% rígido, pero con poca maniobrabilidad
	if _player:
		var desired_dir := (_player.global_position - global_position).normalized()
		_charge_direction = lerp(_charge_direction, desired_dir, 0.05).normalized()
		
	velocity = _charge_direction * charge_speed
	_play_animation("run", velocity)
	
	# Si choca contra una pared (obstáculo sólido) se aturde de inmediato
	if get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var collider := collision.get_collider()
			if collider and not collider.is_in_group("player"): # Es una pared o muro
				_trigger_stun()
				return
				
	if _state_timer <= 0.0:
		_trigger_stun()

func _trigger_stun() -> void:
	current_state = State.STUN
	_state_timer = stun_duration
	velocity = Vector2.ZERO

func _check_collisions() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider and collider.is_in_group("player"):
			if collider.has_method("take_hit"):
				collider.take_hit()

func _has_line_of_sight() -> bool:
	if not _player:
		return false
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, _player.global_position)
	query.exclude = [get_rid()]
	query.collision_mask = 1 | 2 # Paredes (1) y Jugador (2)
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
	if dir != Vector2.ZERO:
		if dir.x != 0.0:
			_anim.flip_h = dir.x < 0.0
			
		var suffix := ""
		if absf(dir.x) >= absf(dir.y):
			suffix = "_side"
		else:
			suffix = "_up" if dir.y < 0.0 else "_down"
			
		var anim_name = animation_base + suffix
		if _anim.sprite_frames.has_animation(anim_name):
			_anim.play(anim_name)
			return
			
	# Fallback a la animación básica
	if _anim.sprite_frames.has_animation(animation_base):
		_anim.play(animation_base)

func _on_detection_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player = body

func _on_detection_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player = null

func on_player_stealthed(is_stealthed: bool) -> void:
	_player_stealthed = is_stealthed
	if is_stealthed and current_state == State.CHARGE:
		# Si entra en sigilo a mitad de una carga, el jabalí pierde el blanco y se aturde/detiene
		_trigger_stun()

## Llamado por alarmas (ej. el Búho) para avisar de la última posición del jugador
func on_player_spotted(spotted_position: Vector2) -> void:
	# El jabalí reacciona a la alarma preparándose para embestir hacia esa zona
	if current_state == State.PATROL:
		_charge_direction = (spotted_position - global_position).normalized()
		current_state = State.WINDUP
		_state_timer = 0.4
		_anim.play("idle")

func _draw() -> void:
	# Dibujar el cono de visión del jabalí alineado con la rotación de su detección
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	
	var steps := 12
	var radius := 100.0 # Basado en CollisionPolygon2D del editor (100 de alcance)
	var half_angle := deg_to_rad(45.0) # Cono de 90 grados
	var base_angle := _detection.rotation
	
	var start_angle := base_angle - half_angle
	var end_angle := base_angle + half_angle
	
	for i in range(steps + 1):
		var angle = start_angle + (float(i) / steps) * (end_angle - start_angle)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
		
	# Definir color: Naranja por defecto, Amarillo en Windup, Rojo en Carga
	var color := Color(1.0, 0.5, 0.1, 0.05)
	if current_state == State.CHARGE:
		color = Color(1.0, 0.1, 0.1, 0.15)
	elif current_state == State.WINDUP:
		color = Color(1.0, 0.8, 0.1, 0.1)
		
	draw_polygon(points, [color])
