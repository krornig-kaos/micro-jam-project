extends CanvasLayer # Cambia a Control si al final decides no usar CCanvasLayeranvasLayer


func _ready() -> void:
	visible = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		print("Pausa: Alternando estado de pausa")
		alternar_pausa()

func alternar_pausa() -> void:
	# Invertimos el estado de pausa del motor
	var nuevo_estado_pausa = not get_tree().paused
	get_tree().paused = nuevo_estado_pausa
	
	visible = nuevo_estado_pausa



func _on_boton_reanudar_pressed() -> void:
	alternar_pausa()

func _on_boton_salir_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/ui/boot_screen.tscn") # Reemplaza con tu ruta real
