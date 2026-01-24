extends Control

@onready var preview = $VBoxContainer/PreviewContainer/CharacterPreview
@onready var char_name_label = $VBoxContainer/CycleContainer/CharacterName
@onready var male_button = $VBoxContainer/VariantContainer/MaleButton
@onready var female_button = $VBoxContainer/VariantContainer/FemaleButton
@onready var name_input = $VBoxContainer/NameInput

var current_char_id = 1
var current_variant = "male"

func _ready():
	update_preview()
	update_highlights()

func _input(event):
	if name_input.has_focus():
		return
		
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		cycle_character(-1)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		cycle_character(1)
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		_on_continue_button_pressed()

func cycle_character(direction):
	current_char_id += direction
	if current_char_id > 4: current_char_id = 1
	if current_char_id < 1: current_char_id = 4
	update_preview()

func update_preview():
	var scene_path = ""
	if current_variant == "male":
		if current_char_id == 1:
			scene_path = "res://scenes/People and dog/Dude1.tscn"
		else:
			scene_path = "res://scenes/People and dog/Dude" + str(current_char_id) + ".tscn"
	else:
		scene_path = "res://scenes/People and dog/girl" + str(current_char_id) + ".tscn"
	
	var scene = load(scene_path).instantiate()
	var sprite = scene.get_node("Sprite2D") if scene.has_node("Sprite2D") else scene.get_node("playerspriteanim")
	preview.sprite_frames = sprite.sprite_frames
	
	if preview.sprite_frames.has_animation("idle_up"):
		preview.play("idle_up")
	elif preview.sprite_frames.has_animation("idle_up_dude1"):
		preview.play("idle_up_dude1")
	
	char_name_label.text = "Character " + str(current_char_id)
	scene.free()

func update_highlights():
	if current_variant == "male":
		male_button.modulate = Color(1.5, 1.5, 1.5)
		female_button.modulate = Color(1, 1, 1)
	else:
		female_button.modulate = Color(1.5, 1.5, 1.5)
		male_button.modulate = Color(1, 1, 1)

func _on_prev_button_pressed():
	cycle_character(-1)

func _on_next_button_pressed():
	cycle_character(1)

func _on_male_button_pressed():
	current_variant = "male"
	update_preview()
	update_highlights()

func _on_female_button_pressed():
	current_variant = "female"
	update_preview()
	update_highlights()

func _on_continue_button_pressed():
	if name_input.text.strip_edges() == "":
		return
		
	GameState.save_character(current_char_id, current_variant)
	GameState.save_player_name(name_input.text.strip_edges())
	SceneManager.change_scene("res://scenes/ui/PetSelect.tscn", {"pattern": "curtains"})
