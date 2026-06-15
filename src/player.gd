## Personaje principal del jugador.
## Movimiento top-down con 4 direcciones y animaciones por dirección.
extends CharacterBody2D

# ─── Señales ───────────────────────────────────────────────────────────────────
signal orb_collected(total: int)
signal player_died
signal souls_delivered(amount: int)
signal footstep
signal stealth_toggled(is_on: bool)
signal intangible_activated

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
var _dust_particles: CPUParticles2D = null
var _stealth_particles: CPUParticles2D = null
var _intangible_particles: CPUParticles2D = null
var _puff_particles: CPUParticles2D = null

# ─── Nodos hijos ───────────────────────────────────────────────────────────────
@onready var _anim: AnimatedSprite2D      = $AnimatedSprite2D
@onready var _pickup_area: Area2D         = $PickupArea
@onready var _particles: GPUParticles2D   = $GPUParticles2D
@onready var _intangible_timer: Timer     = $IntangibleTimer
@onready var _stealth_area: Area2D        = $StealthDetector
@onready var _collision: CollisionShape2D = $CollisionShape2D

var _intangible_sound_node: AudioStreamPlayer2D = null

var _footstep_timer: float = 0.0

# ─── Godot lifecycle ───────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("player")
	
	# Conectar señales de audio al AudioManager
	footstep.connect(func(): AudioManager.play_sfx("player_footsteps", global_position, -5.0))
	stealth_toggled.connect(func(is_on): if is_on: AudioManager.play_sfx("stealth_on", global_position))
	intangible_activated.connect(func(): _intangible_sound_node = AudioManager.play_sfx("intangible_cast", global_position))
	player_died.connect(func(): 
		AudioManager.play_sfx("player_death", global_position)
		if _intangible_sound_node:
			AudioManager.stop_sfx(_intangible_sound_node)
			_intangible_sound_node = null
	)
	
	_intangible_timer.wait_time = intangible_duration
	_intangible_timer.one_shot  = true
	_intangible_timer.timeout.connect(_on_intangible_timeout)
	_pickup_area.body_entered.connect(_on_pickup_body_entered)
	_stealth_area.area_entered.connect(_on_hide_spot_entered)
	_stealth_area.area_exited.connect(_on_hide_spot_exited)

	if _anim:
		_anim.animation_finished.connect(_on_animation_finished)

	_setup_vision_and_shadows()
	_setup_dust_particles()
	_setup_stealth_particles()
	_setup_intangible_particles()
	_setup_puff_particles()

func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	var direction := _get_input_direction()
	var is_sprinting := Input.is_key_pressed(KEY_SHIFT) and direction != Vector2.ZERO
	var is_stealthing := Input.is_key_pressed(KEY_C)

	if direction != Vector2.ZERO:
		_update_direction(direction)

	var needs_stealth := is_stealthing or _in_hide_spot
	if needs_stealth and current_state not in [State.DEAD, State.INTANGIBLE]:
		if current_state != State.STEALTH:
			current_state = State.STEALTH
			stealth_toggled.emit(true)
			if _stealth_particles:
				_stealth_particles.emitting = true
			get_tree().call_group("enemy", "on_player_stealthed", true)
	elif current_state == State.STEALTH and not needs_stealth:
		_exit_stealth()

	if direction == Vector2.ZERO or is_stealthing:
		current_noise_radius = 0.0
	elif is_sprinting:
		current_noise_radius = noise_sprint_radius
	else:
		current_noise_radius = noise_walk_radius

	velocity = direction * _effective_speed(is_sprinting)
	move_and_slide()
	
	# Emitir pasos
	if velocity.length() > 10.0 and current_state != State.STEALTH:
		_footstep_timer -= _delta
		if _footstep_timer <= 0.0:
			footstep.emit()
			# El intervalo depende de si corre o camina
			_footstep_timer = 0.25 if is_sprinting else 0.4
	else:
		_footstep_timer = 0.0

	# Limitar al player dentro de los bordes del mundo
	global_position.x = clampf(global_position.x, 0.0, 1152.0)
	global_position.y = clampf(global_position.y, 0.0, 648.0)
	_check_collisions()
	_update_animation(direction, is_sprinting, is_stealthing or _in_hide_spot)

	if _dust_particles:
		var is_moving := velocity.length_squared() > 10.0
		_dust_particles.emitting = is_moving and current_state != State.STEALTH
		if is_moving:
			_dust_particles.amount = 12 if is_sprinting else 6
			_dust_particles.speed_scale = 1.5 if is_sprinting else 1.0

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
			return base_speed * sprint_multiplier if is_sprinting else base_speed
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
				# No recibir daño si el player está en sigilo o escondido
				if current_state == State.STEALTH or _in_hide_spot:
					continue
				take_hit()

