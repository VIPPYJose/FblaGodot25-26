extends Control

## Character customization screen inspired by the Character-Generator-2.0 UI.
## Features dropdown selectors, 4-directional preview, component visibility toggles,
## and a pixel-art themed bottom bar.

const CharacterAssets = preload("res://scripts/CharacterAssets.gd")

# Categories in display order (maps to PREVIEW_TEXTURES keys)
const CATEGORIES := ["Body", "Eyes", "Outfit", "Hairstyle", "Accessory"]

# The 4 preview directions (matches the screenshot layout: left, front, back, right)
const DIRECTIONS := ["left", "down", "up", "right"]

const PIXEL_FONT_PATH := "res://assets/fonts/Minecraft.ttf"

# Atlas regions for idle frame 0 in each direction.
# Each sprite sheet row at y=96 contains: idle_right(6) → idle_up(6) → idle_left(6) → idle_down(6)
# Frame size is 48×96.
const DIR_ATLAS := {
	"left":  Rect2(576, 96, 48, 96),
	"down":  Rect2(864, 96, 48, 96),
	"up":    Rect2(288, 96, 48, 96),
	"right": Rect2(0, 96, 48, 96),
}

# Scale factor for the 48×96 sprites (makes them ~240×480 at scale 5)
const SPRITE_SCALE := 5.0

var PREVIEW_TEXTURES: Dictionary = CharacterAssets.PREVIEW_TEXTURES

# Current selection per category (1-based index into PREVIEW_TEXTURES arrays)
var selections := {
	"Body": 1, "Eyes": 1, "Outfit": 1, "Hairstyle": 1, "Accessory": 1,
}

# Whether each component layer is visible in the preview
var visibility := {
	"Body": true, "Eyes": true, "Outfit": true, "Hairstyle": true, "Accessory": true,
}

# ─── UI references (populated in _build_ui) ───
var dropdowns := {}        # String(category) → OptionButton
var preview_sprites := {}  # String(direction) → { String(category) → Sprite2D }
var vis_checks := {}       # String(category) → CheckBox
var name_input: LineEdit
var continue_btn: Button
var back_btn: Button
var randomize_btn: Button
var pixel_font: Font


func _ready() -> void:
	if ResourceLoader.exists(PIXEL_FONT_PATH):
		pixel_font = load(PIXEL_FONT_PATH)
	_build_ui()
	_apply_saved()
	_sync_all_previews()
	_update_continue()


# ═══════════════════════════════════════════════════════════════════
#  UI CONSTRUCTION
# ═══════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	# ── Background (blue checker) ──
	var checker := _create_checker_bg()
	add_child(checker)

	# ── Main vertical layout ──
	var main := VBoxContainer.new()
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.add_theme_constant_override("separation", 0)
	add_child(main)

	# Top padding
	var top_pad := Control.new()
	top_pad.custom_minimum_size.y = 40
	main.add_child(top_pad)

	# ── Title ──
	var title := Label.new()
	title.text = "CHARACTER CREATOR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	if pixel_font:
		title.add_theme_font_override("font", pixel_font)
	main.add_child(title)

	# Small gap
	var gap1 := Control.new()
	gap1.custom_minimum_size.y = 20
	main.add_child(gap1)

	# ── Dropdown panel (centered 2-column grid) ──
	var dd_center := CenterContainer.new()
	dd_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(dd_center)

	var dd_grid := GridContainer.new()
	dd_grid.columns = 3
	dd_grid.add_theme_constant_override("h_separation", 24)
	dd_grid.add_theme_constant_override("v_separation", 14)
	dd_center.add_child(dd_grid)

	for cat in CATEGORIES:
		var opt := _create_dropdown(cat)
		dd_grid.add_child(opt)
		dropdowns[cat] = opt

	# ── Flexible spacer before preview ──
	var flex1 := Control.new()
	flex1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(flex1)

	# ── 4-direction preview area ──
	var preview_center := CenterContainer.new()
	preview_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(preview_center)

	var preview_hbox := HBoxContainer.new()
	preview_hbox.add_theme_constant_override("separation", 60)
	preview_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_center.add_child(preview_hbox)

	for dir in DIRECTIONS:
		var col := _create_preview_column(dir)
		preview_hbox.add_child(col)

	# ── Flexible spacer after preview ──
	var flex2 := Control.new()
	flex2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(flex2)

	# ── Bottom bar ──
	var bar := _create_bottom_bar()
	main.add_child(bar)


