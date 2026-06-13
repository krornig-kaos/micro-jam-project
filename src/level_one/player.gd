# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does forest navigation + carry-weight slowdown feel meaningfully different?
# Date: 2026-06-13
extends CharacterBody2D

const BASE_SPEED := 220.0
const WEIGHT_FACTOR := 0.15

var carried_orbs := 0
var label: Label

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	var sprite := Sprite2D.new()
	sprite.texture = load("res://design/assets/characters/With_Shadow/Hare/Hare_Idle_with_shadow.png")
	add_child(sprite)

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 24.0
	collision.shape = shape
	collision.position = Vector2(0, 18)
	add_child(collision)

	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)

	var hud := CanvasLayer.new()
	var lbl := Label.new()
	lbl.position = Vector2(16, 16)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	hud.add_child(lbl)
	add_child(hud)
	label = lbl
	_update_label()

func _physics_process(_delta: float) -> void:
	var input_vec := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	if input_vec.length() > 0.0:
		input_vec = input_vec.normalized()

	velocity = input_vec * _current_speed()
	move_and_slide()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var key := key_event.physical_keycode
	if key == KEY_EQUAL or key == KEY_KP_ADD:
		carried_orbs += 1
		_update_label()
	elif key == KEY_MINUS or key == KEY_KP_SUBTRACT:
		carried_orbs = maxi(carried_orbs - 1, 0)
		_update_label()

func _current_speed() -> float:
	return BASE_SPEED / (1.0 + WEIGHT_FACTOR * carried_orbs)

func _update_label() -> void:
	label.text = "Carried orbs: %d   Speed: %.0f px/s   (+/- to change, arrows to move)" % [carried_orbs, _current_speed()]