# ─── Animaciones ───────────────────────────────────────────────────────────────
func _update_animation(dir: Vector2, is_sprinting: bool, is_stealthing: bool) -> void:
	if is_dead:
		return

	var prefix: String

	if is_stealthing:
		# En sigilo siempre usa stealth_*, se mueva o no
		prefix = "stealth"
	elif dir == Vector2.ZERO:
		# Sin input de movimiento → idle
		prefix = "idle"
	else:
		# Moviéndose (sprint o walk usan el mismo set run_*)
		prefix = "run"

	var suffix: String
	match current_direction:
		Direction.DOWN:  suffix = "_down"
		Direction.UP:    suffix = "_up"
		Direction.LEFT:  suffix = "_left"
		Direction.RIGHT: suffix = "_right"

	var anim_name := prefix + suffix
	# Evitar reiniciar la animación si ya está reproduciendo la misma
	if _anim.animation != anim_name:
		_anim.play(anim_name)

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
	stealth_toggled.emit(false)
	if _stealth_particles:
		_stealth_particles.emitting = false
	get_tree().call_group("enemy", "on_player_stealthed", false)
	_update_state()

func _activate_intangible() -> void:
	if current_state in [State.DEAD, State.INTANGIBLE]:
		return
	current_state = State.INTANGIBLE
	intangible_activated.emit()
	_collision.set_deferred("disabled", true)
	modulate.a = 0.45
	if _intangible_particles:
		_intangible_particles.emitting = true
	_intangible_timer.start()

func _on_intangible_timeout() -> void:
	_collision.set_deferred("disabled", false)
	modulate.a = 1.0
	if _intangible_particles:
		_intangible_particles.emitting = false
	if _intangible_sound_node:
		AudioManager.stop_sfx(_intangible_sound_node)
		_intangible_sound_node = null
	current_state = State.NORMAL
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
	get_tree().call_group("orb", "consume_delivered", self)
	souls_delivered.emit(orb_count)
	orb_count = 0
	_update_state()

# ─── Detección de zonas de sigilo ─────────────────────────────────────────────
func _on_hide_spot_entered(area: Area2D) -> void:
	if area.is_in_group("hide_spot"):
		_in_hide_spot = true
		AudioManager.play_sfx("bush_rustle", global_position)
		if _puff_particles:
			_puff_particles.restart()
			_puff_particles.emitting = true

func _on_hide_spot_exited(area: Area2D) -> void:
	if area.is_in_group("hide_spot"):
		_in_hide_spot = false
		if _puff_particles:
			_puff_particles.restart()
			_puff_particles.emitting = true

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
		var game_over_scene := load("res://src/ui/game_over.tscn")
		if game_over_scene:
			var game_over_instance = game_over_scene.instantiate()
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
	_vision_light = PointLight2D.new()

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
	call_deferred("_add_canvas_modulator")

func _add_canvas_modulator() -> void:
	var parent := get_parent()
	if parent:
		var modulator = parent.get_node_or_null("CanvasModulate")
		if not modulator:
			modulator = CanvasModulate.new()
			modulator.name = "CanvasModulate"
			modulator.color = Color(0.55, 0.55, 0.55)
			parent.add_child(modulator)

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
	for child in sprite.get_children():
		if child.is_in_group("hide_spot"):
			return

	var is_hiding_spot := false
	var lower_name := sprite.name.to_lower()
	for keyword in ["chanterelles", "mushroom", "bush"]:
		if keyword in lower_name:
			is_hiding_spot = true
			break

	if not is_hiding_spot:
		return

	var hide_spot_scene := load("res://src/props/HideSpot.tscn")
	if hide_spot_scene:
		var hide_spot = hide_spot_scene.instantiate()
		hide_spot.position = Vector2.ZERO
		sprite.add_child(hide_spot)

