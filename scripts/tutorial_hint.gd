extends CanvasLayer

@onready var panel = $Panel
@onready var hint_label = $Panel/MarginContainer/HintLabel
@onready var anim_player = $AnimationPlayer

signal hint_shown
signal hint_hidden

var current_timer: Timer = null

func _ready():
	panel.modulate.a = 0
	anim_player.animation_finished.connect(_on_animation_finished)

func show_hint(text: String, duration: float = 0.0):
	"""Show a hint with optional auto-hide after duration seconds. If duration is 0, waits for manual hide."""
	hint_label.text = text
	anim_player.play("fade_in")
	
	# Clear any existing timer
	if current_timer:
		current_timer.queue_free()
		current_timer = null
	
	# Set up auto-hide timer if duration specified
	if duration > 0:
		current_timer = Timer.new()
		current_timer.process_mode = Node.PROCESS_MODE_ALWAYS
		current_timer.wait_time = duration
		current_timer.one_shot = true
		current_timer.timeout.connect(func():
			hide_hint()
			current_timer.queue_free()
			current_timer = null
		)
		add_child(current_timer)
		current_timer.start()
	
	hint_shown.emit()

func hide_hint():
	"""Fade out the current hint."""
	anim_player.play("fade_out")

func _on_animation_finished(anim_name: String):
	if anim_name == "fade_out":
		hint_hidden.emit()

func is_hint_visible() -> bool:
	return panel.modulate.a > 0.5

