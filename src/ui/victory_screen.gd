extends CanvasLayer

@onready var next_level_button: Button = $Control/Panel/VBoxContainer/NextLevelButton
@onready var replay_button: Button = $Control/Panel/VBoxContainer/ReplayButton
@onready var menu_button: Button = $Control/Panel/VBoxContainer/MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# El botón de Next Level queda desactivado o para implementación futura según el usuario
	next_level_button.visible = false
	replay_button.grab_focus()
	
	replay_button.pressed.connect(_on_replay_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_replay_pressed() -> void:
	AudioManager.stop_all_sfx()
	get_tree().paused = false
	get_tree().reload_current_scene()
	queue_free()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")
	queue_free()
