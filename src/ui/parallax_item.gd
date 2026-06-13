extends Parallax2D

@onready var sprite: Sprite2D = $Sprite2D # Asegúrate de que el nombre coincida

func _ready() -> void:
	# Nos conectamos al evento de cambio de tamaño de la ventana
	get_viewport().size_changed.connect(reajustar_fondo)
	# Lo ejecutamos la primera vez al iniciar
	reajustar_fondo()

func reajustar_fondo() -> void:
	# Obtenemos el tamaño actual de la pantalla visible
	var tamano_pantalla = get_viewport().get_visible_rect().size
	
	# Si usas la Opción A (Región):
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, tamano_pantalla)
	
	# Configuramos el Parallax2D para que reinicie el bucle justo al terminar la pantalla
	repeat_size.x = tamano_pantalla.x
