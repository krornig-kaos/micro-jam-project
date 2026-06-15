## AudioManager — Singleton para la gestión centralizada de audio.
## Permite reproducir SFX con variaciones de tono y gestionar música/ambiente.
extends Node

# Diccionario de rutas de audio para acceso rápido
const SOUNDS = {
	"boar_patrol": "res://assets/audio/boar/patrol.mp3",
	"boar_charge": "res://assets/audio/boar/charge.flac",
	"boar_gallop": "res://assets/audio/boar/gallop.mp3",
	"boar_impact": "res://assets/audio/boar/impact.wav",
	"boar_stun": "res://assets/audio/boar/stun.wav",
	"fox_bark": "res://assets/audio/fox/bark.wav",
	"fox_sniff": "res://assets/audio/fox/sniff.wav",
	"owl_hoot": "res://assets/audio/owl/hoot.wav",
	"owl_screech": "res://assets/audio/owl/screech.mp3",
	"owl_flaps": "res://assets/audio/owl/flaps.wav",
	"soul_pickup": "res://assets/audio/environment/soul_pickup.wav",
	"bush_rustle": "res://assets/audio/environment/bush_rustle.ogg",
	"altar_release": "res://assets/audio/environment/altar_release.wav",
	"player_footsteps": "res://assets/audio/player/footsteps.wav",
	"stealth_on": "res://assets/audio/player/stealth_on.wav",
	"intangible_cast": "res://assets/audio/player/intangible_cast.wav",
	"player_death": "res://assets/audio/player/death.flac"
}

## Reproduce un efecto de sonido en una posición 2D y devuelve el nodo.
## [param sound_name] Nombre clave en el diccionario SOUNDS.
## [param position] Posición global donde debe sonar.
## [param volume_db] Ajuste de volumen opcional.
## [param pitch_min] Variación mínima de tono.
## [param pitch_max] Variación máxima de tono.
## [param max_distance] Distancia máxima a la que se puede escuchar (atenuación).
func play_sfx(sound_name: String, position: Vector2 = Vector2.ZERO, volume_db: float = 0.0, pitch_min: float = 0.9, pitch_max: float = 1.1, max_distance: float = 600.0) -> AudioStreamPlayer2D:
	if not SOUNDS.has(sound_name):
		push_warning("AudioManager: Sonido no encontrado: " + sound_name)
		return null
		
	var stream = load(SOUNDS[sound_name])
	if not stream:
		return null
		
	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = "SFX"
	player.volume_db = volume_db
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.global_position = position
	
	# Configuración de atenuación 2D
	player.max_distance = max_distance
	player.attenuation = 2.0 # Caída logarítmica (más natural)
	
	add_child(player)
	player.play()
	
	# Asegurar que el sonido se detenga si la escena cambia
	player.add_to_group("auto_sfx")
	
	# Liberar el nodo automáticamente al terminar
	player.finished.connect(player.queue_free)
	return player

## Detiene todos los sonidos marcados como auto_sfx (útil en reinicios de nivel).
func stop_all_sfx() -> void:
	for player in get_tree().get_nodes_in_group("auto_sfx"):
		if is_instance_valid(player):
			player.stop()
			player.queue_free()

## Detiene un sonido suavemente con un fade-out.
func stop_sfx(player: Node, fade_time: float = 0.1) -> void:
	if not is_instance_valid(player) or not player is AudioStreamPlayer2D and not player is AudioStreamPlayer:
		return
		
	if fade_time <= 0.0:
		player.stop()
		player.queue_free()
	else:
		var tween = create_tween()
		tween.tween_property(player, "volume_db", -80.0, fade_time)
		tween.finished.connect(player.queue_free)

## Reproduce un sonido que no depende de la posición (UI o efectos globales).
func play_ui_sfx(sound_name: String, volume_db: float = 0.0) -> void:
	if not SOUNDS.has(sound_name):
		return
		
	var stream = load(SOUNDS[sound_name])
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "SFX"
	player.volume_db = volume_db
	
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
