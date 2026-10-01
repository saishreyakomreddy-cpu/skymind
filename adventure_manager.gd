extends Node

var keys: Dictionary = {}
var discovered_areas: Dictionary = {"entrance": true}
var checkpoints: Dictionary = {}
var current_checkpoint_scene: String = ""
var current_checkpoint_position: Vector3 = Vector3.ZERO


func unlock_key(key_name: String) -> void:
	keys[key_name] = true


func has_key(key_name: String) -> bool:
	return keys.get(key_name, false)


func discover_area(area_name: String) -> void:
	discovered_areas[area_name] = true


func is_area_discovered(area_name: String) -> bool:
	return discovered_areas.get(area_name, false)


func save_checkpoint(scene_path: String, position: Vector3, checkpoint_name: String) -> void:
	checkpoints[checkpoint_name] = {
		"scene": scene_path,
		"position": position
	}
	current_checkpoint_scene = scene_path
	current_checkpoint_position = position


func has_checkpoint() -> bool:
	return current_checkpoint_scene != ""


func reset_adventure() -> void:
	keys.clear()
	discovered_areas = {"entrance": true}
	checkpoints.clear()
	current_checkpoint_scene = ""
	current_checkpoint_position = Vector3.ZERO