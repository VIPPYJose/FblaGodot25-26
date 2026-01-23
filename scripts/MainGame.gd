extends Node2D

# Tile (45, 20) in Map.tscn scaled by 2 and offset by (-724, -317)
# (45 * 16 * 2) - 724 = 716
# (20 * 16 * 2) - 317 = 323
@onready var player_spawn_pos = Vector2(716, 323)
@onready var dog_spawn_pos = Vector2(766, 323) # Spawn dog slightly to the right

var dog_instance: CharacterBody2D = null
var hud_instance: CanvasLayer = null
var tutorial_controller: Node = null

var Day1Tutorial = preload("res://scripts/day1_tutorial.gd")

func _ready():
	spawn_player()
	spawn_dog()
	setup_hud()
	setup_pause_menu()
	
	# Initialize Day 1 if it's a new game
	if GameState.is_day_one and not GameState.is_tutorial_complete:
		if dog_instance:
			dog_instance.initialize_day_one()
		GameState.initialize_day_one()
		
		# Start Day 1 tutorial after a brief delay
		call_deferred("start_day1_tutorial")
	else:
		# Restore saved dog data if continuing
		restore_dog_from_save()
	
	# Connect to day started signal for health changes
	GameState.day_started.connect(_on_day_started)

func start_day1_tutorial():
	tutorial_controller = Day1Tutorial.new()
	add_child(tutorial_controller)
	tutorial_controller.start_tutorial(dog_instance, hud_instance)

func _on_day_started(_day_number: int):
	if dog_instance:
		dog_instance.apply_daily_health_change()
	# Auto-save at end of each day
	save_current_game()

func _exit_tree():
	# Save game when leaving the scene
	save_current_game()

func save_current_game():
	if dog_instance:
		var dog_data = {
			"hunger": dog_instance.hunger,
			"thirst": dog_instance.thirst,
			"energy": dog_instance.energy,
			"hygiene": dog_instance.hygiene,
			"health": dog_instance.health
		}
		GameState.save_game(dog_data)

func restore_dog_from_save():
	var saved_dog_data = GameState.get_saved_dog_data()
	if dog_instance and not saved_dog_data.is_empty():
		dog_instance.hunger = saved_dog_data.get("hunger", 100.0)
		dog_instance.thirst = saved_dog_data.get("thirst", 100.0)
		dog_instance.energy = saved_dog_data.get("energy", 100.0)
		dog_instance.hygiene = saved_dog_data.get("hygiene", 100.0)
		dog_instance.health = saved_dog_data.get("health", 30.0)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		var pause_menu = get_node_or_null("PauseMenu")
		if pause_menu:
			pause_menu.toggle_pause()

func setup_pause_menu():
	var pause_scene = load("res://scenes/ui/PauseMenu.tscn")
	if pause_scene:
		var pause_menu = pause_scene.instantiate()
		pause_menu.name = "PauseMenu"
		add_child(pause_menu)

func setup_hud():
	var hud_scene = load("res://scenes/ui/bottom_hud.tscn")
	if hud_scene:
		var hud = hud_scene.instantiate()
		add_child(hud)
		# Store reference for tutorial
		hud_instance = hud

func spawn_player():
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
	
	var label_settings = LabelSettings.new()
	label_settings.font_size = 18
	label_settings.outline_size = 3
	label_settings.outline_color = Color.BLACK
	name_tag.label_settings = label_settings
	
	name_tag.scale = Vector2(1.0 / player.scale.x, 1.0 / player.scale.y)
	name_tag.position = Vector2(-50 * name_tag.scale.x, -30 * name_tag.scale.y)
	name_tag.visible = false
	name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player.add_child(name_tag)
	
	player.mouse_entered.connect(func():
		name_tag.visible = true
	)
	player.mouse_exited.connect(func():
		name_tag.visible = false
	)

func spawn_dog():
	var dog_scene = load("res://scenes/People and dog/dog.tscn")
	var dog = dog_scene.instantiate()
	dog.global_position = dog_spawn_pos
	dog.breed = GameState.dog_breed
	dog.input_pickable = true
	add_child(dog)
	
	# Store reference for save/load
	dog_instance = dog
	
	var name_tag = Label.new()
	name_tag.text = GameState.pet_name
	name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_tag.custom_minimum_size = Vector2(100, 20)
	
	var label_settings = LabelSettings.new()
	label_settings.font_size = 18
	label_settings.outline_size = 3
	label_settings.outline_color = Color.BLACK
	name_tag.label_settings = label_settings
	
	name_tag.scale = Vector2(1.0 / dog.scale.x, 1.0 / dog.scale.y)
	name_tag.position = Vector2(-50 * name_tag.scale.x, -40 * name_tag.scale.y)
	name_tag.visible = false
	name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dog.add_child(name_tag)
	
	dog.mouse_entered.connect(func():
		name_tag.visible = true
	)
	dog.mouse_exited.connect(func():
		name_tag.visible = false
	)
