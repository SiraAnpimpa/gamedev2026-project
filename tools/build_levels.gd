extends SceneTree

const SMALL = "res://assets/small_platformer/"
const EXTRA = "res://assets/ultimate_platformer/"
var report := {}

func _initialize():
	build.call_deferred()

func add(parent: Node, child: Node, node_name: String) -> Node:
	child.name = node_name
	parent.add_child(child)
	return child

func meshes(node: Node, transform := Transform3D.IDENTITY) -> Array:
	var result := []
	if node is Node3D:
		transform = transform * node.transform
	if node is MeshInstance3D and node.mesh:
		result.append([node, transform])
	for child in node.get_children():
		result.append_array(meshes(child, transform))
	return result

func bounds(node: Node) -> AABB:
	var box := AABB()
	var first := true
	for entry in meshes(node):
		var b: AABB = entry[1] * entry[0].mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box

func own(node: Node, owner_root: Node):
	for child in node.get_children():
		child.owner = owner_root
		if child.scene_file_path.ends_with(".tscn"):
			continue
		if child.scene_file_path.ends_with(".glb"):
			child.scene_file_path = ""
		own(child, owner_root)

func save_scene(node: Node, path: String):
	own(node, node)
	var packed := PackedScene.new()
	assert(packed.pack(node) == OK)
	assert(ResourceSaver.save(packed, path) == OK)
	print("SAVED ", path)

func model(parent: Node, file: String, node_name: String) -> Node3D:
	return add(parent, load(file).instantiate(), node_name)

func tint(node: Node, stone: bool):
	for entry in meshes(node):
		var m: MeshInstance3D = entry[0]
		for i in m.mesh.get_surface_count():
			var original = m.get_active_material(i)
			if original is StandardMaterial3D:
				var material: StandardMaterial3D = original.duplicate()
				if stone:
					material.albedo_color = Color("718899") if i == 1 else Color("4c5d70")
				elif material.resource_name == "Grass":
					material.albedo_color = Color("75b65a")
				elif material.resource_name == "Dirt":
					material.albedo_color = Color("977556")
				material.roughness = 0.9
				m.set_surface_override_material(i, material)

func fit(parent: Node, file: String, node_name: String, size: Vector3, top: bool, yaw := 0.0) -> Node3D:
	var holder: Node3D = add(parent, Node3D.new(), node_name)
	var asset := model(holder, file, "Model")
	asset.rotation.y = yaw
	var box := bounds(asset)
	holder.scale = size / box.size
	var center := box.get_center()
	center.y = box.end.y if top else box.position.y
	holder.position = -center * holder.scale
	return holder

func collision_for(parent: Node3D, visual: Node3D):
	# Bake the model transforms into triangles: collision follows the visible mesh.
	var faces := PackedVector3Array()
	for entry in meshes(visual):
		for point in entry[0].mesh.get_faces():
			faces.append(entry[1] * point)
	var body: StaticBody3D = add(parent, StaticBody3D.new(), "Solid")
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var collider: CollisionShape3D = add(body, CollisionShape3D.new(), "CollisionShape3D")
	collider.shape = shape

func platform(parent: Node, file: String, node_name: String, pos: Vector3, size: Vector3, stone := false):
	var node: Node3D = add(parent, Node3D.new(), node_name)
	node.position = pos
	var visual := fit(node, SMALL + file + ".glb", "Visual", size, true)
	tint(visual, stone)
	collision_for(node, visual)
	return node

func decor(parent: Node, file: String, pos: Vector3, height: float, yaw := 0.0, small := false):
	var holder: Node3D = add(parent, Node3D.new(), file.replace(" ", "") + str(parent.get_child_count()))
	holder.position = pos
	var asset := model(holder, (SMALL if small else EXTRA) + file + ".glb", "Model")
	asset.rotation.y = yaw
	var box := bounds(asset)
	var ratio := height / box.size.y
	asset.scale *= ratio
	asset.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z) * ratio
	return holder

func track(animation: Animation, path: String, times: Array, values: Array):
	var index := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(index, NodePath(path))
	for i in times.size():
		animation.track_insert_key(index, times[i], values[i])

func build_player():
	var player: Node3D = load("res://scenes/player.tscn").instantiate()
	load("res://tools/build_potato.gd").new().build(player)
	save_scene(player, "res://scenes/player.tscn")
	player.free()

