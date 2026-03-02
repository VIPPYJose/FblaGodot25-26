extends Area2D
## Teleport area that shows an interact prompt and teleports the player when E is pressed.

## Duration of the pop-in / pop-out animation for the interact prompt.
@export var interact_prompt_pop_duration: float = 0.2

## Target position to teleport the player to.
@export var teleport_position: Vector2 = Vector2(3400, 250)

@onready var interact_canvas: CanvasLayer = get_node_or_null("CanvasLayer")
@onready var interact_prompt_label: Label = get_node_or_null("CanvasLayer/EToInteract")

var _player_in_range: CharacterBody2D = null
var _interact_prompt_showing: bool = false
var _interact_tween: Tween


func _ready() -> void:
	if not body_entered.is_connected(_on_area_body_entered):
		body_entered.connect(_on_area_body_entered)
	if not body_exited.is_connected(_on_area_body_exited):
		body_exited.connect(_on_area_body_exited)
	if interact_canvas != null:
		interact_canvas.visible = false
	if interact_prompt_label != null:
		interact_prompt_label.text = "Press E to enter backyard"


func _update_prompt_visibility() -> void:
	var show_prompt: bool = _player_in_range != null
	_update_interact_prompt_animation(show_prompt)


func _update_interact_prompt_animation(show_prompt: bool) -> void:
	if interact_canvas == null or interact_prompt_label == null:
		return
	if _interact_tween != null and _interact_tween.is_valid():
		_interact_tween.kill()
	if show_prompt and not _interact_prompt_showing:
		_interact_prompt_showing = true
		interact_canvas.visible = true
		interact_prompt_label.scale = Vector2.ZERO
		call_deferred("_play_interact_pop_in")
	elif not show_prompt and _interact_prompt_showing:
		_interact_prompt_showing = false
		_interact_tween = create_tween()
		_interact_tween.set_ease(Tween.EASE_IN)
		_interact_tween.set_trans(Tween.TRANS_BACK)
		_interact_tween.tween_property(interact_prompt_label, "scale", Vector2.ZERO, interact_prompt_pop_duration * 0.8)
		_interact_tween.tween_callback(func() -> void:
			interact_canvas.visible = false
			interact_prompt_label.scale = Vector2.ONE
		)


func _play_interact_pop_in() -> void:
	if interact_prompt_label == null or not _interact_prompt_showing:
		return
	interact_prompt_label.pivot_offset = interact_prompt_label.size / 2.0
	_interact_tween = create_tween()
	_interact_tween.set_ease(Tween.EASE_OUT)
	_interact_tween.set_trans(Tween.TRANS_BACK)
	_interact_tween.tween_property(interact_prompt_label, "scale", Vector2.ONE, interact_prompt_pop_duration)


func _on_area_body_entered(body: Node2D) -> void:
	if body.name == "player" and body is CharacterBody2D:
		_player_in_range = body as CharacterBody2D
		_update_prompt_visibility()


func _on_area_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		_update_prompt_visibility()


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"interact"):
		return
	if _player_in_range == null:
		return
	
	# Teleport the player to the target position
	_player_in_range.global_position = teleport_position
	# Hide the prompt after teleporting
	_player_in_range = null
	_update_prompt_visibility()
