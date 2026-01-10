extends CharacterBody2D

@export var target_distance: float = 67.0
@export var player_group: String = "player"
@export var needs_menu_scene: PackedScene = preload("res://scenes/needs_menu.tscn")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var breed: String = "basic_dog"

var path: Array[Vector2] = []
var needs_menu_instance: CanvasLayer


var hunger: float = 80.0
var thirst: float = 70.0
var energy: float = 100.0
var hygiene: float = 90.0


var hunger_decay: float = 0.5
var thirst_decay: float = 0.8
var energy_decay: float = 0.3
var hygiene_decay: float = 0.2

func _ready() -> void:
	# Enable input picking for the dog so it can be clicked
	input_pickable = true
	
	# Instance the needs menu and add it to the scene
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
	# Decay needs
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
	var found_target = false
	
	for i in range(path.size() - 1, 0, -1):
		var p_current = path[i]
		var p_prev = path[i-1]
		var segment_distance = p_current.distance_to(p_prev)
		
		if accumulated_distance + segment_distance >= target_distance:
			# The target point is on this segment
			var remaining_distance = target_distance - accumulated_distance
			var ratio = remaining_distance / segment_distance
			global_position = p_current.lerp(p_prev, ratio)
			
			while i > 0:
				path.remove_at(0)
				i -= 1
			
			found_target = true
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
	
	if not found_target and not path.is_empty():
		pass

func _play_animation(anim_name: String) -> void:
	if not animated_sprite_2d:
		return
	
	# Try various naming conventions found in the tscn
	var possible_names = [
		breed + "_" + anim_name,
		breed.capitalize() + "_" + anim_name,
		anim_name, # fallback to exact name if it exists
		"basic_dog_" + anim_name # final fallback
	]
	
	for name in possible_names:
		if animated_sprite_2d.sprite_frames.has_animation(name):
			animated_sprite_2d.play(name)
			return
