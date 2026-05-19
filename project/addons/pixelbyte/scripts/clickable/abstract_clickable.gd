@abstract class_name AbstractClickable
extends Node

## Emitted when the mouse is clicked
signal clicked(button:MouseButton)
## Emitted when the mouse is "unclicked"
signal unclicked(button:MouseButton)
## Emitted when the mouse is double clicked
signal double_clicked(button:MouseButton)
## Emitted when the mouse starts or stops hovering over the object
signal hovering(is_hovering:bool)

@export var enabled:bool = true:
	set(val):
		if enabled == val:
			return
			
		if !val && is_hovering:
			is_hovering = false
			hovering.emit(false)
		enabled = val
				
var is_hovering:bool:
	get: return is_hovering

func connect_control(control:Node) -> void:
	if control.has_signal("mouse_entered"):
		control.mouse_entered.connect(_on_mouse_entered)
	if control.has_signal("mouse_exited"):
		control.mouse_exited.connect(_on_mouse_exited)
	if control.has_signal("gui_input"):
		control.gui_input.connect(_process_input_events)
	elif control.has_signal("input_event"):
		if control is Node3D:
			control.input_event.connect(_on_3d_input)
		else:
			control.input_event.connect(_on_2d_input)

func _on_mouse_entered():
	if !enabled || is_hovering:
		return
	is_hovering = true
	hovering.emit(true)

func _on_mouse_exited():
	if !enabled || !is_hovering:
		return	
	is_hovering = false
	hovering.emit(false)	

func _set_event_handled(): get_viewport().set_input_as_handled()

func _on_2d_input(viewport:Viewport, event:InputEvent, shape_idx:int):
	_process_input_events(event)

func _on_3d_input(camera:Node, event:InputEvent, event_position:Vector3, normal: Vector3, shape_idx:int):
	_process_input_events(event)
	
func _process_input_events(event: InputEvent) -> void:
	if !enabled || !(event is InputEventMouseButton):
		return
		
	var mbe:InputEventMouseButton = event
	_set_event_handled()
	if mbe.pressed:
		clicked.emit(mbe.button_index)
		if mbe.double_click:
			double_clicked.emit(mbe.button_index)
	elif mbe.is_released():
		unclicked.emit(mbe.button_index)
