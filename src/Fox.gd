## Zorro — enemigo que patrulla y persigue al player si lo detecta.
## Si el player está en sigilo no lo detecta.
extends CharacterBody2D

@export var patrol_speed: float = 80.0
@export var chase_speed: float = 160.0
@export var detection_radius: float = 150.0
@export var patrol_points: Array[Vector2] = []

enum State { PATROL, CHASE }
var current_state: State = State.PATROL
var _patrol_index: int = 0
var _player: Node2D = null
var _player_stealthed: bool = false

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _detection: Area2D = $DetectionArea

func _ready() -> void:
	_detection.body_entered.connect(_on_detection_entered)
	_detection.body_exited.connect(_on_detection_exited)
	if patrol_points.is_empty():
		patrol_points = [global_position, global_position + Vector2(100, 0)]

func _physics_process(_delta: float) -> void:
	match current_state:
		State.PATROL:
			_do_patrol()
		State.CHASE:
			_do_chase()
	move_and_slide()

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

func _on_detection_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player = body
		if not _player_stealthed:
			current_state = State.CHASE

func _on_detection_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player = null
		current_state = State.PATROL

## Llamado por el player cuando activa/desactiva sigilo
func on_player_stealthed(is_stealthed: bool) -> void:
	_player_stealthed = is_stealthed
	if is_stealthed:
		current_state = State.PATROL
		velocity = Vector2.ZERO
	elif _player and global_position.distance_to(_player.global_position) < detection_radius:
		current_state = State.CHASE

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_hit()
