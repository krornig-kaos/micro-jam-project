# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does forest navigation + carry-weight slowdown feel meaningfully different?
# Date: 2026-06-13
extends TileMapLayer

const GRASS_VARIANTS: Array[Vector2i] = [
	Vector2i(38, 10), Vector2i(39, 10), Vector2i(40, 10), Vector2i(41, 10),
	Vector2i(38, 11), Vector2i(39, 11), Vector2i(40, 11), Vector2i(41, 11),
	Vector2i(38, 12), Vector2i(39, 12), Vector2i(40, 12), Vector2i(41, 12),
	Vector2i(38, 13), Vector2i(39, 13), Vector2i(40, 13), Vector2i(41, 13),
]

func _ready() -> void:
	for x in range(-7, 113):
		for y in range(-7, 85):
			set_cell(Vector2i(x, y), 0, GRASS_VARIANTS[randi() % GRASS_VARIANTS.size()])
