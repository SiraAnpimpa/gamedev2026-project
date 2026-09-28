extends SceneTree

func _initialize():
	go.call_deferred()

func snap(name: String):
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(OS.get_environment("POTATO_CAPTURE_DIR").path_join(name + ".png"))

func go():
	change_scene_to_file("res://scenes/levels/level_1.tscn")
	for i in 100:
		await physics_frame
	print("PLAYER ", current_scene.get_node("Player").position)
	await snap("level_1")
	var player=current_scene.get_node("Player")
	player.set_physics_process(false)
	var camera=player.get_node("Gimbal/Camera3D")
	camera.global_position=Vector3(4,2.4,5)
	camera.look_at(player.global_position+Vector3.UP*0.75)
	await snap("potato_front")
	camera.global_position=Vector3(25,27,14)
	camera.look_at(Vector3(0,-1,-20))
	await snap("level_1_overview")
	print("GROUND PROFILE 1")
	for j in range(0,461,2):
		var z=-j/10.0
		var query=PhysicsRayQueryParameters3D.create(Vector3(0,4,z),Vector3(0,-6,z),1)
		query.exclude=[player.get_rid()]
		var hit=current_scene.get_world_3d().direct_space_state.intersect_ray(query)
		print("FLOOR ",z," ",hit.position.y if hit else -99)
	change_scene_to_file("res://scenes/levels/level_2.tscn")
	for i in 60: await physics_frame
	await snap("level_2")
	player=current_scene.get_node("Player")
	player.set_physics_process(false)
	camera=player.get_node("Gimbal/Camera3D")
	camera.global_position=Vector3(25,27,14)
	camera.look_at(Vector3(0,-1,-20))
	await snap("level_2_overview")
	quit()
