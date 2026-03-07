# COMMIT: Achievements and Catch Minigame Update
extends Control

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION_DISPLAY := "display"
const SETTINGS_KEY_MAXIMIZED := "maximized"

@export var taglines: Array[String] = [
	"Something's odd in Maplewood. You're on the case.",
	"The neighborhood's full of clues. You just have to look.",
	"Where every corner hides a clue.",
	"A small town. A big mystery. No problem too small.",
	"Strange goings-on in a friendly town.",
	"Maplewood Mysteries—and it's stranger than it sounds.",
	"Maplewood's got secrets. You've got questions.",
	"Clues, friends, and one very curious kid.",
]

const TITLE_TEXT := "Maplewood Mysteries"
const GLOW_SPREAD := 1
const GLOW_OUTLINE_SIZE := 16
const GLOW_OUTLINE_COLOR := Color(0.98, 0.82, 0.36, 1.0)
const GLOW_FONT_COLOR := Color(1.0, 1.0, 0.95, 1.0)

@onready var tagline_label: Label = $VBoxContainer2/Tagline
@onready var title_container: MarginContainer = $VBoxContainer2/TitleContainer
@onready var title_hbox: HBoxContainer = $VBoxContainer2/TitleContainer/TitleHBox
@onready var quit_button: Button = $VBoxContainer/Quit
@onready var credits_button: Button = $VBoxContainer/Credits
@onready var settings_button: Button = $VBoxContainer/Settings
@onready var play_button: Button = $VBoxContainer/Play

var _title_char_labels: Array[Label] = []
var _title_wrappers: Array[Control] = []
var _title_theme: Theme

func _ready() -> void:
	if taglines.size() > 0:
		tagline_label.text = taglines.pick_random()
	_apply_saved_maximized()
	_build_title_with_glow()
	quit_button.pressed.connect(_on_quit_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	play_button.pressed.connect(_on_play_pressed)

func _build_title_with_glow() -> void:
	_title_theme = preload("res://resources/themes/title.tres") as Theme
	for child in title_hbox.get_children():
		child.queue_free()
	_title_char_labels.clear()
	_title_wrappers.clear()
	for i in TITLE_TEXT.length():
		var char_str := TITLE_TEXT.substr(i, 1)
		var wrapper := MarginContainer.new()
		wrapper.mouse_filter = Control.MOUSE_FILTER_STOP
		var lbl := Label.new()
		lbl.text = char_str
		lbl.theme = _title_theme
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrapper.add_child(lbl)
		title_hbox.add_child(wrapper)
		_title_char_labels.append(lbl)
		_title_wrappers.append(wrapper)
		wrapper.mouse_entered.connect(_on_title_char_hovered.bind(i))
		wrapper.mouse_exited.connect(_on_title_char_exited)

func _on_title_char_hovered(char_index: int) -> void:
	var glow_start := maxi(0, char_index - GLOW_SPREAD)
	var glow_end := mini(TITLE_TEXT.length(), char_index + GLOW_SPREAD + 1)
	_clear_title_glow()
	for i in range(glow_start, glow_end):
		_apply_glow(_title_char_labels[i])

func _on_title_char_exited() -> void:
	call_deferred("_check_clear_glow")

func _check_clear_glow() -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	for w in _title_wrappers:
		if w.get_global_rect().has_point(mouse_pos):
			return
	_clear_title_glow()

func _apply_glow(label: Label) -> void:
	label.add_theme_constant_override("outline_size", GLOW_OUTLINE_SIZE)
	label.add_theme_color_override("font_outline_color", GLOW_OUTLINE_COLOR)
	label.add_theme_color_override("font_color", GLOW_FONT_COLOR)

func _clear_title_glow() -> void:
	for lbl in _title_char_labels:
		lbl.remove_theme_constant_override("outline_size")
		lbl.remove_theme_color_override("font_outline_color")
		lbl.remove_theme_color_override("font_color")

func _apply_saved_maximized() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	var maximized: bool = config.get_value(SETTINGS_SECTION_DISPLAY, SETTINGS_KEY_MAXIMIZED, false)
	if maximized:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _disable_menu_buttons() -> void:
	quit_button.disabled = true
	credits_button.disabled = true
	settings_button.disabled = true
	$VBoxContainer/Play.disabled = true

func _on_play_pressed() -> void:
	_disable_menu_buttons()
	await SceneManager.change_scene("res://scenes/menu/character_selecter.tscn", get_node("/root/TransitionPrefs").get_transition_dict())

func _on_credits_pressed() -> void:
	_disable_menu_buttons()
	await SceneManager.change_scene("res://scenes/menu/credits.tscn", get_node("/root/TransitionPrefs").get_transition_dict())

func _on_settings_pressed() -> void:
	_disable_menu_buttons()
	await SceneManager.change_scene("res://scenes/menu/settings.tscn", get_node("/root/TransitionPrefs").get_transition_dict())

func _on_quit_pressed() -> void:
	_disable_menu_buttons()
	await SceneManager.change_scene("res://scenes/menu/quitting_msg.tscn", get_node("/root/TransitionPrefs").get_transition_dict())
