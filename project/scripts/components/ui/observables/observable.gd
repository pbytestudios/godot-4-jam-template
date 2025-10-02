class_name Observable
extends Resource

# modified from 
# https://github.com/NoBS-Code/godot-reactive-ui

signal observable_changed(observable:Observable)

var owner: Observable:
	set(val):
		if owner != null:
			owner.observable_changed.disconnect(owner._propogate)
		owner = val
		if owner != null:
			owner.observable_changed.connect(owner._propagate)

func _init(_owner:Observable = null) -> void: owner = _owner
func _propagate(observable:Observable = null) -> void: observable_changed.emit(self)
func emit_manual() -> void: _propagate()
