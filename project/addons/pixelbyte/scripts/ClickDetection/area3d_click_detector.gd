class_name Area3DClickDetector
extends AbstractClickable

@export var clickable_area:Area3D

func _ready() -> void:
	if clickable_area:
		clickable_area.input_event.connect(_on_collision_input)
		clickable_area.mouse_entered.connect(_on_mouse_entered)
		clickable_area.mouse_exited.connect(_on_mouse_exited)
		#_setup_timer()
	else:
		printerr("clickable_area is not defined on '%s'!" % name)

func _on_collision_input(viewport:Viewport, event:InputEvent, shape_idx:int):
	_process_input_events(event)
