extends Control

const GAME_SCENE: String = "res://src/game/game_stub.tscn"
const CREDITS_SCENE: String = "res://src/ui/credits_stub.tscn"
const MENU_START_KEY: String = "MENU_START"
const MENU_CREDITS_KEY: String = "MENU_CREDITS"
const MENU_QUIT_KEY: String = "MENU_QUIT"

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var credits_button: Button = $VBoxContainer/CreditsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	start_button.text = tr(MENU_START_KEY)
	credits_button.text = tr(MENU_CREDITS_KEY)
	quit_button.text = tr(MENU_QUIT_KEY)

	start_button.pressed.connect(_on_start_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	start_button.grab_focus()



func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(CREDITS_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
