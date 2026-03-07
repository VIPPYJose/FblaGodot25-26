# COMMIT: Achievements and Catch Minigame Update
extends TextureButton

## Button with two visual states: none (no unread messages) and check (has unread messages).
## State is controlled externally (e.g. by world from message screen read_state_changed).
## Pushes down visually when pressed.

const PRESS_OFFSET_PX: int = 4

enum MsgState { NO_MSGS, MSGS }

var _state: MsgState = MsgState.NO_MSGS

@export_enum("No msgs", "Msgs") var state: int = 0:
	set(value):
		_state = value as MsgState
		_update_texture()
	get:
		return _state

@onready var texture_none: Texture2D = load("res://assets/sprites/msgs/none.png") as Texture2D
@onready var texture_check: Texture2D = load("res://assets/sprites/msgs/check.png") as Texture2D


func _ready() -> void:
	_update_texture()
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)


func _on_button_down() -> void:
	offset_top += PRESS_OFFSET_PX
	offset_bottom += PRESS_OFFSET_PX


func _on_button_up() -> void:
	offset_top -= PRESS_OFFSET_PX
	offset_bottom -= PRESS_OFFSET_PX


func _update_texture() -> void:
	if texture_none and texture_check:
		texture_normal = texture_check if state == MsgState.MSGS else texture_none
