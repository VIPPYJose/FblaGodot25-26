# COMMIT: Achievements and Catch Minigame Update
extends CanvasLayer

@onready var panel = $PanelContainer
@onready var food_label = $PanelContainer/VBoxContainer/ContentContainer/FoodLabel
@onready var water_label = $PanelContainer/VBoxContainer/ContentContainer/WaterLabel
@onready var medication_label = $PanelContainer/VBoxContainer/ContentContainer/MedicationLabel

# Signal emitted when menu is opened (for tutorial)
signal menu_opened

func _ready():
	UITheme.apply_overlay_theme(self)
	panel.hide()
	$PanelContainer/VBoxContainer/TitleHBox/CloseButton.pressed.connect(func():
		panel.hide()
	)

func show_menu():
	panel.show()
	update_ui()
	menu_opened.emit()

func hide_menu():
	panel.hide()

func toggle_menu():
	if panel.visible:
		hide_menu()
	else:
		show_menu()

func _process(_delta):
	if panel.visible:
		update_ui()
	
	if Input.is_action_just_pressed("ui_cancel") and panel.visible:
		hide_menu()

func update_ui():
	# Display supplies from GameState
	if GameState.food == 0:
		food_label.text = "Food: 0 days left"
	elif GameState.food == 1:
		food_label.text = "Food: 1 day left"
	else:
		food_label.text = "Food: %d days left" % GameState.food
	
	if GameState.water == 0:
		water_label.text = "Water: 0 days left"
	elif GameState.water == 1:
		water_label.text = "Water: 1 day left"
	else:
		water_label.text = "Water: %d days left" % GameState.water
	
	if GameState.medication == "none":
		medication_label.text = "Medication: none prescribed"
	else:
		medication_label.text = "Medication: %s" % GameState.medication

func get_menu_visible() -> bool:
	return panel.visible
