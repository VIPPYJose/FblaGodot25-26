extends Area2D

var tutorial_hint_scene = preload("res://scenes/ui/tutorial_hint.tscn")
var hint_instance: CanvasLayer = null
var player_in_area: bool = false
var dialogue_resource = load("res://dialogues/vet.dialogue")
var has_talked_to_vet: bool = false

func _ready():
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	hint_instance = tutorial_hint_scene.instantiate()
	get_tree().root.add_child.call_deferred(hint_instance)
	
	# Connect to vet_talk_finished signal to know when dialogue is done
	GameState.vet_talk_finished.connect(_on_vet_talk_finished)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = true
		if hint_instance and not has_talked_to_vet:
			hint_instance.show_hint("Press E to talk")

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = false
		if hint_instance:
			hint_instance.hide_hint()
		# Show hint to follow shop path when leaving after talking
		if has_talked_to_vet and GameState.is_day_one:
			await get_tree().create_timer(0.5).timeout
			if hint_instance:
				hint_instance.show_hint("Follow the path to the shop", 5.0)

func _input(event: InputEvent):
	if player_in_area and (event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E)):
		start_dialogue()

func start_dialogue():
	if DialogueManager:
		has_talked_to_vet = true
		if hint_instance:
			hint_instance.hide_hint()
		
		# Using custom balloon for larger text
		var balloon_scene = load("res://dialogues/balloon.tscn")
		var balloon = balloon_scene.instantiate()
		get_tree().root.add_child(balloon)
		balloon.start(dialogue_resource, "start")
	else:
		print("[VetNPC] DialogueManager not found!")

func _on_vet_talk_finished():
	# Mark that we've talked to the vet
	has_talked_to_vet = true

func _exit_tree():
	if hint_instance:
		hint_instance.queue_free()
		hint_instance = null

