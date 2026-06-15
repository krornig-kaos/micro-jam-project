extends CanvasLayer

const LEVELS: Array[String] = [
	"res://src/level_one/main.tscn",
	"res://src/level_two/main.tscn",
	"res://src/level_three/main.tscn"
]

@onready var next_level_button: Button = $Control/Panel/VBoxContainer/NextLevelButton
@onready var replay_button: Button = $Control/Panel/VBoxContainer/ReplayButton
@onready var menu_button: Button = $Control/Panel/VBoxContainer/MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Check if there is a next level
	var next_level_path = _get_next_level_path()
	if next_level_path == "":
		next_level_button.visible = false
		replay_button.grab_focus()
	else:
		next_level_button.pressed.connect(_on_next_level_pressed)
		next_level_button.grab_focus()
	
	replay_button.pressed.connect(_on_replay_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _get_next_level_path() -> String:
	var current_scene_path = get_tree().current_scene.scene_file_path
	var current_index = LEVELS.find(current_scene_path)
	
	if current_index != -1 and current_index < LEVELS.size() - 1:
		return LEVELS[current_index + 1]
	
	return ""

func _on_next_level_pressed() -> void:
	var next_level_path = _get_next_level_path()
	if next_level_path != "":
		AudioManager.stop_all_sfx()
		get_tree().paused = false
		get_tree().change_scene_to_file(next_level_path)
		queue_free()

func _on_replay_pressed() -> void:
	AudioManager.stop_all_sfx()
	get_tree().paused = false
	get_tree().reload_current_scene()
	queue_free()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")
	queue_free()
