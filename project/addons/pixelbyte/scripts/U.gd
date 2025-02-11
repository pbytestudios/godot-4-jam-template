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
#non-recursive version of the above function
static func get_children(parent:Node, child_type) -> Array:
	var arr:Array = []
	for child in parent.get_children():
		if is_instance_of(child, child_type):
			arr.push_back(child)
	return arr

static func get_children_rec(parent:Node, child_type, array:Array):
	if parent.get_child_count() > 0:
		for child in parent.get_children():
			get_children_rec(child, child_type, array)
	elif is_instance_of(parent, child_type):
		array.push_back(parent)

static func get_first_child(parent:Node, type):
	for i in range(parent.get_child_count()):
		if is_instance_of(parent.get_child(i), type):
			return parent.get_child(i)
	return null

static func get_first_child_rec(parent:Node, type):
	if is_instance_of(parent, type):
		return parent
	for i in range(parent.get_child_count()):
		var ch = get_first_child_rec(parent.get_child(i), type)
		if ch:	return ch
	return null
	
static func free_children(parent:Node) -> void:
	if !is_instance_valid(parent):
		return
	for child in parent.get_children():
		child.queue_free()

static func clear_subscribers(sig:Signal):
	var sub_info:Array = sig.get_connections()
	for con in sub_info:
		sig.disconnect(con.callable)

# gets the specific properties of a node with the given hint_string
# use the following to mark a variable:
# @export_custom(PROPERTY_HINT_NONE, "your_hint_name_here")
# var examle:int = 0
static func get_props_with_hint(n:Node, hint_string:String) -> PackedStringArray:
	var names:PackedStringArray = []
	for p in n.get_property_list():
		if p.hint_string == hint_string:
			names.append(p.name)
	return names