func _create_checker_bg() -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 color1 : source_color = vec4(0.247, 0.584, 0.776, 1.0);
uniform vec4 color2 : source_color = vec4(0.208, 0.529, 0.722, 1.0);
uniform float tile_size = 48.0;
void fragment() {
	vec2 pos = FRAGCOORD.xy / tile_size;
	float checker = mod(floor(pos.x) + floor(pos.y), 2.0);
	COLOR = mix(color1, color2, checker);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	rect.material = mat
	return rect


func _create_dropdown(category: String) -> OptionButton:
	var opt := OptionButton.new()
	opt.custom_minimum_size = Vector2(440, 64)
	opt.fit_to_longest_item = false
	opt.add_theme_font_size_override("font_size", 26)
	opt.add_theme_color_override("font_color", Color.WHITE)
	opt.add_theme_color_override("font_hover_color", Color.WHITE)
	opt.add_theme_color_override("font_pressed_color", Color.WHITE)
	if pixel_font:
		opt.add_theme_font_override("font", pixel_font)

	# Grey metallic style matching the screenshot
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.42, 0.48, 0.54)
	sb.border_color = Color(0.32, 0.36, 0.40)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	opt.add_theme_stylebox_override("normal", sb)

	var sb_hover: StyleBoxFlat = sb.duplicate()
	sb_hover.bg_color = Color(0.48, 0.54, 0.60)
	opt.add_theme_stylebox_override("hover", sb_hover)

	var sb_pressed: StyleBoxFlat = sb.duplicate()
	sb_pressed.bg_color = Color(0.38, 0.42, 0.48)
	opt.add_theme_stylebox_override("pressed", sb_pressed)

	var sb_focus: StyleBoxFlat = sb.duplicate()
	sb_focus.border_color = Color(0.8, 0.8, 0.2)
	opt.add_theme_stylebox_override("focus", sb_focus)

	# Populate items
	var textures: Array = PREVIEW_TEXTURES.get(category, [])
	for i in range(textures.size()):
		var label := _get_option_label(category, textures[i])
		opt.add_item(label.to_upper(), i)

	opt.item_selected.connect(_on_dropdown_changed.bind(category))
	return opt


func _get_option_label(category: String, path: String) -> String:
	var filename := path.get_file().get_basename()
	match category:
		"Body":
			return filename.replace("Body_", "Body ")
		"Eyes":
			return filename.replace("Eyes_", "Eyes ")
		"Hairstyle":
			var s := filename.replace("Hairstyle_", "Hair ")
			return s.replace("_", " ")
		"Outfit":
			var s := filename.replace("Outfit_", "Outfit ")
			return s.replace("_", " ")
		"Accessory":
			var s := filename.replace("Accessory_", "")
			return s.replace("_", " ")
	return filename


