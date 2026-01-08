extends Control

@onready var name_input = $VBoxContainer/NameInput

func _on_continue_button_pressed():
	if name_input.text != "":
		SceneManager.change_scene("res://scenes/PetSelect.tscn")

