extends Control

const GAME_SCENE: String = "res://src/level_one/main.tscn"

@onready var start_button: Button = %StartButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	start_button.grab_focus()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)
