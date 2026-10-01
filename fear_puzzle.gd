extends Node3D

const STAGE_COUNT: int = 6
const BOX_SIZE := Vector3(3.6, 0.55, 2.4)
const STAGE_DISTANCE: float = 3.2
const BOX_HEIGHT: float = 0.0
const PLAYER_LAND_HEIGHT: float = 1.05
const TEST_MODE: bool = false
const TEST_REAL_SIDES: Array[int] = [0, 1, 0, 1, 0, 1]
const SHOW_VICTORY_DEMO: bool = false

var rng := RandomNumberGenerator.new()
var real_sides: Array[int] = []
var stage_boxes: Array[Array] = []
var current_stage: int = 0
var choice_locked: bool = false
var chances: int = 3
var crystals_found: int = 0
var door_body: StaticBody3D
var door_label: Label3D
var player: CharacterBody3D
var energy_label: Label
var mission_label: Label
var chances_label: Label
var story_label: Label
var status_label: Label
var victory_started: bool = false


func _ready() -> void:
	rng.randomize()
	player = get_node_or_null("player") as CharacterBody3D
	energy_label = get_node_or_null("HUD/EnergyLabel") as Label
	mission_label = get_node_or_null("HUD/MissionLabel") as Label
	chances_label = get_node_or_null("HUD/ChancesLabel") as Label
	story_label = get_node_or_null("HUD/StoryLabel") as Label
	status_label = get_node_or_null("HUD/LevelLabel") as Label
	_clear_old_layout()
	_build_puzzle()
	_update_hud()
	if SHOW_VICTORY_DEMO:
		await get_tree().create_timer(1.5).timeout
		_unlock_door()


func _process(_delta: float) -> void:
	if not is_instance_valid(player) or current_stage >= STAGE_COUNT or choice_locked:
		return
	for side in 2:
		var box: StaticBody3D = stage_boxes[current_stage][side]
		if abs(player.global_position.x - box.global_position.x) <= 1.7 and abs(player.global_position.z - box.global_position.z) <= 1.2 and player.global_position.y >= PLAYER_LAND_HEIGHT and player.velocity.y <= 0.0:
			_resolve_choice(side)
			return


func is_choice_locked() -> bool:
	return choice_locked


func _clear_old_layout() -> void:
	for child in get_children():
		if child == self or child.name in ["Environment", "player", "HUD", "Camera3D"]:
			continue
		if child.is_in_group("energy_crystal") or child.is_in_group("decoy_crystal") or child.name in ["StationFloor", "StationDeck", "StationWing", "StationLight", "StationCamp"] or child.name.begins_with("ZebraStep"):
			child.free()


func _build_puzzle() -> void:
	for index in STAGE_COUNT:
		real_sides.append(TEST_REAL_SIDES[index] if TEST_MODE else rng.randi_range(0, 1))
		var pair: Array = []
		for side in 2:
			var box := _create_box(index, side)
			pair.append(box)
			_create_crystal(index, side, box)
		stage_boxes.append(pair)
	_create_start_platform()
	_create_door()
	
	if story_label:
		story_label.text = "FEAR PROTOCOL: Choose one box at every stage. Once you land, only forward remains."


func _create_box(stage: int, side: int) -> StaticBody3D:
	var box := StaticBody3D.new()
	box.name = "FearBox_%d_%d" % [stage + 1, side + 1]
	box.position = Vector3(-2.2 if side == 0 else 2.2, BOX_HEIGHT, -stage * STAGE_DISTANCE)
	box.set_meta("stage", stage)
	box.set_meta("side", side)
	add_child(box)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = BOX_SIZE
	collision.shape = shape
	box.add_child(collision)

	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = BOX_SIZE
	mesh.mesh = box_mesh
	mesh.material_override = _make_material(Color(0.96, 0.96, 0.96, 1) if (stage + side) % 2 == 0 else Color(0.035, 0.035, 0.04, 1))
	box.add_child(mesh)

	var marker := Label3D.new()
	marker.text = "REAL" if TEST_MODE and side == real_sides[stage] else ("DUPLICATE" if TEST_MODE else "?")
	marker.font_size = 52
	marker.outline_size = 10
	marker.position.y = 0.5
	marker.modulate = Color(0.45, 1, 0.55, 1) if side == real_sides[stage] else Color(1, 0.4, 0.4, 1)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	box.add_child(marker)
	return box


