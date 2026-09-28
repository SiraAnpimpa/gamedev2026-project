extends SceneTree

var failures := []
var evidence := []

func _initialize(): go.call_deferred()

func frames(n: int):
	for i in n: await physics_frame

func trial(scene: Node3D, gap: Dictionary, jump: bool, margin: float) -> bool:
	var player=scene.get_node("Player")
	Input.action_release("move_forward")
	Input.action_release("jump")
	player.position=Vector3(0,gap.before_y+0.12,gap.start+1.5)
	player.velocity=Vector3.ZERO
	player.get_node("Gimbal").rotation=Vector3.ZERO
	await frames(25)
	var pressed:=false
	var held:=0
	var landed:=false
	Input.action_press("move_forward")
	for i in 150:
		await physics_frame
		if held>0:
			held-=1
			if held==0: Input.action_release("jump")
		if jump and not pressed and player.position.z<=gap.takeoff+margin and player.is_on_floor():
			Input.action_press("jump")
			pressed=true
			held=2
		if player.position.z<gap.end-0.5 and player.is_on_floor():
			landed=true
			break
		if player.position.y<minf(gap.before_y,gap.after_y)-0.75: break
	Input.action_release("move_forward")
	Input.action_release("jump")
	return landed

func go():
	for level in [1,2]:
		change_scene_to_file("res://scenes/levels/level_%d.tscn"%level)
		await frames(30)
		var scene=current_scene
		var gaps: Array=load("res://tools/gap_profile.gd").new().scan(scene,scene.get_node("Player"))
		if gaps.size()!=5: failures.append("Expected five required gaps in level %d"%level)
		for i in gaps.size():
			var gap: Dictionary=gaps[i]
			var walked:bool=await trial(scene,gap,false,0.0)
			var jump_early:bool=await trial(scene,gap,true,0.2)
			var jump_late:bool=await trial(scene,gap,true,-0.2)
			var passed:bool=not walked and jump_early and jump_late
			var record={"level":level,"gap":i+1,"edge_gap_m":gap.width,"walk_crossed":walked,"single_jump_early_landed":jump_early,"single_jump_late_landed":jump_late,"passed":passed}
			evidence.append(record)
			print("PASS " if passed else "FAIL ",JSON.stringify(record))
			if not passed: failures.append(record)
	var log=FileAccess.open(OS.get_environment("POTATO_CAPTURE_DIR").path_join("gap_validation.json"),FileAccess.WRITE)
	log.store_string(JSON.stringify({"failures":failures,"trials":evidence},"\t"))
	print("GAP RESULT ","PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
