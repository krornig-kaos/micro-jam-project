## Personaje principal del jugador.
##
## CharacterBody2D con vista cenital (top-down) al estilo Don't Starve Together.
## Gestiona movimiento, recolección de orbes, sigilo, power-up de intangibilidad
## y entrega de almas en el Punto B.
##
## Señales emitidas:
##   orb_collected(total)   → HUD actualiza contador
##   player_died            → GameManager reinicia escena
##   souls_delivered(amount) → GameManager revive animales
extends CharacterBody2D

# ─── Señales ───────────────────────────────────────────────────────────────────
signal orb_collected(total: int)
signal player_died
signal souls_delivered(amount: int)

# ─── Exportables (ajustables desde el Inspector sin tocar código) ──────────────
## Velocidad base en píxeles por segundo
@export var base_speed: float = 320.0
## Penalización de velocidad por cada orbe cargado
@export var speed_penalty_per_orb: float = 18.0
## Velocidad mínima (con muchos orbes)
@export var min_speed: float = 80.0
## Duración del power-up de intangibilidad en segundos
@export var intangible_duration: float = 3.0

# ─── Estado interno ────────────────────────────────────────────────────────────
enum State { NORMAL, LOADED, STEALTH, INTANGIBLE, DEAD }

var current_state: State = State.NORMAL
var orb_count: int = 0
var is_dead: bool = false

# ─── Nodos hijos ───────────────────────────────────────────────────────────────
@onready var _anim: AnimatedSprite2D        = $AnimatedSprite2D
@onready var _collision: CollisionShape2D   = $CollisionShape2D
@onready var _pickup_area: Area2D           = $PickupArea
@onready var _particles: GPUParticles2D     = $GPUParticles2D
@onready var _intangible_timer: Timer       = $IntangibleTimer

# ─── Godot lifecycle ───────────────────────────────────────────────────────────
func _ready() -> void:
	_intangible_timer.wait_time = intangible_duration
	_intangible_timer.one_shot  = true
	_intangible_timer.timeout.connect(_on_intangible_timeout)
	_pickup_area.body_entered.connect(_on_pickup_body_entered)

func _physics_process(_delta: float) -> void:
	if is_dead:
		return
	var direction := _get_input_direction()
	velocity = direction * _effective_speed()
	move_and_slide()
	_update_animation(direction)

# ─── Input ─────────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	# Sigilo: mantener pulsado para activar, soltar para desactivar
	if event.is_action_pressed("stealth"):
		_enter_stealth()
	elif event.is_action_released("stealth"):
		_exit_stealth()
	# Power-up de intangibilidad
	if event.is_action_pressed("powerup_intangible"):
		_activate_intangible()

func _get_input_direction() -> Vector2:
	return Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up",   "ui_down")
	).normalized()

# ─── Velocidad efectiva ────────────────────────────────────────────────────────
## Devuelve la velocidad real del frame según el estado activo y los orbes
## portados. Fórmula: max(min_speed, base_speed - orb_count × penalty)
func _effective_speed() -> float:
	match current_state:
		State.STEALTH:
			return 0.0          # inmóvil en sigilo (modifica si prefieres sigilo lento)
		State.INTANGIBLE:
			return base_speed   # intangible corre a velocidad plena
		_:
			return maxf(min_speed, base_speed - orb_count * speed_penalty_per_orb)

# ─── Animaciones ───────────────────────────────────────────────────────────────
## Usa un único spritesheet de Run con flip_h para izquierda/derecha.
## Animaciones requeridas en SpriteFrames: idle, run, stealth, death, hurt
func _update_animation(dir: Vector2) -> void:
	if dir.x != 0.0:
		_anim.flip_h = dir.x < 0.0
	_anim.play("idle")

# ─── Gestión de estados ────────────────────────────────────────────────────────
func _update_state() -> void:
	if is_dead:
		current_state = State.DEAD
		return
	# No interrumpir estados activos gestionados por su propio flujo
	if current_state in [State.INTANGIBLE, State.STEALTH]:
		return
	current_state = State.LOADED if orb_count > 0 else State.NORMAL

func _enter_stealth() -> void:
	if current_state in [State.DEAD, State.INTANGIBLE]:
		return
	current_state = State.STEALTH
	_particles.emitting = true
	# Notificar a enemigos para reducir su campo de visión
	get_tree().call_group("enemies", "on_player_stealthed", true)

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
	# Desactivar colisiones (set_deferred evita errores mid-physics)
	_collision.set_deferred("disabled", true)
	modulate.a = 0.45           # feedback visual: translúcido
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
	# El orbe decide cómo adjuntarse visualmente (tween hacia el player, etc.)
	body.collect(self)
	_update_state()
	orb_collected.emit(orb_count)

# ─── Entrega de almas en Punto B ──────────────────────────────────────────────
## Llamado por el nodo del Punto B al detectar al player dentro de su área.
func deliver_souls() -> void:
	if orb_count == 0:
		return
	souls_delivered.emit(orb_count)
	orb_count = 0
	_update_state()

# ─── Muerte ────────────────────────────────────────────────────────────────────
## Llamado por el GameManager o por los enemigos al confirmar impacto.
func die() -> void:
	if is_dead:
		return
	is_dead = true
	current_state = State.DEAD
	player_died.emit()
	_anim.play("death")
	# GameManager escucha player_died y llama get_tree().reload_current_scene()

## Punto de entrada para que los enemigos inflijan daño.
## Durante la intangibilidad el golpe es absorbido sin consecuencias.
func take_hit() -> void:
	if current_state == State.INTANGIBLE:
		return
	die()
