class_name Controller
extends Node

signal control_enabled(enabled:bool)

## If enabled then the controller sends valid dats
## Otherwise not
var enabled:bool = true:
	get: return enabled
	set(val): 
		enabled = val
		control_enabled.emit(enabled)

# Could be used to get the direction the player wants to move
func dir() -> Vector2: 
	if !enabled:
		return _disabled_vector2()
	else:
		return _dir()

# Determine diretion to "fire" 
func fire_dir() -> Vector2:
	if !enabled:
		return _disabled_vector2()
	else:
		return _fire_dir()
		
func forward() -> float:
	if !enabled:
		return _disabled_float()
	else:
		return _forward()
				
func actionA() -> bool:
	if !enabled:
		return _disabled_bool()
	else:
		return _actionA()
		
func actionB() -> bool:
	if !enabled:
		return _disabled_bool()
	else:
		return _actionB()

func actionC() -> bool:
	if !enabled:
		return _disabled_bool()
	else:
		return _actionC()
		
func actionD() -> bool:
	if !enabled:
		return _disabled_bool()
	else:
		return _actionD()

## optionally override these to chage disabled values	
func _disabled_vector2() -> Vector2: return Vector2.ZERO
func _disabled_float() -> float: return 0
func _disabled_bool() -> bool: return false

## Override these methods to implement a controller

func _dir() -> Vector2: return Vector2.ZERO
func _forward() -> float: return 0
func _fire_dir() -> Vector2: return Vector2.ZERO
func _actionA() -> bool: return false
func _actionB() -> bool: return false
func _actionC() -> bool: return false
func _actionD() -> bool: return false
