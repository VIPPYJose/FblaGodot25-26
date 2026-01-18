extends Node2D

@onready var player_spawn_pos = Vector2(500, 300)
@onready var dog_spawn_pos = Vector2(450, 320)

func _ready():
	spawn_player()
	spawn_dog()
	setup_hud()

func setup_hud():
	var hud_scene = load("res://scenes/bottom_hud.tscn")
	if hud_scene:
		var hud = hud_scene.instantiate()
		add_child(hud)

func spawn_player():
	var variant = GameState.character_variant
	var id = GameState.character_id
	var scene_path = ""
	
	if variant == "male":
		scene_path = "res://scenes/Dude" + str(id) + ".tscn"
	else:
		scene_path = "res://scenes/girl" + str(id) + ".tscn"
		
	var player = load(scene_path).instantiate()
	player.global_position = player_spawn_pos
	player.set_script(load("res://scripts/player.gd"))
	player.input_pickable = true
	add_child(player)
	player.add_to_group("player")
	
	var name_tag = Label.new()
	name_tag.text = GameState.player_name
	name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_tag.custom_minimum_size = Vector2(100, 20)
	name_tag.position = Vector2(-50, -40)
	name_tag.visible = false
	name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Smaller pixel font look
	name_tag.add_theme_font_size_override("font_size", 10)
	
	player.add_child(name_tag)
	
	player.mouse_entered.connect(func(): 
		name_tag.visible = true
	)
	player.mouse_exited.connect(func(): 
		name_tag.visible = false
	)

func spawn_dog():
	var dog_scene = load("res://scenes/dog.tscn")
	var dog = dog_scene.instantiate()
	dog.global_position = dog_spawn_pos
	dog.breed = GameState.dog_breed
	dog.input_pickable = true
	add_child(dog)
	
	var name_tag = Label.new()
	name_tag.text = GameState.pet_name
	name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_tag.custom_minimum_size = Vector2(100, 20)
	name_tag.position = Vector2(-50, -40)
	name_tag.visible = false
	name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Smaller pixel font look
	name_tag.add_theme_font_size_override("font_size", 10)
	
	dog.add_child(name_tag)
	
	dog.mouse_entered.connect(func(): 
		name_tag.visible = true
	)
	dog.mouse_exited.connect(func(): 
		name_tag.visible = false
	)
