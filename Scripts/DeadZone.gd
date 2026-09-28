extends Area3D

@onready var spawn_position = %SpawnPosition

func _on_body_entered(body):
	if body.is_in_group("Player"):
		respawn.call_deferred(body)

func respawn(player):
	if not is_instance_valid(player):
		return
	player.velocity = Vector3.ZERO
	player.global_position = spawn_position.global_position
	player.can_double_jump = false
	player.get_node("Gimbal").global_position = player.global_position
