# COMMIT: Achievements and Catch Minigame Update
extends Node

# Day 1 Tutorial Controller
# Manages the guided tutorial sequence on the first day

var tutorial_hint_scene = preload("res://scenes/ui/tutorial_hint.tscn")
var tutorial_hint: CanvasLayer = null

var current_step: int = 0
var tutorial_active: bool = false

# References to game elements
var dog: CharacterBody2D = null
var hud: CanvasLayer = null

signal tutorial_completed

func _ready():
	# This node processes even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_tutorial(game_dog: CharacterBody2D, game_hud: CanvasLayer):
	"""Initialize and start the Day 1 tutorial."""
	dog = game_dog
	hud = game_hud
	tutorial_active = true
	current_step = 0
	
	# Create tutorial hint UI
	tutorial_hint = tutorial_hint_scene.instantiate()
	tutorial_hint.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(tutorial_hint)
	
	# Wait for scene to render (use process_always timer)
	await get_tree().create_timer(1.0, false, true).timeout
	
	# Block movement but allow menu inputs (don't pause the game)
	GameState.tutorial_blocks_movement = true
	
	print("[Tutorial] Starting tutorial")
	run_step()

func run_step():
	"""Execute current tutorial step."""
	print("[Tutorial] Running step ", current_step)
	match current_step:
		0:
			# Step 1: Press P or paw to open pet needs
			# Don't pause - let player interact
			tutorial_hint.show_hint("Press P or 🐾 to open pet needs.")
			# Wait for needs menu to open
			if dog:
				# Wait a bit for needs_menu_instance to be created if not yet
				if not dog.needs_menu_instance:
					await get_tree().create_timer(0.5, false, true).timeout
				if dog.needs_menu_instance:
					dog.needs_menu_instance.process_mode = Node.PROCESS_MODE_ALWAYS
					var panel = dog.needs_menu_instance.panel
					while not panel.visible:
						await get_tree().process_frame
					advance_step()
				else:
					# Fallback: skip this step after 3 seconds if menu not available
					print("[Tutorial] Warning: needs_menu_instance not found, skipping step 0")
					await get_tree().create_timer(3.0, false, true).timeout
					advance_step()
			else:
				print("[Tutorial] Error: dog is null")
				advance_step()
		
		1:
			# Step 2: Explain pet needs (4 seconds)
			tutorial_hint.show_hint("This tells you the needs of your little buddy. When food or water is low, take them back home to feed them.", 4.0)
			await tutorial_hint.hint_hidden
			advance_step()
		
		2:
			# Step 3: Energy and health (6 seconds), then close menu
			tutorial_hint.show_hint("When their energy is low, take them home to sleep. If health is low, take them to the vet.", 6.0)
			await tutorial_hint.hint_hidden
			# Close the needs menu
			if dog and dog.needs_menu_instance:
				dog.needs_menu_instance.panel.hide()
				if dog.needs_menu_instance.has_node("../Download7_44_10Pm"):
					dog.needs_menu_instance.arrow.hide()
			advance_step()
		
		3:
			# Step 4: Show supplies hint for 5 seconds (no click required)
			tutorial_hint.show_hint("Press 📈 to see your supplies.", 5.0)
			await tutorial_hint.hint_hidden
			advance_step()
		
		4:
			# Step 5: Final hint about pause and finances (4 seconds)
			tutorial_hint.show_hint("Press ... to pause and click 📝 to see your finances.", 4.0)
			await tutorial_hint.hint_hidden
			advance_step()
		
		5:
			# Tutorial complete!
			end_tutorial()

func _on_supplies_opened():
	advance_step()

func advance_step():
	current_step += 1
	run_step()

func end_tutorial():
	"""Clean up main tutorial and start vet visit sequence."""
	tutorial_active = false
	GameState.is_tutorial_complete = true
	
	# Allow movement again
	GameState.tutorial_blocks_movement = false
	
	tutorial_completed.emit()
	
	# Start vet visit sequence (keep tutorial_hint for these hints)
	await show_vet_hints()

func show_vet_hints():
	"""Show hints guiding player to vet."""
	# Hint 1: Pet health is low (4 seconds)
	tutorial_hint.show_hint("Your pet's health is low. Let's go and take them to the vet!", 4.0)
	await tutorial_hint.hint_hidden
	
	# Hint 2: Follow path (4 seconds)
	tutorial_hint.show_hint("Follow the path to the vet.", 4.0)
	await tutorial_hint.hint_hidden
	
	# Now clean up tutorial hint - vet entrance will handle "press E" hint
	if tutorial_hint:
		tutorial_hint.queue_free()
		tutorial_hint = null
