# COMMIT: Achievements and Catch Minigame Update
extends Control

## Email-style message screen: left pane = list of messages (new at bottom), right pane = detail view.
## Call add_message(sender, subject, body) to add a message; it appears at the bottom of the list.
## Emits closed when the user closes the screen.
## Emits read_state_changed(has_unread) when any message's read state changes.

signal closed
signal read_state_changed(has_unread: bool)

var _messages: Array[Dictionary] = []

@onready var message_list: ItemList = $HSplitContainer/MessageListPanel/LeftMargin/LeftVBox/MessageList
@onready var detail_subject: Label = $HSplitContainer/DetailPanel/DetailMargin/DetailVBox/DetailSubject
@onready var detail_sender: Label = $HSplitContainer/DetailPanel/DetailMargin/DetailVBox/DetailSender
@onready var detail_body: RichTextLabel = $HSplitContainer/DetailPanel/DetailMargin/DetailVBox/BodyScroll/DetailBody
@onready var close_button: Button = $CloseButton
@onready var prev_button: Button = $HSplitContainer/MessageListPanel/LeftMargin/LeftVBox/NavButtons/PrevButton
@onready var next_button: Button = $HSplitContainer/MessageListPanel/LeftMargin/LeftVBox/NavButtons/NextButton


func _ready() -> void:
	message_list.item_selected.connect(_on_message_selected)
	close_button.pressed.connect(_on_close_pressed)
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	_show_empty_detail()
	_update_nav_buttons()


func _on_close_pressed() -> void:
	visible = false
	closed.emit()


func _on_message_selected(index: int) -> void:
	if index < 0 or index >= _messages.size():
		return
	var msg: Dictionary = _messages[index]
	msg["read"] = true
	_set_item_tooltip(index)
	detail_subject.text = msg.get("subject", "")
	detail_sender.text = msg.get("sender", "")
	detail_body.text = msg.get("body", "")
	_update_nav_buttons()
	_emit_read_state()


func _update_nav_buttons() -> void:
	var count: int = _messages.size()
	var sel_items: PackedInt32Array = message_list.get_selected_items()
	var current: int = sel_items[0] if sel_items.size() > 0 else -1
	prev_button.disabled = count == 0 or current <= 0
	next_button.disabled = count == 0 or current < 0 or current >= count - 1


func _on_prev_pressed() -> void:
	var sel: PackedInt32Array = message_list.get_selected_items()
	if sel.size() == 0:
		return
	var i: int = sel[0]
	if i > 0:
		select_index(i - 1)


func _on_next_pressed() -> void:
	var sel: PackedInt32Array = message_list.get_selected_items()
	if sel.size() == 0:
		return
	var i: int = sel[0]
	if i < _messages.size() - 1:
		select_index(i + 1)


func _show_empty_detail() -> void:
	detail_subject.text = ""
	detail_sender.text = ""
	detail_body.text = "Select a message"


## Add a message; it appears at the bottom of the list. Optionally select it.
func add_message(sender: String, subject: String, body: String, select: bool = true) -> void:
	var msg: Dictionary = {
		"sender": sender,
		"subject": subject,
		"body": body,
		"read": false
	}
	_messages.append(msg)
	var index: int = _messages.size() - 1
	# List display: show subject (or short sender + subject)
	var list_text: String = subject if subject.length() > 0 else "(No subject)"
	if sender.length() > 0:
		list_text = sender + " — " + list_text
	message_list.add_item(list_text, null)
	_set_item_tooltip(index)
	if select:
		message_list.select(index)
		message_list.ensure_current_is_visible()
		_on_message_selected(index)
	else:
		_emit_read_state()


func _set_item_tooltip(index: int) -> void:
	if index < 0 or index >= _messages.size():
		return
	var read: bool = _messages[index].get("read", false)
	message_list.set_item_tooltip(index, "Read" if read else "Unread")


func clear_messages() -> void:
	_messages.clear()
	message_list.clear()
	_show_empty_detail()
	_emit_read_state()


func _has_unread() -> bool:
	for msg in _messages:
		if not msg.get("read", false):
			return true
	return false


func _emit_read_state() -> void:
	read_state_changed.emit(_has_unread())


## Select a message by index and show it in the detail pane.
func select_index(index: int) -> void:
	if index >= 0 and index < _messages.size():
		message_list.select(index)
		message_list.ensure_current_is_visible()
		_on_message_selected(index)
