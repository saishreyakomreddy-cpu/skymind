extends Node3D

const STAGE_COUNT := 6
const STAGE_DISTANCE := 3.4
const PLATFORM_X := 2.2
const PLATFORM_SIZE := Vector3(3.4, 0.45, 2.4)
const INTERACT_DISTANCE := 2.0
const MEMORY_SECONDS := 4.0

var rng := RandomNumberGenerator.new()
var real_sides: Array[int] = []
var platforms: Array[Array] = []
var current_stage := 0
var chances := 3
var crystals_found := 0
var symbols_visible := true
var door_unlocked := false
var player: CharacterBody3D
var mission_label: Label
var chances_label: Label
var energy_label: Label
var story_label: Label
var level_label: Label
var door: StaticBody3D
var menu_panel: PanelContainer


func _ready() -> void:
	rng.randomize()
	player = get_node_or_null("player") as CharacterBody3D
	mission_label = get_node_or_null("HUD/MissionLabel") as Label
	chances_label = get_node_or_null("HUD/ChancesLabel") as Label
	energy_label = get_node_or_null("HUD/EnergyLabel") as Label
	story_label = get_node_or_null("HUD/StoryLabel") as Label
	level_label = get_node_or_null("HUD/LevelLabel") as Label
	if player:
		player.global_position = Vector3(0, 1, 4)
	_build_memory_route()
	_update_hud()
	_create_menu()
	await get_tree().create_timer(MEMORY_SECONDS).timeout
	symbols_visible = false
	for pair in platforms:
		for platform in pair:
			var symbol := platform.get_node_or_null("MemorySymbol") as Label3D
			if symbol:
				symbol.visible = false
	if story_label:
		story_label.text = "The symbols are gone. Trust your memory and follow the glowing footprints."


func _process(_delta: float) -> void:
	if not player:
		return
	if current_stage < STAGE_COUNT:
		for side in 2:
			var platform: StaticBody3D = platforms[current_stage][side]
			if player.global_position.distance_to(platform.global_position) <= INTERACT_DISTANCE and player.global_position.y >= 0.65 and player.velocity.y <= 0.0:
				_resolve_platform(side)
				return
	else:
		var door_position := Vector3(0, 1, -STAGE_COUNT * STAGE_DISTANCE - 2.0)
		if player.global_position.distance_to(door_position) <= 3.0:
			get_tree().change_scene_to_file("res://final_simulation.tscn")


func is_forward_only() -> bool:
	return true


func _build_memory_route() -> void:
	_clear_old_layout()
	for stage in STAGE_COUNT:
		real_sides.append(rng.randi_range(0, 1))
		var pair: Array = []
		for side in 2:
			pair.append(_create_platform(stage, side))
		platforms.append(pair)
	_create_start_platform()
	_create_door()


func _clear_old_layout() -> void:
	for child in get_children():
		if child.name in ["Environment", "player", "HUD", "Camera3D"]:
			continue
		child.queue_free()


func _create_platform(stage: int, side: int) -> StaticBody3D:
	var platform := StaticBody3D.new()
	platform.name = "MemoryPlatform_%d_%d" % [stage + 1, side + 1]
	platform.position = Vector3(-PLATFORM_X if side == 0 else PLATFORM_X, 0, -stage * STAGE_DISTANCE)
	add_child(platform)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = PLATFORM_SIZE
	collision.shape = shape
	platform.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = PLATFORM_SIZE
	mesh.mesh = box
	mesh.material_override = _material(Color(0.08, 0.1, 0.14, 1), Color(0.04, 0.18, 0.24, 1))
	platform.add_child(mesh)
	var symbol := Label3D.new()
	symbol.name = "MemorySymbol"
	symbol.text = ["EYE", "MOON", "KEY", "CROWN", "STAR", "DOOR"][stage]
	symbol.font_size = 32
	symbol.outline_size = 8
	symbol.position.y = 0.45
	symbol.modulate = Color(0.65, 0.95, 1, 1)
	symbol.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	platform.add_child(symbol)
	_create_crystal(platform, stage, side)
	_create_footprint(platform)
	return platform


func _create_crystal(platform: StaticBody3D, stage: int, side: int) -> void:
	var crystal := MeshInstance3D.new()
	crystal.name = "OriginalOrDecoyCrystal"
	crystal.position = Vector3(0, 0.75, 0)
	crystal.mesh = _crystal_mesh()
	crystal.material_override = _material(Color(0.65, 0.95, 1, 1), Color(0.25, 0.8, 1, 1))
	crystal.set_meta("real", side == real_sides[stage])
	platform.add_child(crystal)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.35, 0.85, 1, 1)
	glow.light_energy = 2.0
	glow.omni_range = 4.0
	crystal.add_child(glow)


func _create_footprint(platform: StaticBody3D) -> void:
	var footprint := Label3D.new()
	footprint.text = "•  •  •"
	footprint.font_size = 24
	footprint.position = Vector3(0, 0.3, 0.65)
	footprint.modulate = Color(0.35, 0.8, 0.9, 0.8)
	footprint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	platform.add_child(footprint)


func _create_start_platform() -> void:
	var start := StaticBody3D.new()
	start.name = "TempleStart"
	start.position = Vector3(0, -0.25, 4)
	add_child(start)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(5.0, 0.5, 2.5)
	collision.shape = shape
	start.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = shape.size
	mesh.mesh = box
	mesh.material_override = _material(Color(0.08, 0.08, 0.1, 1))
	start.add_child(mesh)


