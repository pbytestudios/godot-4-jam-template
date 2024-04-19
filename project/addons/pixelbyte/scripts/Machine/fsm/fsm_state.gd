class_name FSM_State
extends Node

signal finished

func _ready() -> void: 
	set_process(false)
	set_physics_process(false)

func _enter() -> void: pass
func _exit() -> void: finished.emit()
