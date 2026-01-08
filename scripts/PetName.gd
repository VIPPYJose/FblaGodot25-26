extends Control

@onready var pet_name_input = $VBoxContainer/PetNameInput

func _on_continue_button_pressed():
	if pet_name_input.text != "":
		SceneManager.change_scene("res://scenes/MainGame.tscn")

