extends SceneTree

func _initialize(): go.call_deferred()

func snap(name: String):
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("POTATO_CAPTURE_DIR").path_join(name+".png"))

func go():
	change_scene_to_file("res://scenes/levels/level_1.tscn")
	for i in 50: await physics_frame
	await snap("level_1")
	var player=current_scene.get_node("Player")
	player.set_physics_process(false)
	current_scene.get_node("HUD").hide()
	current_scene.get_node("Coins").hide()
	current_scene.get_node("Decorations").hide()
	var camera=player.get_node("Gimbal/Camera3D")
	camera.global_position=player.global_position+Vector3(1.2,1.25,-3.4)
	camera.look_at(player.global_position+Vector3.UP*0.72)
	camera.fov=36
	var animation: AnimationPlayer=player.get_node("Visual/AnimationPlayer")
	for state in ["Idle","Run","Jump","Fall"]:
		animation.play(state)
		animation.seek(0.12,true)
		animation.pause()
		await snap("potato_"+state.to_lower())
	change_scene_to_file("res://scenes/levels/level_2.tscn")
	for i in 50: await physics_frame
	await snap("level_2")
	quit()
