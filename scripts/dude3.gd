extends CharacterBody2D

@export var speed := 300

var input_dir := Vector2.ZERO
var last_dir := Vector2.ZERO

@onready var sprite_2d: AnimatedSprite2D = $Sprite2D if has_node("Sprite2D") else $playerspriteanim
@onready var npc: CharacterBody2D = get_node_or_null("../Path2D/PathFollow2D/npc")


func _ready():
	# Set camera zoom to 5
	var camera = get_node_or_null("Camera2D")
	if camera:
		camera.zoom = Vector2(5, 5)

func _physics_process(_delta: float) -> void:
	var player_can_move = player_moveable()

	# Get keyboard input
	var keyboard_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down"),
	)
	
	# Get controller left joystick input
	var controller_dir = Vector2(
		Input.get_axis("controller_move_left", "controller_move_right"),
		Input.get_axis("controller_move_up", "controller_move_down"),
	)
	
	# Combine inputs (controller takes priority if both are active)
	if controller_dir.length() > 0.2:  # Deadzone check
		input_dir = controller_dir
	else:
		input_dir = keyboard_dir

	if !player_can_move:
		input_dir = Vector2(0, 0)

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		velocity = input_dir * speed
		move_and_slide()
		#print("player is moving")
		
		last_dir = input_dir
		_play_move_anim()
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		_play_idle_anim()

func _play_move_anim():
	var anim = ""
	if last_dir.x > 0: anim = "move_right"
	elif last_dir.x < 0: anim = "move_left"
	elif last_dir.y < 0: anim = "move_up"
	else: anim = "move_down"
	_play_if_exists(anim)

func _play_idle_anim():
	var anim = ""
	if last_dir.x > 0: anim = "idle_right"
	elif last_dir.x < 0: anim = "idle_left"
	elif last_dir.y < 0: anim = "idle_up"
	else: anim = "idle_down"
	_play_if_exists(anim)

func _play_if_exists(anim_name: String):
	if !sprite_2d: return
	if sprite_2d.sprite_frames.has_animation(anim_name):
		sprite_2d.play(anim_name)
	elif sprite_2d.sprite_frames.has_animation(anim_name + "_dude1"):
		sprite_2d.play(anim_name + "_dude1")

func player_moveable():
	if npc and not npc.player_can_move:
		return false
	return true
