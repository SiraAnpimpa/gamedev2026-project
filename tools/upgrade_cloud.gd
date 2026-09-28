extends SceneTree
func _initialize():
	var mesh=load("res://assets/Resources/cloud.res")
	print("Mesh upgrade saved: ", ResourceSaver.save(mesh,"res://assets/Resources/cloud.res"))
	quit()
