# COMMIT: Achievements and Catch Minigame Update
extends CanvasLayer

## Achievements popup — shows all achievements, their descriptions, and unlock status.

const ACHIEVEMENT_DESCRIPTIONS := {
	"Penny Pincher": "Save $200 in your emergency fund",
	"Master Chef": "Feed your dog 10 times",
	"Golden Years": "Reach Day 30",
	"Catch Pro": "Earn $40 in a single catch round",
	"Catch Master": "Earn $200 total from the catch minigame"
}

func _ready():
	UITheme.apply_overlay_theme(self )
	_build_ui()

func _build_ui():
	# Background dimmer
	var bg = ColorRect.new()
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0, 0, 0, 0.5)
	add_child(bg)

	# Panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 650)
	panel.anchors_preset = Control.PRESET_CENTER
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -450
	panel.offset_top = -325
	panel.offset_right = 450
	panel.offset_bottom = 325
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	# Header with title and close button
	var header = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(header)

	var title = Label.new()
	title.text = "Achievements"
	title.add_theme_font_size_override("font_size", 58)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font = UITheme.get_pixel_font()
	if font:
		title.add_theme_font_override("font", font)
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = " X "
	close_btn.custom_minimum_size = Vector2(80, 80)
	close_btn.add_theme_font_size_override("font_size", 42)
	close_btn.pressed.connect(func(): queue_free())
	header.add_child(close_btn)

	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Scrollable list
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 18)
	scroll.add_child(list)

	# Build achievement rows
	for achievement_name in GameState.achievements.keys():
		var is_unlocked = GameState.achievements[achievement_name]
		var description = ACHIEVEMENT_DESCRIPTIONS.get(achievement_name, "")

		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 20)
		list.add_child(row)

		# Left side: achievement name + icon
		var name_label = Label.new()
		if is_unlocked:
			name_label.text = "🏆 " + achievement_name
			name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		else:
			name_label.text = "🔒 " + achievement_name
			name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		name_label.add_theme_font_size_override("font_size", 38)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if font:
			name_label.add_theme_font_override("font", font)
		row.add_child(name_label)

		# Right side: description
		var desc_label = Label.new()
		desc_label.text = description
		desc_label.add_theme_font_size_override("font_size", 26)
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if is_unlocked:
			desc_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
		else:
			desc_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		if font:
			desc_label.add_theme_font_override("font", font)
		row.add_child(desc_label)

		# Separator between rows
		var row_sep = HSeparator.new()
		row_sep.modulate = Color(1, 1, 1, 0.3)
		list.add_child(row_sep)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		queue_free()
		get_viewport().set_input_as_handled()
