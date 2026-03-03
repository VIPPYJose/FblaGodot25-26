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
@onready var shop_path = $ShopPath
@onready var original_path = $VetPath

func _ready():
	spawn_player()
	spawn_dog()
	setup_hud()
	setup_pause_menu()
	# Only show tutorial paths if it's Day 1 and tutorial isn't complete
	if GameState.is_day_one and not GameState.is_tutorial_complete:
		_make_paths_visible()
	else:
		# Ensure they are hidden if they exist
		if original_path: original_path.visible = false
		if shop_path: shop_path.visible = false
	
	# Background Music
	var music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic"
	var music_stream = load("res://assets/Music/inspiring-synth-arpeggios-with-mellow-pads-and-creative-calm-energy-408709 (1).mp3")
	if music_stream:
		music_player.stream = music_stream
		music_player.autoplay = true
		# Godot 4.x loop setting is on the stream itself usually for mp3, 
		# but let's ensure it loops via script if needed or trust the importer.
		# If it's an AudioStreamMP3, we can set loop.
		if music_stream is AudioStreamMP3:
			music_stream.loop = true
		add_child(music_player)
		music_player.play()
	
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
	GameState.vet_talk_finished.connect(_on_vet_talk_finished)

var home_hint_shown = false
func _on_shop_closed():
	if GameState.is_day_one and not home_hint_shown:
		home_hint_shown = true
		# Show hint after shop
		var tutorial_hint_scene = preload("res://scenes/ui/tutorial_hint.tscn")
		var hint = tutorial_hint_scene.instantiate()
		get_tree().root.add_child(hint)
		hint.show_hint("Press the home button 🏠 to go home.", 6.0)

func _on_vet_talk_finished():
	if GameState.is_day_one:
		if original_path:
			original_path.visible = false
		if shop_path:
			shop_path.visible = true
			# Ensure the visual representation (Line2D) is also updated if needed
			# _make_paths_visible() already creates Line2D as children.
			# If shop_path was already visible, _make_paths_visible handles it.
			# But we might need to recreate Line2D if we just made it visible.

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
		
		# Connect to shop closed signal for home hint
		if hud.shop_menu_instance:
			hud.shop_menu_instance.shop_closed.connect(_on_shop_closed)

func spawn_player():
	if GameState.uses_component_system:
		_spawn_component_player()
	else:
		_spawn_legacy_player()


func _spawn_legacy_player():
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
	_add_name_tag(player)


func _spawn_component_player():
	# Build a layered character from individual component SpriteFrames
	var player = CharacterBody2D.new()
	player.name = "Player"
	player.global_position = player_spawn_pos
	player.scale = Vector2(0.0000000017, 0.0000000017)
	player.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	player.input_pickable = true

	# Layer order: Body → Eyes → Outfit → Hairstyle → Accessory
	var components := GameState.get_character_components()
	var layer_order := ["body", "eyes", "outfit", "hairstyle", "accessory"]
	var first_sprite: AnimatedSprite2D = null

	for category in layer_order:
		var option: int = components.get(category, 1)
		var sf: SpriteFrames = GameState.get_component_sprite_frames(category, option)
		if sf:
			var sprite := AnimatedSprite2D.new()
			sprite.name = category.capitalize()
			sprite.sprite_frames = sf
			sprite.position = Vector2(0, -4.26)
			if sf.has_animation("idle_down"):
				sprite.animation = "idle_down"
			player.add_child(sprite)
			if first_sprite == null:
				first_sprite = sprite

	# Add collision shape
	var collision = CollisionPolygon2D.new()
	collision.polygon = PackedVector2Array([
		Vector2(0, -5.28), Vector2(-3.52, -5.28), Vector2(-3.08, 6.6),
		Vector2(0, 9.25), Vector2(3.08, 6.6), Vector2(3.52, -5.28)
	])
	player.add_child(collision)

	# Add camera
	var camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.zoom = Vector2(2.5, 2.5)
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.position_smoothing_enabled = true
	camera.scale = Vector2(1.005, 1.075)
	camera.add_to_group("player")
	player.add_child(camera)

	player.set_script(load("res://scripts/player_component.gd"))
	add_child(player)
	player.add_to_group("player")
	_add_name_tag(player)


func _add_name_tag(player: Node):
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
	dog.add_to_group("dog")
	
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

func _make_paths_visible():
	# Look for Path2D nodes and create Line2D to make them visible
	# We'll check children of current node and also look for 'path2d' nodes specifically
	var paths = []
	for child in get_children():
		if child is Path2D:
			paths.append(child)
	
	# Also check globally for common names if not found
	if paths.is_empty():
		var global_path = get_node_or_null("Path2D")
		if global_path and global_path is Path2D:
			paths.append(global_path)
			
	for path in paths:
		var line = Line2D.new()
		line.points = path.curve.get_baked_points()
		line.width = 4.0
		line.default_color = Color(1, 1, 0, 0.5) # Semi-transparent yellow
		path.add_child(line)
		print("[MainGame] Made path visible: ", path.name)
