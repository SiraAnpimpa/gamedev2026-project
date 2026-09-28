extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	print("CAPTURE ", path, " ", image.get_width(), "x", image.get_height(), " result=", image.save_png(path))

func run() -> void:
	change_scene_to_file("res://scenes/levels/level_1.tscn")
	for i in 40:
		await physics_frame
	var player := current_scene.get_node("Player") as CharacterBody3D
	player.set_physics_process(false)
	current_scene.get_node("HUD").hide()
	current_scene.get_node("Coins").hide()
	current_scene.get_node("Decorations").hide()
	var camera := player.get_node("Gimbal/Camera3D") as Camera3D
	camera.global_position = player.global_position + Vector3(1.6, 1.6, -4.5)
	camera.look_at(player.global_position + Vector3.UP * 0.95)
	camera.fov = 38
	var ap := player.get_node("Visual/Juice/Motion/Alignment/Somchai/AnimationPlayer") as AnimationPlayer
	var target := OS.get_environment("LAB06_CAPTURE_DIR")
	for state in ["Idle", "Walk", "Run"]:
		ap.play(state)
		ap.seek(0.25, true)
		ap.pause()
		await capture(target.path_join("somchai_" + state.to_lower() + ".png"))
	quit()
