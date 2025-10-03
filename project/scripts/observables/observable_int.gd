class_name ObservableInt
extends Observable

var value:int:
	set(val):
		value = val
		_propagate()

func _init(_val:int, _owner:Observable = null) -> void:
	super._init(_owner)
	value = _val
