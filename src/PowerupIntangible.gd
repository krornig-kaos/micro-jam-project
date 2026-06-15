## Item de Intangibilidad — al ser recolectado activa el poder de intangibilidad en el jugador.
extends Area2D

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if _sprite:
		_sprite.play("default")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("_activate_intangible"):
			body.call("_activate_intangible")
			
			# Sonido de recogida
			AudioManager.play_sfx("soul_pickup", global_position, 5.0, 1.2, 1.4)
			
			queue_free()
