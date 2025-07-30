extends Node
class_name Scene

static func load_into(container:Node, scene_path:String) -> Node:
	if container == null:
		printerr("container node cannot be null!")
		return null
		
	var scn : PackedScene = load(scene_path)
	if scn == null:
		printerr("Unable to find scene: '%s'!" % scene_path)
		return null
	
	var inst = scn.instantiate()
	container.add_child(inst)
	return inst

static func exists(scene_path:String, hint:String="") -> bool: return ResourceLoader.exists(scene_path, hint)

static func reload(tree:SceneTree) -> Error: return tree.reload_current_scene()

static func change(tree:SceneTree, scene_path:String) -> Error: 
	return tree.change_scene_to_file(scene_path)

static func change_packed(tree:SceneTree, new_scene:PackedScene)-> Error: 
	return tree.change_scene_to_packed(new_scene)
