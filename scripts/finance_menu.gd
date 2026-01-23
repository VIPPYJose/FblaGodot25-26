extends CanvasLayer

signal menu_closed

# UI References
@onready var overview_tab = $Panel/VBox/Content/TabContainer/Overview
@onready var budget_tab = $Panel/VBox/Content/TabContainer/BudgetPlanner
@onready var report_tab = $Panel/VBox/Content/TabContainer/WeeklyReport

# Overview Elements
@onready var spendable_label = $Panel/VBox/Content/TabContainer/Overview/SpendableLabel
@onready var savings_label = $Panel/VBox/Content/TabContainer/Overview/SavingsLabel
@onready var deposit_input = $Panel/VBox/Content/TabContainer/Overview/DepositInput
@onready var food_progress = $Panel/VBox/Content/TabContainer/Overview/FoodProgress
@onready var vet_progress = $Panel/VBox/Content/TabContainer/Overview/VetProgress

# Budget Elements
@onready var food_slider = $Panel/VBox/Content/TabContainer/BudgetPlanner/FoodSlider
@onready var vet_slider = $Panel/VBox/Content/TabContainer/BudgetPlanner/VetSlider
@onready var food_limit_label = $Panel/VBox/Content/TabContainer/BudgetPlanner/FoodLimitLabel
@onready var vet_limit_label = $Panel/VBox/Content/TabContainer/BudgetPlanner/VetLimitLabel

# History Elements
@onready var history_cash_label = $Panel/VBox/Content/TabContainer/AllTimeHistory/CashHeader
@onready var history_spent_label = $Panel/VBox/Content/TabContainer/AllTimeHistory/SpentTotalLabel
@onready var history_list = $Panel/VBox/Content/TabContainer/AllTimeHistory/ScrollContainer/HistoryList

# Report Elements
@onready var report_text = $Panel/VBox/Content/TabContainer/WeeklyReport/ReportLabel

func _ready():
	# Connect to GameState signals
	GameState.budget_updated.connect(update_ui)
	GameState.savings_updated.connect(update_ui)
	GameState.history_updated.connect(update_history)
	
	update_ui()

func show_menu():
	visible = true
	update_ui()
	update_history() # Ensure history is fresh

func hide_menu():
	visible = false
	menu_closed.emit()

func update_ui():
	update_overview()
	update_budget_inputs()
	update_report()
	update_history_header()

func update_overview():
	spendable_label.text = "Spending Money: $%d" % GameState.money
	savings_label.text = "Emergency Savings: $%d" % GameState.savings_balance
	
	# Update Progress Bars
	var food_pct = GameState.get_budget_status("Food")
	var vet_pct = GameState.get_budget_status("Vet")
	
	food_progress.value = food_pct
	vet_progress.value = vet_pct
	
	update_progress_color(food_progress, food_pct)
	update_progress_color(vet_progress, vet_pct)

func update_progress_color(bar: ProgressBar, percent: float):
	var style = StyleBoxFlat.new()
	if percent >= 100:
		style.bg_color = Color.RED
	elif percent >= 90:
		style.bg_color = Color.ORANGE_RED
	elif percent >= 75:
		style.bg_color = Color.YELLOW
	else:
		style.bg_color = Color.GREEN
	
	bar.add_theme_stylebox_override("fill", style)

func update_budget_inputs():
	# Sync sliders with current limits if not interacting
	if not food_slider.has_focus():
		food_slider.value = GameState.budget_data["Food"]["limit"]
		food_limit_label.text = "$%d" % food_slider.value
		
	if not vet_slider.has_focus():
		vet_slider.value = GameState.budget_data["Vet"]["limit"]
		vet_limit_label.text = "$%d" % vet_slider.value

func update_report():
	var r = GameState.weekly_report
	var text = "Weekly Financial Report (Week %d)\n\n" % (int(float(GameState.current_day) / 7.0) + 1)
	text += "Income Received: +$%d\n" % r["income"]
	text += "Total Spending: -$%d\n" % r["total_spent"]
	text += "----------------\n"
	text += "Category Breakdown:\n"
	for cat in r["category_breakdown"]:
		text += "  %s: $%d\n" % [cat, r["category_breakdown"][cat]]
	text += "----------------\n"
	text += "Emergency Fund Used: $%d" % r["emergency_usage"]
	
	report_text.text = text

func update_history_header():
	history_cash_label.text = "Spending Cash: $%d" % GameState.money
	history_spent_label.text = "All-Time Total Spent: $%d" % GameState.all_time_spent

func update_history():
	# Clear existing items
	for child in history_list.get_children():
		child.queue_free()
	
	# Populate from GameState
	for entry in GameState.transaction_history:
		var h_box = HBoxContainer.new()
		
		var day_label = Label.new()
		day_label.text = "[Day %d]" % entry["day"]
		day_label.custom_minimum_size.x = 80
		h_box.add_child(day_label)
		
		var desc_label = Label.new()
		desc_label.text = entry["description"]
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h_box.add_child(desc_label)
		
		var amount_label = Label.new()
		var prefix = "+" if entry["amount"] >= 0 else ""
		amount_label.text = "%s$%d" % [prefix, entry["amount"]]
		amount_label.add_theme_color_override("font_color", Color.GREEN if entry["amount"] >= 0 else Color.RED)
		h_box.add_child(amount_label)
		
		history_list.add_child(h_box)

# Signal Handlers

func _on_close_btn_pressed():
	hide_menu()

func _on_deposit_btn_pressed():
	var amount = int(deposit_input.text)
	if amount > 0:
		if GameState.deposit_to_savings(amount):
			deposit_input.text = ""
		else:
			# Could show error animation
			pass

func _on_food_slider_value_changed(value):
	GameState.budget_data["Food"]["limit"] = int(value)
	food_limit_label.text = "$%d" % value
	update_overview() # Refresh progress bars immediately

func _on_vet_slider_value_changed(value):
	GameState.budget_data["Vet"]["limit"] = int(value)
	vet_limit_label.text = "$%d" % value
	update_overview()
