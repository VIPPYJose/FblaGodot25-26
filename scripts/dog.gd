extends CharacterBody2D

@export var target_distance: float = 67.0
@export var player_group: String = "player"
@export var needs_menu_scene: PackedScene = preload("res://scenes/ui/needs_menu.tscn")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var breed: String = "basic_dog"

# State machine
enum DogState {FOLLOWING_PLAYER, GOING_TO_FOOD, GOING_TO_WATER, GOING_TO_SLEEP, SLEEPING}
var current_state: DogState = DogState.FOLLOWING_PLAYER

var path: Array[Vector2] = []
var needs_menu_instance: CanvasLayer

# Path following for actions
var action_path: Array = []
var action_callback: Callable
var action_speed: float = 100.0

var hunger: float = 80.0
var thirst: float = 70.0
var energy: float = 100.0
var hygiene: float = 90.0
var health: float = 30.0 # Starts at 30 on Day 1

var hunger_decay: float = 100.0 / 240.0 # ~0.417 per second (4 minutes to empty)
var thirst_decay: float = 100.0 / 240.0
var energy_decay: float = 100.0 / 240.0
var hygiene_decay: float = 100.0 / 240.0

# Initialize all pet needs for Day 1
func initialize_day_one():
	hunger = 100.0
	thirst = 100.0
	energy = 100.0
	hygiene = 100.0
	health = 30.0 # Health starts low on Day 1

# Apply random health change at start of each day
func apply_daily_health_change():
	var change = randi_range(-30, 30)
	health = clamp(health + change, 10, 100) # Floor at 10, cap at 100

func _ready() -> void:
	add_to_group("dog")
	input_pickable = true
	
	# Ensure dog collides with everything
	collision_mask = 1
	collision_layer = 1
	
	if needs_menu_scene:
		needs_menu_instance = needs_menu_scene.instantiate()
		get_tree().root.add_child.call_deferred(needs_menu_instance)
	
	# Connect to day started signal
	GameState.day_started.connect(_on_day_started)

func _on_day_started(_day: int):
	# Wake up from sleep
	if current_state == DogState.SLEEPING:
		current_state = DogState.FOLLOWING_PLAYER
		GameState.is_dog_sleeping = false
		_play_animation("idle")

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggle_menu()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		toggle_menu()
	
	# Dog action keys (only when following player)
	if current_state == DogState.FOLLOWING_PLAYER and event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			start_action("food path", DogState.GOING_TO_FOOD, _on_food_complete)
		elif event.keycode == KEY_2:
			start_action("water path", DogState.GOING_TO_WATER, _on_water_complete)
		elif event.keycode == KEY_3:
			start_action("Sleep path", DogState.GOING_TO_SLEEP, _on_sleep_complete)

func start_action(path_name: String, state: DogState, callback: Callable):
	var main_game = get_tree().current_scene
	var path_node = main_game.get_node_or_null(path_name)
	if not path_node or not path_node is Path2D:
		print("Path not found: ", path_name)
		return
	
	# Get baked points and convert to GLOBAL coordinates
	var local_points = path_node.curve.get_baked_points()
	action_path.clear()
	for point in local_points:
		action_path.append(path_node.to_global(point))
	
	action_callback = callback
	current_state = state
	path.clear()
	print("Started action: ", path_name, " with ", action_path.size(), " points")

func _on_food_complete():
	hunger = min(100.0, hunger + 30.0)
	current_state = DogState.FOLLOWING_PLAYER
	print("Dog ate! Hunger: ", hunger)

func _on_water_complete():
	thirst = min(100.0, thirst + 30.0)
	current_state = DogState.FOLLOWING_PLAYER
	print("Dog drank! Thirst: ", thirst)

func _on_sleep_complete():
	energy = 100.0
	current_state = DogState.SLEEPING
	GameState.is_dog_sleeping = true
	_play_animation("sleeping")
	print("Dog sleeping! Energy: ", energy)

func toggle_menu() -> void:
	if needs_menu_instance:
		if needs_menu_instance.panel.visible:
			needs_menu_instance.panel.hide()
		else:
			needs_menu_instance.show_menu(self)

