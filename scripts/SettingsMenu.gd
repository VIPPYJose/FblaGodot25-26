extends CanvasLayer

signal settings_closed

@onready var volume_slider = $Panel/VBox/VolumeContainer/VolumeSlider
@onready var volume_value_label = $Panel/VBox/VolumeContainer/VolumeValue
@onready var close_btn = $Panel/VBox/CloseBtn

func _ready():
	# Initial value from GameState if exists, else default to 70
	var initial_volume = GameState.get("master_volume") if "master_volume" in GameState else 70
	volume_slider.value = initial_volume
	volume_value_label.text = str(initial_volume)
	
	volume_slider.value_changed.connect(_on_volume_changed)
	close_btn.pressed.connect(_on_close_pressed)

func _on_volume_changed(value):
	volume_value_label.text = str(int(value))
	if "master_volume" in GameState:
		GameState.master_volume = int(value)
	
	# Apply volume to master bus
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	# Handle mute if volume is 0
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), value == 0)

func _on_close_pressed():
	settings_closed.emit()
	queue_free()

