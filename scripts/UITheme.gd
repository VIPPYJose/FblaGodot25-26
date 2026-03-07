# COMMIT: Achievements and Catch Minigame Update
class_name UITheme
## Shared UI styling utilities for the blue-checker pixel-art aesthetic.
##
## Two modes:
##   apply_theme(root)          – full-screen menus: adds checker bg + styles everything
##   apply_overlay_theme(root)  – in-game popups: styles fonts/buttons/panels, preserves label colors

const PIXEL_FONT_PATH := "res://assets/fonts/Minecraft.ttf"

# Button colour palette
const CLR_GREY   := Color(0.45, 0.48, 0.52)
const CLR_GREEN  := Color(0.30, 0.68, 0.38)
const CLR_ORANGE := Color(0.92, 0.62, 0.08)
const CLR_RED    := Color(0.72, 0.25, 0.25)


# ═══════════════════════════════════════════════════════════════════
#  PUBLIC API
# ═══════════════════════════════════════════════════════════════════

## Full-screen theme: replaces background with checker + styles every child.
static func apply_theme(root: Control) -> void:
	_replace_background(root)
	_style_children_recursive(root, true)


## Overlay theme: styles fonts, buttons, panels but preserves existing label colors.
## Works on CanvasLayer, Control, or any Node.
static func apply_overlay_theme(root: Node) -> void:
	_style_children_recursive(root, false)


## Create the blue checker background (can also be used standalone).
static func create_checker_bg() -> ColorRect:
	var rect := ColorRect.new()
	rect.name = "CheckerBG"
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


static func get_pixel_font() -> Font:
	if ResourceLoader.exists(PIXEL_FONT_PATH):
		return load(PIXEL_FONT_PATH)
	return null


# ═══════════════════════════════════════════════════════════════════
#  INDIVIDUAL STYLE HELPERS  (can be called directly if needed)
# ═══════════════════════════════════════════════════════════════════

static func style_button(btn: Button, bg_color: Color = CLR_GREY) -> void:
	var font := get_pixel_font()
	if font and not _has_emoji(btn.text):
		btn.add_theme_font_override("font", font)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)

	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = bg_color.darkened(0.25)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
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


static func style_label(label: Label, force_white: bool = true) -> void:
	var font := get_pixel_font()
	if font and not _has_emoji(label.text):
		label.add_theme_font_override("font", font)
	if force_white:
		label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)


static func style_line_edit(input: LineEdit) -> void:
	var font := get_pixel_font()
	if font:
		input.add_theme_font_override("font", font)
	# Black text on white background so you can clearly see what you're typing
	input.add_theme_color_override("font_color", Color.BLACK)
	input.add_theme_color_override("font_placeholder_color", Color(0.45, 0.45, 0.45))

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.border_color = Color(0.4, 0.45, 0.5)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	input.add_theme_stylebox_override("normal", sb)

	var sb_focus: StyleBoxFlat = sb.duplicate()
	sb_focus.border_color = Color(0.85, 0.80, 0.2)
	sb_focus.border_width_bottom = 4
	input.add_theme_stylebox_override("focus", sb_focus)


static func style_panel(panel: Control) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.16, 0.92)
	sb.border_color = Color(0.30, 0.35, 0.42)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(20)
	if panel is PanelContainer:
		panel.add_theme_stylebox_override("panel", sb)
	elif panel is Panel:
		panel.add_theme_stylebox_override("panel", sb)


static func style_rich_text(rtl: RichTextLabel) -> void:
	var font := get_pixel_font()
	if font:
		rtl.add_theme_font_override("normal_font", font)
		rtl.add_theme_font_override("bold_font", font)
		rtl.add_theme_font_override("italics_font", font)


static func style_check_box(cb: CheckBox) -> void:
	var font := get_pixel_font()
	if font and not _has_emoji(cb.text):
		cb.add_theme_font_override("font", font)
	cb.add_theme_color_override("font_color", Color.WHITE)
	cb.add_theme_color_override("font_hover_color", Color(0.9, 0.9, 1.0))
	cb.add_theme_color_override("font_pressed_color", Color.WHITE)


# ═══════════════════════════════════════════════════════════════════
#  INTERNALS
# ═══════════════════════════════════════════════════════════════════

## Remove any existing full-screen ColorRect backgrounds, then add checker.
static func _replace_background(root: Control) -> void:
	for child in root.get_children():
		if child is ColorRect and child.anchor_right >= 1.0 and child.anchor_bottom >= 1.0:
			child.queue_free()
	var checker := create_checker_bg()
	root.add_child(checker)
	root.move_child(checker, 0)


## Auto-detect a good colour based on button text.
static func _auto_button_color(btn: Button) -> Color:
	var t := btn.text.to_lower().strip_edges()
	if t in ["continue", "continue game", "yes", "start new game", "start", "resume",
			"got it!", "transfer", "submit", "ask", "send", "purchace", "purchase"]:
		return CLR_GREEN
	elif t in ["randomize"]:
		return CLR_ORANGE
	elif t in ["no", "back", "close", "x", "quit game", " x "]:
		return CLR_RED
	return CLR_GREY


## Walk the tree and style every relevant node.
## preserve_colors=false → full styling (for full-screen menus)
## preserve_colors=true  → skip label color overrides (for overlays)
static func _style_children_recursive(node: Node, force_label_colors: bool = true) -> void:
	if node is CheckBox:
		style_check_box(node)
	elif node is OptionButton:
		pass  # OptionButtons are custom-styled by their own scripts
	elif node is Button:
		style_button(node, _auto_button_color(node))
	elif node is Label:
		if force_label_colors:
			style_label(node, true)
		else:
			# Overlay mode: set font + shadow but keep existing color
			style_label(node, not node.has_theme_color_override("font_color"))
	elif node is LineEdit:
		style_line_edit(node)
	elif node is RichTextLabel:
		style_rich_text(node)
	elif node is PanelContainer or node is Panel:
		style_panel(node)
	for child in node.get_children():
		_style_children_recursive(child, force_label_colors)


## Returns true if the text contains emoji (high-unicode) characters.
## We skip setting the pixel font on these since Minecraft.ttf lacks emoji glyphs.
static func _has_emoji(text: String) -> bool:
	for i in range(text.length()):
		if text.unicode_at(i) > 0x2000:
			return true
	return false
