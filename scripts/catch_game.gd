# COMMIT: Achievements and Catch Minigame Update
extends Node2D

# ------- Catch Minigame -------
# The player controls the dog (actual dog sprite asset).
# A red ball is thrown to a random position. They have a timer
# (starting 10s, decreasing by 0.2s each round, min 2s) to
# reach the ball. Touching it awards $2 and a next ball spawns.
# Missing ends the game and shows earnings.

const BALL_RADIUS := 24.0
const DOG_SPEED := 280.0

var time_limit: float = 10.0
var timer: float = 0.0
var round_earnings: int = 0
var game_active: bool = false
var ball_position: Vector2 = Vector2.ZERO

# Popup for "+$2"
var popup_list: Array = []
# End screen
var show_end_screen: bool = false

# Arena rect (half viewport, centered)
var arena_rect: Rect2

# Timer bar
var bar_height := 56.0

# Dog sprite node
var dog_sprite: AnimatedSprite2D = null
var dog_pos: Vector2 = Vector2.ZERO
var current_breed: String = "basic_dog"
var last_dir: String = "idle"

func _ready():
	var vp_size = get_viewport_rect().size
	# Half-size arena, centered
	var arena_w = vp_size.x * 0.5
	var arena_h = vp_size.y * 0.5
	var arena_x = (vp_size.x - arena_w) / 2
	var arena_y = (vp_size.y - arena_h) / 2
	arena_rect = Rect2(arena_x, arena_y, arena_w, arena_h)

	# Get breed from GameState
	current_breed = GameState.dog_breed

	# Load and add the dog scene's AnimatedSprite2D
	var dog_scene = load("res://scenes/People and dog/dog.tscn")
	if dog_scene:
		var dog_instance = dog_scene.instantiate()
		# We only want the AnimatedSprite2D from the dog scene
		for child in dog_instance.get_children():
			if child is AnimatedSprite2D:
				dog_instance.remove_child(child)
				dog_sprite = child
				add_child(dog_sprite)
				break
		dog_instance.queue_free()

	if not dog_sprite:
		# Fallback: create a blank one
		dog_sprite = AnimatedSprite2D.new()
		add_child(dog_sprite)

	# Scale the dog sprite to 2x
	dog_sprite.scale = Vector2(2, 2)

	# Start dog at bottom-center of arena
	dog_pos = Vector2(arena_rect.position.x + arena_rect.size.x / 2, arena_rect.position.y + arena_rect.size.y - 40)
	dog_sprite.position = dog_pos
	_play_dog_anim("idle")

	_spawn_ball()
	game_active = true
	timer = time_limit

func _play_dog_anim(anim_name: String):
	if not dog_sprite or not dog_sprite.sprite_frames:
		return
	var possible_names = [
		current_breed + "_" + anim_name,
		current_breed.capitalize() + "_" + anim_name,
		anim_name,
		"basic_dog_" + anim_name,
		"basic_Dog_" + anim_name
	]
	for name_check in possible_names:
		if dog_sprite.sprite_frames.has_animation(name_check):
			if dog_sprite.animation != name_check:
				dog_sprite.play(name_check)
			return

func _spawn_ball():
	ball_position = Vector2(
		randf_range(arena_rect.position.x + 30, arena_rect.position.x + arena_rect.size.x - 30),
		randf_range(arena_rect.position.y + 30, arena_rect.position.y + arena_rect.size.y * 0.6)
	)
	timer = time_limit

func _process(delta):
	if show_end_screen:
		queue_redraw()
		return

	if not game_active:
		return

	# Dog movement
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_action_pressed("move_up") or Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down") or Input.is_key_pressed(KEY_S):
		input_dir.y += 1

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()

	dog_pos += input_dir * DOG_SPEED * delta

	# Clamp dog inside arena
	dog_pos.x = clamp(dog_pos.x, arena_rect.position.x + 20, arena_rect.position.x + arena_rect.size.x - 20)
	dog_pos.y = clamp(dog_pos.y, arena_rect.position.y + 20, arena_rect.position.y + arena_rect.size.y - 20)

	# Update sprite position
	if dog_sprite:
		dog_sprite.position = dog_pos

	# Animate based on movement
	if input_dir == Vector2.ZERO:
		if last_dir != "idle":
			last_dir = "idle"
			_play_dog_anim("idle")
	else:
		# Flip sprite for left/right
		if dog_sprite:
			dog_sprite.flip_h = input_dir.x < 0
		if last_dir != "run":
			last_dir = "run"
			_play_dog_anim("run")

	# Check ball collision
	if dog_pos.distance_to(ball_position) < BALL_RADIUS + 36:
		_catch_ball()

	# Timer countdown
	timer -= delta
	if timer <= 0:
		_end_game()

	# Update popups
	var to_remove = []
	for popup in popup_list:
		popup["time"] -= delta
		popup["pos"].y -= 30 * delta
		if popup["time"] <= 0:
			to_remove.append(popup)
	for p in to_remove:
		popup_list.erase(p)

	queue_redraw()

