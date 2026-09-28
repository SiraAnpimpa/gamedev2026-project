extends Area3D

var player_inside := false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameManager.score_changed.connect(_on_score_changed)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_inside = true
		GameManager.try_finish()

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_inside = false

func _on_score_changed(_score):
	if player_inside:
		GameManager.try_finish.call_deferred()
