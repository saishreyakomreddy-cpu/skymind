extends Control

@onready var instructions: Label = $CenterContainer/Panel/VBox/Instructions
@onready var intro_overlay: Control = $IntroOverlay
@onready var menu_container: Control = $CenterContainer


func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	intro_overlay.visible = false
	menu_container.visible = true
	$CenterContainer/Panel/VBox/PlayButton.grab_focus()


func _on_play_button_pressed() -> void:
	AdventureManager.reset_adventure()
	get_tree().change_scene_to_file("res://skymindsimulation.tscn")


func _on_how_to_play_button_pressed() -> void:
	instructions.visible = not instructions.visible


func _on_quit_button_pressed() -> void:
	get_tree().quit()
