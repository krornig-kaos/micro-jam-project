extends Node2D

## Velocidades de scroll para cada capa (píxeles por segundo, de fondo a frente).
## Negativo = hacia la izquierda.
@export var velocidades: Array[float] = [0.0, -100.0, -200.0, -300.0, -400.0, -500.0]

var capas: Array[Parallax2D] = []

func _ready() -> void:
	# Recolectar todas las capas Parallax2D
	for child in get_children():
		if child is Parallax2D:
			capas.append(child)
			# Desactivar influencia de cámara
			child.ignore_camera_scroll = true
			child.follow_viewport = false
			child.scroll_scale = Vector2.ONE
	

func _process(delta: float) -> void:
	for i in range(capas.size()):
			capas[i].scroll_offset.x += i * 10 * delta
	
