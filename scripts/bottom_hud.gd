extends CanvasLayer

@onready var money_label = $Background/Margin/MainHBox/LeftSection/MoneyLabel
@onready var time_label = $Background/Margin/MainHBox/TimeLabel

var money: int = 353

func _ready():
	update_ui()

func update_ui():
	money_label.text = "§ " + str(money)
	time_label.text = "Sun. 1:25 PM"
