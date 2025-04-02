class_name Level
extends Node

@export_multiline var title = ""
@export_multiline var speech = ""

var player:Player:
	get: return player
	
func _ready() -> void:
	#if OS.has_feature("editor"):
			#var root_scene_name = get_tree().current_scene.scene_file_path
			#if !root_scene_name.contains("game.tscn"):
				## todo: tell the scene we are loading that we want it to load this level!
				#Scene.change.call_deferred(get_tree(), "res://screens/game.tscn")
			
	for node in get_children():
		if node is Player:
			player = node
			break
		
