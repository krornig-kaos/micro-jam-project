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
@export var vision_radius: float = 220.0
@export var noise_walk_radius: float = 120.0
@export var noise_sprint_radius: float = 250.0

# ─── Estado interno ────────────────────────────────────────────────────────────
enum State { NORMAL, LOADED, STEALTH, INTANGIBLE, DEAD }
enum Direction { DOWN, UP, LEFT, RIGHT }

var current_state: State = State.NORMAL
var current_direction: Direction = Direction.DOWN
var orb_count: int = 0
var is_dead: bool = false
var _in_hide_spot: bool = false
var _vision_light: PointLight2D = null
var current_noise_radius: float = 0.0

# ─── Nodos hijos ───────────────────────────────────────────────────────────────
@onready var _anim: AnimatedSprite2D      = $AnimatedSprite2D
@onready var _pickup_area: Area2D         = $PickupArea
@onready var _particles: GPUParticles2D   = $GPUParticles2D
@onready var _intangible_timer: Timer     = $IntangibleTimer
@onready var _stealth_area: Area2D        = $StealthDetector
@onready var _collision: CollisionShape2D = $PlayerArea/CollisionShape2D
@onready var _player_area: Area2D 		  = $PlayerArea

# ─── Godot lifecycle ───────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("player")
	_intangible_timer.wait_time = intangible_duration
	_intangible_timer.one_shot  = true
	_intangible_timer.timeout.connect(_on_intangible_timeout)
	_pickup_area.body_entered.connect(_on_pickup_body_entered)
	_stealth_area.area_entered.connect(_on_hide_spot_entered)
	_stealth_area.area_exited.connect(_on_hide_spot_exited)
	
	if _anim:
		_anim.animation_finished.connect(_on_animation_finished)
	
	# Inicializar la luz de visión y la niebla de guerra
	_setup_vision_and_shadows()

func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	var direction := _get_input_direction()
	var is_sprinting := Input.is_key_pressed(KEY_SHIFT) and direction != Vector2.ZERO
	var is_stealthing := Input.is_key_pressed(KEY_C)

	# Actualizar dirección solo cuando hay movimiento
	if direction != Vector2.ZERO:
		_update_direction(direction)

	# Actualizar estado sigilo (Manual con C, o automático al estar en escondite/arbusto)
	var needs_stealth := is_stealthing or _in_hide_spot
	if needs_stealth and current_state not in [State.DEAD, State.INTANGIBLE]:
		if current_state != State.STEALTH:
			current_state = State.STEALTH
			_particles.emitting = true
			get_tree().call_group("enemy", "on_player_stealthed", true)
	elif current_state == State.STEALTH and not needs_stealth:
		_exit_stealth()

	# Calcular emisión de ruido dinámica
	if direction == Vector2.ZERO or is_stealthing:
		current_noise_radius = 0.0
	elif is_sprinting:
		current_noise_radius = noise_sprint_radius
	else:
		current_noise_radius = noise_walk_radius

	velocity = direction * _effective_speed(is_sprinting)
	move_and_slide()
	_check_collisions()
	_update_animation(direction, is_sprinting, is_stealthing or _in_hide_spot)

	# Actualizar opacidad visual de feedback (oculto en arbusto, intangible o normal)
	if is_hidden():
		modulate.a = 0.55
	elif current_state == State.INTANGIBLE:
		modulate.a = 0.45
	else:
		modulate.a = 1.0

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	if event.is_action_pressed("powerup_intangible"):
		_activate_intangible()

func _get_input_direction() -> Vector2:
	var raw := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up",   "ui_down")
	)
	if raw == Vector2.ZERO:
		return Vector2.ZERO
	return raw.normalized()

# ─── Dirección dominante ───────────────────────────────────────────────────────
func _update_direction(dir: Vector2) -> void:
	# Priorizar la dirección dominante para las animaciones (izquierda, derecha, arriba, abajo)
	if absf(dir.x) >= absf(dir.y):
		if dir.x > 0.0:
			current_direction = Direction.RIGHT
		elif dir.x < 0.0:
			current_direction = Direction.LEFT
	else:
		if dir.y < 0.0:
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

# ─── Colisiones nativas robustas ───────────────────────────────────────────────
func _check_collisions() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider and collider.is_in_group("enemy"):
			if collider.is_in_group("non_lethal"):
				if collider.has_method("on_player_touched"):
					collider.on_player_touched(self)
			else:
				take_hit()

# ─── Animaciones ───────────────────────────────────────────────────────────────
func _update_animation(dir: Vector2, is_sprinting: bool, is_stealthing: bool) -> void:
	if is_dead:
		return
	var prefix: String
	if dir == Vector2.ZERO:
		prefix = "run" # Se asume la animación de "idle" o "walk" según el sprite, pero en su spritesheet corre/camina
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
	current_state = State.NORMAL
	_particles.emitting = false
	get_tree().call_group("enemy", "on_player_stealthed", false)
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

## Devuelve true si el player está oculto en un escondite/arbusto
func is_hidden() -> bool:
	return _in_hide_spot

# ─── Muerte ────────────────────────────────────────────────────────────────────
func die() -> void:
	if is_dead:
		return
	is_dead = true
	current_state = State.DEAD
	player_died.emit()
	_anim.play("death")
	_release_souls()

