class_name ObservableString
extends Observable

var value:String:
	set(val):
		value = val
		_propagate()

func _init(_val:String = "", _owner:Observable = null) -> void:
	super._init(_owner)
	value = _val
