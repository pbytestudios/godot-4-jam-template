class_name ObservableFloat
extends Observable

var value:float:
	set(val):
		value = val
		_propagate()

func _init(_val:float, _owner:Observable = null) -> void:
	super._init(_owner)
	value = _val
