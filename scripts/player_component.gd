# COMMIT: Achievements and Catch Minigame Update
extends CharacterBody2D

## Player controller for the component-based (layered) character system.
## Each visual layer (Body, Eyes, Outfit, Hairstyle, Accessory) is a separate
## AnimatedSprite2D child — this script keeps them all in sync.

@export var speed := 300

var input_dir := Vector2.ZERO
var last_dir := Vector2.ZERO

# Cached references to the layered sprites (populated in _ready)
var _sprites: Array[AnimatedSprite2D] = []

@onready var npc: CharacterBody2D = get_node_or_null("../Path2D/PathFollow2D/npc")


func _ready() -> void:
	# Gather every AnimatedSprite2D child as a component layer
	for child in get_children():
		if child is AnimatedSprite2D:
			_sprites.append(child)

	# Set camera zoom
	var camera = get_node_or_null("Camera2D")
	if camera:
		camera.zoom = Vector2(2.5, 2.5)

	# Ensure player collides with everything
	collision_mask = 1
	collision_layer = 1


func _physics_process(_delta: float) -> void:
	var player_can_move := player_moveable()

	input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down"),
	)

	if not player_can_move:
		input_dir = Vector2.ZERO

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		velocity = input_dir * speed
		move_and_slide()

		last_dir = input_dir
		_play_move_anim()
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		_play_idle_anim()


func _play_move_anim() -> void:
	var anim := ""
	if last_dir.x > 0:
		anim = "move_right"
	elif last_dir.x < 0:
		anim = "move_left"
	elif last_dir.y < 0:
		anim = "move_up"
	else:
		anim = "move_down"
	_play_on_all(anim)


func _play_idle_anim() -> void:
	var anim := ""
	if last_dir.x > 0:
		anim = "idle_right"
	elif last_dir.x < 0:
		anim = "idle_left"
	elif last_dir.y < 0:
		anim = "idle_up"
	else:
		anim = "idle_down"
	_play_on_all(anim)


func _play_on_all(anim_name: String) -> void:
	for sprite in _sprites:
		if sprite and sprite.sprite_frames:
			if sprite.sprite_frames.has_animation(anim_name):
				sprite.play(anim_name)


func player_moveable() -> bool:
	# Block movement during tutorial
	if GameState.tutorial_blocks_movement:
		return false
	if npc and not npc.player_can_move:
		return false
	return true
