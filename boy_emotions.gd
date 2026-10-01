extends Node3D

var emotion_label: Label3D
var emotion_tween: Tween
var dance_tween: Tween
var base_position: Vector3


func _ready() -> void:
	base_position = position
	emotion_label = Label3D.new()
	emotion_label.name = "Emotion"
	emotion_label.font_size = 34
	emotion_label.outline_size = 8
	emotion_label.position = Vector3(0, 1.65, 0.15)
	emotion_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	emotion_label.modulate = Color(0.65, 0.95, 1, 1)
	add_child(emotion_label)
	set_emotion("focused")


func set_emotion(emotion: String) -> void:
	if not emotion_label:
		return
	if emotion_tween and emotion_tween.is_valid():
		emotion_tween.kill()
	match emotion:
		"smile":
			emotion_label.text = ":)"
			emotion_label.modulate = Color(0.45, 1, 0.55, 1)
		"sad":
			emotion_label.text = ":("
			emotion_label.modulate = Color(1, 0.45, 0.45, 1)
		"focused":
			emotion_label.text = "..."
			emotion_label.modulate = Color(0.65, 0.95, 1, 1)


func celebrate() -> void:
	set_emotion("smile")
	if dance_tween and dance_tween.is_valid():
		dance_tween.kill()
	var left_arm := get_node_or_null("LeftArm") as Node3D
	var right_arm := get_node_or_null("RightArm") as Node3D
	dance_tween = create_tween().set_loops(10)
	dance_tween.set_parallel(true)
	dance_tween.tween_property(self, "rotation:z", 0.16, 0.22).set_trans(Tween.TRANS_SINE)
	dance_tween.tween_property(self, "position:y", base_position.y + 0.2, 0.22).set_trans(Tween.TRANS_SINE)
	if left_arm:
		dance_tween.tween_property(left_arm, "rotation:z", -1.1, 0.22).set_trans(Tween.TRANS_SINE)
	if right_arm:
		dance_tween.tween_property(right_arm, "rotation:z", 1.1, 0.22).set_trans(Tween.TRANS_SINE)
	dance_tween.chain().set_parallel(true)
	dance_tween.tween_property(self, "rotation:z", -0.16, 0.22).set_trans(Tween.TRANS_SINE)
	dance_tween.tween_property(self, "position:y", base_position.y, 0.22).set_trans(Tween.TRANS_SINE)
	if left_arm:
		dance_tween.tween_property(left_arm, "rotation:z", -0.2, 0.22).set_trans(Tween.TRANS_SINE)
	if right_arm:
		dance_tween.tween_property(right_arm, "rotation:z", 0.2, 0.22).set_trans(Tween.TRANS_SINE)
