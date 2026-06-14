extends Control

const UI_THEME: Theme = preload("res://src/ui/theme.tres")
const MAIN_MENU_SCENE: String = "res://src/ui/main_menu.tscn"
const TEAM_NAME_KEY: String = "BOOT_TEAM_NAME_PLACEHOLDER"

@onready var vbox: VBoxContainer = $VBoxContainer
@onready var logo_panel: Panel = $VBoxContainer/Panel


func _ready() -> void:
	theme = UI_THEME
	modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.tween_interval(2.0)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(get_tree().change_scene_to_file.bind(MAIN_MENU_SCENE))
