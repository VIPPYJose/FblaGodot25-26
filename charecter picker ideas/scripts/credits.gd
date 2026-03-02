extends Control

@onready var back_button: Button = $BackToMenu

func _ready() -> void:
	back_button.pressed.connect(_on_back_to_menu_pressed)

func _on_back_to_menu_pressed() -> void:
	back_button.disabled = true
	await SceneManager.change_scene("res://scenes/menu/starting_menu.tscn", get_node("/root/TransitionPrefs").get_transition_dict())
