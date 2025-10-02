class_name Observable
extends Resource

# modified from 
# https://github.com/NoBS-Code/godot-reactive-ui

signal updated(observable:Observable)

var owner: Observable:
	set(val):
		if owner != null:
			updated.disconnect(owner._propagate)
		owner = val
		if owner != null:
			updated.connect(owner._propagate)

func _init(_owner:Observable = null) -> void: owner = _owner
func _propagate(observable:Observable = null) -> void: updated.emit(self)
func emit_manual() -> void: updated.emit(self)
