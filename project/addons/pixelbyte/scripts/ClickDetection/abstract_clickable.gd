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

func _on_mouse_exited(): hovering.emit(false)
func _on_mouse_entered(): hovering.emit(true)	

func _process_input_events(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mbe:InputEventMouseButton = event
		if mbe.pressed:
			if mbe.double_click:
				#print("double click")
				double_clicked.emit(mbe.button_index)
			else:
				#print("click")
				clicked.emit(mbe.button_index)
		elif mbe.is_released():
			#print("up")
			unclicked.emit(mbe.button_index)