func _setup_dust_particles() -> void:
	_dust_particles = CPUParticles2D.new()
	_dust_particles.amount = 6
	_dust_particles.lifetime = 0.4
	_dust_particles.local_coords = false
	_dust_particles.position = Vector2(12, 24)
	_dust_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust_particles.emission_rect_extents = Vector2(6.0, 2.0)
	_dust_particles.direction = Vector2(0.0, -1.0)
	_dust_particles.spread = 45.0
	_dust_particles.gravity = Vector2(0.0, -15.0)
	_dust_particles.initial_velocity_min = 5.0
	_dust_particles.initial_velocity_max = 12.0
	_dust_particles.scale_amount_min = 2.0
	_dust_particles.scale_amount_max = 5.0
	_dust_particles.color = Color(0.65, 0.58, 0.5, 0.35)

	var color_ramp := Gradient.new()
	color_ramp.offsets = [0.0, 1.0]
	color_ramp.colors = [Color(0.65, 0.58, 0.5, 0.35), Color(0.65, 0.58, 0.5, 0.0)]
	_dust_particles.color_ramp = color_ramp

	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_NORMAL
	_dust_particles.material = mat

	add_child(_dust_particles)

func _setup_stealth_particles() -> void:
	_stealth_particles = CPUParticles2D.new()
	_stealth_particles.amount = 8
	_stealth_particles.lifetime = 0.6
	_stealth_particles.local_coords = false
	_stealth_particles.position = Vector2(12, 12)
	_stealth_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_stealth_particles.emission_sphere_radius = 16.0
	_stealth_particles.gravity = Vector2(0.0, -10.0)
	_stealth_particles.spread = 45.0
	_stealth_particles.initial_velocity_min = 5.0
	_stealth_particles.initial_velocity_max = 12.0
	_stealth_particles.scale_amount_min = 3.0
	_stealth_particles.scale_amount_max = 5.0
	_stealth_particles.color = Color(0.3, 0.7, 0.2, 0.4)

	var color_ramp := Gradient.new()
	color_ramp.offsets = [0.0, 1.0]
	color_ramp.colors = [Color(0.3, 0.7, 0.2, 0.4), Color(0.3, 0.7, 0.2, 0.0)]
	_stealth_particles.color_ramp = color_ramp

	var p_mat := CanvasItemMaterial.new()
	p_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_stealth_particles.material = p_mat

	add_child(_stealth_particles)

func _setup_intangible_particles() -> void:
	_intangible_particles = CPUParticles2D.new()
	_intangible_particles.amount = 20
	_intangible_particles.lifetime = 0.5
	_intangible_particles.local_coords = false
	_intangible_particles.position = Vector2(12, 8)
	_intangible_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_intangible_particles.emission_sphere_radius = 20.0
	_intangible_particles.gravity = Vector2(0.0, -30.0)
	_intangible_particles.spread = 180.0
	_intangible_particles.initial_velocity_min = 10.0
	_intangible_particles.initial_velocity_max = 25.0
	_intangible_particles.scale_amount_min = 2.0
	_intangible_particles.scale_amount_max = 4.0
	_intangible_particles.color = Color(0.4, 0.9, 1.0, 0.7)

	var color_ramp := Gradient.new()
	color_ramp.offsets = [0.0, 1.0]
	color_ramp.colors = [Color(0.4, 0.9, 1.0, 0.7), Color(0.4, 0.9, 1.0, 0.0)]
	_intangible_particles.color_ramp = color_ramp

	var p_mat := CanvasItemMaterial.new()
	p_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_intangible_particles.material = p_mat

	add_child(_intangible_particles)

func _setup_puff_particles() -> void:
	_puff_particles = CPUParticles2D.new()
	_puff_particles.amount = 15
	_puff_particles.lifetime = 0.4
	_puff_particles.one_shot = true
	_puff_particles.explosiveness = 0.85
	_puff_particles.local_coords = false
	_puff_particles.position = Vector2(12, 16)
	_puff_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_puff_particles.emission_sphere_radius = 8.0
	_puff_particles.gravity = Vector2(0.0, -10.0)
	_puff_particles.spread = 180.0
	_puff_particles.initial_velocity_min = 20.0
	_puff_particles.initial_velocity_max = 50.0
	_puff_particles.scale_amount_min = 3.0
	_puff_particles.scale_amount_max = 6.0
	_puff_particles.color = Color(0.2, 0.6, 0.15, 0.6)

	var color_ramp := Gradient.new()
	color_ramp.offsets = [0.0, 1.0]
	color_ramp.colors = [Color(0.2, 0.6, 0.15, 0.6), Color(0.2, 0.6, 0.15, 0.0)]
	_puff_particles.color_ramp = color_ramp

	var p_mat := CanvasItemMaterial.new()
	p_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_puff_particles.material = p_mat

	add_child(_puff_particles)
