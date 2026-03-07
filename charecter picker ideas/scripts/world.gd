# COMMIT: Achievements and Catch Minigame Update
extends Node2D

## World scene: wires msg button to message screen and adds spawn messages from the plan.

const MC_DIALOGUE_PATH: String = "res://dialogue/introduction/characters/MC.dialogue"

@onready var msg_button: TextureButton = $UICanvas/MsgIconButton
@onready var message_screen: Control = $UICanvas/MessageScreen
@onready var player: CharacterBody2D = $player

var _mc_dialogue_ended_callback: Callable


func _ready() -> void:
	message_screen.visible = false
	message_screen.closed.connect(_on_message_screen_closed)
	message_screen.read_state_changed.connect(_on_read_state_changed)
	msg_button.pressed.connect(_on_msg_button_pressed)
	_add_spawn_messages()
	player.first_move_attempted.connect(_on_first_move_attempted)


func _on_first_move_attempted() -> void:
	player.first_move_attempted.disconnect(_on_first_move_attempted)
	_play_mc_spawn_dialogue()


func _play_mc_spawn_dialogue() -> void:
	var dialogue_resource: DialogueResource = load(MC_DIALOGUE_PATH) as DialogueResource
	if dialogue_resource == null:
		return
	player.can_move = false
	_mc_dialogue_ended_callback = _on_mc_dialogue_ended
	if not DialogueManager.dialogue_ended.is_connected(_mc_dialogue_ended_callback):
		DialogueManager.dialogue_ended.connect(_mc_dialogue_ended_callback)
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")


func _on_mc_dialogue_ended(_resource: DialogueResource) -> void:
	DialogueManager.dialogue_ended.disconnect(_mc_dialogue_ended_callback)
	player.can_move = true


func _on_msg_button_pressed() -> void:
	if message_screen.visible:
		message_screen.visible = false
		player.can_move = true
		_notify_npcs_messages_screen_open(false)
	else:
		message_screen.visible = true
		player.can_move = false
		_notify_npcs_messages_screen_open(true)


func _on_message_screen_closed() -> void:
	message_screen.visible = false
	player.can_move = true
	_notify_npcs_messages_screen_open(false)


func _notify_npcs_messages_screen_open(open: bool) -> void:
	for node in get_tree().get_nodes_in_group("interact_prompt_npc"):
		if node.has_method("set_messages_screen_open"):
			node.set_messages_screen_open(open)


func _on_read_state_changed(has_unread: bool) -> void:
	# Msg button shows "Msgs" when there are unread, "No msgs" when all read or no messages.
	msg_button.set("state", 1 if has_unread else 0)


func _add_spawn_messages() -> void:
	# From plan: context, movement, interaction, and where to check messages.
	message_screen.clear_messages()
	message_screen.add_message(
		"Maplewood",
		"Welcome to the neighborhood",
		"Strange things have been happening around here — lost pets, weird noises, missing items. You're here to investigate and help figure out what's going on!",
		false
	)
	message_screen.add_message(
		"Maplewood",
		"Getting around",
		"Use [b]WASD[/b] or the [b]Arrow keys[/b] to move. Explore the streets, park, and school to find clues and talk to people.",
		false
	)
	message_screen.add_message(
		"Maplewood",
		"Talking and using things",
		"Talk to NPCs and use objects with the [b]E[/b] key (or click). There's no combat — just puzzles, clues, and dialogue to move the story forward.",
		false
	)
	message_screen.add_message(
		"Maplewood",
		"Your messages",
		"Tap the message icon in the top-right anytime to open this screen. New messages will appear here so you don't miss important updates. Good luck, detective!",
		false
	)
	# Select first message so it shows in the detail pane; only this one is marked read.
	message_screen.select_index(0)
