@abstract class_name Controller
extends Node

signal control_enabled(enabled:bool)

## optionally override these in your _ready() function	
var disabled_vec2:Vector2 = Vector2.ZERO
# var disabled_float:float = 0.0
var disabled_bool:bool = false

## If enabled then the controller sends valid data
var enabled:bool = true:
	get: return enabled && is_node_ready()
	set(val): 
		enabled = val
		control_enabled.emit(enabled)

# Could be used to get the direction the player wants to move
# func dir() -> Vector2: 
# 	if !enabled:
# 		return disabled_vec2
# 	else:
# 		return _dir()
				
# func actionA() -> bool:
# 	if !enabled:
# 		return disabled_bool
# 	else:
# 		return _actionA()


## Override these methods to implement a controller
# func _dir() -> Vector2: return disabled_vec2
# func _actionA() -> bool: return disabled_bool
