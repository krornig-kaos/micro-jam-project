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

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("orb")
	_initial_position = global_position
	body_entered.connect(_on_body_entered)

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

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not _collected:
		body.call("_on_pickup_body_entered", self)
