extends Control

@onready var label = $VBoxContainer/Label
@onready var continue_button = $VBoxContainer/ContinueButton
@onready var technical_panel = $TechnicalPanel
@onready var slides_container = $VBoxContainer

var slides = [
	"Some dogs don’t start life feeling safe.",
	"This one didn’t either.",
	"You’ve adopted a dog who’s been through more than they can show.",
	"They’re not broken. Just unsure who to trust.",
	"Through daily care, play, and time together, you’ll help them heal.",
	"Welcome to your little buddy."
]

var current_slide = 0
var typing_speed = 0.05
var is_typing = false
var technical_slide_index = 6

func _ready():
	technical_panel.hide()
	continue_button.hide()
	show_slide(0)

func _input(event):
	var is_enter = event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER)
	var is_mouse = event is InputEventMouseButton and event.pressed
	
	if is_enter or is_mouse:
		if current_slide < technical_slide_index:
			if is_typing:
				finish_typing()
			else:
				next_slide()
		elif current_slide == technical_slide_index:
			if is_enter:
				_on_continue_button_pressed()

func show_slide(index):
	if index < slides.size():
		current_slide = index
		label.text = ""
		start_typing(slides[index])
	elif index == technical_slide_index:
		current_slide = index
		slides_container.hide()
		technical_panel.show()
		if continue_button.get_parent() != technical_panel.get_node("VBoxContainer"):
			var parent = continue_button.get_parent()
			parent.remove_child(continue_button)
			technical_panel.get_node("VBoxContainer").add_child(continue_button)
		continue_button.show()

func start_typing(text):
	is_typing = true
	label.text = ""
	for c in text:
		if not is_typing: break
		label.text += c
		await get_tree().create_timer(typing_speed).timeout
	is_typing = false

func finish_typing():
	is_typing = false
	label.text = slides[current_slide]

func next_slide():
	if current_slide < technical_slide_index:
		show_slide(current_slide + 1)

func _on_continue_button_pressed():
	SceneManager.change_scene("res://scenes/CharacterCustomize.tscn", {"pattern": "curtains"})

func _on_toggle_pressed(toggle_index):
	var vbox = technical_panel.get_node("VBoxContainer")
	for i in range(1, 5):
		var content = vbox.get_node("Section" + str(i) + "/Content")
		if i == toggle_index:
			content.visible = !content.visible
		else:
			content.visible = false
