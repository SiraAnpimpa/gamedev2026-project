extends RefCounted

# The supplied GLB has disconnected body/limb geometry, but no skeleton.
# Preserve its triangles and UVs, and animate five simple pivoted visual parts.
var parents := PackedInt32Array()

func mesh_entries(node: Node, transform := Transform3D.IDENTITY) -> Array:
	var result := []
	if node is Node3D: transform = transform * node.transform
	if node is MeshInstance3D: result.append([node, transform])
	for child in node.get_children(): result.append_array(mesh_entries(child, transform))
	return result

func find_root(index: int) -> int:
	while parents[index] != index:
		parents[index] = parents[parents[index]]
		index = parents[index]
	return index

func join(a: int, b: int):
	parents[find_root(a)] = find_root(b)

func child(parent: Node, node_name: String) -> Node3D:
	var node := Node3D.new()
	node.name = node_name
	parent.add_child(node)
	return node

func track(animation: Animation, path: String, values: Array, times: Array):
	var index := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(index, NodePath(path))
	for i in times.size(): animation.track_insert_key(index, times[i], values[i])

func build(player: Node3D):
	var old := player.get_node("Visual")
	player.remove_child(old)
	old.free()
	var visual := child(player, "Visual")
	visual.rotation.y = PI
	var juice := child(visual, "Juice")
	var motion := child(juice, "Motion")
	var alignment := child(motion, "Alignment")
	var potato := child(alignment, "Potato")
	var source: Node3D = load("res://assets/player/potato.glb").instantiate()
	source.rotation.y = -PI / 2.0
	var entry: Array = mesh_entries(source)[0]
	var mesh_instance: MeshInstance3D = entry[0]
	var transform: Transform3D = entry[1]
	var box: AABB = transform * mesh_instance.mesh.get_aabb()
	var ratio := 1.36 / box.size.y
	var offset := Vector3(box.get_center().x, box.position.y, box.get_center().z)
	var arrays: Array = mesh_instance.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var points := PackedVector3Array()
	parents.resize(vertices.size())
	var welded := {}
	for i in vertices.size():
		parents[i] = i
		var point := (transform * vertices[i] - offset) * ratio
		points.append(point)
		var key := point.snapped(Vector3.ONE * 0.000001)
		if welded.has(key): join(i, welded[key])
		else: welded[key] = i
	for i in range(0, indices.size(), 3):
		join(indices[i], indices[i+1])
		join(indices[i], indices[i+2])
	var component_bounds := {}
	for i in points.size():
		var id := find_root(i)
		if component_bounds.has(id): component_bounds[id] = component_bounds[id].expand(points[i])
		else: component_bounds[id] = AABB(points[i], Vector3.ZERO)
	var component_parts := {}
	for id in component_bounds:
		var b: AABB = component_bounds[id]
		var part := "Body"
		if b.end.x < -0.17 and b.position.y > 0.70: part = "LeftArm"
		elif b.position.x > 0.17 and b.position.y > 0.70: part = "RightArm"
		elif b.end.x < 0.0 and b.end.y < 0.5: part = "LeftLeg"
		elif b.position.x > 0.0 and b.end.y < 0.5: part = "RightLeg"
		component_parts[id] = part
	var pivots := {"Body": Vector3.ZERO, "LeftArm": Vector3(-0.20,0.783,0), "RightArm": Vector3(0.20,0.783,0), "LeftLeg": Vector3(-0.168,0.43,0), "RightLeg": Vector3(0.168,0.43,0)}
	var material: StandardMaterial3D = mesh_instance.get_active_material(0).duplicate()
	material.metallic = 0.0
	material.roughness = 0.75
	var total_triangles := 0
	for part in pivots:
		var new_positions := PackedVector3Array()
		var new_normals := PackedVector3Array()
		var new_uvs := PackedVector2Array()
		var new_indices := PackedInt32Array()
		var remap := {}
		for i in range(0, indices.size(), 3):
			if component_parts[find_root(indices[i])] != part: continue
			for corner in 3:
				var original := indices[i+corner]
				if not remap.has(original):
					remap[original] = new_positions.size()
					var point: Vector3 = points[original] - pivots[part]
					var normal := (transform.basis.inverse().transposed() * normals[original]).normalized()
					# Relax the cartoon's very long arms without lowering hands into the floor.
					if part.ends_with("Arm"):
						point.x *= 0.72
						normal.x /= 0.72
					new_positions.append(point)
					new_normals.append(normal.normalized())
					new_uvs.append(uvs[original])
				new_indices.append(remap[original])
		assert(not new_indices.is_empty(), "Missing Potato part: " + part)
		total_triangles += new_indices.size() / 3
		var new_arrays := []
		new_arrays.resize(Mesh.ARRAY_MAX)
		new_arrays[Mesh.ARRAY_VERTEX] = new_positions
		new_arrays[Mesh.ARRAY_NORMAL] = new_normals
		new_arrays[Mesh.ARRAY_TEX_UV] = new_uvs
		new_arrays[Mesh.ARRAY_INDEX] = new_indices
		var part_mesh := ArrayMesh.new()
		part_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, new_arrays)
		part_mesh.surface_set_material(0, material)
		var path := "res://assets/player/potato_%s.tres" % part.to_snake_case()
		assert(ResourceSaver.save(part_mesh, path) == OK)
		var pivot := child(potato, part)
		pivot.position = pivots[part]
		var piece := MeshInstance3D.new()
		piece.name = "Mesh"
		piece.mesh = part_mesh
		pivot.add_child(piece)
		if part == "LeftArm": pivot.rotation.z = deg_to_rad(75.0)
		if part == "RightArm": pivot.rotation.z = deg_to_rad(-75.0)
	assert(total_triangles == indices.size()/3, "All source triangles must be retained exactly once")
	print("Potato: retained ", total_triangles, " triangles in five visual parts; relaxed arms and animated legs")
	source.free()
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	visual.add_child(ap)
	var library := AnimationLibrary.new()
	var path := "Juice/Motion/Alignment/Potato/"
	for state in ["Idle", "Run", "Jump", "Fall", "Flip", "RESET"]:
		var a := Animation.new()
		a.length = 1.8 if state == "Idle" else 0.48
		if state in ["Idle", "Run"]: a.loop_mode = Animation.LOOP_LINEAR
		var times := [0.0,a.length/4.0,a.length/2.0,a.length*0.75,a.length]
		var arm_l := []; var arm_r := []; var leg_l := []; var leg_r := []; var bounce := []; var torso := []
		for i in 5:
			var wave := sin(float(i) * PI / 2.0)
			var swing := wave * 0.62 if state == "Run" else wave * 0.035
			var spread := deg_to_rad(75.0)
			var bend := 0.0
			var tilt := 0.0
			if state in ["Jump", "Flip"]:
				spread = deg_to_rad(52.0); swing = -0.30; bend = -0.25; tilt = -0.10
			elif state == "Fall":
				spread = deg_to_rad(58.0); swing = 0.20; bend = 0.18; tilt = 0.10
			arm_l.append(Vector3(swing,0,spread))
			arm_r.append(Vector3(-swing if state == "Run" else swing,0,-spread))
			leg_l.append(Vector3(-wave*0.55 if state == "Run" else bend,0,0))
			leg_r.append(Vector3(wave*0.55 if state == "Run" else bend,0,0))
			bounce.append(Vector3(0,absf(wave)*0.065 if state == "Run" else 0.0,0))
			torso.append(Vector3(tilt,0,-wave*0.025 if state == "Run" else 0))
		track(a,path+"LeftArm:rotation",arm_l,times)
		track(a,path+"RightArm:rotation",arm_r,times)
		track(a,path+"LeftLeg:rotation",leg_l,times)
		track(a,path+"RightLeg:rotation",leg_r,times)
		track(a,"Juice/Motion:position",bounce,times)
		track(a,"Juice/Motion:rotation",torso,times)
		track(a,path+"Body:scale",[Vector3.ONE,Vector3(1,1.012,1),Vector3.ONE],[0.0,a.length/2.0,a.length])
		library.add_animation(state,a)
	ap.add_animation_library("",library)
	ap.autoplay = "Idle"
