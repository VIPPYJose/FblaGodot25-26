extends CanvasLayer

@onready var resume_btn = $Panel/VBox/ResumeBtn
@onready var quit_btn = $Panel/VBox/QuitBtn
@onready var close_btn = $Panel/VBox/Header/CloseBtn

func _ready():
	visible = false
	resume_btn.pressed.connect(_on_resume_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	close_btn.pressed.connect(_on_resume_pressed)

func _input(event):
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	var new_pause_state = !get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state
	
	if visible:
		resume_btn.grab_focus()

func _on_resume_pressed():
	get_tree().paused = false
	visible = false

func _on_quit_pressed():
	get_tree().paused = false
	SceneManager.change_scene("res://scenes/ui/MainMenu.tscn", {"pattern": "curtains"})
