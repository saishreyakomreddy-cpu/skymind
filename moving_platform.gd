extends AnimatableBody3D

@export var travel_distance: float = 4.0
@export var travel_speed: float = 1.5

var start_position: Vector3
var travel_time: float = 0.0


func _ready() -> void:
	start_position = position


func _physics_process(delta: float) -> void:
	travel_time += delta * travel_speed
	position = start_position + Vector3(sin(travel_time) * travel_distance, 0, 0)
