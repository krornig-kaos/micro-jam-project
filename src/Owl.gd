## Búho patrullero — vuela en un patrón fijo vigilando el área.
## Detecta al player desde más lejos pero no persigue, solo marca su posición
## para alertar al Zorro más cercano.
extends CharacterBody2D

@export var patrol_speed: float = 100.0
@export var detection_radius: float = 250.0
@export var patrol_radius: float = 200.0

var _center: Vector2
var _angle: float = 0.0
var _player_stealthed: bool = false
var _alerted: bool = false

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _detection: Area2D = $DetectionArea

func _ready() -> void:
	_center = global_position
	_detection.body_entered.connect(_on_detection_entered)
	_detection.body_exited.connect(_on_detection_exited)

func _physics_process(delta: float) -> void:
	# Patrulla circular
	_angle += patrol_speed * delta * 0.01
	var target := _center + Vector2(cos(_angle), sin(_angle)) * patrol_radius
	var dir := (target - global_position).normalized()
	velocity = dir * patrol_speed
	move_and_slide()
	_anim.flip_h = velocity.x < 0
	_anim.play("fly" if _anim.sprite_frames and _anim.sprite_frames.has_animation("fly") else "idle")

func _on_detection_entered(body: Node) -> void:
	if body.is_in_group("player") and not _player_stealthed:
		# Alertar a todos los zorros del nivel
		get_tree().call_group("fox", "on_player_spotted", body.global_position)
		_alerted = true

func _on_detection_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_alerted = false

func on_player_stealthed(is_stealthed: bool) -> void:
	_player_stealthed = is_stealthed