func _create_preview_column(direction: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_END
	col.add_theme_constant_override("separation", 4)

	# Direction label
	var dir_label := Label.new()
	var dir_names := {"left": "LEFT", "down": "FRONT", "up": "BACK", "right": "RIGHT"}
	dir_label.text = dir_names.get(direction, direction.to_upper())
	dir_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dir_label.add_theme_font_size_override("font_size", 22)
	dir_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	if pixel_font:
		dir_label.add_theme_font_override("font", pixel_font)
	col.add_child(dir_label)

	# Sprite container (Control that holds layered Sprite2D nodes)
	var sprite_w := int(48 * SPRITE_SCALE)
	var sprite_h := int(96 * SPRITE_SCALE)
	var container := Control.new()
	container.custom_minimum_size = Vector2(sprite_w, sprite_h)
	container.clip_contents = true
	col.add_child(container)

	preview_sprites[direction] = {}

	# Layer order: Body (back) → Eyes → Outfit → Hairstyle → Accessory (front)
	var layer_order := ["Body", "Eyes", "Outfit", "Hairstyle", "Accessory"]
	for i in range(layer_order.size()):
		var cat: String = layer_order[i]
		var sprite := Sprite2D.new()
		sprite.name = cat
		sprite.centered = false
		sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
		sprite.z_index = i
		container.add_child(sprite)
		preview_sprites[direction][cat] = sprite

	# Shadow ellipse under the sprite
	var shadow_panel := Panel.new()
	shadow_panel.custom_minimum_size = Vector2(sprite_w * 0.7, 16)
	shadow_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var shadow_sb := StyleBoxFlat.new()
	shadow_sb.bg_color = Color(0, 0, 0, 0.2)
	shadow_sb.set_corner_radius_all(8)
	shadow_panel.add_theme_stylebox_override("panel", shadow_sb)
	col.add_child(shadow_panel)

	return col


func _create_bottom_bar() -> PanelContainer:
	var bar := PanelContainer.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.75, 0.75, 0.75)
	sb.border_color = Color(0.55, 0.55, 0.55)
	sb.border_width_top = 4
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	bar.add_theme_stylebox_override("panel", sb)

	var bar_vbox := VBoxContainer.new()
	bar_vbox.add_theme_constant_override("separation", 14)
	bar.add_child(bar_vbox)

	# ── Row 1: Name input ──
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 14)
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bar_vbox.add_child(name_row)

	var name_label := Label.new()
	name_label.text = "NAME:"
	name_label.add_theme_font_size_override("font_size", 30)
	name_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	name_row.add_child(name_label)

	name_input = LineEdit.new()
	name_input.custom_minimum_size = Vector2(350, 50)
	name_input.placeholder_text = "Enter Name"
	name_input.max_length = 25
	name_input.add_theme_font_size_override("font_size", 26)
	if pixel_font:
		name_input.add_theme_font_override("font", pixel_font)
	var input_sb := StyleBoxFlat.new()
	input_sb.bg_color = Color.WHITE
	input_sb.border_color = Color(0.5, 0.5, 0.5)
	input_sb.set_border_width_all(2)
	input_sb.set_corner_radius_all(4)
	input_sb.content_margin_left = 10
	input_sb.content_margin_right = 10
	name_input.add_theme_stylebox_override("normal", input_sb)
	name_input.text_changed.connect(_on_name_changed)
	name_row.add_child(name_input)

	# ── Row 2: Buttons + visibility toggles ──
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bar_vbox.add_child(btn_row)

	# Back button (dark grey)
	back_btn = _create_styled_button("BACK", Color(0.45, 0.48, 0.52))
	back_btn.pressed.connect(_on_back_pressed)
	btn_row.add_child(back_btn)

	# Randomize button (orange — prominent like in the screenshot)
	randomize_btn = _create_styled_button("RANDOMIZE", Color(0.92, 0.62, 0.08))
	randomize_btn.pressed.connect(_on_randomize_pressed)
	btn_row.add_child(randomize_btn)

	# Separator
	var sep1 := VSeparator.new()
	sep1.custom_minimum_size.x = 10
	btn_row.add_child(sep1)

	# Visibility toggles for each component
	for cat in CATEGORIES:
		var check := CheckBox.new()
		check.text = cat.to_upper()
		check.button_pressed = true
		check.add_theme_font_size_override("font_size", 22)
		check.add_theme_color_override("font_color", Color(0.25, 0.25, 0.25))
		if pixel_font:
			check.add_theme_font_override("font", pixel_font)
		check.toggled.connect(_on_visibility_toggled.bind(cat))
		btn_row.add_child(check)
		vis_checks[cat] = check

	# Separator
	var sep2 := VSeparator.new()
	sep2.custom_minimum_size.x = 10
	btn_row.add_child(sep2)

	# Continue button (green)
	continue_btn = _create_styled_button("CONTINUE", Color(0.30, 0.68, 0.38))
	continue_btn.pressed.connect(_on_continue_pressed)
	btn_row.add_child(continue_btn)

	return bar


