extends CharacterBody2D

@export var target_distance: float = 67.0
@export var player_group: String = "player"
@export var needs_menu_scene: PackedScene = preload("res://scenes/ui/needs_menu.tscn")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var breed: String = "basic_dog"

var path: Array[Vector2] = []
var needs_menu_instance: CanvasLayer

var hunger: float = 80.0
var thirst: float = 70.0
var energy: float = 100.0
var hygiene: float = 90.0
var health: float = 30.0 # Starts at 30 on Day 1

var hunger_decay: float = 0.5
var thirst_decay: float = 0.8
var energy_decay: float = 0.3
var hygiene_decay: float = 0.2

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

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggle_menu()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		toggle_menu()

func toggle_menu() -> void:
	if needs_menu_instance:
		if needs_menu_instance.panel.visible:
			needs_menu_instance.panel.hide()
		else:
			needs_menu_instance.show_menu(self)

func _physics_process(delta: float) -> void:
	# Don't decay needs during tutorial
	if not GameState.is_tutorial_complete:
		pass # Skip decay
	else:
		hunger = max(0, hunger - hunger_decay * delta)
		thirst = max(0, thirst - thirst_decay * delta)
		energy = max(0, energy - energy_decay * delta)
		hygiene = max(0, hygiene - hygiene_decay * delta)
	
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
