## Búho de vigilancia — permanece en una posición fija y rota sobre su propio eje.
## Cada 60 segundos realiza un vuelo circular de exploración antes de volver a su anclaje.
## Detecta al jugador únicamente dentro de su cono de visión y emite una alarma
## que alerta a los enemigos cercanos (Jabalíes y Zorros).
extends CharacterBody2D

# ─── Exportables ───────────────────────────────────────────────────────────────
@export var rotation_speed: float = 45.0 ## Velocidad de rotación en grados por segundo en estado WATCH
@export var detection_radius: float = 250.0 ## Distancia máxima de detección
@export var cone_angle: float = 60.0 ## Ángulo del cono de visión en grados
@export var explore_cooldown: float = 60.0 ## Tiempo entre vuelos de exploración en segundos
@export var patrol_radius: float = 200.0 ## Radio del círculo de exploración
@export var patrol_speed: float = 100.0 ## Velocidad de vuelo durante la exploración

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

# Variables para la onda expansiva roja
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
	
	# Hacer que el enemigo y su cono de visión solo sean visibles bajo la luz (invisible en sombras)
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_LIGHT_ONLY
	material = mat
	_anim.material = mat
	
	_detection.body_entered.connect(_on_detection_entered)
	_detection.body_exited.connect(_on_detection_exited)
	
	_anchor_position = global_position
	
	# Ajustar el radio de detección físico al exportado
	if _detection_shape and _detection_shape.shape is CircleShape2D:
		_detection_shape.shape.radius = detection_radius
		
	# Configurar el Line2D del anillo para que dibuje un círculo aproximado si existe
	if _alert_ring:
		var ring_mat := CanvasItemMaterial.new()
		ring_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		_alert_ring.material = ring_mat
		_setup_alert_ring()

func _physics_process(delta: float) -> void:
	# Detección acústica (Oído del Búho)
	var player = _get_player_node()
	if player and not player.is_dead and not _alerted:
		var dist := global_position.distance_to(player.global_position)
		if dist <= player.current_noise_radius:
			# Escuchó ruido: detiene su patrón e investiga girando hacia allí
			_is_investigating_noise = true
			_investigate_timer = 2.0
			_noise_target = player.global_position

	# Cooldown de exploración en estado WATCH (solo corre el tiempo si no está alertado ni investigando ruido)
	if current_state == State.WATCH and not _alerted and not _is_investigating_noise:
		_explore_timer += delta
		if _explore_timer >= explore_cooldown:
			_start_explore()

	# 1. Prioridad 1: Si está alertado (vio al jugador), se enfoca en él
	if _alerted and _player:
		var to_player := (_player.global_position - global_position).normalized()
		global_rotation = lerp_angle(global_rotation, to_player.angle() + PI / 2.0, 10.0 * delta)
		velocity = Vector2.ZERO
	# 2. Prioridad 2: Si escuchó ruido, gira a investigar la zona por 2 segundos
	elif _is_investigating_noise:
		var to_noise := (_noise_target - global_position).normalized()
		global_rotation = lerp_angle(global_rotation, to_noise.angle() + PI / 2.0, 8.0 * delta)
		velocity = Vector2.ZERO
		
		_investigate_timer -= delta
		if _investigate_timer <= 0.0:
			_is_investigating_noise = false
	# 3. Prioridad 3: Movimiento y rotación de patrulla normales
	else:
		match current_state:
			State.WATCH:
				velocity = Vector2.ZERO
				# Rotación continua sobre su propio eje
				global_rotation += deg_to_rad(rotation_speed) * delta
			State.EXPLORE:
				_do_explore(delta)

	# Controlar la alerta basado en línea de visión y cono de visión (solo si el jugador no está en un arbusto)
	if _player and not _player.is_dead and not _player.is_hidden() and _is_player_in_cone() and _has_line_of_sight():
		if not _alerted:
			_alerted = true
			# Cancelar investigación por ruido ya que hay contacto visual directo
			_is_investigating_noise = false
			# Reiniciar efecto de onda expansiva
			_ring_radius = 0.0
			_ring_alpha = 1.0
			if _alert_ring:
				_alert_ring.visible = true
			
			print("OWL: Player spotted in cone! Alerting nearby land enemies.")
			get_tree().call_group("enemy", "on_player_spotted", _player.global_position)
	else:
		_alerted = false

	# Actualizar la animación de la onda expansiva
	_update_alert_ring(delta)

	# Actualizar animación direccional (quieto en WATCH, volando en EXPLORE)
	var current_dir := Vector2.UP.rotated(global_rotation)
	var anim_name := "fly" if current_state == State.EXPLORE else "idle"
	_play_animation(anim_name, current_dir)
	
	# Solicitar redibujado del cono de visión
	queue_redraw()

