# COMMIT: Achievements and Catch Minigame Update
extends Control

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION_DISPLAY := "display"
const SETTINGS_KEY_MAXIMIZED := "maximized"

@onready var back_button: Button = $BackToMenu
@onready var master_slider: HSlider = $VBoxContainer/Volume/Master/HSlider
@onready var music_slider: HSlider = $VBoxContainer/Volume/Music/HSlider
@onready var sfx_slider: HSlider = $VBoxContainer/Volume/SFX/HSlider
@onready var maximize_check: CheckButton = $VBoxContainer/Maximize/CheckButton

func _ready() -> void:
	var audio_manager := get_node("/root/AudioBusManager")
	back_button.pressed.connect(_on_back_to_menu_pressed)

	master_slider.value = audio_manager.get_bus_volume("Master")
	master_slider.value_changed.connect(_on_volume_changed.bind(audio_manager, "Master"))

	music_slider.value = audio_manager.get_bus_volume("Music")
	music_slider.value_changed.connect(_on_volume_changed.bind(audio_manager, "Music"))

	sfx_slider.value = audio_manager.get_bus_volume("SFX")
	sfx_slider.value_changed.connect(_on_volume_changed.bind(audio_manager, "SFX"))

	maximize_check.button_pressed = _get_saved_maximized()
	_apply_maximized(maximize_check.button_pressed)
	maximize_check.toggled.connect(_on_maximize_toggled)

	_setup_transition_buttons()

func _get_saved_maximized() -> bool:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED
	return config.get_value(SETTINGS_SECTION_DISPLAY, SETTINGS_KEY_MAXIMIZED, false)

func _save_maximized(enabled: bool) -> void:
	var config := ConfigFile.new()
	var _err := config.load(SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION_DISPLAY, SETTINGS_KEY_MAXIMIZED, enabled)
	config.save(SETTINGS_PATH)

func _apply_maximized(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_maximize_toggled(button_pressed: bool) -> void:
	_apply_maximized(button_pressed)
	_save_maximized(button_pressed)

func _setup_transition_buttons() -> void:
	var grid := $VBoxContainer/Transition/GridContainer
	var transition_prefs := get_node("/root/TransitionPrefs")
	var saved_pattern: String = transition_prefs.get_pattern()
	var ui_name: String = transition_prefs.get_ui_name_for_pattern(saved_pattern)
	for child in grid.get_children():
		if child is HBoxContainer:
			var check: CheckBox = child.get_node_or_null("CheckBox")
			if check:
				check.button_pressed = (child.name == ui_name)
				check.toggled.connect(_on_transition_toggled.bind(child.name))


func _on_transition_toggled(button_pressed: bool, option_name: String) -> void:
	var transition_prefs := get_node("/root/TransitionPrefs")
	if button_pressed and option_name in transition_prefs.UI_TO_PATTERN:
		transition_prefs.set_pattern(transition_prefs.UI_TO_PATTERN[option_name])

func _on_volume_changed(value: float, audio_manager: Node, bus_name: String) -> void:
	audio_manager.set_bus_volume(bus_name, value)

func _on_back_to_menu_pressed() -> void:
	back_button.disabled = true
	await SceneManager.change_scene("res://scenes/menu/starting_menu.tscn", get_node("/root/TransitionPrefs").get_transition_dict())
