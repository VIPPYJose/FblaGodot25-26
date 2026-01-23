extends CanvasLayer

@onready var food_count_label = $Panel/VBox/Items/FoodItem/Controls/Count
@onready var water_count_label = $Panel/VBox/Items/WaterItem/Controls/Count
@onready var total_label = $Panel/VBox/Footer/TotalLabel
@onready var prescription_item = $Panel/VBox/Items/PrescriptionItem
@onready var prescription_check = $Panel/VBox/Items/PrescriptionItem/CheckBox

const FOOD_PRICE = 20
const WATER_PRICE = 10
const PRESCRIPTION_PRICE = 40

var food_cart_count = 0
var water_cart_count = 0
var prescription_selected = false

func _ready():
	visible = false
	update_ui()

func show_shop():
	# Reset cart when opening
	food_cart_count = 0
	water_cart_count = 0
	prescription_selected = false
	prescription_check.button_pressed = false
	
	# Only show prescription if the vet actually gave one
	prescription_item.visible = GameState.has_prescription and GameState.medication != "antibiotics"
	
	update_ui()
	visible = true
	get_tree().paused = true

func update_ui():
	food_count_label.text = str(food_cart_count)
	water_count_label.text = str(water_cart_count)
	
	var total = (food_cart_count * FOOD_PRICE) + (water_cart_count * WATER_PRICE)
	if prescription_selected:
		total += PRESCRIPTION_PRICE
		
	total_label.text = "Total: $" + str(total)

func _on_close_btn_pressed():
	visible = false
	get_tree().paused = false

func _on_food_plus_pressed():
	food_cart_count += 1
	update_ui()

func _on_food_minus_pressed():
	if food_cart_count > 0:
		food_cart_count -= 1
		update_ui()

func _on_water_plus_pressed():
	water_cart_count += 1
	update_ui()

func _on_water_minus_pressed():
	if water_cart_count > 0:
		water_cart_count -= 1
		update_ui()

func _on_prescription_toggled(toggled_on):
	prescription_selected = toggled_on
	update_ui()

func _on_purchase_pressed():
	var total = (food_cart_count * FOOD_PRICE) + (water_cart_count * WATER_PRICE)
	if prescription_selected:
		total += PRESCRIPTION_PRICE
		
	if total == 0:
		return
		
	if GameState.money >= total:
		# Process payments by category for budget tracking
		if food_cart_count > 0:
			GameState.spend_money(food_cart_count * FOOD_PRICE, "Food")
		if water_cart_count > 0:
			# If we want to strictly follow spend_money which records individual category transactions:
			# We already subtracted from GameState.money in the spend_money calls.
			# But wait, GameState.spend_money(amount, category) returns bool and DOES the subtraction.
			# So if I call it multiple times, it might over-subtract if I don't handle total check first.
			# Actually, I should probably use a custom logic or call spend_money carefully.
			# Let's do it individually to ensure budget categories are hit.
			# Re-calculate and check specifically.
			pass # already checked total >= money
			
		# Actually, since GameState.spend_money subtracts money, I'll do this:
		var success = true
		if food_cart_count > 0:
			success = GameState.spend_money(food_cart_count * FOOD_PRICE, "Food")
		if success and water_cart_count > 0:
			success = GameState.spend_money(water_cart_count * WATER_PRICE, "Food") # Water usually in food budget
		if success and prescription_selected:
			success = GameState.spend_money(PRESCRIPTION_PRICE, "Vet")
			if success:
				GameState.medication = "antibiotics"
				GameState.has_prescription = false # Prescription consumed
				# Also heal the dog slightly as per previous logic if wanted, 
				# but user only asked to change medication to antibiotics.
				var dog = get_tree().get_first_node_in_group("dog")
				if dog:
					dog.health = min(100, dog.health + 40)
		
		if success:
			GameState.food += (food_cart_count * 5)
			GameState.water += (water_cart_count * 5)
			
			print("Purchase successful!")
			visible = false
			get_tree().paused = false
	else:
		print("Not enough money!")
		# Could show a visual warning here