func _create_door() -> void:
	door = StaticBody3D.new()
	door.name = "AncientMemoryDoor"
	door.position = Vector3(0, 2, -STAGE_COUNT * STAGE_DISTANCE - 2.0)
	add_child(door)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(5.0, 4.0, 0.5)
	collision.shape = shape
	door.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = shape.size
	mesh.mesh = box
	mesh.material_override = _material(Color(0.03, 0.04, 0.06, 1), Color(0.08, 0.3, 0.4, 1))
	door.add_child(mesh)
	var label := Label3D.new()
	label.text = "ANCIENT DOOR\nLOCKED"
	label.font_size = 38
	label.outline_size = 10
	label.position.z = -0.35
	label.modulate = Color(0.65, 0.95, 1, 1)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	door.add_child(label)


func _resolve_platform(side: int) -> void:
	var crystal := platforms[current_stage][side].get_node_or_null("OriginalOrDecoyCrystal") as Node3D
	var is_real: bool = crystal.get_meta("real", false)
	if is_real:
		crystals_found += 1
		current_stage += 1
		if mission_label:
			mission_label.text = "SYMBOL REMEMBERED. MOVE FORWARD."
	else:
		chances -= 1
		if mission_label:
			mission_label.text = "DUPLICATE! YOU LOST ONE CHANCE."
		if chances <= 0:
			if mission_label:
				mission_label.text = "YOU LOST! THE TEMPLE PATH CHANGES."
			await get_tree().create_timer(1.0).timeout
			get_tree().reload_current_scene()
			return
		await get_tree().create_timer(0.8).timeout
		get_tree().reload_current_scene()
		return
	if crystals_found >= STAGE_COUNT:
		_unlock_door()
	_update_hud()


func _unlock_door() -> void:
	door_unlocked = true
	if is_instance_valid(door):
		door.queue_free()
	_create_portal()
	if mission_label:
		mission_label.text = "YOU WON! THE ANCIENT DOOR IS OPEN."
	if story_label:
		story_label.text = "A strange glowing world waits beyond the memory door."
	if player:
		var character := player.get_node_or_null("BoyCharacter") as Node3D
		if character and character.has_method("celebrate"):
			character.celebrate()
	_update_hud()


func _create_portal() -> void:
	var portal := MeshInstance3D.new()
	portal.name = "Level4GlowPortal"
	portal.position = Vector3(0, 2, -STAGE_COUNT * STAGE_DISTANCE - 2.0)
	var mesh := TorusMesh.new()
	mesh.inner_radius = 1.2
	mesh.outer_radius = 1.5
	portal.mesh = mesh
	portal.material_override = _material(Color(0.1, 0.5, 0.7, 1), Color(0.2, 0.9, 1, 1))
	add_child(portal)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.2, 0.85, 1, 1)
	glow.light_energy = 5.0
	glow.omni_range = 12.0
	portal.add_child(glow)


func _update_hud() -> void:
	if level_label:
		level_label.text = "LEVEL 3: MEMORY TEMPLE"
	if energy_label:
		energy_label.text = "CRYSTALS: %d / %d" % [crystals_found, STAGE_COUNT]
	if chances_label:
		chances_label.text = "CHANCES: %d / 3" % chances
	if mission_label and not door_unlocked:
		mission_label.text = "Remember the symbols. Choose one platform at each stage."
	if story_label:
		story_label.visible = false
	var clue_label := get_node_or_null("HUD/ClueLabel") as Label
	if clue_label:
		clue_label.visible = false
	var key_label := get_node_or_null("HUD/KeyLabel") as Label
	if key_label:
		key_label.visible = false
	var puzzle_label := get_node_or_null("HUD/PuzzleLabel") as Label
	if puzzle_label:
		puzzle_label.visible = false


func _create_menu() -> void:
	var menu_button := Button.new()
	menu_button.name = "MenuButton"
	menu_button.text = "⋮"
	menu_button.tooltip_text = "Open menu"
	menu_button.position = Vector2(1000, 24)
	menu_button.size = Vector2(48, 42)
	menu_button.pressed.connect(_toggle_menu)
	get_node("HUD").add_child(menu_button)

	menu_panel = PanelContainer.new()
	menu_panel.name = "InstructionsMenu"
	menu_panel.visible = false
	menu_panel.position = Vector2(300, 120)
	menu_panel.size = Vector2(560, 330)
	get_node("HUD").add_child(menu_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	menu_panel.add_child(box)
	var title := Label.new()
	title.text = "MEMORY TEMPLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
	var instructions := Label.new()
	instructions.text = "MEMORIZE THE SIX SYMBOLS\nChoose one floating platform at each stage.\nMove forward only.\nCollect the real crystals and avoid duplicates.\nYou have 3 chances.\n\nWASD / ARROWS: MOVE    SPACE: JUMP    MOUSE: LOOK"
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(instructions)
	var close_button := Button.new()
	close_button.text = "CLOSE"
	close_button.pressed.connect(_toggle_menu)
	box.add_child(close_button)


func _toggle_menu() -> void:
	if menu_panel:
		menu_panel.visible = not menu_panel.visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if menu_panel.visible else Input.MOUSE_MODE_CAPTURED


func _crystal_mesh() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.18
	mesh.bottom_radius = 0.28
	mesh.height = 0.9
	mesh.radial_segments = 6
	return mesh


func _material(color: Color, emission: Color = Color(0, 0, 0, 1)) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.7
	if emission != Color(0, 0, 0, 1):
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 2.5
	return material
