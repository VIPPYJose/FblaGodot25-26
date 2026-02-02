extends CanvasLayer

@onready var chat_history = $Panel/MainHBox/RightSection/ChatContainer/ChatScroll/ChatHistory
@onready var chat_scroll = $Panel/MainHBox/RightSection/ChatContainer/ChatScroll
@onready var question_input = $Panel/MainHBox/RightSection/InputContainer/QuestionInput
@onready var send_btn = $Panel/MainHBox/RightSection/InputContainer/SendBtn
@onready var status_label = $Panel/MainHBox/RightSection/StatusLabel

var llm_assistant: LLMAssistant = null
var is_waiting_for_response: bool = false

func _ready():
	# Create LLM Assistant instance
	llm_assistant = LLMAssistant.new()
	add_child(llm_assistant)
	
	# Connect signals
	llm_assistant.response_received.connect(_on_response_received)
	llm_assistant.request_started.connect(_on_request_started)
	llm_assistant.request_failed.connect(_on_request_failed)

func _on_close_btn_pressed():
	queue_free()

func _on_send_btn_pressed():
	_submit_question()

func _on_question_submitted(_text: String):
	_submit_question()

func _submit_question():
	var question = question_input.text.strip_edges()
	if question.is_empty() or is_waiting_for_response:
		return
	
	# Add user question to chat
	add_chat_message(question, true)
	
	# Clear input
	question_input.text = ""
	
	# Send to LLM
	llm_assistant.ask_question(question)

func _on_request_started():
	is_waiting_for_response = true
	status_label.text = "Thinking..."
	send_btn.disabled = true
	question_input.editable = false

func _on_response_received(response: String):
	is_waiting_for_response = false
	status_label.text = ""
	send_btn.disabled = false
	question_input.editable = true
	
	# Add assistant response to chat
	add_chat_message(response, false)
	
	# Focus back on input
	question_input.grab_focus()

func _on_request_failed(error: String):
	is_waiting_for_response = false
	status_label.text = ""
	send_btn.disabled = false
	question_input.editable = true
	
	# Show error in chat
	add_chat_message("Error: " + error, false, true)
	
	question_input.grab_focus()

func add_chat_message(text: String, is_user: bool, is_error: bool = false):
	var message_container = HBoxContainer.new()
	message_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 22)
	
	if is_user:
		# User message - right aligned, blue tint
		label.text = "You: " + text
		label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	elif is_error:
		# Error message - red
		label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	else:
		# Assistant message - green tint
		label.text = "Assistant: " + text
		label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
	
	message_container.add_child(label)
	chat_history.add_child(message_container)
	
	# Auto-scroll to bottom after a frame
	await get_tree().process_frame
	chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value
