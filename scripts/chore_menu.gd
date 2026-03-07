# COMMIT: Achievements and Catch Minigame Update
extends CanvasLayer

@onready var question_label = $Panel/VBoxContainer/QuestionLabel
@onready var answer_input = $Panel/VBoxContainer/AnswerInput
@onready var result_label = $Panel/VBoxContainer/ResultLabel

var num1: int
var num2: int
var answer: int

func _ready():
	UITheme.apply_overlay_theme(self)
	$Panel/VBoxContainer/SubmitButton.pressed.connect(_on_submit)
	$Panel/VBoxContainer/CloseButton.pressed.connect(queue_free)
	get_tree().paused = true
	generate_question()

func _exit_tree():
	get_tree().paused = false

func generate_question():
	num1 = randi() % 12 + 1
	num2 = randi() % 12 + 1
	answer = num1 * num2
	question_label.text = "Solve: " + str(num1) + " x " + str(num2) + " ="
	answer_input.text = ""
	answer_input.grab_focus()

func _on_submit():
	var user_answer = answer_input.text.to_int()
	if user_answer == answer:
		var reward = int(15 * GameState.inflation_rate)
		GameState.money += reward
		result_label.text = "Correct! You earned $" + str(reward) + "!"
		result_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
		GameState.event_triggered.emit("Completed chores, earned $" + str(reward))
		generate_question()
	else:
		result_label.text = "Wrong! Try again."
		result_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
