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

## Reproduce un efecto de sonido en una posición 2D.
## [param sound_name] Nombre clave en el diccionario SOUNDS.
## [param position] Posición global donde debe sonar.
## [param volume_db] Ajuste de volumen opcional.
## [param pitch_min] Variación mínima de tono.
## [param pitch_max] Variación máxima de tono.
func play_sfx(sound_name: String, position: Vector2 = Vector2.ZERO, volume_db: float = 0.0, pitch_min: float = 0.9, pitch_max: float = 1.1) -> void:
	if not SOUNDS.has(sound_name):
		push_warning("AudioManager: Sonido no encontrado: " + sound_name)
		return
		
	var stream = load(SOUNDS[sound_name])
	if not stream:
		return
		
	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = "SFX"
	player.volume_db = volume_db
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.global_position = position
	
	add_child(player)
	player.play()
	
	# Liberar el nodo automáticamente al terminar
	player.finished.connect(player.queue_free)

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
