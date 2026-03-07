# COMMIT: Achievements and Catch Minigame Update
extends CanvasLayer

@onready var panel = $PanelContainer
@onready var hunger_bar = $PanelContainer/VBoxContainer/GridContainer/Hunger/HBox/ProgressBar
@onready var hunger_val = $PanelContainer/VBoxContainer/GridContainer/Hunger/HBox/Value
@onready var thirst_bar = $PanelContainer/VBoxContainer/GridContainer/Thirst/HBox/ProgressBar
@onready var thirst_val = $PanelContainer/VBoxContainer/GridContainer/Thirst/HBox/Value
@onready var energy_bar = $PanelContainer/VBoxContainer/GridContainer/Energy/HBox/ProgressBar
@onready var energy_val = $PanelContainer/VBoxContainer/GridContainer/Energy/HBox/Value
@onready var health_bar = $PanelContainer/VBoxContainer/GridContainer/Health/HBox/ProgressBar
@onready var health_val = $PanelContainer/VBoxContainer/GridContainer/Health/HBox/Value
# @onready var arrow = $Download7_44_10Pm # This node does not exist in the scene

var target_dog: Node2D

func _ready():
	UITheme.apply_overlay_theme(self )
	panel.hide()
	# arrow.hide()
	$PanelContainer/VBoxContainer/TitleHBox/CloseButton.pressed.connect(func():
		panel.hide()
		# arrow.hide()
	)

func show_menu(dog: Node2D):
	target_dog = dog
	panel.show()
	# arrow.show()
	update_ui()

func _process(_delta):
	if panel.visible and target_dog:
		update_ui()
	
	if Input.is_action_just_pressed("ui_cancel") or (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_mouse_over_panel()):
		panel.hide()
		# arrow.hide()

func update_ui():
	if not target_dog: return
	#updates the ui with the current values of the dog from dog.gd
	hunger_bar.value = target_dog.hunger
	hunger_val.text = str(round(target_dog.hunger))
	
	thirst_bar.value = target_dog.thirst
	thirst_val.text = str(round(target_dog.thirst))
	
	energy_bar.value = target_dog.energy
	energy_val.text = str(round(target_dog.energy))
	
	health_bar.value = target_dog.health
	health_val.text = str(round(target_dog.health))

func is_mouse_over_panel() -> bool:
	return panel.get_global_rect().has_point(panel.get_global_mouse_position())
