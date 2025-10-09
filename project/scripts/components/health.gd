extends Node
class_name Health

signal depleated
signal max_set(val:float)
signal changed(new_val:float)

@export var max_value:int = 10:
	get: return max_value
	set(val):
		max_value = val
		max_set.emit(max_value)

var value:float = 0:
	get: return value
	set(val):
		val = clamp(val, 0.0, max_value)
		prev = value
		value = val
		changed.emit(value)
		if prev != 0.0 && value == 0.0:
			depleated.emit()

var prev:float = 0:
	get: return prev

var normalized:float:
	get: return value / float(max_value)

func _ready():
	reset()
	max_set.emit(max_value)

func reset(): 
	value = max_value
	prev = value
