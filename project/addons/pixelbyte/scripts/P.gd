extends Node
class_name P

static func free_children(parent:Node) -> void:
	if !is_instance_valid(parent):
		return
	for child in parent.get_children():
		child.queue_free()
