extends Node
class_name LLMAssistant

signal response_received(text: String)
signal request_started()
signal request_failed(error: String)

const OLLAMA_URL = "http://localhost:11434/api/generate"
const MODEL_NAME = "llama3.2:3b"

var http_request: HTTPRequest
var system_prompt: String = ""

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	load_game_knowledge()

func load_game_knowledge():
	var file = FileAccess.open("res://game_knowledge.txt", FileAccess.READ)
	if file:
		system_prompt = file.get_as_text()
		file.close()
	else:
		system_prompt = "You are a game assistant. Only answer questions about this pet care game."
		push_warning("game_knowledge.txt not found, using default prompt")

func get_current_game_state() -> String:
	"""Gathers current game state from GameState singleton and formats it for the LLM"""
	if not has_node("/root/GameState"):
		return ""
	
	var gs = get_node("/root/GameState")
	var state_text = "\n=== CURRENT GAME STATE ===\n"
	
	# Finance info
	state_text += "Current Money: $" + str(gs.money) + "\n"
	state_text += "Emergency Savings: $" + str(gs.savings_balance) + "\n"
	state_text += "Current Day: " + str(gs.current_day) + " (" + gs.get_time_string() + ")\n"
	
	# Budget spending
	if gs.budget_data.has("Food"):
		state_text += "Food Budget - Spent: $" + str(gs.budget_data["Food"]["spent"]) + " / Limit: $" + str(gs.budget_data["Food"]["limit"]) + "\n"
	if gs.budget_data.has("Vet"):
		state_text += "Vet Budget - Spent: $" + str(gs.budget_data["Vet"]["spent"]) + " / Limit: $" + str(gs.budget_data["Vet"]["limit"]) + "\n"
	
	# Weekly report
	if gs.weekly_report.has("total_spent"):
		state_text += "This Week Total Spent: $" + str(gs.weekly_report["total_spent"]) + "\n"
	
	# All-time spending
	state_text += "All-Time Total Spent: $" + str(gs.all_time_spent) + "\n"
	
	# Supplies
	state_text += "Food Supply: " + str(gs.food) + " days remaining\n"
	state_text += "Water Supply: " + str(gs.water) + " days remaining\n"
	state_text += "Medication: " + str(gs.medication) + "\n"
	
	# Dog stats (if dog exists in scene)
	var dog = get_tree().get_first_node_in_group("dog")
	if dog:
		state_text += "\nDog Stats:\n"
		state_text += "  Hunger: " + str(round(dog.hunger)) + "/100\n"
		state_text += "  Thirst: " + str(round(dog.thirst)) + "/100\n"
		state_text += "  Energy: " + str(round(dog.energy)) + "/100\n"
		state_text += "  Hygiene: " + str(round(dog.hygiene)) + "/100\n"
		state_text += "  Health: " + str(round(dog.health)) + "/100\n"
	else:
		# Fallback to GameState if dog not found
		state_text += "Dog Health: " + str(gs.dog_health) + "/100\n"
	
	# Recent vet transactions (last 3)
	var vet_transactions = []
	for entry in gs.transaction_history:
		if entry.has("category") and entry["category"] == "Vet":
			vet_transactions.append(entry)
		if vet_transactions.size() >= 3:
			break
	
	if vet_transactions.size() > 0:
		state_text += "\nRecent Vet Transactions:\n"
		for entry in vet_transactions:
			state_text += "  Day " + str(entry["day"]) + ": " + entry["description"] + " - $" + str(abs(entry["amount"])) + "\n"
	
	state_text += "=== END GAME STATE ===\n"
	return state_text

func ask_question(question: String):
	request_started.emit()
	
	# Get current game state and inject it into the prompt
	var current_state = get_current_game_state()
	var full_prompt = system_prompt + "\n" + current_state + "\n\nPlayer Question: " + question + "\n\nAnswer:"
	
	var body = JSON.stringify({
		"model": MODEL_NAME,
		"prompt": full_prompt,
		"stream": false,
		"options": {
			"temperature": 0.7,
			"num_predict": 150
		}
	})
	
	var headers = ["Content-Type: application/json"]
	var error = http_request.request(OLLAMA_URL, headers, HTTPClient.METHOD_POST, body)
	
	if error != OK:
		request_failed.emit("Could not connect to Ollama. Make sure it's running!")

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		request_failed.emit("Error: Could not get response. Is Ollama running?")
		return
	
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json and json.has("response"):
		response_received.emit(json["response"].strip_edges())
	else:
		request_failed.emit("Invalid response from assistant")