func _create_styled_button(label_text: String, bg_color: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(200, 55)
	btn.add_theme_font_size_override("font_size", 28)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	if pixel_font:
		btn.add_theme_font_override("font", pixel_font)

	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = bg_color.darkened(0.25)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", sb)

	var sb_hover: StyleBoxFlat = sb.duplicate()
	sb_hover.bg_color = bg_color.lightened(0.12)
	btn.add_theme_stylebox_override("hover", sb_hover)

	var sb_pressed: StyleBoxFlat = sb.duplicate()
	sb_pressed.bg_color = bg_color.darkened(0.12)
	btn.add_theme_stylebox_override("pressed", sb_pressed)

	var sb_disabled: StyleBoxFlat = sb.duplicate()
	sb_disabled.bg_color = Color(0.5, 0.5, 0.5, 0.6)
	sb_disabled.border_color = Color(0.4, 0.4, 0.4)
	btn.add_theme_stylebox_override("disabled", sb_disabled)

	return btn


# ═══════════════════════════════════════════════════════════════════
#  STATE & PREVIEW LOGIC
# ═══════════════════════════════════════════════════════════════════

func _apply_saved() -> void:
	var saved := GameState.get_character_components()
	for cat in CATEGORIES:
		var option: int = saved.get(cat.to_lower(), 1)
		selections[cat] = option
		if dropdowns.has(cat):
			var idx := clampi(option - 1, 0, dropdowns[cat].item_count - 1)
			dropdowns[cat].selected = idx
	name_input.text = GameState.player_name


func _sync_all_previews() -> void:
	for cat in CATEGORIES:
		_update_preview_for_category(cat)


func _update_preview_for_category(category: String) -> void:
	var textures: Array = PREVIEW_TEXTURES.get(category, [])
	if textures.is_empty():
		return
	var idx := clampi(selections[category] - 1, 0, textures.size() - 1)
	var tex_path: String = textures[idx]
	var full_tex: Texture2D = load(tex_path)
	if not full_tex:
		return

	for dir in DIRECTIONS:
		if not preview_sprites.has(dir) or not preview_sprites[dir].has(category):
			continue
		var sprite: Sprite2D = preview_sprites[dir][category]
		var atlas := AtlasTexture.new()
		atlas.atlas = full_tex
		atlas.region = DIR_ATLAS[dir]
		sprite.texture = atlas
		sprite.visible = visibility[category]


# ═══════════════════════════════════════════════════════════════════
#  SIGNAL HANDLERS
# ═══════════════════════════════════════════════════════════════════

func _on_dropdown_changed(index: int, category: String) -> void:
	selections[category] = index + 1
	_update_preview_for_category(category)


func _on_visibility_toggled(toggled: bool, category: String) -> void:
	visibility[category] = toggled
	for dir in DIRECTIONS:
		if preview_sprites.has(dir) and preview_sprites[dir].has(category):
			preview_sprites[dir][category].visible = toggled


func _on_name_changed(_new_text: String) -> void:
	_update_continue()


func _update_continue() -> void:
	continue_btn.disabled = name_input.text.strip_edges().is_empty()


func _on_continue_pressed() -> void:
	if name_input.text.strip_edges().is_empty():
		return
	continue_btn.disabled = true
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
	back_btn.disabled = true
	SceneManager.change_scene("res://scenes/ui/IntroCutscene.tscn", {"pattern": "curtains"})


func _on_randomize_pressed() -> void:
	for cat in CATEGORIES:
		var textures: Array = PREVIEW_TEXTURES.get(cat, [])
		var max_opts := maxi(1, textures.size())
		var random_opt := randi_range(1, max_opts)
		selections[cat] = random_opt
		if dropdowns.has(cat):
			dropdowns[cat].selected = random_opt - 1
		_update_preview_for_category(cat)
