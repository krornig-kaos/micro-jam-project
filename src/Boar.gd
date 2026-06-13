## Jabalí — patrulla buscando al player, al detectarlo embiste en línea recta.
## Si falla la embestida se queda aturdido brevemente.
extends CharacterBody2D

@export var patrol_speed: float = 60.0
@export var charge_speed: float = 300.0
@export var detection_radius: float = 120.0
@export var charge_duration: float = 0.8
@export var stun_duration: float = 1.2

enum State { PATROL, WINDUP, CHARGE, STUN }
var current_state: State = State.PATROL
var _charge_direction: Vector2 = Vector2.ZERO
var _state_timer: float = 0.0
var _patrol_dir: Vector2 = Vector2.RIGHT

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _detection: Area2D = $DetectionArea

func _ready() -> void:
	_detection.body_entered.connect(_on_detection_entered)

func _physics_process(delta: float) -> void:
	_state_timer -= delta
	match current_state:
		State.PATROL:
			_do_patrol()
		State.WINDUP:
			velocity = Vector2.ZERO
			if _state_timer <= 0.0:
				current_state = State.CHARGE
				_state_timer = charge_duration
		State.CHARGE:
			velocity = _charge_direction * charge_speed
			_anim.play("run")
			if _state_timer <= 0.0:
				current_state = State.STUN
				_state_timer = stun_duration
				velocity = Vector2.ZERO
		State.STUN:
			velocity = Vector2.ZERO
			_anim.play("idle")
			if _state_timer <= 0.0:
				current_state = State.PATROL
	move_and_slide()

func _do_patrol() -> void:
	velocity = _patrol_dir * patrol_speed
	_anim.flip_h = velocity.x < 0
	_anim.play("walk")
	if get_slide_collision_count() > 0:
		_patrol_dir = -_patrol_dir

func _on_detection_entered(body: Node) -> void:
	if body.is_in_group("player") and current_state == State.PATROL:
		if body.is_hidden() if body.has_method("is_hidden") else false:
			return
		_charge_direction = (body.global_position - global_position).normalized()
		current_state = State.WINDUP
		_state_timer = 0.5
		_anim.play("idle")

func on_player_stealthed(_is_stealthed: bool) -> void:
	pass

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and current_state == State.CHARGE:
		body.take_hit()
