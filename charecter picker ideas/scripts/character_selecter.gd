# COMMIT: Achievements and Catch Minigame Update
extends Control

@onready var components: Control = $Components
@onready var confirm_button: Button = $Button
@onready var back_to_menu_button: Button = $BackToMenu
@onready var name_edit: LineEdit = $HBoxContainer/LineEdit
@onready var character_preferences: Node = get_node("/root/CharacterPreferences")

const TAB_NAMES := ["Body", "Hairstyle", "Outfit", "Eyes", "Accessory"]


func _ready() -> void:
	_apply_saved_preferences()
	_connect_customization_buttons()
	_sync_initial_preview()
	_update_confirm_enabled()
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_to_menu_button.pressed.connect(_on_back_to_menu_pressed)
	name_edit.text_changed.connect(_on_name_changed)


func _apply_saved_preferences() -> void:
	name_edit.text = character_preferences.player_name
	for tab_name in TAB_NAMES:
		var option: int = character_preferences.get_option(tab_name)
		var tab: Control = $CustomizationOptions.get_node(tab_name)
		var checkbox: BaseButton = tab.get_child(option - 1)
		checkbox.button_pressed = true


func _connect_customization_buttons() -> void:
	for tab_name in TAB_NAMES:
		var tab: Control = $CustomizationOptions.get_node(tab_name)
		var first_checkbox: BaseButton = tab.get_child(0)
		var button_group: ButtonGroup = first_checkbox.button_group
		if button_group:
			button_group.pressed.connect(_on_option_pressed.bind(tab_name))


func _sync_initial_preview() -> void:
	for tab_name in TAB_NAMES:
		var tab: Control = $CustomizationOptions.get_node(tab_name)
		var first_checkbox: BaseButton = tab.get_child(0)
		var button_group: ButtonGroup = first_checkbox.button_group
		if button_group:
			var pressed_button: BaseButton = button_group.get_pressed_button()
			if pressed_button:
				_on_option_pressed(pressed_button, tab_name)


func _on_option_pressed(button: BaseButton, category: String) -> void:
	var option_index: int = button.get_index()
	var option_one_based: int = option_index + 1
	var animation_name: String = "Option%d" % option_one_based
	var sprite: AnimatedSprite2D = components.get_node_or_null(category)
	if sprite:
		sprite.animation = animation_name
	character_preferences.set_option(category, option_one_based)


func _on_name_changed(new_text: String) -> void:
	character_preferences.set_player_name(new_text)
	_update_confirm_enabled()


func _update_confirm_enabled() -> void:
	confirm_button.disabled = name_edit.text.strip_edges().is_empty()


func _on_confirm_pressed() -> void:
	confirm_button.disabled = true
	await SceneManager.change_scene("res://scenes/world.tscn", get_node("/root/TransitionPrefs").get_transition_dict())


func _on_back_to_menu_pressed() -> void:
	back_to_menu_button.disabled = true
	await SceneManager.change_scene("res://scenes/menu/starting_menu.tscn", get_node("/root/TransitionPrefs").get_transition_dict())
