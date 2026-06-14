## Alma flotante que el player puede recolectar.
## Al ser recogida sigue al player y reduce su velocidad.
extends Area2D

@export var float_speed: float = 2.0
@export var float_amplitude: float = 5.0
@export var follow_speed: float = 8.0

var _collected: bool = false
var _player: Node2D = null
var _initial_position: Vector2
var _time: float = 0.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("orb")
	
	# Hacer que el alma solo sea visible bajo la luz (invisible en sombras)
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_LIGHT_ONLY
	_sprite.material = mat
	
	_initial_position = global_position
	body_entered.connect(_on_body_entered)
	
	# Inicializar rastro de partículas místicas
	_setup_trail_particles()

func _process(delta: float) -> void:
	_time += delta
	if _collected and _player:
		# Seguir al player suavemente
		global_position = global_position.lerp(
			_player.global_position + Vector2(0, -20),
			follow_speed * delta
		)
	else:
		# Flotar arriba y abajo
		position.y = _initial_position.y + sin(_time * float_speed) * float_amplitude

## Llamado por el player al recoger el alma
func collect(player: Node2D) -> void:
	_collected = true
	_player = player
	_collision.set_deferred("disabled", true)
	# Efecto visual: el alma se vuelve más pequeña y semitransparente
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.7, 0.3)
	tween.tween_property(self, "scale", Vector2(0.6, 0.6), 0.3)

## Llamado cuando el player muere — el alma vuelve a su posición inicial
func release() -> void:
	_collected = false
	_player = null
	_collision.set_deferred("disabled", false)
	global_position = _initial_position
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate:a", 1.0, 0.3)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)

## Llamado al entregar el alma con éxito en el Altar (Punto B)
func consume_delivered(player_node: Node2D) -> void:
	if _collected and _player == player_node:
		_collected = false
		_player = null
		
		# Animación de desvanecimiento ascendente al liberarse
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(_sprite, "modulate:a", 0.0, 0.4)
		tween.tween_property(self, "scale", Vector2(0.0, 0.0), 0.4)
		tween.tween_property(self, "global_position", global_position + Vector2(0, -40), 0.4)
		
		# Eliminar el alma una vez termine la animación
		tween.chain().tween_callback(queue_free)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not _collected:
		body.call("_on_pickup_body_entered", self)

func _setup_trail_particles() -> void:
	var particles := CPUParticles2D.new()
	particles.amount = 12
	particles.lifetime = 0.5
	particles.local_coords = false # IMPORTANTE: Crea el rastro (trail) en el mundo al moverse
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 8.0
	
	# Gravedad y dirección hacia arriba de forma sutil
	particles.gravity = Vector2(0.0, -20.0)
	
	# Variación de velocidad inicial
	particles.spread = 180.0
	particles.initial_velocity_min = 5.0
	particles.initial_velocity_max = 15.0
	
	# Escala inicial y curva de atenuación
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	
	# Color: Chispas celestes/místicas semi-transparentes
	particles.color = Color(0.4, 0.8, 1.0, 0.6)
	
	# Curva de color o atenuación lineal
	var color_ramp := Gradient.new()
	color_ramp.offsets = [0.0, 1.0]
	color_ramp.colors = [Color(0.4, 0.8, 1.0, 0.6), Color(0.4, 0.8, 1.0, 0.0)]
	particles.color_ramp = color_ramp
	
	# Hacer que no se vea afectada por la iluminación del material LIGHT_MODE_LIGHT_ONLY
	# Queremos que las chispas brillen en la oscuridad
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	particles.material = mat
	
	add_child(particles)
