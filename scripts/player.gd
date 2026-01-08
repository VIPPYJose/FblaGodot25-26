extends CharacterBody2D

@export var speed := 150

var input_dir := Vector2.ZERO
var last_dir := Vector2.ZERO

@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var npc: CharacterBody2D = get_node_or_null("../Path2D/PathFollow2D/npc")


func _physics_process(_delta: float) -> void:
	var player_can_move = player_moveable()

	input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down"),
	)

	if !player_can_move:
		input_dir = Vector2(0,0)

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
	if last_dir.x > 0: 
		sprite_2d.play("move_right")
	elif last_dir.x < 0: 
		sprite_2d.play("move_left")
	elif last_dir.y < 0: 
		sprite_2d.play("move_up")
	else: 
		sprite_2d.play("move_down")
		
func _play_idle_anim():
	if last_dir.x > 0: 
		sprite_2d.play("idle_right")
	elif last_dir.x < 0: 
		sprite_2d.play("idle_left")
	elif last_dir.y < 0: 
		sprite_2d.play("idle_up")
	else: 
		sprite_2d.play("idle_down")
	
func player_moveable():
	if npc and not npc.player_can_move:
		return false
	return true
