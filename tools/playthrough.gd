extends SceneTree

# Test-only driver. Route traversal uses Input actions and the shipped controller.
# Teleports are used only for the isolated locked-goal test, never for completion.
var failures: Array[String] = []
var events: Array[String] = []
var trace: Array = []
var seen_states := {}

func _initialize():
	go.call_deferred()

func check(ok: bool, message: String):
	print(("PASS " if ok else "FAIL ") + message)
	events.append(("PASS " if ok else "FAIL ") + message)
	if not ok: failures.append(message)

func frames(count: int):
	for i in count: await physics_frame

func screenshot(file: String):
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("POTATO_CAPTURE_DIR").path_join(file + ".png"))

func gm():
	return root.get_node("GameManager")

func traverse(number: int):
	var scene=current_scene
	var player=scene.get_node("Player")
	var measured_gaps: Array=load("res://tools/gap_profile.gd").new().scan(scene,player)
	var jumps: Array=measured_gaps.map(func(gap): return gap.takeoff)
	var jump_index:=0
	var jump_held:=0
	var last_score:=0
	var last_z:float=player.position.z
	var bridge_shot:=false
	Input.action_press("move_forward")
	for frame in 900:
		await physics_frame
		if current_scene != scene or not is_instance_valid(player) or gm().level_finished:
			break
		if jump_held > 0:
			jump_held-=1
			if jump_held==0: Input.action_release("jump")
		if jump_index < jumps.size() and player.position.z <= jumps[jump_index] and player.is_on_floor():
			Input.action_press("jump")
			jump_held=2
			print("JUMP level ",number," at ",player.position)
			jump_index+=1
		seen_states[player.animation.current_animation]=true
		if frame%6==0:
			trace.append({"level":number,"frame":frame,"position":str(player.position),"velocity":str(player.velocity),"floor":player.is_on_floor(),"score":gm().score})
		if gm().score!=last_score:
			check(gm().score==last_score+1,"Level %d coin %d collected by physical overlap"%[number,gm().score])
			last_score=gm().score
		if player.position.y < -2 or player.position.z > last_z+5:
			check(false,"Level %d route fell or respawned at %s"%[number,player.position])
			break
		last_z=player.position.z
		if not bridge_shot and player.position.z < (-27 if number==1 else -19.7):
			bridge_shot=true
			check(player.get_node("Gimbal").global_position.distance_to(player.global_position)<2.5, "Level %d camera follows the player"%number)
			check(root.get_camera_3d()==player.get_node("Gimbal/Camera3D"), "Level %d uses the single player camera"%number)
			await screenshot("level_%d_bridge"%number)
	Input.action_release("move_forward")
	Input.action_release("jump")
	check(last_score==5,"Level %d all five coins collected on the route"%number)
	check(jump_index==jumps.size(),"Level %d crossed all %d planned gaps with single jumps"%[number,jumps.size()])

func go():
	change_scene_to_file("res://scenes/levels/level_1.tscn")
	await frames(30)
	var player=current_scene.get_node("Player")
	check(player.is_on_floor(),"Spawn rests on an island collider")
	check(player.move_speed==6 and player.jump_force==6,"Starter movement speed and jump force preserved")
	check(is_equal_approx(player.get_node("CollisionShape3D").shape.height,1.78),"Somchai capsule height")
	check(gm().score==0,"Fresh level starts at 0 / 5")
	# Locked-goal check, separate from the input-driven playthrough.
	player.global_position=current_scene.get_node("Goal").global_position+Vector3(0,0.12,0.5)
	player.velocity=Vector3.ZERO
	await frames(15)
	check(gm().level_number==1 and not gm().level_finished,"Goal rejects 0 / 5 coins")
	check(current_scene.get_node("HUD/UI/Message").text.contains("Collect all coins first!"),"Locked goal displays a clear message")
	change_scene_to_file("res://scenes/levels/level_1.tscn")
	await frames(30)
	# Walk to coin one, then walk off the side to exercise the real dead-zone signal.
	Input.action_press("move_forward")
	await frames(21)
	Input.action_release("move_forward")
	await frames(2)
	check(gm().score==1,"Collected one coin before fall recovery test")
	Input.action_press("move_right")
	await frames(65)
	Input.action_release("move_right")
	await frames(150)
	player=current_scene.get_node("Player")
	check(player.position.distance_to(Vector3(0,0,1.5))<0.3 and player.is_on_floor(),"Falling returns to the spawn safely")
	check(gm().score==1,"Collected coins remain collected after a fall")
	change_scene_to_file("res://scenes/levels/level_1.tscn")
	await frames(30)
	await screenshot("level_1")
	await traverse(1)
	await frames(15)
	check(current_scene.scene_file_path.ends_with("level_2.tscn"),"Level 1 goal loads level 2")
	check(gm().score==0,"Level 2 resets its own coin counter")
	if current_scene.scene_file_path.ends_with("level_2.tscn"):
		await screenshot("level_2")
		await traverse(2)
		await frames(20)
		check(gm().level_finished and current_scene.get_node("HUD/UI/WinPanel").visible,"Level 2 goal displays YOU WIN")
		check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"Win screen releases the mouse")
		await screenshot("you_win")
		# Click the actual Restart button with viewport mouse input events.
		var click:=InputEventMouseButton.new()
		click.button_index=MOUSE_BUTTON_LEFT
		click.position=current_scene.get_node("HUD/UI/WinPanel/Restart").get_global_rect().get_center()
		click.global_position=click.position
		click.pressed=true
		Input.parse_input_event(click)
		await frames(3)
		click=click.duplicate()
		click.pressed=false
		Input.parse_input_event(click)
		await frames(20)
		check(current_scene.scene_file_path.ends_with("level_1.tscn") and gm().score==0,"Restart button returns to fresh level 1")
	for state in ["Run","Jump","Fall"]:
		check(seen_states.has(state),"Movement drove Somchai %s animation"%state)
	var out:=OS.get_environment("POTATO_CAPTURE_DIR")
	var log=FileAccess.open(out.path_join("test_results.json"),FileAccess.WRITE)
	log.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"failures":failures,"checks":events,"states":seen_states,"trace":trace},"\t"))
	print("RESULT ","PASS" if failures.is_empty() else "FAIL"," (",failures.size()," failures)")
	quit(0 if failures.is_empty() else 1)





