# COMMIT: Achievements and Catch Minigame Update
extends Area2D

## Catch area in the dog park. Shows "Press E to play catch" when the player
## enters, and "Play again tomorrow" if already played today. Pressing E
## launches the catch minigame overlay.

var tutorial_hint_scene = preload("res://scenes/ui/tutorial_hint.tscn")
var hint_instance: CanvasLayer = null
var player_in_area: bool = false

func _ready():
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	hint_instance = tutorial_hint_scene.instantiate()
	get_tree().root.add_child.call_deferred(hint_instance)

	# Draw the highlight
	_create_highlight()

func _create_highlight():
	# Add a semi-transparent neon yellow polygon over this area's collision shape
	for child in get_children():
		if child is CollisionShape2D:
			var shape = child.shape
			if shape is RectangleShape2D:
				var rect_size = shape.size
				var poly = Polygon2D.new()
				poly.polygon = PackedVector2Array([
					Vector2(-rect_size.x / 2, -rect_size.y / 2),
					Vector2(rect_size.x / 2, -rect_size.y / 2),
					Vector2(rect_size.x / 2, rect_size.y / 2),
					Vector2(-rect_size.x / 2, rect_size.y / 2),
				])
				poly.color = Color(0.8, 1.0, 0.0, 0.3) # Neon yellow, 70% transparent
				poly.position = child.position
				add_child(poly)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = true

		# Check if catch was already played today
		if GameState.catch_last_played_day == GameState.current_day:
			GameState.catch_played_today = true

		if hint_instance:
			await get_tree().process_frame
			if GameState.catch_played_today:
				hint_instance.show_hint("Play again tomorrow")
			else:
				hint_instance.show_hint("Press E to play catch")

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = false
		if hint_instance:
			hint_instance.hide_hint()

func _input(event: InputEvent):
	if player_in_area and not GameState.catch_played_today:
		if event is InputEventKey and event.pressed and event.keycode == KEY_E:
			_start_catch_game()

func _start_catch_game():
	if hint_instance:
		hint_instance.hide_hint()

	# Create the catch game as an overlay CanvasLayer
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	var game = load("res://scripts/catch_game.gd").new()
	game.name = "CatchGame"
	canvas.add_child(game)
	get_tree().current_scene.add_child(canvas)

func _exit_tree():
	if hint_instance:
		hint_instance.queue_free()
		hint_instance = null