func build_coin():
	var coin := Area3D.new()
	coin.name = "Coin"
	coin.set_script(load("res://Scripts/Coin.gd"))
	coin.collision_layer = 0
	coin.collision_mask = 1
	coin.add_to_group("Coins", true)
	var visual := model(coin, SMALL + "Coin.glb", "CoinModel")
	visual.scale = Vector3.ONE * 2.0
	visual.rotation.y = PI / 2.0
	var cs: CollisionShape3D = add(coin, CollisionShape3D.new(), "CollisionShape3D")
	var sphere := SphereShape3D.new()
	sphere.radius = 0.72
	cs.shape = sphere
	save_scene(coin, "res://scenes/gameplay/coin.tscn")
	coin.free()

func style(color: Color, radius := 16) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	return box

func label(parent: Node, node_name: String, text: String, pos: Vector2, size: Vector2, font_size: int, color := Color.WHITE) -> Label:
	var l: Label = add(parent, Label.new(), node_name)
	l.text = text
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func panel(parent: Node, node_name: String, pos: Vector2, size: Vector2, color: Color) -> Panel:
	var p: Panel = add(parent, Panel.new(), node_name)
	p.position = pos
	p.size = size
	p.add_theme_stylebox_override("panel", style(color))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

func build_hud(scene: Node, level: int):
	var layer := add(scene, CanvasLayer.new(), "HUD")
	var ui: Control = add(layer, Control.new(), "UI")
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.set_script(load("res://Scripts/GameUI.gd"))
	var ink := Color("18372e") if level == 1 else Color("243347")
	var bg := Color(ink, 0.92)
	panel(ui, "TitleBackground", Vector2(24,24), Vector2(405,100), bg)
	label(ui, "Chapter", "POTATO ISLANDS    /    0%d" % level, Vector2(44,36), Vector2(365,24), 15, Color("efd892"))
	label(ui, "Title", "Grass Islands" if level == 1 else "Stone Islands", Vector2(43,58), Vector2(368,52), 32)
	var cp := panel(ui, "CoinBackground", Vector2.ZERO, Vector2(210,68), bg)
	cp.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	cp.offset_left = -234; cp.offset_right = -24; cp.offset_top = 24; cp.offset_bottom = 92
	var coin_label := label(ui, "CoinsLabel", "Coins: 0 / 5", Vector2.ZERO, Vector2(182,44), 26, Color("ffe093"))
	coin_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	coin_label.offset_left=-215; coin_label.offset_right=-34; coin_label.offset_top=36; coin_label.offset_bottom=80
	var objective := label(ui, "Objective", "Collect all 5 coins, then find the flag", Vector2(30,134), Vector2(570,32), 19)
	objective.add_theme_color_override("font_shadow_color", Color(0,0,0,0.65))
	objective.add_theme_constant_override("shadow_offset_y",2)
	var footer := panel(ui, "Footer", Vector2.ZERO, Vector2(620,46), bg)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	footer.offset_left=24; footer.offset_right=678; footer.offset_top=-70; footer.offset_bottom=-24
	var help := label(footer, "Controls", "W A S D  Move     SPACE  Jump     MOUSE  Look     ESC  Cursor", Vector2(18,9), Vector2(625,30), 17)
	help.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var msg := label(ui, "Message", "", Vector2.ZERO, Vector2(940,44), 24, Color("fff2c8"))
	msg.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	msg.offset_left=-470;msg.offset_right=470;msg.offset_top=183;msg.offset_bottom=227
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_color_override("font_shadow_color", Color("243347"))
	msg.add_theme_constant_override("shadow_offset_y",2)
	msg.visible=false
	var shade: ColorRect = add(ui, ColorRect.new(), "WinShade")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03,0.07,0.1,0.72)
	shade.visible=false
	var win := panel(ui,"WinPanel",Vector2.ZERO,Vector2(490,310),Color("f7f0dc"))
	win.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	win.offset_left=-245;win.offset_right=245;win.offset_top=-155;win.offset_bottom=155
	win.visible=false
	var overline:=label(win,"Complete","BOTH ISLANDS COMPLETE",Vector2(30,31),Vector2(430,24),15,ink)
	overline.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var title:=label(win,"WinTitle","YOU WIN!",Vector2(30,63),Vector2(430,65),46,ink)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var sub:=label(win,"Summary","All Coins Collected\n10 / 10 coins across 2 levels",Vector2(30,132),Vector2(430,59),20,ink)
	sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var button: Button = add(win,Button.new(),"Restart")
	button.text="Restart"
	button.position=Vector2(125,219);button.size=Vector2(240,57)
	button.add_theme_font_size_override("font_size",22)
	button.add_theme_stylebox_override("normal",style(ink,12))
	button.add_theme_stylebox_override("hover",style(Color("447963"),12))
	button.add_theme_stylebox_override("pressed",style(Color("315646"),12))

