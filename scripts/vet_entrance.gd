extends Area2D

# Vet entrance controller - shows "Press E to enter" and handles teleportation

var tutorial_hint_scene = preload("res://scenes/ui/tutorial_hint.tscn")
var hint_instance: CanvasLayer = null
var player_in_area: bool = false

# Teleport destination inside vet (in MainGame.tscn coordinates)
const VET_ENTRANCE_POS = Vector2(-1390, 2915)

func _ready():
	# Ensure monitoring is enabled
	monitoring = true
	
	# Connect area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	print("[VetEntrance] Ready, monitoring = ", monitoring)
	
	# Create hint instance
	hint_instance = tutorial_hint_scene.instantiate()
	get_tree().root.add_child.call_deferred(hint_instance)

func _on_body_entered(body: Node2D):
	print("[VetEntrance] Body entered: ", body.name, " groups: ", body.get_groups())
	if body.is_in_group("player"):
		player_in_area = true
		print("[VetEntrance] Player detected, showing hint")
		# Wait a frame for hint to be ready if just created
		if hint_instance:
			await get_tree().process_frame
			hint_instance.show_hint("Press E to enter the vet")

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = false
		# Hide hint
		if hint_instance:
			hint_instance.hide_hint()

func _input(event: InputEvent):
	if player_in_area and event.is_action_pressed("interact"):
		teleport_to_vet()
	# Also handle E key directly in case "interact" action isn't set up
	if player_in_area and event is InputEventKey and event.pressed and event.keycode == KEY_E:
		teleport_to_vet()

func teleport_to_vet():
	var player = get_tree().get_first_node_in_group("player")
	var dog = get_tree().get_first_node_in_group("dog")
	
	if player:
		player.global_position = VET_ENTRANCE_POS
	if dog:
		dog.global_position = VET_ENTRANCE_POS + Vector2(50, 0) # Dog beside player
	
	# Hide the hint after teleporting
	if hint_instance:
		hint_instance.hide_hint()
	
	player_in_area = false
	print("[Vet] Teleported player to vet at ", VET_ENTRANCE_POS)