## Inicia el estado de vuelo circular
func _start_explore() -> void:
	current_state = State.EXPLORE
	_explore_timer = 0.0
	_orbit_angle = -PI / 2.0 # Ángulo de inicio (coincide exactamente con _anchor_position)

## Finaliza el estado de vuelo circular regresando al WATCH
func _end_explore() -> void:
	current_state = State.WATCH
	global_position = _anchor_position
	velocity = Vector2.ZERO

## Ejecuta el movimiento circular durante la exploración
func _do_explore(delta: float) -> void:
	# Desplazar el centro de la órbita de modo que en _orbit_angle = -PI/2
	# la posición calculada sea exactamente el punto de anclaje
	var center := _anchor_position + Vector2(0.0, patrol_radius)
	
	# w = v / r
	var angular_speed := patrol_speed / patrol_radius
	_orbit_angle += angular_speed * delta
	
	# Calcular posición de órbita
	var target_position := center + Vector2(cos(_orbit_angle), sin(_orbit_angle)) * patrol_radius
	global_position = target_position
	
	# Calcular vector tangente para la velocidad física y orientación
	var tangent := Vector2(-sin(_orbit_angle), cos(_orbit_angle))
	velocity = tangent * patrol_speed
	
	# Alinear la cabeza en dirección tangencial al vuelo (sprite mirando al frente)
	global_rotation = tangent.angle() + PI / 2.0
	
	# Si completa la órbita (de -PI/2 a 3*PI/2) regresa al anclaje
	if _orbit_angle >= 3.0 * PI / 2.0:
		_end_explore()

## Comprueba si el jugador está dentro del cono de visión
func _is_player_in_cone() -> bool:
	if not _player:
		return false
	var to_player := (_player.global_position - global_position).normalized()
	var facing_dir := Vector2.UP.rotated(global_rotation)
	var angle := facing_dir.angle_to(to_player)
	return absf(angle) <= deg_to_rad(cone_angle / 2.0)

## Inicializa los puntos de un círculo en el Line2D
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
	# Desactivar que rote con el padre para que la onda de choque siempre se expanda circularmente de forma fija
	_alert_ring.top_level = true

## Actualiza el tamaño y transparencia del anillo expansivo
func _update_alert_ring(delta: float) -> void:
	if _alert_ring and _alert_ring.visible:
		# Mantener posicionado en el búho (ya que es top_level = true)
		_alert_ring.global_position = global_position + Vector2(0, -16)
		# Crecer radio de la onda
		_ring_radius += 120.0 * delta # velocidad de expansión
		# Desvanecimiento (fade out)
		_ring_alpha = maxf(0.0, 1.0 - (_ring_radius / _ring_max_radius))
		
		# Aplicar escala al anillo
		_alert_ring.scale = Vector2(_ring_radius, _ring_radius)
		# Aplicar opacidad roja
		_alert_ring.default_color = Color(1.0, 0.0, 0.0, _ring_alpha)
		
		# Si se desvanece por completo, se oculta o reinicia si continúa alertado
		if _ring_alpha <= 0.0:
			if _alerted:
				# Bucle de la onda mientras siga viendo al jugador
				_ring_radius = 0.0
				_ring_alpha = 1.0
			else:
				_alert_ring.visible = false

## Comprueba si hay línea de visión directa con el player (sin obstáculos en medio)
func _has_line_of_sight() -> bool:
	if not _player:
		return false
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, _player.global_position)
	query.exclude = [get_rid()]
	query.collision_mask = 1 | 2 # Terreno (1) y Jugador (2)
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

## Llamado cuando el jugador colisiona físicamente con el búho
func on_player_touched(player_node: Node2D) -> void:
	if not _alerted and not _player_stealthed:
		_alerted = true
		# Reiniciar efecto de onda expansiva
		_ring_radius = 0.0
		_ring_alpha = 1.0
		if _alert_ring:
			_alert_ring.visible = true
		
		print("OWL: Player touched physically! Triggering instant alert.")
		get_tree().call_group("enemy", "on_player_spotted", player_node.global_position)

func _get_player_node() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func _draw() -> void:
	# Dibujar el cono de visión en base a la rotación local del nodo (cabeza del búho apunta hacia UP por defecto)
	var points := PackedVector2Array()
	points.append(Vector2.ZERO) # Origen en el centro del búho
	
	var steps := 16
	var start_angle := -PI / 2.0 - deg_to_rad(cone_angle / 2.0)
	var end_angle := -PI / 2.0 + deg_to_rad(cone_angle / 2.0)
	
	for i in range(steps + 1):
		var angle = start_angle + (float(i) / steps) * (end_angle - start_angle)
		points.append(Vector2(cos(angle), sin(angle)) * detection_radius)
		
	# Definir color: Amarillo suave normal, Rojo si está alertado
	var color := Color(1.0, 0.9, 0.2, 0.08)
	if _alerted:
		color = Color(1.0, 0.1, 0.1, 0.16)
		
	draw_polygon(points, [color])

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
