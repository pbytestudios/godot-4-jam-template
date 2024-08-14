#
# Pixelbyte utilities and such
#
class_name U
extends RefCounted

#
# Given a node, a type, and an empty array, this function
# returns ALL the sub-nodes of the given type
# Note: This function can be called multiple times on the same
# array as it will not erase anything already in it
#
static func get_children_of_type_rec(parent:Node, child_type, array:Array):
	if parent.get_child_count() > 0:
		for child in parent.get_children():
			get_children_of_type_rec(child, child_type, array)
	elif is_instance_of(parent, child_type):
		array.push_back(parent)
	
#non-recursive version of the above function
static func get_children_of_type(parent:Node, child_type) -> Array:
	var arr:Array = []
	for child in parent.get_children():
		if is_instance_of(child, child_type):
			arr.push_back(child)
	return arr

static func get_first_child_of_type_rec(parent:Node, type):
	for i in range(parent.get_child_count()):
		var ch = _get_first_child_rec(parent.get_child(i), type)
		if ch:	return ch
	return null

static func _get_first_child_rec(parent:Node, type):
	if is_instance_of(parent, type):
		return parent
	for i in range(parent.get_child_count()):
		var ch = _get_first_child_rec(parent.get_child(i), type)
		if ch:	return ch
	return null
	
static func get_first_child_of_type(parent:Node, type):
	for i in range(parent.get_child_count()):
		if is_instance_of(parent.get_child(i), type):
			return parent.get_child(i)
	return null

static func free_children(parent:Node) -> void:
	if !is_instance_valid(parent):
		return
	for child in parent.get_children():
		child.queue_free()
