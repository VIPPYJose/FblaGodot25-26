extends Node

var character_id: int = 1
var character_variant: String = "male"
var dog_breed: String = "Golden_Retriever"
var pet_name: String = ""
var player_name: String = ""

var money: int = 150

# Customizable Costs
var food_cost: int = 20
var water_cost: int = 10
var medicine_cost: int = 40
var vet_fee: int = 50
var dog_house_cost: int = 300
var master_volume: int = 70
var current_day: int = 0
var days_of_week = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
var day_timer: float = 0.0
var DAY_DURATION: float = 300.0

# Supplies Group (player inventory, NOT pet needs)
var food: int = 0 # Days of food remaining
var water: int = 0 # Days of water remaining
var medication: int = 0 # Days of medication remaining (0 = none prescribed)
var dog_health: float = 100.0 # Utility for dialogue/UI
var has_prescription: bool = false # Added to track vet orders

# Tutorial state
var is_tutorial_complete: bool = false
var is_day_one: bool = true
var tutorial_blocks_movement: bool = false # When true, blocks movement but allows menu inputs
var is_dog_sleeping: bool = false # Freeze needs when dog sleeps

# Signal emitted when a new day starts
signal day_started(day_number: int)

# Finance System
var weekly_allowance: int = 150
var savings_balance: int = 200 # Starts at $200
var budget_data: Dictionary = {
	"Food": {"limit": 50, "spent": 0},
	"Vet": {"limit": 50, "spent": 0}
}
var weekly_report: Dictionary = {
	"income": 0,
	"total_spent": 0,
	"category_breakdown": {},
	"emergency_usage": 0
}
var transaction_history: Array = [] # Stores {day, description, amount, category}
var all_time_spent: int = 0

# Signals
signal budget_updated
signal savings_updated
signal emergency_fund_used(item_name: String)
signal history_updated
signal vet_talk_finished
signal open_shop_requested

func _ready():
	apply_volume()

func apply_volume():
	var db = linear_to_db(master_volume / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), master_volume == 0)

func _process(_delta):
	# Day advancement is now handled via advance_day() called from sleep interaction
	pass

func advance_day():
	# Decrement supplies
	food = max(0, food - 1)
	water = max(0, water - 1)
	medication = max(0, medication - 1)
	
	# Increment day
	current_day += 1
	is_day_one = false
	
	# Check for weekly reset
	if current_day % 7 == 0:
		reset_weekly_budgets()
	
	# Wake up dog
	is_dog_sleeping = false
	
	day_started.emit(current_day)

func old_process_disabled(delta):
	if get_tree().paused:
		return
		
	day_timer += delta
	if day_timer >= DAY_DURATION:
		day_timer = 0.0
		current_day += 1
		is_day_one = false
		
		# Consume supplies each day (cap at 0)
		food = max(0, food - 1)
		water = max(0, water - 1)
		
		if current_day % 7 == 0:
			reset_weekly_budgets()
		
		day_started.emit(current_day)

signal budget_warning(category: String, message: String)

func reset_weekly_budgets():
	# Archive current week's report (could store in a history list if needed)
	weekly_report["income"] = weekly_allowance
	weekly_report["total_spent"] = 0
	weekly_report["category_breakdown"] = {}
	weekly_report["emergency_usage"] = 0
	
	# Add allowance
	money += weekly_allowance
	record_transaction("Weekly Allowance", weekly_allowance, "Income")
	
	# Reset spent amounts, keep limits
	for category in budget_data:
		weekly_report["category_breakdown"][category] = budget_data[category]["spent"]
		budget_data[category]["spent"] = 0
		
	budget_updated.emit()
	print("Weekly budgets reset. Income received.")

func record_transaction(description: String, amount: int, category: String):
	var entry = {
		"day": current_day,
		"description": description,
		"amount": amount,
		"category": category
	}
	transaction_history.push_front(entry) # Newest first
	if amount < 0:
		all_time_spent += abs(amount)
	history_updated.emit()

func spend_money(amount: int, category: String) -> bool:
	if money >= amount:
		money -= amount
		record_transaction("Purchase: " + category, -amount, category)
		
		# Update budget if category exists
		if category in budget_data:
			var limit = budget_data[category]["limit"]
			if limit > 0:
				var old_spent = budget_data[category]["spent"]
				var old_pct = float(old_spent) / float(limit) * 100.0
				
				budget_data[category]["spent"] += amount
				
				var new_pct = float(old_spent + amount) / float(limit) * 100.0
				
				if new_pct >= 100 and old_pct < 100:
					budget_warning.emit(category, "Over Budget!")
				elif new_pct >= 90 and old_pct < 90:
					budget_warning.emit(category, "90% Used!")
				
			else:
				budget_data[category]["spent"] += amount
				
			weekly_report["total_spent"] += amount
			budget_updated.emit()
		return true
	
	# Emergency Logic for Essentials
	if category in ["Food", "Vet"]:
		if check_emergency_fund(amount, category):
			return true
			
	return false

func deposit_to_savings(amount: int) -> bool:
	if money >= amount:
		money -= amount
		savings_balance += amount
		record_transaction("Deposit to Savings", -amount, "Transfer")
		savings_updated.emit()
		return true
	return false

