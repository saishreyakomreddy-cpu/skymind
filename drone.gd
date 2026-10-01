extends Node3D

@export var patrol_distance: float = 5.0
@export var patrol_speed: float = 0.8
@export var detection_range: float = 5.0

var start_position: Vector3
var patrol_time: float = 0.0
var attack_timer: float = 0.0
var player: Variant


func _ready() -> void:
	start_position = position
	player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	patrol_time += delta * patrol_speed
	position = start_position + Vector3(sin(patrol_time) * patrol_distance, sin(patrol_time * 2.0) * 0.5, 0)
	rotation.y += delta

	if not is_instance_valid(player):
		return

	attack_timer -= delta
	if global_position.distance_to(player.global_position) <= detection_range and attack_timer <= 0.0:
		player.take_damage(5)
		attack_timer = 2.0
