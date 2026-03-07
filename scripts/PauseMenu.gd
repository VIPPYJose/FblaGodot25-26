# COMMIT: Achievements and Catch Minigame Update
extends CanvasLayer

## Pause menu — all button wiring is handled by bottom_hud.gd,
## which also manages ESC toggling. This script just applies the theme.

func _ready():
	visible = false
	UITheme.apply_overlay_theme(self)
