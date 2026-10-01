extends Node3D

@export var flight_speed: float = 1.8
@export var flight_radius: float = 8.0
@export var wing_speed: float = 5.0

var start_position: Vector3
var flight_time: float = 0.0
var left_wing: MeshInstance3D
var right_wing: MeshInstance3D


func _ready() -> void:
	start_position = position
	_create_bird()


func _process(delta: float) -> void:
	flight_time += delta
	position = start_position + Vector3(
		sin(flight_time * flight_speed) * flight_radius,
		sin(flight_time * flight_speed * 1.7) * 0.8,
		cos(flight_time * flight_speed) * flight_radius * 0.35
	)
	rotation.y = sin(flight_time * flight_speed) * 0.35
	var flap: float = sin(flight_time * wing_speed) * 0.45
	left_wing.rotation.z = -0.35 - flap
	right_wing.rotation.z = 0.35 + flap


func _create_bird() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.005, 0.008, 0.03, 1)
	material.roughness = 0.9

	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.22
	body_mesh.height = 0.42
	var body := MeshInstance3D.new()
	body.mesh = body_mesh
	body.material_override = material
	body.scale = Vector3(1.6, 0.7, 0.8)
	add_child(body)

	var wing_mesh := BoxMesh.new()
	wing_mesh.size = Vector3(0.9, 0.04, 0.28)
	left_wing = MeshInstance3D.new()
	left_wing.mesh = wing_mesh
	left_wing.material_override = material
	left_wing.position = Vector3(-0.42, 0.02, 0)
	add_child(left_wing)
	right_wing = MeshInstance3D.new()
	right_wing.mesh = wing_mesh
	right_wing.material_override = material
	right_wing.position = Vector3(0.42, 0.02, 0)
	add_child(right_wing)