extends Node3D

@export var level_number := 1
@export_file("*.tscn") var next_level := ""

func _ready():
	GameManager.start_level(level_number)
	GameManager.level_completed.connect(_on_level_completed)
	$Player.get_node("Gimbal").global_position = $Player.global_position

func _on_level_completed():
	if not next_level.is_empty():
		go_to_next_level.call_deferred()
	else:
		$Player.set_physics_process(false)
		$Player.velocity = Vector3.ZERO
		$Player.get_node("Footsteps").stop()
		$Player.get_node("ParticleTrail").emitting = false
		$Player.get_node("Visual/Juice/Motion/Alignment/Somchai/AnimationPlayer").play("Idle")
		$HUD/UI.show_win()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func go_to_next_level():
	var error = get_tree().change_scene_to_file(next_level)
	if error != OK:
		GameManager.level_finished = false
		push_error("Could not load next level: %s" % error)

