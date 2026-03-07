# COMMIT: Achievements and Catch Minigame Update
extends Node

## Autoload that manages volume for the buses defined in default_bus_layout.tres.
## References Master, Music, and SFX - only reads/writes their volume_db values.
## Slider values (0-100) use linear_to_db for proper perceptual volume scaling.

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "audio"
const SETTINGS_KEYS := {
	BUS_MASTER: "master_volume",
	BUS_MUSIC: "music_volume",
	BUS_SFX: "sfx_volume"
}

func _ready() -> void:
	_load_volumes()


func _load_volumes() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for bus_name in SETTINGS_KEYS:
		var key: String = SETTINGS_KEYS.get(bus_name, "")
		if key.is_empty():
			continue
		var volume: float = config.get_value(SETTINGS_SECTION, key, 100.0)
		var idx := AudioServer.get_bus_index(bus_name)
		if idx != -1:
			AudioServer.set_bus_volume_db(idx, _slider_to_db(volume))


## Convert slider value (0-100) to volume in dB. Uses linear_to_db for perceptual scaling.
func _slider_to_db(slider_value: float) -> float:
	var linear := clampf(slider_value / 100.0, 0.0, 1.0)
	return linear_to_db(maxf(linear, 0.0001))


## Convert dB to slider value (0-100) for displaying current volume.
func _db_to_slider(volume_db: float) -> float:
	var linear := db_to_linear(volume_db)
	return clampf(linear * 100.0, 0.0, 100.0)


## Get current bus volume as slider value (0-100).
func get_bus_volume(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return 100.0
	return _db_to_slider(AudioServer.get_bus_volume_db(idx))


## Set bus volume from slider value (0-100). Saves to config.
func set_bus_volume(bus_name: String, slider_value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var db := _slider_to_db(slider_value)
	AudioServer.set_bus_volume_db(idx, db)
	_save_volume(bus_name, slider_value)


func _save_volume(bus_name: String, slider_value: float) -> void:
	var key: String = SETTINGS_KEYS.get(bus_name, "")
	if key.is_empty():
		return
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		pass
	config.set_value(SETTINGS_SECTION, key, slider_value)
	config.save(SETTINGS_PATH)