func environment(scene: Node, level: int):
	var env_root := add(scene,Node3D.new(),"Environment")
	# Reuse the starter's Environment resource and sun, with a simple procedural sky.
	var old: Node = load("res://scenes/demo_scene.tscn").instantiate()
	var env: Environment = old.get_node("Environment/WorldEnvironment").environment.duplicate()
	var sun: DirectionalLight3D = old.get_node("Environment/DirectionalLight3D").duplicate()
	old.free()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color=Color("5292bf") if level==1 else Color("6d7fa6")
	sky_mat.sky_horizon_color=Color("d5e7df") if level==1 else Color("dfdbe0")
	sky_mat.ground_bottom_color=Color("94b8c4")
	sky_mat.ground_horizon_color=sky_mat.sky_horizon_color
	var sky := Sky.new()
	sky.sky_material=sky_mat
	env.background_mode=Environment.BG_SKY;env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("d4e4f1");env.ambient_light_energy=0.5
	env.reflected_light_source=0
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR;env.tonemap_exposure=1.0
	env.ssao_enabled=false;env.ssr_enabled=false;env.ssil_enabled=false;env.glow_enabled=false
	env.adjustment_enabled=false
	var world: WorldEnvironment = add(env_root,WorldEnvironment.new(),"WorldEnvironment")
	world.environment=env
	add(env_root,sun,"DirectionalLight3D")
	sun.rotation_degrees=Vector3(-48,-30,0)
	sun.light_color=Color("fff2d4");sun.light_energy=0.85
	sun.directional_shadow_max_distance=100

func bridge(parent: Node, pos: Vector3):
	var node: Node3D = add(parent,Node3D.new(),"SmallBridge")
	node.position=pos
	# The supplied bridge runs along X; rotate it to follow the route along -Z.
	var visual := fit(node,EXTRA+"Small Bridge.glb","Visual",Vector3(2.8,1.5,6.0),false,PI/2.0)
	# Mesh collision includes the actual planks and railings, without an oversized box.
	collision_for(node,visual)
	return node

