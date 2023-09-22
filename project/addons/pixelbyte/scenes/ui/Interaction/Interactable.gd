extends Area2D
class_name Interactable

# the text that will be shown above the interactable when it can be interacted with
@export var action_name:String = "Interact"

# Offsets the interaction text this amount from this object's global position
# if you want an offset, simply add one when you instantiate this node in your object
@export var offset_marker : Marker2D

#this is what we use to determine the label's offset from the object's global pos
var label_offset_local: Vector2:
	get: return offset_marker.position if is_instance_valid(offset_marker) else Vector2.ZERO

# Point this callable to your interact function
var interact: Callable  = func (): pass

func _on_body_entered(body: Node2D) -> void:
	InteractMgr.register(self)

func _on_body_exited(body: Node2D) -> void:
	InteractMgr.unregister(self)
