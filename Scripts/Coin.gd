extends Area3D

# The starter kit's hover, pickup signal, score and sound are reused.
@export_category("Properties")
@export var follow_speed := 6.0
@export var amplitude := 0.12
@export var frequency := 3.0
var time_passed := 0.0
var is_in_range := false
var collected := false
var initial_position := Vector3.ZERO
@onready var player := get_tree().get_first_node_in_group("Player")

func _ready():
	initial_position = position
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _process(delta):
	coin_hover(delta)
	rotate_y(delta * 1.8)
	if is_in_range and is_instance_valid(player):
		follow_player(delta)

func coin_hover(delta):
	time_passed += delta
	position.y = initial_position.y + amplitude * sin(frequency * time_passed)

func follow_player(delta):
	global_position = global_position.move_toward(player.global_position + Vector3.UP * 0.7, follow_speed * delta)

func _on_body_entered(body):
	if body.is_in_group("Player") and not collected:
		collected = true
		GameManager.add_score()
		AudioManager.coin_sfx.play()
		queue_free()

func _on_range_body_entered(body):
	if body.is_in_group("Player"):
		is_in_range = true

