extends Control

@onready var player_sprite = $PlayerContainer/PlayerSprite
@onready var dog_sprite = $DogContainer/DogSprite
@onready var yes_button = $ButtonContainer/YesButton
@onready var no_button = $ButtonContainer/NoButton
@onready var player_label = $PlayerLabel
@onready var dog_label = $DogLabel
@onready var question_label = $QuestionLabel

func _ready():
	setup_player()
	setup_dog()
	setup_labels()
	setup_buttons()
	
	# Hide labels initially
	player_label.visible = false
	dog_label.visible = false

func setup_player():
	var variant = GameState.character_variant
	var id = GameState.character_id
	var scene_path = ""
	
	if variant == "male":
		if id == 1:
			scene_path = "res://scenes/People and dog/Dude1.tscn"
		else:
			scene_path = "res://scenes/People and dog/Dude" + str(id) + ".tscn"
	else:
		scene_path = "res://scenes/People and dog/girl" + str(id) + ".tscn"
	
	var player_scene = load(scene_path).instantiate()
	var sprite = player_scene.get_node("Sprite2D") if player_scene.has_node("Sprite2D") else player_scene.get_node("playerspriteanim")
	player_sprite.sprite_frames = sprite.sprite_frames
	
	# Play idle animation (swapped priority: idle_up instead of idle_down)
	if player_sprite.sprite_frames.has_animation("idle_up"):
		player_sprite.play("idle_up")
	elif player_sprite.sprite_frames.has_animation("idle_down"):
		player_sprite.play("idle_down")
	elif player_sprite.sprite_frames.has_animation("idle_up_dude1"):
		player_sprite.play("idle_up_dude1")
	
	player_scene.free()

func setup_dog():
	var dog_scene = load("res://scenes/People and dog/dog.tscn").instantiate()
	var sprite = dog_scene.get_node("AnimatedSprite2D")
	dog_sprite.sprite_frames = sprite.sprite_frames
	
	# Play idle animation for the selected breed
	var breed_id = GameState.dog_breed
	var anim_name = breed_id + "_idle"
	
	if dog_sprite.sprite_frames.has_animation(anim_name):
		dog_sprite.play(anim_name)
	else:
		dog_sprite.play("basic_dog_idle")
	
	dog_scene.free()

func setup_labels():
	question_label.text = "Are you sure you want this before you start the game?"
	player_label.text = GameState.player_name
	dog_label.text = GameState.pet_name

func setup_buttons():
	yes_button.pressed.connect(_on_yes_button_pressed)
	no_button.pressed.connect(_on_no_button_pressed)

func _on_yes_button_pressed():
	SceneManager.change_scene("res://scenes/ui/MainGame.tscn", {"pattern": "curtains"})

func _on_no_button_pressed():
	# Go back to character select
	SceneManager.change_scene("res://scenes/ui/CharacterCustomize.tscn", {"pattern": "curtains"})

# Mouse hover events for player (connected to the Container)
func _on_player_container_mouse_entered():
	player_label.visible = true

func _on_player_container_mouse_exited():
	player_label.visible = false

# Mouse hover events for dog (connected to the Container)
func _on_dog_container_mouse_entered():
	dog_label.visible = true

func _on_dog_container_mouse_exited():
	dog_label.visible = false
