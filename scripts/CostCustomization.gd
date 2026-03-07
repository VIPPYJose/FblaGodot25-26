# COMMIT: Achievements and Catch Minigame Update
extends Control

@onready var starting_cash_input: LineEdit = $CostColumns/StartingCashColumn/StartingCashInput
@onready var food_input: LineEdit = $CostColumns/FoodColumn/FoodInput
@onready var water_input: LineEdit = $CostColumns/WaterColumn/WaterInput
@onready var medicine_input: LineEdit = $CostColumns/MedicineColumn/MedicineInput
@onready var vet_input: LineEdit = $CostColumns/VetColumn/VetInput
@onready var taxi_input: LineEdit = $CostColumns/TaxiColumn/TaxiInput
@onready var continue_button: Button = $ButtonContainer/ContinueButton
@onready var back_button: Button = $ButtonContainer/BackButton

func _ready() -> void:
	UITheme.apply_theme(self )
	# Initialize inputs with current GameState values
	starting_cash_input.text = str(GameState.starting_money)
	food_input.text = str(GameState.food_cost)
	water_input.text = str(GameState.water_cost)
	medicine_input.text = str(GameState.medicine_cost)
	vet_input.text = str(GameState.vet_fee)
	taxi_input.text = str(GameState.taxi_cost)
	
	# Connect buttons
	continue_button.pressed.connect(_on_continue_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Focus first input
	starting_cash_input.grab_focus()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_continue_pressed()

func _on_continue_pressed() -> void:
	# Validate and update GameState with custom costs
	var starting_cash_val := _parse_cost(starting_cash_input.text, GameState.starting_money)
	var food_val := _parse_cost(food_input.text, GameState.food_cost)
	var water_val := _parse_cost(water_input.text, GameState.water_cost)
	var medicine_val := _parse_cost(medicine_input.text, GameState.medicine_cost)
	var vet_val := _parse_cost(vet_input.text, GameState.vet_fee)
	var taxi_val := _parse_cost(taxi_input.text, GameState.taxi_cost)
	
	# Update GameState
	GameState.starting_money = starting_cash_val
	GameState.food_cost = food_val
	GameState.water_cost = water_val
	GameState.medicine_cost = medicine_val
	GameState.vet_fee = vet_val
	GameState.taxi_cost = taxi_val
	
	# Transition to ConfirmSelection
	SceneManager.change_scene("res://scenes/ui/ConfirmSelection.tscn", {"pattern": "curtains"})

func _on_back_pressed() -> void:
	# Go back to PetName screen
	SceneManager.change_scene("res://scenes/ui/PetName.tscn", {"pattern": "curtains"})

func _parse_cost(text: String, default_value: int) -> int:
	var stripped := text.strip_edges()
	if stripped.is_valid_int():
		var val := int(stripped)
		# Ensure non-negative costs
		return max(0, val)
	return default_value
