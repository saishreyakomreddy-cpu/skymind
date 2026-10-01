extends RigidBody3D

var spawn_position: Vector3


func _ready() -> void:
	spawn_position = global_position


func _physics_process(_delta: float) -> void:
	if global_position.y < -20.0:
		global_position = spawn_position
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
