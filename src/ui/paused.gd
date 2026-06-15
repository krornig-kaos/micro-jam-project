extends CanvasLayer

@onready var resume_button: Button = %ResumeButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		alternar_pausa()

func alternar_pausa() -> void:
	var nuevo_estado_pausa = not get_tree().paused
	get_tree().paused = nuevo_estado_pausa
	visible = nuevo_estado_pausa
	
	if visible:
		resume_button.grab_focus()

func _on_resume_pressed() -> void:
	alternar_pausa()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")
