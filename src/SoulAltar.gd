## Punto B — altar donde el player entrega las almas para revivir animales.
## Al entrar en su área con almas, las entrega automáticamente y restaura la saturación de color del mundo.
extends Area2D

signal animals_revived(count: int)

# ─── Exportables ───────────────────────────────────────────────────────────────
@export var base_saturation: float = 0.05 ## Saturación inicial del mundo (casi blanco y negro)

# ─── Estado interno ────────────────────────────────────────────────────────────
var _total_souls: int = 0
var _delivered_souls: int = 0
var _shader_material: ShaderMaterial = null

# ─── Nodos hijos ───────────────────────────────────────────────────────────────
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	animals_revived.connect(_on_animals_revived)
	
	# Inicializar niebla de color / desaturador post-procesado
	call_deferred("_setup_color_filter")

func _setup_color_filter() -> void:
	# Contar el total de almas esparcidas en la escena al inicio
	_total_souls = get_tree().get_nodes_in_group("orb").size()
	
	# Cargar e instanciar el shader de desaturación de pantalla
	var shader = load("res://src/desaturation.gdshader")
	if shader:
		_shader_material = ShaderMaterial.new()
		_shader_material.shader = shader
		_shader_material.set_shader_parameter("saturation", base_saturation)
		
		# Crear CanvasLayer y ColorRect de pantalla completa
		var canvas_layer := CanvasLayer.new()
		canvas_layer.layer = 90 # Por encima de la mayoría de CanvasItems
		
		var color_rect := ColorRect.new()
		color_rect.material = _shader_material
		color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		canvas_layer.add_child(color_rect)
		add_child(canvas_layer)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.orb_count > 0:
		var count := body.orb_count as int
		body.deliver_souls()
		animals_revived.emit(count)
		
		# Efecto visual de brillo del altar al recibir almas
		var tween := create_tween()
		tween.tween_property(_sprite, "modulate", Color(1.5, 1.5, 1.0), 0.2)
		tween.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0), 0.4)

func _on_animals_revived(count: int) -> void:
	_delivered_souls = clampi(_delivered_souls + count, 0, _total_souls)
	_update_world_saturation()

func _update_world_saturation() -> void:
	if _shader_material and _total_souls > 0:
		# Fórmula del GDD: Saturation = base_saturation + (1.0 - base_saturation) * (delivered / total)
		var progress := float(_delivered_souls) / float(_total_souls)
		var current_saturation := base_saturation + (1.0 - base_saturation) * progress
		
		# Transición suave de color usando un Tween
		var tween := create_tween()
		tween.tween_method(
			func(val: float): _shader_material.set_shader_parameter("saturation", val),
			_shader_material.get_shader_parameter("saturation") as float,
			current_saturation,
			1.5 # Duración del efecto en segundos
		)
		
		# Si se entregaron todas las almas, mostrar pantalla de victoria al terminar el efecto
		if _delivered_souls == _total_souls:
			tween.finished.connect(_on_victory)

func _on_victory() -> void:
	var victory_scene := load("res://src/ui/victory_screen.tscn")
	if victory_scene:
		var victory_instance = victory_scene.instantiate()
		get_tree().current_scene.add_child(victory_instance)
		get_tree().paused = true
