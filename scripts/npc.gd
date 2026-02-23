extends CharacterBody2D

@export var dialogue_resource: DialogueResource
@export var dialugue_start: String = "start"

var finished: bool = false
var player_can_move: bool = true
var player_in_range: bool = false

@onready var label = get_node_or_null("CanvasLayer/Label")

func _ready():
	if label:
		label.hide()

func _process(_delta):
	if player_in_range and (Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("controller_interact")):
		DialogueManager.show_example_dialogue_balloon(dialogue_resource, dialugue_start)

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		if label:
			label.show()

func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		if label:
			label.hide()
