class_name ObservableBool
extends Observable

var value:bool:
	set(val):
		value = val
		_propagate()

func _init(_val:bool = false, _owner:Observable = null) -> void:
	super._init(_owner)
	value = _val
