extends Node

## Autoload that stores the user's chosen scene transition pattern.
## Persists to user://settings.cfg and provides get_transition_dict() for SceneManager.

const TRANSITION_COLOR := Color("#2c1810")
const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "display"
const SETTINGS_KEY := "transition"
const DEFAULT_PATTERN := "squares"

## Maps UI option names (parent node names) to SceneManager pattern strings.
const UI_TO_PATTERN := {
	"Squares": "squares",
	"Circles": "circle",
	"Curtains": "curtains",
	"Diagonal": "diagonal",
	"Horizontal": "horizontal",
	"Radial": "radial",
	"Scribbles": "scribbles",
	"Vertical": "vertical",
}

func _ready() -> void:
	pass


func get_pattern() -> String:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return DEFAULT_PATTERN
	return config.get_value(SETTINGS_SECTION, SETTINGS_KEY, DEFAULT_PATTERN)


func set_pattern(pattern: String) -> void:
	var config := ConfigFile.new()
	var _err := config.load(SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION, SETTINGS_KEY, pattern)
	config.save(SETTINGS_PATH)


func get_ui_name_for_pattern(pattern: String) -> String:
	for ui_name in UI_TO_PATTERN:
		if UI_TO_PATTERN[ui_name] == pattern:
			return ui_name
	return "Squares"


func get_transition_dict() -> Dictionary:
	return {"pattern": get_pattern(), "color": TRANSITION_COLOR}