func check_emergency_fund(cost: int, item_name: String) -> bool:
	# Auto-pay from savings if affordable
	if savings_balance >= cost:
		savings_balance -= cost
		weekly_report["emergency_usage"] += cost
		record_transaction("Emergency: " + item_name, -cost, "Emergency")
		savings_updated.emit()
		emergency_fund_used.emit(item_name)
		return true
	return false

func get_budget_status(category: String) -> float:
	if category in budget_data and budget_data[category]["limit"] > 0:
		return float(budget_data[category]["spent"]) / float(budget_data[category]["limit"]) * 100.0
	return 0.0

# Initialize Day 1 supplies
func initialize_day_one():
	food = 0
	water = 0
	medication = 0
	is_day_one = true
	is_tutorial_complete = false
	# Reset finances for new game
	money = 150
	savings_balance = 200
	budget_data = {
		"Food": {"limit": 50, "spent": 0},
		"Vet": {"limit": 50, "spent": 0}
	}
	transaction_history = []
	all_time_spent = 0

func save_character(id: int, variant: String):
	character_id = id
	character_variant = variant

func save_pet(breed: String):
	dog_breed = breed

func save_pet_name(p_name: String):
	pet_name = p_name

func save_player_name(p_name: String):
	player_name = p_name

func get_time_string() -> String:
	var day_name = days_of_week[current_day % 7]
	var week_num: int = int(float(current_day) / 7.0) + 1
	return "%s Week %d" % [day_name, week_num]

const SAVE_PATH = "user://save_game.dat"

func save_game(dog_data: Dictionary = {}):
	var save_data = {
		"character_id": character_id,
		"character_variant": character_variant,
		"dog_breed": dog_breed,
		"pet_name": pet_name,
		"player_name": player_name,
		"money": money,
		"current_day": current_day,
		"day_timer": day_timer,
		"food": food,
		"water": water,
		"medication": medication,
		"is_tutorial_complete": is_tutorial_complete,
		"is_day_one": is_day_one,
		"master_volume": master_volume,
		# Customizable Costs
		"food_cost": food_cost,
		"water_cost": water_cost,
		"medicine_cost": medicine_cost,
		"vet_fee": vet_fee,
		"dog_house_cost": dog_house_cost,
		# Finance Data
		"savings_balance": savings_balance,
		"budget_data": budget_data,
		"weekly_report": weekly_report,
		"transaction_history": transaction_history,
		"all_time_spent": all_time_spent,
		# Dog needs (passed from dog instance)
		"dog_hunger": dog_data.get("hunger", 100.0),
		"dog_thirst": dog_data.get("thirst", 100.0),
		"dog_energy": dog_data.get("energy", 100.0),
		"dog_hygiene": dog_data.get("hygiene", 100.0),
		"dog_health": dog_data.get("health", 30.0)
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("Game saved successfully!")

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	
	var save_data = file.get_var()
	file.close()
	
	if save_data == null:
		return false
	
	# Restore GameState variables
	character_id = save_data.get("character_id", 1)
	character_variant = save_data.get("character_variant", "male")
	dog_breed = save_data.get("dog_breed", "Golden_Retriever")
	pet_name = save_data.get("pet_name", "")
	player_name = save_data.get("player_name", "")
	money = save_data.get("money", 150)
	current_day = save_data.get("current_day", 0)
	day_timer = save_data.get("day_timer", 0.0)
	food = save_data.get("food", 0)
	water = save_data.get("water", 0)
	# Handle both old string format and new int format for backward compatibility
	var med_data = save_data.get("medication", 0)
	if med_data is String:
		medication = 0  # Old save file with string, reset to 0
	else:
		medication = med_data
	is_tutorial_complete = save_data.get("is_tutorial_complete", false)
	is_day_one = save_data.get("is_day_one", true)
	master_volume = save_data.get("master_volume", 70)
	
	# Restore Customizable Costs
	food_cost = save_data.get("food_cost", 20)
	water_cost = save_data.get("water_cost", 10)
	medicine_cost = save_data.get("medicine_cost", 40)
	vet_fee = save_data.get("vet_fee", 50)
	dog_house_cost = save_data.get("dog_house_cost", 300)
	
	# Restore Finance Data
	savings_balance = save_data.get("savings_balance", 200)
	budget_data = save_data.get("budget_data", {
		"Food": {"limit": 50, "spent": 0},
		"Vet": {"limit": 50, "spent": 0}
	})
	weekly_report = save_data.get("weekly_report", {
		"income": 0,
		"total_spent": 0,
		"category_breakdown": {},
		"emergency_usage": 0
	})
	transaction_history = save_data.get("transaction_history", [])
	all_time_spent = save_data.get("all_time_spent", 0)
	
	print("Game loaded successfully!")
	return true

func get_saved_dog_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return {}
	
	var save_data = file.get_var()
	file.close()
	
	if save_data == null:
		return {}
	
	return {
		"hunger": save_data.get("dog_hunger", 100.0),
		"thirst": save_data.get("dog_thirst", 100.0),
		"energy": save_data.get("dog_energy", 100.0),
		"hygiene": save_data.get("dog_hygiene", 100.0),
		"health": save_data.get("dog_health", 30.0)
	}

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
