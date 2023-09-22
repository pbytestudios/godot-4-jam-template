extends Node
class_name Scene

static func load_into(container:Node, scene_path:String) -> Node:
	var scn : PackedScene = load(scene_path)
	if scn == null:
		printerr("Enable to find scene: '%s'!" % scene_path)
		return null
	
	var inst = scn.instantiate()
	container.add_child(inst)
	return inst

static func reload(tree:SceneTree) -> Error: return tree.reload_current_scene()

static func change(tree:SceneTree, scene_path:String) -> Error: return tree.change_scene_to_file(scene_path)
