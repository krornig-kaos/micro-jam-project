extends Control

const TUTORIAL_SCENE: String = "res://src/ui/tutorial_screen.tscn"
const CREDITS_SCENE: String = "res://src/ui/credits_stub.tscn"

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var credits_button: Button = $VBoxContainer/CreditsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	start_button.text = "Start Game"
	credits_button.text = "Credits"
	quit_button.text = "Exit"

	start_button.pressed.connect(_on_start_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	start_button.grab_focus()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(TUTORIAL_SCENE)

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(CREDITS_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()
