extends Control

## Character customization screen using layered component system.
## Categories: Body, Hairstyle, Outfit, Eyes, Accessory — each with 5 options.
## Selections are stored in GameState for use during gameplay.

@onready var tab_container: TabContainer = $Panel/HSplitContainer/LeftPanel/TabContainer
@onready var name_input: LineEdit = $Panel/HSplitContainer/LeftPanel/NameContainer/NameInput
@onready var continue_button: Button = $Panel/HSplitContainer/LeftPanel/ButtonContainer/ContinueButton
@onready var back_button: Button = $Panel/HSplitContainer/LeftPanel/ButtonContainer/BackButton
@onready var components: Control = $Panel/HSplitContainer/RightPanel/PreviewBG/PreviewCenter/Components
@onready var randomize_button: Button = $Panel/HSplitContainer/LeftPanel/ButtonContainer/RandomizeButton

const TAB_NAMES := ["Body", "Hairstyle", "Outfit", "Eyes", "Accessory"]

## Maps category → array of preview texture paths (the full sprite sheets)
const PREVIEW_TEXTURES := {
	"Body": [
		"res://assets/sprites/Character Components/Body/Body_01.png",
		"res://assets/sprites/Character Components/Body/Body_02.png",
		"res://assets/sprites/Character Components/Body/Body_03.png",
		"res://assets/sprites/Character Components/Body/Body_04.png",
		"res://assets/sprites/Character Components/Body/Body_07.png",
	],
	"Hairstyle": [
		"res://assets/sprites/Character Components/Hairstyle/Hairstyle_01_04.png",
		"res://assets/sprites/Character Components/Hairstyle/Hairstyle_02_04.png",
		"res://assets/sprites/Character Components/Hairstyle/Hairstyle_05_04.png",
		"res://assets/sprites/Character Components/Hairstyle/Hairstyle_06_04.png",
		"res://assets/sprites/Character Components/Hairstyle/Hairstyle_19_04.png",
	],
	"Eyes": [
		"res://assets/sprites/Character Components/Eyes/Eyes_01.png",
		"res://assets/sprites/Character Components/Eyes/Eyes_03.png",
		"res://assets/sprites/Character Components/Eyes/Eyes_04.png",
		"res://assets/sprites/Character Components/Eyes/Eyes_05.png",
		"res://assets/sprites/Character Components/Eyes/Eyes_06.png",
	],
	"Outfit": [
		"res://assets/sprites/Character Components/Outfit/Outfit_01_03.png",
		"res://assets/sprites/Character Components/Outfit/Outfit_02_01.png",
		"res://assets/sprites/Character Components/Outfit/Outfit_04_02.png",
		"res://assets/sprites/Character Components/Outfit/Outfit_07_02.png",
		"res://assets/sprites/Character Components/Outfit/Outfit_10_04.png",
	],
	"Accessory": [
		"res://assets/sprites/Character Components/Accessory/Accessory_03_Backpack_01.png",
		"res://assets/sprites/Character Components/Accessory/Accessory_04_Snapback_01.png",
		"res://assets/sprites/Character Components/Accessory/Accessory_04_Snapback_04.png",
		"res://assets/sprites/Character Components/Accessory/Accessory_11_Beanie_01.png",
		"res://assets/sprites/Character Components/Accessory/Accessory_15_Glasses_01.png",
	],
}

## Maps category → array of SpriteFrames .tres paths (for in-game animations)
const ANIMATION_PATHS := {
	"Body": [
		"res://resources/character_components_animations/body/Body_01.tres",
		"res://resources/character_components_animations/body/Body_02.tres",
		"res://resources/character_components_animations/body/Body_03.tres",
		"res://resources/character_components_animations/body/Body_04.tres",
		"res://resources/character_components_animations/body/Body_07.tres",
	],
	"Hairstyle": [
		"res://resources/character_components_animations/hairstyle/Hairstyle_01_04.tres",
		"res://resources/character_components_animations/hairstyle/Hairstyle_02_04.tres",
		"res://resources/character_components_animations/hairstyle/Hairstyle_05_04.tres",
		"res://resources/character_components_animations/hairstyle/Hairstyle_06_04.tres",
		"res://resources/character_components_animations/hairstyle/Hairstyle_19_04.tres",
	],
	"Eyes": [
		"res://resources/character_components_animations/eyes/Eyes_01.tres",
		"res://resources/character_components_animations/eyes/Eyes_03.tres",
		"res://resources/character_components_animations/eyes/Eyes_04.tres",
		"res://resources/character_components_animations/eyes/Eyes_05.tres",
		"res://resources/character_components_animations/eyes/Eyes_06.tres",
	],
	"Outfit": [
		"res://resources/character_components_animations/outfit/Outfit_01_03.tres",
		"res://resources/character_components_animations/outfit/Outfit_02_01.tres",
		"res://resources/character_components_animations/outfit/Outfit_04_02.tres",
		"res://resources/character_components_animations/outfit/Outfit_07_02.tres",
		"res://resources/character_components_animations/outfit/Outfit_10_04.tres",
	],
	"Accessory": [
		"res://resources/character_components_animations/accessory/Accessory_03_Backpack_01.tres",
		"res://resources/character_components_animations/accessory/Accessory_04_Snapback_01.tres",
		"res://resources/character_components_animations/accessory/Accessory_04_Snapback_04.tres",
		"res://resources/character_components_animations/accessory/Accessory_11_Beanie_01.tres",
		"res://resources/character_components_animations/accessory/Accessory_15_Glasses_01.tres",
	],
}

