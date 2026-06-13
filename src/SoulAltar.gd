## Punto B — altar donde el player entrega las almas para revivir animales.
## Al entrar en su área con almas, las entrega automáticamente.
extends Area2D

signal animals_revived(count: int)

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.orb_count > 0:
		var count := body.orb_count
		body.deliver_souls()
		animals_revived.emit(count)
		# Efecto visual del altar
		var tween := create_tween()
		tween.tween_property(_sprite, "modulate", Color(1.5, 1.5, 1.0), 0.2)
		tween.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0), 0.4)
