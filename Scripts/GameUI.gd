extends Control

@onready var coinsLabel = $CoinsLabel
var message_time := 0.0

func _ready():
	GameManager.goal_hint.connect(show_hint)
	if has_node("WinPanel"):
		$WinPanel/Restart.pressed.connect(GameManager.restart)

func _process(delta):
	coinsLabel.text = "Coins: %d / %d" % [GameManager.score, GameManager.required_coins]
	if has_node("Message"):
		message_time = maxf(0.0, message_time - delta)
		$Message.visible = message_time > 0.0
	if has_node("Objective"):
		$Objective.text = "Reach the goal flag" if GameManager.score == 5 else "Collect all 5 coins, then find the flag"

func show_hint(message: String):
	if has_node("Message"):
		$Message.text = message
		message_time = 4.0

func show_win():
	$WinShade.show()
	$WinPanel.show()
	$WinPanel/Restart.grab_focus()