func _on_animation_finished() -> void:
	if _anim and _anim.animation == "death":
		# Instanciar pantalla de Game Over
		var game_over_scene := load("res://src/ui/game_over.tscn")
		if game_over_scene:
			var game_over_instance = game_over_scene.instantiate()
			# Añadir a la escena raíz actual
			get_tree().current_scene.add_child(game_over_instance)
			get_tree().paused = true

func _release_souls() -> void:
	get_tree().call_group("orb", "release")

func take_hit() -> void:
	if current_state == State.INTANGIBLE:
		return
	die()

# ─── Configuración de Luz y Sombras (Niebla de Guerra) ─────────────────────────
func _setup_vision_and_shadows() -> void:
	# 1. Crear e instanciar la luz de visión
	_vision_light = PointLight2D.new()
	
	# Generar textura radial plana programáticamente con un tono más suave (menos brillante)
	var gradient := Gradient.new()
	gradient.offsets = [0.0, 0.95, 1.0]
	var light_color := Color(0.7, 0.7, 0.7)
	gradient.colors = [light_color, light_color, Color(light_color.r, light_color.g, light_color.b, 0.0)]
	
	var grad_texture := GradientTexture2D.new()
	grad_texture.fill = GradientTexture2D.FILL_RADIAL
	grad_texture.fill_from = Vector2(0.5, 0.5)
	grad_texture.fill_to = Vector2(1.0, 0.5)
	grad_texture.gradient = gradient
	grad_texture.width = 512
	grad_texture.height = 512
	
	_vision_light.texture = grad_texture
	var scale_factor := (vision_radius * 2.0) / 512.0
	_vision_light.texture_scale = scale_factor
	_vision_light.shadow_enabled = true
	_vision_light.shadow_filter = PointLight2D.SHADOW_FILTER_PCF5
	
	add_child(_vision_light)

	# 2. Oscurecer el entorno del nivel con un CanvasModulate
	# Se usa call_deferred para esperar a que la escena esté completamente lista
	call_deferred("_add_canvas_modulator")

func _add_canvas_modulator() -> void:
	var parent := get_parent()
	if parent:
		var modulator = parent.get_node_or_null("CanvasModulate")
		if not modulator:
			modulator = CanvasModulate.new()
			modulator.name = "CanvasModulate"
			# Oscuridad moderada para mantener el mapa visible
			modulator.color = Color(0.55, 0.55, 0.55)
			parent.add_child(modulator)
			
		# Añadir oclusores de luz a todos los StaticBody2D de forma recursiva
		var level_root = get_tree().current_scene
		if level_root:
			_add_shadow_occluders_to_scene(level_root)

func _add_shadow_occluders_to_scene(node: Node) -> void:
	if node is StaticBody2D and node != self:
		_add_occluder_to_body(node)
	elif node is Sprite2D:
		_add_hidespot_to_sprite(node)
	for child in node.get_children():
		_add_shadow_occluders_to_scene(child)

func _add_occluder_to_body(body: StaticBody2D) -> void:
	# Evitar duplicar oclusores
	for child in body.get_children():
		if child is LightOccluder2D:
			return
			
	var col_shape: CollisionShape2D = null
	for child in body.get_children():
		if child is CollisionShape2D:
			col_shape = child
			break
			
	if not col_shape or not col_shape.shape:
		return
		
	var shape = col_shape.shape
	var points: PackedVector2Array = []
	
	if shape is RectangleShape2D:
		var size = shape.size
		var half_x = size.x / 2.0
		var half_y = size.y / 2.0
		points = PackedVector2Array([
			Vector2(-half_x, -half_y),
			Vector2(half_x, -half_y),
			Vector2(half_x, half_y),
			Vector2(-half_x, half_y)
		])
	elif shape is CircleShape2D:
		var radius = shape.radius
		var segments := 12
		for i in range(segments):
			var angle = (float(i) / segments) * TAU
			points.append(Vector2(cos(angle), sin(angle)) * radius)
	elif shape is CapsuleShape2D:
		var radius = shape.radius
		var height = shape.height
		var half_x = radius
		var half_y = height / 2.0
		points = PackedVector2Array([
			Vector2(-half_x, -half_y),
			Vector2(half_x, -half_y),
			Vector2(half_x, half_y),
			Vector2(-half_x, half_y)
		])
		
	if points.size() > 0:
		var occluder := LightOccluder2D.new()
		var poly := OccluderPolygon2D.new()
		poly.polygon = points
		occluder.occluder = poly
		occluder.position = col_shape.position
		body.add_child(occluder)

func _add_hidespot_to_sprite(sprite: Sprite2D) -> void:
	# 1. Verificar si ya tiene un escondite en sus hijos
	for child in sprite.get_children():
		if child.is_in_group("hide_spot"):
			return
			
	# 2. Identificar si es vegetación tipo arbusto/planta/hongo (Chanterelles, Mushroom)
	var is_hiding_spot := false
	var lower_name := sprite.name.to_lower()
	for keyword in ["chanterelles", "mushroom", "bush"]:
		if keyword in lower_name:
			is_hiding_spot = true
			break
			
	if not is_hiding_spot:
		return
		
	# 3. Instanciar HideSpot.tscn dinámicamente
	var hide_spot_scene := load("res://src/props/HideSpot.tscn")
	if hide_spot_scene:
		var hide_spot = hide_spot_scene.instantiate()
		hide_spot.position = Vector2.ZERO
		sprite.add_child(hide_spot)

