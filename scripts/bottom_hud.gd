extends CanvasLayer

@onready var money_label = $Background/Margin/MainHBox/LeftSection/MoneyLabel
@onready var time_label = $Background/Margin/MainHBox/TimeLabel
@onready var needs_btn = $Background/Margin/MainHBox/RightSection/NeedsBtn
@onready var finance_btn = $TopRightHUD/FinanceBtn
@onready var pause_btn = $TopRightHUD/PauseBtn

var pause_menu_scene = preload("res://scenes/PauseMenu.tscn")
var finance_menu_scene = preload("res://scenes/ui/FinanceMenu.tscn")
var current_pause_menu = null

func _ready():
	needs_btn.pressed.connect(_on_needs_btn_pressed)
	finance_btn.pressed.connect(_on_finance_btn_pressed)
	pause_btn.pressed.connect(_on_pause_btn_pressed)
	update_ui()

func _process(_delta):
	update_ui()

func update_ui():
	money_label.text = "$ " + str(GameState.money)
	time_label.text = GameState.get_time_string()

func _on_needs_btn_pressed():
	var dog = get_tree().get_first_node_in_group("dog")
	if dog and dog.has_method("toggle_menu"):
		dog.toggle_menu()

func _on_finance_btn_pressed():
	get_tree().paused = true
	var finance_menu = finance_menu_scene.instantiate()
	add_child(finance_menu)
	finance_menu.get_node("Panel/VBox/Header/CloseBtn").pressed.connect(func():
		finance_menu.queue_free()
		get_tree().paused = false
	)
	finance_menu.get_node("Panel/VBox/Content/BalanceLabel").text = "Current Balance: $" + str(GameState.money)

func _on_pause_btn_pressed():
	if current_pause_menu:
		current_pause_menu.queue_free()
		current_pause_menu = null
		get_tree().paused = false
		return

	get_tree().paused = true
	current_pause_menu = pause_menu_scene.instantiate()
	add_child(current_pause_menu)
	
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
		get_tree().quit()
	)
	
	current_pause_menu.get_node("Panel/VBox/FinancesBtn").pressed.connect(func():
		current_pause_menu.queue_free()
		current_pause_menu = null
		_on_finance_btn_pressed()
	)
	
	current_pause_menu.get_node("Panel/VBox/SettingsBtn").pressed.connect(func():
		print("Settings pressed - Placeholder")
	)
