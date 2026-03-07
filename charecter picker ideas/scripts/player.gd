# COMMIT: Achievements and Catch Minigame Update
extends CharacterBody2D

## Player character with layered character components. Applies customization from
## CharacterPreferences and handles movement using move_left, move_right, move_up, move_down.

const LAYER_ORDER := ["Body", "Hairstyle", "Eyes", "Outfit", "Accessory"]

@export var move_speed: float = 150.0
## When false, movement input is ignored (e.g. while a UI screen is open).
var can_move: bool = true
## Duration of the pop-in / pop-out animation for the name label when hovering NameShow.
@export var name_label_pop_duration: float = 0.2

## Emitted the first time the player gives movement input (WASD/arrows) while can_move is true.
signal first_move_attempted

@onready var components: Node2D = $Sprite
@onready var name_show: Area2D = $NameShow
@onready var name_label: Label = $NameLabel
var _last_animation: String = "idle_down"
var _was_moving: bool = false
var _name_label_showing: bool = false
var _name_label_tween: Tween
var _first_move_emitted: bool = false


func _ready() -> void:
	_apply_character_components()
	_play_animation("idle_down")
	_update_display_name()


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
		_name_label_tween.tween_property(name_label, "scale", Vector2.ZERO, name_label_pop_duration * 0.8)
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
	_name_label_tween.tween_property(name_label, "scale", Vector2.ONE, name_label_pop_duration)


func _physics_process(_delta: float) -> void:
	var input_dir := Vector2.ZERO
	if can_move:
		input_dir.x = Input.get_axis(&"move_left", &"move_right")
		input_dir.y = Input.get_axis(&"move_up", &"move_down")
		if input_dir != Vector2.ZERO and not _first_move_emitted:
			_first_move_emitted = true
			first_move_attempted.emit()
			input_dir = Vector2.ZERO

	if input_dir != Vector2.ZERO:
		velocity = input_dir.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	_update_animation(input_dir)


func _apply_character_components() -> void:
	var prefs: Node = get_node("/root/CharacterPreferences")
	for category in LAYER_ORDER:
		var sprite: AnimatedSprite2D = components.get_node_or_null(category)
		if sprite:
			var option: int = prefs.get_option(category)
			var path: String = prefs.get_sprite_frames_path(category, option)
			var frames := load(path) as SpriteFrames
			if frames:
				sprite.sprite_frames = frames


func _update_animation(input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO:
		if _was_moving:
			_was_moving = false
			var idle_anim: String = _last_animation.replace("move_", "idle_")
			_last_animation = idle_anim
			_play_animation(idle_anim)
		return

	_was_moving = true
	var anim: String
	if abs(input_dir.y) > abs(input_dir.x):
		anim = "move_down" if input_dir.y > 0 else "move_up"
	else:
		anim = "move_right" if input_dir.x > 0 else "move_left"

	_last_animation = anim
	_play_animation(anim)


func _play_animation(anim_name: String) -> void:
	for category in LAYER_ORDER:
		var sprite: AnimatedSprite2D = components.get_node_or_null(category)
		if sprite and sprite.sprite_frames:
			if sprite.sprite_frames.has_animation(anim_name):
				sprite.animation = anim_name
				sprite.play()
			else:
				sprite.play()


func _update_display_name() -> void:
	var prefs: Node = get_node_or_null("/root/CharacterPreferences")
	if prefs and prefs.player_name != "":
		name_label.text = prefs.player_name
	else:
		name_label.text = "Player"
