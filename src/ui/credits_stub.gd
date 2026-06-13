extends Control

const MAIN_MENU_SCENE: String = "res://src/ui/main_menu.tscn"
const CREDITS_TITLE_KEY: String = "CREDITS_TITLE"
const CREDITS_BACK_KEY: String = "CREDITS_BACK"

@onready var back_button: Button = $VBoxContainer/BackButton
@onready var credits_label: Label = $VBoxContainer/CreditsLabel


func _ready() -> void:
	credits_label.text = tr(CREDITS_TITLE_KEY)
	back_button.text = tr(CREDITS_BACK_KEY)
	back_button.pressed.connect(_on_back_pressed)
	back_button.grab_focus()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
