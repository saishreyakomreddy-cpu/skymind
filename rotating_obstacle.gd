extends AnimatableBody3D

@export var rotation_speed: float = 1.5


func _physics_process(delta: float) -> void:
	rotate_y(rotation_speed * delta)
