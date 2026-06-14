## Búho patrullero — vuela en un patrón circular fijo vigilando el área.
## Detecta al player desde más lejos pero no lo ataca directamente.
## En su lugar, emite una alarma que alerta al Zorro o Jabalí más cercano.
extends CharacterBody2D

@export var patrol_speed: float = 100.0
@export var detection_radius: float = 250.0
@export var patrol_radius: float = 200.0

var _center: Vector2
var _angle: float = 0.0
var _player: Node2D = null
var _player_stealthed: bool = false
var _alerted: bool = false

# Variables para la onda expansiva roja
var _ring_radius: float = 0.0
var _ring_max_radius: float = 40.0
var _ring_fade_speed: float = 2.0
var _ring_alpha: float = 1.0

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _detection: Area2D = $DetectionArea
@onready var _alert_ring: Line2D = get_node_or_null("AlertRing")

func _ready() -> void:
	add_to_group("enemy")
	_center = global_position
	_detection.body_entered.connect(_on_detection_entered)
	_detection.body_exited.connect(_on_detection_exited)
	
	# Configurar el Line2D del anillo para que dibuje un círculo aproximado si existe
	if _alert_ring:
		_setup_alert_ring()

func _physics_process(delta: float) -> void:
	# Patrulla circular fluida
	_angle += patrol_speed * delta * 0.01
	var target := _center + Vector2(cos(_angle), sin(_angle)) * patrol_radius
	var dir := (target - global_position).normalized()
	velocity = dir * patrol_speed
	
	# Moverse libremente sobre las paredes (es un ave)
	move_and_slide()
	
	_anim.flip_h = velocity.x < 0
	_anim.play("fly")

	# Controlar alerta y línea de visión directa
	if _player and not _player_stealthed and _has_line_of_sight():
		if not _alerted:
			_alerted = true
			# Reiniciar efecto de onda expansiva
			_ring_radius = 0.0
			_ring_alpha = 1.0
			if _alert_ring:
				_alert_ring.visible = true
			
			# Emitir una alerta visual en consola y notificar al grupo "enemy"
			print("OWL: Player spotted! Alerting nearby land enemies.")
			get_tree().call_group("enemy", "on_player_spotted", _player.global_position)
	else:
		_alerted = false

	# Actualizar la animación de la onda expansiva
	_update_alert_ring(delta)

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
	# Posicionarlo encima de la cabeza del búho
	_alert_ring.position = Vector2(0, -16)

## Actualiza el tamaño y transparencia del anillo expansivo
func _update_alert_ring(delta: float) -> void:
	if _alert_ring and _alert_ring.visible:
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
	# El búho también colisiona con el terreno (Capa 1) para la línea de visión
	query.collision_mask = 1 | 2 # Paredes/Obstáculos (1) y Jugador (2)
	var result := space_state.intersect_ray(query)
	if result:
		# Imprimir contra qué chocó para debugear si es necesario
		# print("Owl ray hit: ", result.collider.name)
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
