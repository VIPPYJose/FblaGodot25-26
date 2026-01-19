extends Control

@onready var preview = $VBoxContainer/PreviewContainer/DogPreview
@onready var breed_label = $VBoxContainer/CycleContainer/BreedName

var breeds = [
	{"name": "Golden Retriever", "id": "Golden_Retriever"},
	{"name": "Husky", "id": "Husky"},
	{"name": "Dalmatian", "id": "dalmatian"},
	{"name": "Labrador", "id": "labrador_more_blond"},
	{"name": "Rottweiler", "id": "rottie"},
	{"name": "Argentino", "id": "Argentino"},
	{"name": "Pharaoh Hound", "id": "Pharoah_hound"},
	{"name": "Cane Corso", "id": "basic_Dog"}
]

var current_breed_index = 0

func _ready():
	var dog_scene = load("res://scenes/People and dog/dog.tscn").instantiate()
	preview.sprite_frames = dog_scene.get_node("AnimatedSprite2D").sprite_frames
	dog_scene.free()
	update_preview()

func _input(event):
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		cycle_breed(-1)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		cycle_breed(1)
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		_on_continue_button_pressed()

func cycle_breed(direction):
	current_breed_index += direction
	if current_breed_index >= breeds.size(): current_breed_index = 0
	if current_breed_index < 0: current_breed_index = breeds.size() - 1
	update_preview()

func update_preview():
	var breed = breeds[current_breed_index]
	breed_label.text = breed["name"]
	
	var anim_name = breed["id"] + "_idle"
	if preview.sprite_frames.has_animation(anim_name):
		preview.play(anim_name)
	else:
		preview.play("basic_Dog_idle")

func _on_prev_button_pressed():
	cycle_breed(-1)

func _on_next_button_pressed():
	cycle_breed(1)

func _on_continue_button_pressed():
	GameState.save_pet(breeds[current_breed_index]["id"])
	SceneManager.change_scene("res://scenes/ui/PetName.tscn", {"pattern": "curtains"})
