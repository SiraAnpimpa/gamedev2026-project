extends Node3D

signal score_changed(value: int)
signal goal_hint(message: String)
signal level_completed

var score := 0
var required_coins := 5
var level_number := 1
var level_finished := false

func _process(_delta):
	show_mouse_cursor()

func show_mouse_cursor():
	if Input.is_action_just_pressed("mouse_visible"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not level_finished:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func start_level(number: int, required: int = 5):
	level_number = number
	required_coins = required
	score = 0
	level_finished = false
	score_changed.emit(score)

func add_score():
	if level_finished:
		return
	score += 1
	score_changed.emit(score)
	if score == required_coins:
		goal_hint.emit("All coins collected! Head to the flag.")

func try_finish():
	if level_finished:
		return
	if score < required_coins:
		goal_hint.emit("Collect all coins first!   Coins: %d / %d" % [score, required_coins])
		return
	level_finished = true
	level_completed.emit()

func restart():
	level_finished = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var error = get_tree().change_scene_to_file("res://scenes/levels/level_1.tscn")
	if error != OK:
		push_error("Could not restart level 1: %s" % error)
