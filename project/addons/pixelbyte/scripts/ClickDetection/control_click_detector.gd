class_name ControlClickDetector
extends AbstractClickable

@export var control:Control

func _ready():
	if control:
		control.mouse_entered.connect(_on_mouse_entered)
		control.mouse_exited.connect(_on_mouse_exited)
		control.gui_input.connect(_process_input_events)
	else:
		printerr("control is not defined on '%s'!" % name)