func build_level(level: int):
	var scene := Node3D.new()
	scene.name="GrassIslands" if level==1 else "StoneIslands"
	scene.set_script(load("res://Scripts/gameplay/level.gd"))
	scene.level_number=level
	scene.next_level="res://scenes/levels/level_2.tscn" if level==1 else ""
	var route := add(scene,Node3D.new(),"Platforms")
	# Centers, top heights, and diameters. Gaps are 1.8–2.0 m between mesh edges: walking cannot cross, one jump can.
	var data := [
		["Large Island",Vector3(0,0,0),Vector3(8,4.4,8)],
		["Grass Platform",Vector3(0,0.10,-8.0),Vector3(4.4,1.0,4.4)],
		["Grass Platform",Vector3(0,0.20,-14.2),Vector3(4.4,1.0,4.4)],
		["Medium Island",Vector3(0,0.20,-21.7),Vector3(7,4.3,7)],
		["Island",Vector3(0,0.20,-33.1),Vector3(6.4,3.3,6.4)],
		["Grass Platform",Vector3(0,0.30,-40.3),Vector3(4.4,1.0,4.4)],
		["Large Island",Vector3(0,0.30,-48.8),Vector3(9,5.0,9)]
	]
	if level==2:
		data=[
			["Island",Vector3(0,0,0),Vector3(8,4.0,8)],
			["Stone Platform",Vector3(0,0.25,-8.1),Vector3(4.4,0.9,4.4)],
			["Stone Platform",Vector3(0,0.50,-14.4),Vector3(4.4,0.9,4.4)],
			["Medium Island",Vector3(0,0.50,-25.3),Vector3(7,4.8,7)],
			["Stone Platform",Vector3(0,0.70,-33.0),Vector3(4.6,1.0,4.6)],
			["Stone Platform",Vector3(0,0.90,-39.5),Vector3(4.6,1.0,4.6)],
			["Large Island",Vector3(0,0.90,-48.7),Vector3(10,5.3,10)]
		]
	for i in data.size():
		var d: Array=data[i]
		platform(route,d[0],"Step%02d_%s"%[i,d[0].replace(" ","")],d[1],d[2],level==2)
	var bpos:=Vector3(0,-0.04,-27.4) if level==1 else Vector3(0,0.26,-19.7)
	bridge(route,bpos)
	var player := model(scene,"res://scenes/player.tscn","Player")
	player.position=Vector3(0,0.15,1.5)
	var spawn: Marker3D=add(scene,Marker3D.new(),"SpawnPosition")
	spawn.position=player.position;spawn.unique_name_in_owner=true
	var dead: Area3D=add(scene,Area3D.new(),"DeadZone")
	dead.set_script(load("res://Scripts/DeadZone.gd"))
	dead.position=Vector3(0,-14,-20);dead.collision_layer=0
	var box:=BoxShape3D.new();box.size=Vector3(250,12,250)
	var cs: CollisionShape3D=add(dead,CollisionShape3D.new(),"CollisionShape3D");cs.shape=box
	dead.body_entered.connect(Callable(dead,"_on_body_entered"), CONNECT_PERSIST)
	var coins:=add(scene,Node3D.new(),"Coins")
	var positions := [Vector3(0,1.05,-1),data[1][1]+Vector3.UP*1.05,data[3][1]+Vector3.UP*1.05,bpos+Vector3.UP*1.29,data[6][1]+Vector3(0,1.05,1.5)]
	if level==2:
		positions=[Vector3(0,1.05,-1),data[2][1]+Vector3.UP*1.05,data[3][1]+Vector3.UP*1.05,data[4][1]+Vector3.UP*1.05,data[6][1]+Vector3(0,1.05,1.5)]
	for i in positions.size():
		var coin:=model(coins,"res://scenes/gameplay/coin.tscn","Coin%d"%(i+1))
		coin.position=positions[i]
	var goal: Area3D=add(scene,Area3D.new(),"Goal")
	goal.set_script(load("res://Scripts/gameplay/goal.gd"));goal.collision_layer=0
	goal.position=data[6][1]+Vector3(0,0,-2.0)
	decor(goal,"Flag" if level==1 else "Goal Flag",Vector3.ZERO,3.0,0,level==1)
	var gc: CollisionShape3D=add(goal,CollisionShape3D.new(),"CollisionShape3D")
	var gs:=CylinderShape3D.new();gs.radius=1.05;gs.height=2.5;gc.shape=gs;gc.position.y=1.1
	var goal_label: Label3D=add(goal,Label3D.new(),"GoalLabel")
	goal_label.text="GOAL";goal_label.position=Vector3(0,3.6,0)
	goal_label.font_size=48;goal_label.pixel_size=0.015;goal_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	goal_label.modulate=Color("fff0b2")
	var decorations:=add(scene,Node3D.new(),"Decorations")
	for i in [0,3,6]:
		var p:Vector3=data[i][1]
		if level==1:
			decor(decorations,"Tree",p+Vector3(-2.25,-0.08,0.2),2.9,0,true)
			decor(decorations,"Small Rock",p+Vector3(2.1,-0.08,0.5),0.65,0,true)
			decor(decorations,"Small Plant",p+Vector3(-1.9,0,1.5),0.48)
		else:
			decor(decorations,"Cube Bricks",p+Vector3(-2.3,-0.03,0.4),1.25,0.2)
			decor(decorations,"Rock",p+Vector3(2.3,-0.08,0.6),1.0,0.5)
			decor(decorations,"Small Plant",p+Vector3(2.1,0,1.8),0.36)
		decor(decorations,"Fence",p+Vector3(2.6,0,-0.9),0.9,PI/2.0)
	decor(decorations,"Arrow Sign",Vector3(1.9,0,-1.7),1.45,PI/2.0)
	decor(decorations,"Arrow Sign",data[3][1]+Vector3(1.6,0,-1.6),1.25,PI/2.0)
	decor(decorations,"Cube Crate",data[0][1]+Vector3(-2.1,0,2.0),0.95,0.3)
	decor(decorations,"Large Rock",data[4][1]+Vector3(-1.8,-0.1,0.7),0.85,0,true)
	if level==2:
		decor(decorations,"Tower",data[6][1]+Vector3(3.0,-0.1,-3.2),6.6)
		decor(decorations,"Chest",data[6][1]+Vector3(-2.5,-0.08,-1.4),0.9)
	else:
		platform(decorations,"Island","TowerIsland",Vector3(12,-2,data[6][1].z+5),Vector3(8,7,8))
		decor(decorations,"Tower",Vector3(12,-2.1,data[6][1].z+5),6.8)
	for i in 13:
		var side:float=-1.0 if i%2==0 else 1.0
		decor(decorations,"Cloud",Vector3(side*(12+(i%3)*4),-3+(i%3)*3,-i*6+8),1.6+(i%3)*0.5,0.2*i)
	environment(scene,level)
	build_hud(scene,level)
	save_scene(scene,"res://scenes/levels/level_%d.tscn"%level)
	report["level_%d"%level]={"route":str(data),"coins":str(positions),"bridge":str(bpos)}
	scene.free()

func build():
	build_player()
	build_coin()
	build_level(1)
	build_level(2)
	var file:=FileAccess.open("res://tools/build_report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	quit()





