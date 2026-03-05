extends Control

@onready var food_input: LineEdit = $CostColumns/FoodColumn/FoodInput
@onready var water_input: LineEdit = $CostColumns/WaterColumn/WaterInput
@onready var medicine_input: LineEdit = $CostColumns/MedicineColumn/MedicineInput
@onready var vet_input: LineEdit = $CostColumns/VetColumn/VetInput
@onready var dog_house_input: LineEdit = $CostColumns/DogHouseColumn/DogHouseInput
@onready var continue_button: Button = $ButtonContainer/ContinueButton
@onready var back_button: Button = $ButtonContainer/BackButton

func _ready() -> void:
	UITheme.apply_theme(self)
	# Initialize inputs with current GameState values
	food_input.text = str(GameState.food_cost)
	water_input.text = str(GameState.water_cost)
	medicine_input.text = str(GameState.medicine_cost)
	vet_input.text = str(GameState.vet_fee)
	dog_house_input.text = str(GameState.dog_house_cost)
	
	# Connect buttons
	continue_button.pressed.connect(_on_continue_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Focus first input
	food_input.grab_focus()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_continue_pressed()

func _on_continue_pressed() -> void:
	# Validate and update GameState with custom costs
	var food_val := _parse_cost(food_input.text, GameState.food_cost)
	var water_val := _parse_cost(water_input.text, GameState.water_cost)
	var medicine_val := _parse_cost(medicine_input.text, GameState.medicine_cost)
	var vet_val := _parse_cost(vet_input.text, GameState.vet_fee)
	var dog_house_val := _parse_cost(dog_house_input.text, GameState.dog_house_cost)
	
	# Update GameState
	GameState.food_cost = food_val
	GameState.water_cost = water_val
	GameState.medicine_cost = medicine_val
	GameState.vet_fee = vet_val
	GameState.dog_house_cost = dog_house_val
	
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
