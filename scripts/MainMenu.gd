extends Control

@onready var continue_button = $VBoxContainer/ContinueButton
@onready var start_button = $VBoxContainer/StartButton
@onready var settings_button = $VBoxContainer/SettingsButton

func _ready():
	continue_button.pressed.connect(_on_continue_pressed)
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

func _on_continue_pressed():
	# Load saved game data before transitioning
	if GameState.has_save_file():
		GameState.load_game()
	SceneManager.change_scene("res://scenes/ui/MainGame.tscn", {"pattern": "curtains"})

func _on_start_pressed():
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("save_game.dat")
	SceneManager.change_scene("res://scenes/ui/IntroCutscene.tscn")

func _on_settings_pressed():
	var settings_scene = load("res://scenes/ui/SettingsMenu.tscn")
	if settings_scene:
		var settings_menu = settings_scene.instantiate()
		add_child(settings_menu)

