extends Node
class_name P

static func free_children(parent:Node) -> void:
	for child in parent.get_children():
		child.queue_free()


#static func exists(path:String, hint:String="") -> bool: return ResourceLoader.exists(path, hint)
