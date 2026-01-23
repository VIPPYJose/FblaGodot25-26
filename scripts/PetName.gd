extends Control

@onready var preview = $VBoxContainer/PreviewContainer/DogPreview
@onready var pet_name_input = $VBoxContainer/PetNameInput

func _ready():
	var dog_scene = load("res://scenes/People and dog/dog.tscn").instantiate()
	preview.sprite_frames = dog_scene.get_node("AnimatedSprite2D").sprite_frames
	dog_scene.free()
	
	update_preview()
	pet_name_input.grab_focus()

func _input(event):
	if event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		_on_continue_button_pressed()

func update_preview():
	var breed_id = GameState.dog_breed
	var anim_name = breed_id + "_run"
	
	if preview.sprite_frames.has_animation(anim_name):
		preview.play(anim_name)
	else:
		preview.play("basic_dog_run")
	
	preview.flip_h = true

func _on_continue_button_pressed():
	var p_name = pet_name_input.text.strip_edges()
	if p_name == "":
		return
		
	GameState.save_pet_name(p_name)
	SceneManager.change_scene("res://scenes/ui/ConfirmSelection.tscn", {"pattern": "curtains"})
