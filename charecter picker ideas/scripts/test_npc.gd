# COMMIT: Achievements and Catch Minigame Update
extends CharacterBody2D
## NPC that starts dialogue when the player enters its Area2D and presses the interact key.
## Locks player movement during dialogue and unlocks when dialogue ends.

@export var dialogue_resource: DialogueResource
## Dialogue title to start from (e.g. "start" for ~ start in the .dialogue file).
@export var dialogue_title: String = "start"

## Duration of the pop-in / pop-out animation for the interact prompt.
@export var interact_prompt_pop_duration: float = 0.2

@onready var area: Area2D = $TalkArea
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var name_show: Area2D = $NameShow
@onready var name_label: Label = $NameLabel
@onready var prompt_layer: CanvasLayer = get_node_or_null("PromptLayer")
## CanvasLayer with label that shows when player is in Area2D (e.g. "Press E To Interact").
@onready var interact_canvas: CanvasLayer = get_node_or_null("CanvasLayer")
@onready var interact_prompt_label: Control = get_node_or_null("CanvasLayer/EToInteract")

var _player_in_range: CharacterBody2D = null
var _dialogue_active: bool = false
var _dialogue_ended_connection: Callable
var _messages_screen_open: bool = false
var _interact_prompt_showing: bool = false
var _interact_tween: Tween
var _name_label_showing: bool = false
var _name_label_tween: Tween


func _ready() -> void:
	add_to_group("interact_prompt_npc")
	if not area.body_entered.is_connected(_on_area_body_entered):
		area.body_entered.connect(_on_area_body_entered)
	if not area.body_exited.is_connected(_on_area_body_exited):
		area.body_exited.connect(_on_area_body_exited)
	if dialogue_resource == null:
		dialogue_resource = load("res://dialogue/test.dialogue") as DialogueResource
	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle_down"):
		sprite.animation = "idle_down"
		sprite.play()
	if prompt_layer != null:
		prompt_layer.visible = false
	if interact_canvas != null:
		interact_canvas.visible = false


func _process(_delta: float) -> void:
	if name_show == null or name_label == null:
		return
	var viewport := get_viewport()
	var mouse_pos: Vector2 = viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()
	var query := PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var results: Array[Dictionary] = get_world_2d().direct_space_state.intersect_point(query)
	var over_nameshow := false
	for r in results:
		if r.collider == name_show:
			over_nameshow = true
			break
	_update_name_label_visibility(over_nameshow)


func _update_prompt_visibility() -> void:
	var show_prompt: bool = _player_in_range != null and not _dialogue_active and not _messages_screen_open
	if prompt_layer != null:
		prompt_layer.visible = show_prompt
	_update_interact_prompt_animation(show_prompt)


## Call when the messages tab is opened or closed so the interact prompt pops out while messages are visible.
func set_messages_screen_open(open: bool) -> void:
	if _messages_screen_open == open:
		return
	_messages_screen_open = open
	_update_prompt_visibility()


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


func _update_name_label_visibility(show_label: bool) -> void:
	if name_label == null:
		return
	if show_label and not _name_label_showing:
		_name_label_showing = true
		name_label.visible = true
		name_label.scale = Vector2.ZERO
		call_deferred("_play_name_label_pop_in")
	elif not show_label and _name_label_showing:
		_name_label_showing = false
		if _name_label_tween != null and _name_label_tween.is_valid():
			_name_label_tween.kill()
		_name_label_tween = create_tween()
		_name_label_tween.set_ease(Tween.EASE_IN)
		_name_label_tween.set_trans(Tween.TRANS_BACK)
		_name_label_tween.tween_property(name_label, "scale", Vector2.ZERO, interact_prompt_pop_duration * 0.8)
		_name_label_tween.tween_callback(func() -> void:
			name_label.visible = false
			name_label.scale = Vector2.ONE
		)


func _play_name_label_pop_in() -> void:
	if name_label == null or not _name_label_showing:
		return
	name_label.pivot_offset = name_label.size / 2.0
	_name_label_tween = create_tween()
	_name_label_tween.set_ease(Tween.EASE_OUT)
	_name_label_tween.set_trans(Tween.TRANS_BACK)
	_name_label_tween.tween_property(name_label, "scale", Vector2.ONE, interact_prompt_pop_duration)


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
	if _player_in_range == null or _dialogue_active:
		return
	if dialogue_resource == null:
		return

	_dialogue_active = true
	_update_prompt_visibility()
	_player_in_range.can_move = false

	_dialogue_ended_connection = _on_dialogue_ended
	if not DialogueManager.dialogue_ended.is_connected(_dialogue_ended_connection):
		DialogueManager.dialogue_ended.connect(_dialogue_ended_connection)

	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_title)


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	DialogueManager.dialogue_ended.disconnect(_dialogue_ended_connection)
	_dialogue_active = false
	_update_prompt_visibility()
	if is_instance_valid(_player_in_range):
		_player_in_range.can_move = true