func _physics_process(delta: float) -> void:
	GameState.dog_health = health
	
	# Handle state-specific behavior
	match current_state:
		DogState.SLEEPING:
			# Frozen - play sleep animation and stay put
			_play_animation("sleeping")
			velocity = Vector2.ZERO
			return
		DogState.GOING_TO_FOOD, DogState.GOING_TO_WATER, DogState.GOING_TO_SLEEP:
			# Follow action path
			_process_action_path()
			return
		DogState.FOLLOWING_PLAYER:
			_process_following_player(delta)

func _process_action_path():
	if action_path.is_empty():
		# Reached destination
		velocity = Vector2.ZERO
		_play_animation("idle")
		
		if action_callback.is_valid():
			var cb = action_callback
			action_callback = Callable()
			cb.call()
		return
	
	var target = action_path[0]
	var direction = (target - global_position).normalized()
	var distance = global_position.distance_to(target)
	
	if distance < 10.0:
		action_path.remove_at(0)
		return
	
	velocity = direction * action_speed
	move_and_slide()
	
	_play_animation("run")
	if direction.x < 0:
		animated_sprite_2d.flip_h = true
	elif direction.x > 0:
		animated_sprite_2d.flip_h = false

func _process_following_player(delta: float):
	# Don't decay needs during tutorial or when dog is sleeping
	if not GameState.is_tutorial_complete or GameState.is_dog_sleeping:
		pass # Skip decay
	else:
		hunger = max(0, hunger - hunger_decay * delta)
		thirst = max(0, thirst - thirst_decay * delta)
		energy = max(0, energy - energy_decay * delta)
		hygiene = max(0, hygiene - hygiene_decay * delta)
		
		check_emergency_triggers(delta)
	
	var player = get_tree().get_first_node_in_group(player_group)
	if not player:
		return

	if player.velocity == Vector2.ZERO:
		_play_animation("idle")
		return
	
	var old_pos = global_position
	
	if path.is_empty() or path.back().distance_to(player.global_position) > 1.0:
		path.append(player.global_position)
	
	var accumulated_distance = 0.0
	var _found_target = false
	
	for i in range(path.size() - 1, 0, -1):
		var p_current = path[i]
		var p_prev = path[i - 1]
		var segment_distance = p_current.distance_to(p_prev)
		
		if accumulated_distance + segment_distance >= target_distance:
			var remaining_distance = target_distance - accumulated_distance
			var ratio = remaining_distance / segment_distance
			var target_pos = p_current.lerp(p_prev, ratio)
			
			velocity = (target_pos - global_position) / delta
			move_and_slide()
			
			while i > 0:
				path.remove_at(0)
				i -= 1
			
			_found_target = true
			break
		
		accumulated_distance += segment_distance
	
	if old_pos.distance_to(global_position) > 0.1:
		_play_animation("run")
		if global_position.x < old_pos.x:
			animated_sprite_2d.flip_h = true
		elif global_position.x > old_pos.x:
			animated_sprite_2d.flip_h = false
	else:
		_play_animation("idle")

var emergency_cooldown: float = 0.0

func check_emergency_triggers(delta: float):
	if emergency_cooldown > 0:
		emergency_cooldown -= delta
		return

	# Emergency Vet Logic
	if health < 20:
		# Attempt to pay $50 for emergency care
		if GameState.spend_money(50, "Vet"):
			health = 50
			emergency_cooldown = 10.0
			print("Emergency Vet Care triggered!")
	
	# Emergency Food Logic
	if hunger < 10 and GameState.food <= 0:
		# Attempt to pay $20 for food
		if GameState.spend_money(20, "Food"):
			GameState.food += 7
			hunger = 50
			emergency_cooldown = 10.0
			print("Emergency Food Purchase triggered!")

func _play_animation(anim_name: String) -> void:
	if not animated_sprite_2d:
		return
	
	var possible_names = [
		breed + "_" + anim_name,
		breed.capitalize() + "_" + anim_name,
		anim_name,
		"basic_dog_" + anim_name
	]
	
	for anim_name_to_check in possible_names:
		if animated_sprite_2d.sprite_frames.has_animation(anim_name_to_check):
			animated_sprite_2d.play(anim_name_to_check)
			return

