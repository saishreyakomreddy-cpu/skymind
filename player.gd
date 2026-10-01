extends CharacterBody3D

const MOVE_SPEED: float = 5.5
const JUMP_VELOCITY: float = 6.5
const GRAVITY: float = 20.0
const FALL_LIMIT: float = -20.0
const MOUSE_SENSITIVITY: float = 0.0025
const MAX_LOOK_ANGLE: float = deg_to_rad(80.0)
const DOUBLE_JUMP_WINDOW: float = 0.3
const HIGH_JUMP_MULTIPLIER: float = 1.45

var health: float = 100.0
var energy_collected: int = 0
var max_energy: int = 3
var chances: int = 3
var is_lost: bool = false
var last_jump_press_time: float = -10.0
var high_jump_used: bool = false
var completion_layer: CanvasLayer
var completion_title: Label
var completion_message: Label
var completion_button: Button
var showing_level_two_intro: bool = false
var has_won: bool = false
@onready var camera: Camera3D = $Camera3D
@onready var energy_label: Label = get_node_or_null("../HUD/EnergyLabel") as Label
@onready var mission_label: Label = get_node_or_null("../HUD/MissionLabel") as Label
@onready var level_label: Label = get_node_or_null("../HUD/LevelLabel") as Label


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("player")
	var scene_path := get_tree().current_scene.scene_file_path
	if scene_path == "res://space_station.tscn":
		max_energy = 6
	elif scene_path == "res://ai_facility.tscn":
		max_energy = 8
	elif scene_path == "res://final_simulation.tscn":
		max_energy = 10
	if energy_label:
		energy_label.text = "ENERGY: 0 / %d" % max_energy


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x - event.relative.y * MOUSE_SENSITIVITY, -MAX_LOOK_ANGLE, MAX_LOOK_ANGLE)
	elif event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if is_on_floor():
		high_jump_used = false

	if Input.is_action_just_pressed("ui_accept"):
		var current_time := Time.get_ticks_msec() / 1000.0
		var is_double_press := current_time - last_jump_press_time <= DOUBLE_JUMP_WINDOW
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif is_double_press and not high_jump_used:
			velocity.y = JUMP_VELOCITY * HIGH_JUMP_MULTIPLIER
			high_jump_used = true
		last_jump_press_time = current_time

	var input_x := Input.get_axis("ui_left", "ui_right")
	var input_z := Input.get_axis("ui_up", "ui_down")
	var direction := Vector3(input_x, 0.0, input_z)

	if direction.length() > 0.0:
		direction = direction.normalized()

	var fear_puzzle = get_tree().current_scene if get_tree().current_scene.has_method("is_choice_locked") else null
	var memory_temple = get_tree().current_scene if get_tree().current_scene.has_method("is_forward_only") else null
	if fear_puzzle:
		direction.z = min(direction.z, 0.0)
		if fear_puzzle.is_choice_locked():
			direction.x = 0.0
	elif memory_temple:
		direction.z = min(direction.z, 0.0)

	if direction.length() > 0.0:
		direction = direction.normalized()
		velocity.x = direction.x * MOVE_SPEED
		velocity.z = direction.z * MOVE_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, MOVE_SPEED)
		velocity.z = move_toward(velocity.z, 0.0, MOVE_SPEED)

	move_and_slide()
	if not fear_puzzle and not memory_temple:
		_collect_nearby_crystals()
		_check_decoy_crystals()

	if global_position.y < FALL_LIMIT:
		_show_loss()


func _collect_nearby_crystals() -> void:
	for crystal in get_tree().get_nodes_in_group("energy_crystal"):
		if is_instance_valid(crystal) and global_position.distance_to(crystal.global_position) <= 2.0:
			crystal.queue_free()
			energy_collected += 1
			if energy_label:
				energy_label.text = "ENERGY: %d / %d" % [energy_collected, max_energy]
			if energy_collected >= max_energy and not has_won:
				has_won = true
				var scene_path := get_tree().current_scene.scene_file_path
				if scene_path == "res://skymindsimulation.tscn":
					if mission_label:
						mission_label.text = "YOU WON!"
					_show_level_one_completion()
				else:
					if mission_label:
						mission_label.text = "YOU WON!"
					if level_label:
						level_label.text = "LEVEL COMPLETE - YOU WON!"


func _check_decoy_crystals() -> void:
	for decoy in get_tree().get_nodes_in_group("decoy_crystal"):
		if is_instance_valid(decoy) and global_position.distance_to(decoy.global_position) <= 1.5:
			decoy.queue_free()
			chances -= 1
			var chances_label := get_node_or_null("../HUD/ChancesLabel") as Label
			if chances_label:
				chances_label.text = "CHANCES: %d / 3" % chances
			if mission_label:
				mission_label.text = "DECOY CRYSTAL! CHOOSE THE ZEBRA PATH!"
			if chances <= 0:
				_show_loss()


func _show_level_one_completion() -> void:
	if completion_layer:
		return
	set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	completion_layer = CanvasLayer.new()
	completion_layer.layer = 200
	add_child(completion_layer)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.01, 0.02, 0.04, 0.92)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	completion_layer.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	completion_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(540, 280)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	completion_title = Label.new()
	completion_title.text = "YOU WON!"
	completion_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	completion_title.add_theme_font_size_override("font_size", 30)
	box.add_child(completion_title)

	completion_message = Label.new()
	completion_message.text = "FORGOTTEN MIND COMPLETE"
	completion_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	completion_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	completion_message.add_theme_font_size_override("font_size", 18)
	box.add_child(completion_message)

	completion_button = Button.new()
	completion_button.text = "NEXT"
	completion_button.custom_minimum_size = Vector2(0, 48)
	completion_button.pressed.connect(_on_transition_button_pressed)
	box.add_child(completion_button)


func _on_transition_button_pressed() -> void:
	if not showing_level_two_intro:
		showing_level_two_intro = true
		completion_title.text = "LEVEL 2: FEAR"
		completion_message.text = "The station is afraid of you.\nCollect 6 pale cyan crystals to survive."
		completion_button.text = "START LEVEL 2"
		return
	get_tree().change_scene_to_file("res://space_station.tscn")


func _show_loss() -> void:
	if is_lost:
		return
	is_lost = true
	var mission_label := get_node_or_null("../HUD/MissionLabel") as Label
	if mission_label:
		mission_label.text = "YOU LOST!"
	await get_tree().create_timer(1.2).timeout
	get_tree().reload_current_scene()


func take_damage(amount: float) -> void:
	health = max(0.0, health - amount)
	if health <= 0.0:
		print("Player defeated")
