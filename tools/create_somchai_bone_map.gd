extends SceneTree

const MODEL_PATH := "res://assets/characters/somchai/model/Somchai_rigged.glb"
const MAP_PATH := "res://assets/characters/somchai/SomchaiBoneMap.tres"

func _initialize() -> void:
	var model := (load(MODEL_PATH) as PackedScene).instantiate()
	var skeleton := model.get_node("SomchaiRig/Skeleton3D") as Skeleton3D
	var profile := SkeletonProfileHumanoid.new()
	var bone_map := BoneMap.new()
	bone_map.profile = profile
	var count := 0
	for i in profile.get_bone_size():
		var profile_name := profile.get_bone_name(i)
		if skeleton.find_bone(profile_name) >= 0:
			bone_map.set_skeleton_bone_name(profile_name, profile_name)
			count += 1
	for side in ["Left", "Right"]:
		for finger in ["Index", "Middle", "Ring", "Little"]:
			var index := ["Index", "Middle", "Ring", "Little"].find(finger)
			bone_map.set_skeleton_bone_name(side + finger + "Proximal", side + "Finger" + str(index))
			count += 1
		bone_map.set_skeleton_bone_name(side + "ThumbProximal", side + "Thumb")
		count += 1
	for required in ["Hips", "Spine", "Chest", "Neck", "Head", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"]:
		assert(bone_map.get_skeleton_bone_name(required) == required)
	var result := ResourceSaver.save(bone_map, MAP_PATH)
	print("SOMCHAI_BONEMAP_SAVE ", result, " mapped_bones=", count, " skeleton_bones=", skeleton.get_bone_count())
	model.free()
	quit(0 if result == OK else 1)
