extends Area2D

var tutorial_hint_scene = preload("res://scenes/ui/tutorial_hint.tscn")
var hint_instance: CanvasLayer = null
var player_in_area: bool = false
var dialogue_resource = load("res://dialogues/shop.dialogue")

func _ready():
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	hint_instance = tutorial_hint_scene.instantiate()
	get_tree().root.add_child.call_deferred(hint_instance)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = true
		if hint_instance:
			hint_instance.show_hint("Press E to shop")

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = false
		if hint_instance:
			hint_instance.hide_hint()

func _input(event: InputEvent):
	if player_in_area and (event.is_action_pressed("interact") or event.is_action_pressed("controller_interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E)):
		start_dialogue()

func start_dialogue():
	if DialogueManager:
		# Using custom balloon for larger text
		var balloon_scene = load("res://dialogues/balloon.tscn")
		var balloon = balloon_scene.instantiate()
		get_tree().root.add_child(balloon)
		balloon.start(dialogue_resource, "start")
	else:
		# Fallback if DialogueManager is not working/installed
		open_shop()

func open_shop():
	var shop_menu = get_tree().root.find_child("ShopMenu", true, false)
	if shop_menu:
		shop_menu.show_shop()
	else:
		print("[ShopNPC] ShopMenu not found!")

func _exit_tree():
	if hint_instance:
		hint_instance.queue_free()
		hint_instance = null
