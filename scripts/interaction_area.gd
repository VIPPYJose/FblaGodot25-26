extends Area2D

@export var hint_text: String = "Press E to interact"
@export var target_position: Vector2
@export var is_exit: bool = false
@export var post_teleport_hint: String = ""
@export var is_sleep: bool = false
@export var is_shop_enter: bool = false  # Set to true for shop enter area

var tutorial_hint_scene = preload("res://scenes/ui/tutorial_hint.tscn")
var hint_instance: CanvasLayer = null
var player_in_area: bool = false

func _ready():
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Create hint instance if it doesn't exist
	# Note: We share one hint instance per area, but in a real game we might want a global one
	hint_instance = tutorial_hint_scene.instantiate()
	get_tree().root.add_child.call_deferred(hint_instance)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = true
		if hint_instance:
			await get_tree().process_frame
			hint_instance.show_hint(hint_text)

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = false
		if hint_instance:
			hint_instance.hide_hint()

func _input(event: InputEvent):
	if player_in_area and (event.is_action_pressed("interact") or event.is_action_pressed("controller_interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E)):
		if is_sleep:
			trigger_sleep()
		else:
			teleport()

func trigger_sleep():
	if hint_instance:
		hint_instance.hide_hint()
	
	# Curtain transition, then advance day
	await SceneManager.fade_in_place({"pattern": "curtains"})
	GameState.advance_day()

func teleport():
	var player = get_tree().get_first_node_in_group("player")
	var dog = get_tree().get_first_node_in_group("dog")
	
	if player:
		if player is CharacterBody2D:
			player.velocity = Vector2.ZERO
		player.global_position = target_position
	if dog:
		if dog is CharacterBody2D:
			dog.velocity = Vector2.ZERO
		dog.global_position = target_position + Vector2(40, 0)
		if "path" in dog:
			dog.path.clear()
	
	# Check if this is shop enter - hide shop path (check by name or flag)
	if is_shop_enter or name == "ShopEnter":
		var main_game = get_tree().current_scene
		if main_game and main_game.has_method("_on_shop_entered"):
			main_game._on_shop_entered()
	
	if hint_instance:
		hint_instance.hide_hint()
		if post_teleport_hint != "":
			# Use a small delay to ensure it shows after the fade out of previous hint
			await get_tree().create_timer(0.5).timeout
			hint_instance.show_hint(post_teleport_hint, 4.0)
	
	# Small delay to prevent immediate re-trigger if teleporting near another area
	player_in_area = false

func _exit_tree():
	if hint_instance:
		hint_instance.queue_free()
		hint_instance = null
