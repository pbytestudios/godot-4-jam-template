class_name RayCastVision2D
extends RayCast2D

class VisionResult:
	var visible:bool = false
	var position:Vector2 = Vector2.INF
	var dir:Vector2 = Vector2.ZERO

## How far the vision ray can "see"
## 0.0 means infinite distance
@export var max_vision_distance:float = 0.0:
	get: return max_vision_distance
	set(val):
		max_vision_distance = abs(val)


## Returns a dictionary with keys "visible", "position", and "dir" if the node is visible, 
## otherwise returns an empty dictionary.
func can_see(node:Node2D) -> Dictionary:
	if !is_instance_valid(node):
		return {}
	
	target_position = to_local(node.global_position)
	force_raycast_update()
	
	if is_colliding() && get_collider() == node:
		if max_vision_distance > 0.0 && global_position.distance_squared_to(node.global_position) > max_vision_distance * max_vision_distance:
			return {}
		return {
			"visible": true,
			"position": node.global_position,
			# "col" : get_collider(),
			"dir": (node.global_position - global_position).normalized()
		}

	return {}
