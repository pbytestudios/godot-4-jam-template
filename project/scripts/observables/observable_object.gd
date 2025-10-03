class_name ObservableObject
extends Observable

var value : Object:
	set(v):
		if value != null and value is Observable:
			value.reactive_changed.disconnect(_propagate)
		value = v
		if value != null and value is Observable:
			value.reactive_changed.connect(_propagate)
		_propagate()
		return value

func _init(val : Object, initial_owner : Observable = null) -> void:
	super._init(initial_owner)
	value = val
