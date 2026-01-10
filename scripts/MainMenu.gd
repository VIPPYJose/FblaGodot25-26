extends Control

@onready var continue_button = $VBoxContainer/ContinueButton
@onready var start_button = $VBoxContainer/StartButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var settings_panel = $SettingsPanel

func _ready():
	settings_panel.hide()
	continue_button.pressed.connect(_on_continue_pressed)
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

func _on_continue_pressed():
	pass

func _on_start_pressed():
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("save_game.dat")
	SceneManager.change_scene("res://scenes/IntroCutscene.tscn")

func _on_settings_pressed():
	settings_panel.show()

func _on_close_settings_pressed():
	settings_panel.hide()