func _create_crystal(stage: int, side: int, box: StaticBody3D) -> void:
	var crystal := MeshInstance3D.new()
	crystal.name = "MysteryCrystal_%d_%d" % [stage + 1, side + 1]
	crystal.position = box.position + Vector3(0, 0.7, 0)
	crystal.mesh = _make_crystal_mesh()
	crystal.material_override = _make_material(Color(0.65, 0.95, 1, 1), Color(0.25, 0.8, 1, 1))
	add_child(crystal)

	var glow := OmniLight3D.new()
	glow.light_color = Color(0.35, 0.85, 1, 1)
	glow.light_energy = 2.2
	glow.omni_range = 4.5
	crystal.add_child(glow)


func _create_start_platform() -> void:
	var start := StaticBody3D.new()
	start.name = "FearStartPlatform"
	start.position = Vector3(0, -0.25, 4.0)
	add_child(start)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(5.0, 0.5, 2.5)
	collision.shape = shape
	start.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = shape.size
	mesh.mesh = box_mesh
	mesh.material_override = _make_material(Color(0.08, 0.08, 0.1, 1))
	start.add_child(mesh)


func _create_door() -> void:
	var exit_platform := StaticBody3D.new()
	exit_platform.name = "FearExitPlatform"
	exit_platform.position = Vector3(0, -0.25, -STAGE_COUNT * STAGE_DISTANCE - 1.2)
	add_child(exit_platform)
	var exit_collision := CollisionShape3D.new()
	var exit_shape := BoxShape3D.new()
	exit_shape.size = Vector3(5.0, 0.5, 3.0)
	exit_collision.shape = exit_shape
	exit_platform.add_child(exit_collision)
	var exit_mesh := MeshInstance3D.new()
	var exit_box_mesh := BoxMesh.new()
	exit_box_mesh.size = exit_shape.size
	exit_mesh.mesh = exit_box_mesh
	exit_mesh.material_override = _make_material(Color(0.75, 0.78, 0.8, 1), Color(0.2, 0.35, 0.4, 1))
	exit_platform.add_child(exit_mesh)

	door_body = StaticBody3D.new()
	door_body.name = "FearLockedDoor"
	door_body.position = Vector3(0, 2.2, -STAGE_COUNT * STAGE_DISTANCE - 2.6)
	add_child(door_body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(5.0, 4.4, 0.5)
	collision.shape = shape
	door_body.add_child(collision)
	var mesh := MeshInstance3D.new()
	var door_mesh := BoxMesh.new()
	door_mesh.size = shape.size
	mesh.mesh = door_mesh
	mesh.material_override = _make_material(Color(0.025, 0.025, 0.03, 1), Color(0.05, 0.1, 0.12, 1))
	door_body.add_child(mesh)
	door_label = Label3D.new()
	door_label.text = "LOCKED\n6 CRYSTALS REQUIRED"
	door_label.font_size = 42
	door_label.outline_size = 12
	door_label.position = Vector3(0, 0, -0.3)
	door_label.modulate = Color(0.65, 0.95, 1, 1)
	door_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	door_body.add_child(door_label)


func _resolve_choice(side: int) -> void:
	choice_locked = true
	var chosen_box: StaticBody3D = stage_boxes[current_stage][side]
	if side == real_sides[current_stage]:
		crystals_found += 1
		if energy_label:
			energy_label.text = "CRYSTALS: %d / %d" % [crystals_found, STAGE_COUNT]
		if mission_label:
			mission_label.text = "ORIGINAL FOUND. MOVE FORWARD."
		current_stage += 1
		if current_stage >= STAGE_COUNT:
			_unlock_door()
		else:
			await get_tree().create_timer(0.7).timeout
			choice_locked = false
	else:
		chances -= 1
		if chances_label:
			chances_label.text = "CHANCES: %d / 3" % chances
		if mission_label:
			mission_label.text = "YOU LOST! DUPLICATE CRYSTAL."
		_set_boy_emotion("sad")
		if chances <= 0:
			if mission_label:
				mission_label.text = "YOU LOST! THE PATH HAS CHANGED."
			await get_tree().create_timer(1.0).timeout
			get_tree().reload_current_scene()
			return
		await get_tree().create_timer(0.8).timeout
		player.global_position = Vector3(0, 1, 4)
		player.velocity = Vector3.ZERO
		choice_locked = false


func _unlock_door() -> void:
	victory_started = true
	choice_locked = true
	if is_instance_valid(door_body):
		door_body.queue_free()
	if mission_label:
		mission_label.text = "YOU WON! THE DOOR IS OPEN."
	if story_label:
		story_label.text = "The boy smiles and dances. The fear was only a pattern."
	if is_instance_valid(player):
		player.set_physics_process(false)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_set_boy_emotion("smile")
		_start_victory_dance()


func _set_boy_emotion(emotion: String) -> void:
	var character := player.get_node_or_null("BoyCharacter") as Node3D
	if character and character.has_method("set_emotion"):
		character.set_emotion(emotion)


func _start_victory_dance() -> void:
	var character := player.get_node_or_null("BoyCharacter") as Node3D
	if not character:
		return
	if character.has_method("celebrate"):
		character.celebrate()
		return
	var mouth := character.get_node_or_null("Mouth") as Node3D
	var left_arm := character.get_node_or_null("LeftArm") as Node3D
	var right_arm := character.get_node_or_null("RightArm") as Node3D
	var torso := character.get_node_or_null("Torso") as Node3D
	if mouth:
		mouth.scale = Vector3(1.8, 0.7, 1.0)
		mouth.position.y = 0.82
	var smile := Label3D.new()
	smile.name = "VictorySmile"
	smile.text = ":-)"
	smile.font_size = 28
	smile.outline_size = 6
	smile.position = Vector3(0, 0.86, 0.34)
	smile.modulate = Color(0.65, 0.95, 1, 1)
	smile.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	character.add_child(smile)

	var dance := create_tween().set_loops(8)
	dance.set_parallel(true)
	dance.tween_property(character, "rotation:z", 0.16, 0.18).set_trans(Tween.TRANS_SINE)
	dance.tween_property(character, "position:y", 0.62, 0.18).set_trans(Tween.TRANS_SINE)
	dance.tween_property(left_arm, "rotation:z", -1.0, 0.18).set_trans(Tween.TRANS_SINE)
	dance.tween_property(right_arm, "rotation:z", 1.0, 0.18).set_trans(Tween.TRANS_SINE)
	dance.chain().set_parallel(true)
	dance.tween_property(character, "rotation:z", -0.16, 0.18).set_trans(Tween.TRANS_SINE)
	dance.tween_property(character, "position:y", 0.4, 0.18).set_trans(Tween.TRANS_SINE)
	dance.tween_property(left_arm, "rotation:z", -0.2, 0.18).set_trans(Tween.TRANS_SINE)
	dance.tween_property(right_arm, "rotation:z", 0.2, 0.18).set_trans(Tween.TRANS_SINE)
	if torso:
		torso.scale = Vector3(1.08, 1.08, 1.08)


func _update_hud() -> void:
	if status_label:
		status_label.text = "LEVEL 2: FEAR"
	if energy_label:
		energy_label.text = "CRYSTALS: 0 / %d" % STAGE_COUNT
	if chances_label:
		chances_label.text = "CHANCES: %d / 3" % chances
	if mission_label:
		mission_label.text = "Choose one box at each stage. Collect all 6 originals."


func _make_crystal_mesh() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.18
	mesh.bottom_radius = 0.28
	mesh.height = 0.9
	mesh.radial_segments = 6
	return mesh


func _make_material(color: Color, emission: Color = Color(0, 0, 0, 1)) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.7
	if emission != Color(0, 0, 0, 1):
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 2.5
	return material
