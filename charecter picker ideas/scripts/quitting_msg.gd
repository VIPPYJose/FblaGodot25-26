# COMMIT: Achievements and Catch Minigame Update
extends Control

const DISPLAY_DURATION := 3.0

func _ready() -> void:
	await get_tree().create_timer(DISPLAY_DURATION).timeout
	await SceneManager.fade_out(get_node("/root/TransitionPrefs").get_transition_dict())
	get_tree().quit()
