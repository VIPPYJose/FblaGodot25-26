extends CanvasLayer

@onready var panel = $PanelContainer
@onready var hunger_bar = $PanelContainer/VBoxContainer/GridContainer/Hunger/HBox/ProgressBar
@onready var hunger_val = $PanelContainer/VBoxContainer/GridContainer/Hunger/HBox/Value
@onready var thirst_bar = $PanelContainer/VBoxContainer/GridContainer/Thirst/HBox/ProgressBar
@onready var thirst_val = $PanelContainer/VBoxContainer/GridContainer/Thirst/HBox/Value
@onready var energy_bar = $PanelContainer/VBoxContainer/GridContainer/Energy/HBox/ProgressBar
@onready var energy_val = $PanelContainer/VBoxContainer/GridContainer/Energy/HBox/Value
@onready var hygiene_bar = $PanelContainer/VBoxContainer/GridContainer/Hygiene/HBox/ProgressBar
@onready var hygiene_val = $PanelContainer/VBoxContainer/GridContainer/Hygiene/HBox/Value
@onready var arrow = $Download7_44_10Pm

var target_dog: Node2D

func _ready():
	panel.hide()
	arrow.hide()
	$PanelContainer/VBoxContainer/TitleHBox/CloseButton.pressed.connect(func(): 
		panel.hide()
		arrow.hide()
	)

func show_menu(dog: Node2D):
	target_dog = dog
	panel.show()
	arrow.show()
	update_ui()

func _process(_delta):
	if panel.visible and target_dog:
		update_ui()
	
	if Input.is_action_just_pressed("ui_cancel") or (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_mouse_over_panel()):
		panel.hide()
		arrow.hide()

func update_ui():
	if not target_dog: return
	
	hunger_bar.value = target_dog.hunger
	hunger_val.text = str(round(target_dog.hunger))
	
	thirst_bar.value = target_dog.thirst
	thirst_val.text = str(round(target_dog.thirst))
	
	energy_bar.value = target_dog.energy
	energy_val.text = str(round(target_dog.energy))
	
	hygiene_bar.value = target_dog.hygiene
	hygiene_val.text = str(round(target_dog.hygiene))

func is_mouse_over_panel() -> bool:
	return panel.get_global_rect().has_point(panel.get_global_mouse_position())
