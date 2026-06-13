## Personaje principal del jugador.
## Movimiento top-down con 4 direcciones y animaciones por dirección.
extends CharacterBody2D

# ─── Señales ───────────────────────────────────────────────────────────────────
signal orb_collected(total: int)
signal player_died
signal souls_delivered(amount: int)

# ─── Exportables ───────────────────────────────────────────────────────────────
@export var base_speed: float = 200.0
@export var sprint_multiplier: float = 2.0
@export var stealth_speed: float = 80.0
@export var speed_penalty_per_orb: float = 18.0
@export var min_speed: float = 60.0
@export var intangible_duration: float = 3.0

# ─── Estado interno ────────────────────────────────────────────────────────────
enum State { NORMAL, LOADED, STEALTH, INTANGIBLE, DEAD }
enum Direction { DOWN, UP, LEFT, RIGHT }

var current_state: State = State.NORMAL
var current_direction: Direction = Direction.DOWN
var orb_count: int = 0
var is_dead: bool = false
var _in_hide_spot: bool = false

# ─── Nodos hijos ───────────────────────────────────────────────────────────────
@onready var _anim: AnimatedSprite2D      = $AnimatedSprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _pickup_area: Area2D         = $PickupArea
@onready var _particles: GPUParticles2D   = $GPUParticles2D
@onready var _intangible_timer: Timer     = $IntangibleTimer
@onready var _stealth_area: Area2D        = $StealthDetector

# ─── Godot lifecycle ───────────────────────────────────────────────────────────
func _ready() -> void:
	_intangible_timer.wait_time = intangible_duration
	_intangible_timer.one_shot  = true
	_intangible_timer.timeout.connect(_on_intangible_timeout)
	_pickup_area.body_entered.connect(_on_pickup_body_entered)
	_stealth_area.area_entered.connect(_on_hide_spot_entered)
	_stealth_area.area_exited.connect(_on_hide_spot_exited)

func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	var direction := _get_input_direction()
	var is_sprinting := Input.is_key_pressed(KEY_SHIFT) and direction != Vector2.ZERO
	var is_stealthing := Input.is_key_pressed(KEY_C) and direction != Vector2.ZERO

	# Actualizar dirección solo cuando hay movimiento
	if direction != Vector2.ZERO:
		_update_direction(direction)

	# Actualizar estado sigilo
	if is_stealthing and current_state not in [State.DEAD, State.INTANGIBLE]:
		current_state = State.STEALTH
		_particles.emitting = true
	elif current_state == State.STEALTH and not is_stealthing:
		_exit_stealth()

	velocity = direction * _effective_speed(is_sprinting)
	move_and_slide()
	_update_animation(direction, is_sprinting, is_stealthing)

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	if event.is_action_pressed("powerup_intangible"):
		_activate_intangible()

func _get_input_direction() -> Vector2:
	# Sin diagonales — el eje con mayor valor gana
	var raw := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up",   "ui_down")
	)
	if raw == Vector2.ZERO:
		return Vector2.ZERO
	if absf(raw.x) >= absf(raw.y):
		return Vector2(signf(raw.x), 0.0)
	else:
		return Vector2(0.0, signf(raw.y))

# ─── Dirección dominante ───────────────────────────────────────────────────────
func _update_direction(dir: Vector2) -> void:
	if dir.x > 0.0:
		current_direction = Direction.RIGHT
	elif dir.x < 0.0:
		current_direction = Direction.LEFT
	elif dir.y < 0.0:
		current_direction = Direction.UP
	elif dir.y > 0.0:
		current_direction = Direction.DOWN

# ─── Velocidad efectiva ────────────────────────────────────────────────────────
func _effective_speed(is_sprinting: bool) -> float:
	match current_state:
		State.STEALTH:
			return stealth_speed
		State.INTANGIBLE:
			return base_speed
		State.DEAD:
			return 0.0
		_:
			var speed := maxf(min_speed, base_speed - orb_count * speed_penalty_per_orb)
			return speed * sprint_multiplier if is_sprinting else speed

# ─── Animaciones ───────────────────────────────────────────────────────────────
func _update_animation(dir: Vector2, is_sprinting: bool, is_stealthing: bool) -> void:
	var prefix: String
	if dir == Vector2.ZERO:
		prefix = "run"
	elif is_stealthing:
		prefix = "stealth"
	elif is_sprinting:
		prefix = "run"
	else:
		prefix = "run"

	var suffix: String
	match current_direction:
		Direction.DOWN:  suffix = "_down"
		Direction.UP:    suffix = "_up"
		Direction.LEFT:  suffix = "_left"
		Direction.RIGHT: suffix = "_right"

	_anim.play(prefix + suffix)

# ─── Gestión de estados ────────────────────────────────────────────────────────
func _update_state() -> void:
	if is_dead:
		current_state = State.DEAD
		return
	if current_state in [State.INTANGIBLE, State.STEALTH]:
		return
	current_state = State.LOADED if orb_count > 0 else State.NORMAL

func _exit_stealth() -> void:
	if current_state != State.STEALTH:
		return
	_particles.emitting = false
	get_tree().call_group("enemies", "on_player_stealthed", false)
	_update_state()

func _activate_intangible() -> void:
	if current_state in [State.DEAD, State.INTANGIBLE]:
		return
	current_state = State.INTANGIBLE
	_collision.set_deferred("disabled", true)
	modulate.a = 0.45
	_particles.emitting = true
	_intangible_timer.start()

func _on_intangible_timeout() -> void:
	_collision.set_deferred("disabled", false)
	modulate.a = 1.0
	_particles.emitting = false
	_update_state()

# ─── Recolección de orbes ──────────────────────────────────────────────────────
func _on_pickup_body_entered(body: Node) -> void:
	if not body.is_in_group("orb"):
		return
	orb_count += 1
	body.collect(self)
	_update_state()
	orb_collected.emit(orb_count)

# ─── Entrega de almas en Punto B ──────────────────────────────────────────────
func deliver_souls() -> void:
	if orb_count == 0:
		return
	souls_delivered.emit(orb_count)
	orb_count = 0
	_update_state()

# ─── Detección de zonas de sigilo ─────────────────────────────────────────────
func _on_hide_spot_entered(area: Area2D) -> void:
	if area.is_in_group("hide_spot"):
		_in_hide_spot = true

func _on_hide_spot_exited(area: Area2D) -> void:
	if area.is_in_group("hide_spot"):
		_in_hide_spot = false

## Devuelve true si el player está oculto (en zona de sigilo + estado stealth)
func is_hidden() -> bool:
	return _in_hide_spot and current_state == State.STEALTH

# ─── Muerte ────────────────────────────────────────────────────────────────────
func die() -> void:
	if is_dead:
		return
	is_dead = true
	current_state = State.DEAD
	player_died.emit()
	_anim.play("death")

func take_hit() -> void:
	if current_state == State.INTANGIBLE:
		return
	die()
