extends CanvasLayer

@onready var money_label = $Background/Margin/MainHBox/LeftSection/MoneyLabel
@onready var time_label = $Background/Margin/MainHBox/TimeLabel
@onready var supplies_btn = $Background/Margin/MainHBox/RightSection/SuppliesBtn
@onready var needs_btn = $Background/Margin/MainHBox/RightSection/NeedsBtn
@onready var finance_btn = $TopRightHUD/FinanceBtn
@onready var pause_btn = $TopRightHUD/PauseBtn
@onready var home_btn = $Background/Margin/MainHBox/RightSection/BuildBtn

var pause_menu_scene = preload("res://scenes/ui/PauseMenu.tscn")
var finance_menu_scene = preload("res://scenes/ui/FinanceMenu.tscn")
var supplies_menu_scene = preload("res://scenes/ui/supplies_menu.tscn")
var taxi_menu_scene = preload("res://scenes/ui/taxi_menu.tscn")
var current_pause_menu = null
var supplies_menu_instance = null
var taxi_menu_instance = null
var shop_menu_instance = null

var shop_menu_scene = preload("res://scenes/ui/ShopMenu.tscn")

# Signal for tutorial system
signal supplies_menu_opened

func _ready():
	supplies_btn.pressed.connect(_on_supplies_btn_pressed)
	needs_btn.pressed.connect(_on_needs_btn_pressed)
	finance_btn.pressed.connect(_on_finance_btn_pressed)
	pause_btn.pressed.connect(_on_pause_btn_pressed)
	home_btn.pressed.connect(_on_home_btn_pressed)
	
	# Create supplies menu instance
	supplies_menu_instance = supplies_menu_scene.instantiate()
	add_child(supplies_menu_instance)
	supplies_menu_instance.menu_opened.connect(func(): supplies_menu_opened.emit())
	
	# Create taxi menu instance
	taxi_menu_instance = taxi_menu_scene.instantiate()
	add_child(taxi_menu_instance)
	
	# Create shop menu instance
	shop_menu_instance = shop_menu_scene.instantiate()
	add_child(shop_menu_instance)
	GameState.open_shop_requested.connect(_on_open_shop_requested)
	
	update_ui()

func _process(_delta):
	update_ui()

func update_ui():
	money_label.text = "$ " + str(GameState.money)
	time_label.text = GameState.get_time_string()

# Close all bottom menus so only one can be open at a time
func _close_all_bottom_menus():
	if supplies_menu_instance and supplies_menu_instance.get_menu_visible():
		supplies_menu_instance.hide_menu()
	if taxi_menu_instance and taxi_menu_instance.get_menu_visible():
		taxi_menu_instance.hide_menu()
	# Close needs menu (dog menu) if open
	var dog = get_tree().get_first_node_in_group("dog")
	if dog and dog.has_method("get_menu_visible") and dog.get_menu_visible():
		dog.toggle_menu()

func _on_supplies_btn_pressed():
	if supplies_menu_instance:
		if supplies_menu_instance.get_menu_visible():
			supplies_menu_instance.hide_menu()
		else:
			_close_all_bottom_menus()
			supplies_menu_instance.show_menu()

func _on_needs_btn_pressed():
	var dog = get_tree().get_first_node_in_group("dog")
	if dog and dog.has_method("toggle_menu"):
		var menu_is_visible = dog.has_method("get_menu_visible") and dog.get_menu_visible()
		if menu_is_visible:
			dog.toggle_menu()
		else:
			_close_all_bottom_menus()
			dog.toggle_menu()

func _on_finance_btn_pressed():
	get_tree().paused = true
	var finance_menu = finance_menu_scene.instantiate()
	add_child(finance_menu)
	finance_menu.show_menu()
	
	finance_menu.menu_closed.connect(func():
		finance_menu.queue_free()
		get_tree().paused = false
	)

func _on_pause_btn_pressed():
	if current_pause_menu:
		current_pause_menu.queue_free()
		current_pause_menu = null
		get_tree().paused = false
		return

	get_tree().paused = true
	current_pause_menu = pause_menu_scene.instantiate()
	add_child(current_pause_menu)
	current_pause_menu.visible = true
	
	current_pause_menu.get_node("Panel/VBox/ResumeBtn").pressed.connect(func():
		current_pause_menu.queue_free()
		current_pause_menu = null
		get_tree().paused = false
	)
	
	current_pause_menu.get_node("Panel/VBox/Header/CloseBtn").pressed.connect(func():
		current_pause_menu.queue_free()
		current_pause_menu = null
		get_tree().paused = false
	)
	
	current_pause_menu.get_node("Panel/VBox/QuitBtn").pressed.connect(func():
		get_tree().paused = false
		SceneManager.change_scene("res://scenes/ui/MainMenu.tscn", {"pattern": "curtains"})
	)
	
	current_pause_menu.get_node("Panel/VBox/HelpBtn").pressed.connect(func():
		var help_popup = load("res://scenes/ui/HelpPopup.tscn").instantiate()
		get_tree().root.add_child(help_popup)
	)
	
	current_pause_menu.get_node("Panel/VBox/SettingsBtn").pressed.connect(func():
		var settings_menu = load("res://scenes/ui/SettingsMenu.tscn").instantiate()
		get_tree().root.add_child(settings_menu)
	)

	# Connect to Emergency Fund signal
	if not GameState.emergency_fund_used.is_connected(_on_emergency_fund_used):
		GameState.emergency_fund_used.connect(_on_emergency_fund_used)
		
	# Connect to Budget Warning signal
	if not GameState.budget_warning.is_connected(_on_budget_warning):
		GameState.budget_warning.connect(_on_budget_warning)

func _on_emergency_fund_used(item_name: String):
	show_notification("Emergency Fund used for %s!" % item_name, Color(1, 0.3, 0.3))

func _on_budget_warning(category: String, message: String):
	show_notification("%s: %s" % [category, message], Color(1, 0.5, 0.2))

func show_notification(text: String, color: Color):
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 28)
	
	# Position bottom-left, above HUD
	# Stacking logic could be added, for now simple offset
	label.position = Vector2(40, get_viewport().get_visible_rect().size.y - 200)
	label.modulate.a = 0.0 # Start invisible
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.5)
	tween.tween_interval(3.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

func _on_open_shop_requested():
	if shop_menu_instance:
		shop_menu_instance.show_shop()

func _on_home_btn_pressed():
	if taxi_menu_instance:
		if taxi_menu_instance.get_menu_visible():
			taxi_menu_instance.hide_menu()
		else:
			_close_all_bottom_menus()
			taxi_menu_instance.show_menu()
