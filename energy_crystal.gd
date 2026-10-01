extends MeshInstance3D

@export var bob_height: float = 0.18
@export var bob_speed: float = 2.0
@export var rotation_speed: float = 1.5
@export var pulse_speed: float = 3.0

var start_position: Vector3
var animation_time: float = 0.0
var glow: OmniLight3D


func _ready() -> void:
	start_position = position
	glow = OmniLight3D.new()
	glow.light_color = Color(0.25, 0.85, 1.0)
	glow.light_energy = 1.4
	glow.omni_range = 3.5
	add_child(glow)


func _process(delta: float) -> void:
	animation_time += delta * bob_speed
	position = start_position + Vector3(0, sin(animation_time) * bob_height, 0)
	rotate_y(rotation_speed * delta)
	var pulse: float = 1.0 + sin(animation_time * pulse_speed) * 0.08
	scale = Vector3.ONE * pulse
	glow.light_energy = 1.2 + sin(animation_time * pulse_speed) * 0.35