# Stores the current option (1-based) per category
var selections := {
	"Body": 1,
	"Hairstyle": 1,
	"Outfit": 1,
	"Eyes": 1,
	"Accessory": 1,
}

# Button groups per category (created at runtime)
var button_groups := {}


func _ready() -> void:
	_build_tabs()
	_apply_saved_selections()
	_sync_all_previews()
	_update_continue_enabled()
	continue_button.pressed.connect(_on_continue_pressed)
	back_button.pressed.connect(_on_back_pressed)
	randomize_button.pressed.connect(_on_randomize_pressed)
	name_input.text_changed.connect(_on_name_changed)
	name_input.text = GameState.player_name


func _build_tabs() -> void:
	# Clear any placeholder children
	for child in tab_container.get_children():
		child.queue_free()

	for tab_name in TAB_NAMES:
		var bg := ButtonGroup.new()
		button_groups[tab_name] = bg
		bg.pressed.connect(_on_option_pressed.bind(tab_name))

		var vbox := VBoxContainer.new()
		vbox.name = tab_name
		vbox.add_theme_constant_override("separation", 12)
		tab_container.add_child(vbox)

		var textures: Array = PREVIEW_TEXTURES[tab_name]
		for i in range(textures.size()):
			var cb := CheckBox.new()
			cb.text = "Option " + str(i + 1)
			cb.button_group = bg
			cb.add_theme_font_size_override("font_size", 22)
			if i == 0:
				cb.button_pressed = true
			vbox.add_child(cb)


func _apply_saved_selections() -> void:
	# Restore from GameState if previously set
	var saved := GameState.get_character_components()
	for tab_name in TAB_NAMES:
		var option: int = saved.get(tab_name.to_lower(), 1)
		selections[tab_name] = option
		var tab: VBoxContainer = tab_container.get_node(tab_name)
		if tab and option >= 1 and option <= tab.get_child_count():
			var checkbox: CheckBox = tab.get_child(option - 1)
			checkbox.button_pressed = true


func _sync_all_previews() -> void:
	for tab_name in TAB_NAMES:
		_update_preview(tab_name, selections[tab_name])


func _on_option_pressed(button: BaseButton, category: String) -> void:
	var option_index: int = button.get_index() + 1
	selections[category] = option_index
	_update_preview(category, option_index)


func _update_preview(category: String, option: int) -> void:
	var sprite: AnimatedSprite2D = components.get_node_or_null(category)
	if not sprite:
		return

	# Build a SpriteFrames with a single "preview" animation from the atlas
	var textures: Array = PREVIEW_TEXTURES[category]
	var idx := clampi(option, 1, textures.size()) - 1
	var tex_path: String = textures[idx]
	var full_tex: Texture2D = load(tex_path)
	if not full_tex:
		return

	var atlas := AtlasTexture.new()
	atlas.atlas = full_tex
	atlas.region = Rect2(144, 0, 48, 96)

	var sf := SpriteFrames.new()
	sf.add_animation("preview")
	sf.add_frame("preview", atlas)
	sf.remove_animation("default")

	sprite.sprite_frames = sf
	sprite.animation = "preview"
	sprite.play()


func _on_name_changed(new_text: String) -> void:
	_update_continue_enabled()


func _update_continue_enabled() -> void:
	continue_button.disabled = name_input.text.strip_edges().is_empty()


func _on_continue_pressed() -> void:
	if name_input.text.strip_edges().is_empty():
		return

	continue_button.disabled = true

	# Save selections to GameState
	GameState.save_player_name(name_input.text.strip_edges())
	GameState.save_character_components(
		selections["Body"],
		selections["Hairstyle"],
		selections["Outfit"],
		selections["Eyes"],
		selections["Accessory"]
	)

	SceneManager.change_scene("res://scenes/ui/PetSelect.tscn", {"pattern": "curtains"})


func _on_back_pressed() -> void:
	back_button.disabled = true
	SceneManager.change_scene("res://scenes/ui/IntroCutscene.tscn", {"pattern": "curtains"})


func _on_randomize_pressed() -> void:
	for tab_name in TAB_NAMES:
		var random_option := randi_range(1, 5)
		selections[tab_name] = random_option
		var tab: VBoxContainer = tab_container.get_node(tab_name)
		if tab and random_option >= 1 and random_option <= tab.get_child_count():
			var checkbox: CheckBox = tab.get_child(random_option - 1)
			checkbox.button_pressed = true
		_update_preview(tab_name, random_option)
