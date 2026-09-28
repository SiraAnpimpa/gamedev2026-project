extends RefCounted

func scan(scene: Node3D, player: CharacterBody3D) -> Array:
	var gaps := []
	var in_gap := false
	var start := 0.0
	var last_height := 0.0
	var before := 0.0
	var z := 0.0
	while z > scene.get_node("Goal").position.z:
		var ray := PhysicsRayQueryParameters3D.create(Vector3(0,8,z),Vector3(0,-7,z),1)
		ray.exclude = [player.get_rid()]
		var hit := scene.get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.is_empty() and not in_gap:
			in_gap = true
			start = z
			before = last_height
		elif not hit.is_empty():
			if in_gap and absf(start-z) > 1.0:
				gaps.append({"start":start,"end":z,"width":absf(start-z),"before_y":before,"after_y":hit.position.y,"takeoff":start+0.65})
			in_gap = false
			last_height = hit.position.y
		z -= 0.05
	return gaps
