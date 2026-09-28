extends SceneTree

var failed := false

func check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failed = true

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	check(InputMap.has_action("walk"), "walk input action")
	var walk_keys := InputMap.action_get_events("walk")
	check(walk_keys.size() == 1 and walk_keys[0] is InputEventKey and walk_keys[0].physical_keycode == KEY_CTRL, "walk is bound to Ctrl")
	check(InputMap.has_action("jump"), "Lab05 jump input action")
	var scene := load("res://scenes/levels/level_1.tscn") as PackedScene
	check(scene != null, "Lab05 level 1 loads")
	if scene == null:
		quit(1)
		return
	var level := scene.instantiate()
	root.add_child(level)
	await frames(20)
	var player := level.get_node_or_null("Player") as CharacterBody3D
	check(player != null, "Lab05 Player remains in main scene")
	if player == null:
		quit(1)
		return
	var somchai := player.get_node_or_null("Visual/Juice/Motion/Alignment/Somchai")
	check(somchai != null, "Somchai replaces Potato visual")
	check(player.find_child("Potato", true, false) == null, "old Potato visual absent")
	var skeleton := player.get_node_or_null("Visual/Juice/Motion/Alignment/Somchai/SomchaiRig/Skeleton3D") as Skeleton3D
	check(skeleton != null and skeleton.get_bone_count() == 32, "Somchai 32-bone humanoid skeleton")
	var bone_map := load("res://assets/characters/somchai/SomchaiBoneMap.tres") as BoneMap
	check(bone_map != null and bone_map.profile is SkeletonProfileHumanoid, "Godot humanoid BoneMap loads")
	if skeleton != null and bone_map != null:
		var all_mapped := true
		for index in skeleton.get_bone_count():
			all_mapped = all_mapped and bone_map.find_profile_bone_name(skeleton.get_bone_name(index)) != &""
		check(all_mapped, "all 32 Somchai bones map to humanoid profile")
	var ap := player.get_node_or_null("Visual/Juice/Motion/Alignment/Somchai/AnimationPlayer") as AnimationPlayer
	check(ap != null, "AnimationPlayer resolves from controller")
	if ap == null:
		quit(1)
		return
	for state in ["Idle", "Walk", "Run", "Jump", "Fall", "Flip"]:
		check(ap.has_animation(state), state + " animation exists")
	check(ap.current_animation == "Idle" and ap.is_playing(), "Idle plays on game start")
	check(ap.get_animation("Idle").loop_mode == Animation.LOOP_LINEAR, "Idle loops")
	var collision := player.get_node("CollisionShape3D") as CollisionShape3D
	var capsule := collision.shape as CapsuleShape3D
	check(capsule != null and absf(capsule.height - 1.78) < 0.01 and absf(capsule.radius - 0.39) < 0.01, "capsule fits Somchai")
	check(player.get_node_or_null("Gimbal/Camera3D") is Camera3D, "Lab05 camera remains attached")
	check(player.is_on_floor(), "player starts grounded")
	var start_position := player.global_position
	Input.action_press("move_forward")
	await frames(20)
	check(ap.current_animation == "Run", "default movement plays Run")
	check(player.global_position.distance_to(start_position) > 0.5, "Lab05 movement still works")
	Input.action_press("walk")
	await frames(10)
	check(ap.current_animation == "Walk", "Ctrl movement plays Walk")
	check(absf(Vector2(player.velocity.x, player.velocity.z).length() - 3.6) < 0.2, "walk speed is 3.6")
	Input.action_release("walk")
	Input.action_release("move_forward")
	await frames(10)
	check(ap.current_animation == "Idle", "movement returns to Idle")
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	check(player.velocity.y > 0.0, "Lab05 jump still works")
	check(ap.current_animation == "Jump", "jump plays Jump")
	await frames(32)
	check(ap.current_animation == "Fall" or ap.current_animation == "Idle", "fall or landing animation plays")
	level.queue_free()
	await process_frame
	quit(1 if failed else 0)
