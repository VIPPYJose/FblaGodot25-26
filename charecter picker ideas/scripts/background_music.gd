# COMMIT: Achievements and Catch Minigame Update
extends Node

## Autoload that plays background music continuously across all scenes.
## Uses the Music audio bus - volume controlled via AudioBusManager.

var _audio_player: AudioStreamPlayer

func _ready() -> void:
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)
	_audio_player.stream = load("res://assets/audio/background_music.mp3") as AudioStream
	_audio_player.bus = "Music"
	_audio_player.finished.connect(_on_finished)
	_audio_player.play()


func _on_finished() -> void:
	_audio_player.play()
