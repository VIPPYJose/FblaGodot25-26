# COMMIT: Achievements and Catch Minigame Update
extends CanvasLayer

@onready var panel = $PanelContainer

signal menu_opened
signal menu_closed

# Destination coordinates
const DESTINATIONS := {
	"Home": Vector2(750, 380),
	"Store": Vector2(1025, 2185),
	"Vet": Vector2(1400, 1805),
	"Park": Vector2(1200, 600),
}

func _ready():
	UITheme.apply_overlay_theme(self )
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
	if not GameState.spend_money(GameState.taxi_cost, "Travel"):
		# Not enough money - could show a notification
		return
	hide_menu()
	
	var player = get_tree().get_first_node_in_group("player")
	var dog = get_tree().get_first_node_in_group("dog")
	
	var taxi_scene = load("res://taxi.tscn")
	var taxi_instance = null
	if taxi_scene:
		taxi_instance = taxi_scene.instantiate()
		get_tree().current_scene.add_child(taxi_instance)
		if player:
			taxi_instance.global_position = player.global_position + Vector2(0, 20)
	
	if player:
		player.hide()
	if dog:
		dog.hide()
	
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.autostart = true
	get_tree().current_scene.add_child(timer)
	timer.timeout.connect(func():
		if is_instance_valid(taxi_instance):
			taxi_instance.global_position.x += 40
	)
	
	SceneManager.fade_in_place({
		"pattern": "curtains",
		"on_fade_out": func():
			if is_instance_valid(timer):
				timer.queue_free()
			if is_instance_valid(taxi_instance):
				taxi_instance.queue_free()
			if player:
				player.show()
				player.global_position = pos
			if dog:
				dog.show()
				dog.global_position = pos + Vector2(50, 0)
	})
