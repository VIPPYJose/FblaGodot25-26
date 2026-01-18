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

func _process(delta):
	if get_tree().paused:
		return
		
	day_timer += delta
	if day_timer >= DAY_DURATION:
		day_timer = 0.0
		current_day += 1
		if current_day % 7 == 0:
			money += 150

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
	var week_num = (current_day / 7) + 1
	return "%s Week %d" % [day_name, week_num]