func _catch_ball():
	round_earnings += 2
	popup_list.append({"text": "+$2", "pos": Vector2(ball_position.x, ball_position.y), "time": 1.0})

	# Decrease time limit
	time_limit = max(2.0, time_limit - 0.2)
	_spawn_ball()

func _end_game():
	game_active = false
	show_end_screen = true

	# Stop dog animation
	if dog_sprite:
		_play_dog_anim("idle")

	# Award money
	GameState.money += round_earnings
	GameState.catch_total_earnings += round_earnings
	GameState.record_transaction("Catch game earnings", round_earnings, "Income")

	# Check achievements
	if round_earnings >= 40 and not GameState.achievements["Catch Pro"]:
		GameState.achievements["Catch Pro"] = true
		GameState.achievement_unlocked.emit("Catch Pro")
	if GameState.catch_total_earnings >= 200 and not GameState.achievements["Catch Master"]:
		GameState.achievements["Catch Master"] = true
		GameState.achievement_unlocked.emit("Catch Master")

func _draw():
	var vp_size = get_viewport_rect().size

	# Background (full screen dark green)
	draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.12, 0.22, 0.12))
	# Arena grass
	draw_rect(arena_rect, Color(0.25, 0.55, 0.22))
	# Arena border
	draw_rect(arena_rect, Color(1, 1, 1, 0.3), false, 3.0)

	if show_end_screen:
		_draw_end_screen()
		return

	if not game_active:
		return

	# Timer bar (above the arena)
	var bar_w = arena_rect.size.x
	var bar_x = arena_rect.position.x
	var bar_y = arena_rect.position.y - bar_height - 8
	var pct = clamp(timer / time_limit, 0.0, 1.0)
	# Background bar
	draw_rect(Rect2(bar_x, bar_y, bar_w, bar_height), Color(0.2, 0.2, 0.2))
	# Fill
	var fill_color = Color(0.2, 0.8, 0.2) if pct > 0.3 else Color(0.9, 0.2, 0.2)
	draw_rect(Rect2(bar_x, bar_y, bar_w * pct, bar_height), fill_color)
	# Timer text
	draw_string(ThemeDB.fallback_font, Vector2(bar_x + bar_w / 2 - 40, bar_y + 42), "%.1fs" % timer, HORIZONTAL_ALIGNMENT_CENTER, -1, 40, Color.WHITE)

	# Ball (red circle)
	draw_circle(ball_position, BALL_RADIUS, Color(0.9, 0.15, 0.15))
	draw_circle(ball_position, BALL_RADIUS, Color(1, 0.3, 0.3), false, 3.0)
	# Ball highlight
	draw_circle(ball_position + Vector2(-5, -5), 7, Color(1, 0.6, 0.6, 0.6))

	# Dog sprite is drawn automatically as a child node

	# Earnings label (below the arena)
	draw_string(ThemeDB.fallback_font, Vector2(arena_rect.position.x + 10, arena_rect.position.y + arena_rect.size.y + 40), "Earned: $%d" % round_earnings, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(0.2, 1.0, 0.2))

	# Popups
	for popup in popup_list:
		var alpha = clamp(popup["time"], 0.0, 1.0)
		draw_string(ThemeDB.fallback_font, popup["pos"], "+$2", HORIZONTAL_ALIGNMENT_CENTER, -1, 48, Color(0.1, 1.0, 0.1, alpha))

func _draw_end_screen():
	var vp_size = get_viewport_rect().size
	# Darken
	draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0, 0, 0, 0.6))

	var center = vp_size / 2
	# Panel
	var panel_rect = Rect2(center.x - 200, center.y - 100, 400, 200)
	draw_rect(panel_rect, Color(0.15, 0.15, 0.2, 0.95))
	draw_rect(panel_rect, Color(0.5, 0.8, 0.5), false, 3.0)

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(center.x - 120, center.y - 40), "You earned $%d" % round_earnings, HORIZONTAL_ALIGNMENT_CENTER, -1, 48, Color(0.2, 1.0, 0.2))

	# Exit button
	var btn_rect = Rect2(center.x - 80, center.y + 20, 160, 50)
	draw_rect(btn_rect, Color(0.3, 0.6, 0.3))
	draw_rect(btn_rect, Color(0.5, 0.9, 0.5), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(center.x - 30, center.y + 55), "Exit", HORIZONTAL_ALIGNMENT_CENTER, -1, 40, Color.WHITE)

func _unhandled_input(event):
	if show_end_screen:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var center = get_viewport_rect().size / 2
			var btn_rect = Rect2(center.x - 80, center.y + 20, 160, 50)
			if btn_rect.has_point(event.position):
				_exit_game()
		# Also allow pressing E or Enter or Escape to exit
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_E or event.keycode == KEY_ENTER or event.keycode == KEY_ESCAPE:
				_exit_game()

func _exit_game():
	# Mark as played today
	GameState.catch_played_today = true
	GameState.catch_last_played_day = GameState.current_day
	get_tree().paused = false
	# Free the parent CanvasLayer that wraps us
	if get_parent() is CanvasLayer:
		get_parent().queue_free()
	else:
		queue_free()
