extends CanvasLayer

@onready var panel = $PanelContainer

signal menu_opened
signal menu_closed

# Taxi fare cost
const TAXI_COST := 10

# Destination coordinates
const DESTINATIONS := {
	"Home": Vector2(750, 380),
	"Store": Vector2(1025, 2185),
	"Vet": Vector2(1400, 1805),
	"Park": Vector2(1200, 600),
}

func _ready():
	panel.hide()
	$PanelContainer/VBoxContainer/TitleHBox/CloseButton.pressed.connect(func():
		hide_menu()
	)
	$PanelContainer/VBoxContainer/HomeRow/HomeBtn.pressed.connect(func(): _travel_to("Home"))
	$PanelContainer/VBoxContainer/StoreRow/StoreBtn.pressed.connect(func(): _travel_to("Store"))
	$PanelContainer/VBoxContainer/VetRow/VetBtn.pressed.connect(func(): _travel_to("Vet"))
	$PanelContainer/VBoxContainer/ParkRow/ParkBtn.pressed.connect(func(): _travel_to("Park"))

func show_menu():
	panel.show()
	menu_opened.emit()

func hide_menu():
	panel.hide()
	menu_closed.emit()

func toggle_menu():
	if panel.visible:
		hide_menu()
	else:
		show_menu()

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel") and panel.visible:
		hide_menu()

func get_menu_visible() -> bool:
	return panel.visible

func _travel_to(destination: String):
	var pos = DESTINATIONS[destination]
	if not GameState.spend_money(TAXI_COST, "Travel"):
		# Not enough money - could show a notification
		return
	hide_menu()
	SceneManager.fade_in_place({
		"pattern": "curtains",
		"on_fade_out": func():
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.global_position = pos
			var dog = get_tree().get_first_node_in_group("dog")
			if dog:
				dog.global_position = pos + Vector2(50, 0)
	})
