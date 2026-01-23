extends Node

var character_id: int = 1
var character_variant: String = "male"
var dog_breed: String = "Golden_Retriever"
var pet_name: String = ""
var player_name: String = ""

var money: int = 150
var current_day: int = 0
var days_of_week = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
var day_timer: float = 0.0
var DAY_DURATION: float = 300.0

# Supplies Group (player inventory, NOT pet needs)
var food: int = 0 # Days of food remaining
var water: int = 0 # Days of water remaining
var medication: String = "none" # Current medication status

# Tutorial state
var is_tutorial_complete: bool = false
var is_day_one: bool = true
var tutorial_blocks_movement: bool = false # When true, blocks movement but allows menu inputs

# Signal emitted when a new day starts
signal day_started(day_number: int)

func _process(delta):
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
			money += 150
		
		day_started.emit(current_day)

# Initialize Day 1 supplies
func initialize_day_one():
	food = 0
	water = 0
	medication = "none"
	is_day_one = true
	is_tutorial_complete = false

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
	var week_num: int = int(current_day / 7) + 1
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
	medication = save_data.get("medication", "none")
	is_tutorial_complete = save_data.get("is_tutorial_complete", false)
	is_day_one = save_data.get("is_day_one", true)
	
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
