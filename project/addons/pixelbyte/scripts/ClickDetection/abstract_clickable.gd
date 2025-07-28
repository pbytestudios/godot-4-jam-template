@abstract class_name AbstractClickable
extends Node

signal clicked(button:MouseButton)
signal double_clicked(button:MouseButton)
signal up(button:MouseButton)
signal hovering(is_hovering:bool)

func _on_mouse_exited(): hovering.emit(false)
func _on_mouse_entered(): hovering.emit(true)	

func _process_input_events(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mbe:InputEventMouseButton = event
		if mbe.pressed:
			if mbe.double_click:
				print("double click")
				double_clicked.emit(mbe.button_index)
			else:
				clicked.emit(mbe.button_index)
		elif mbe.is_released():
			print("click")
			up.emit(mbe.button_index)
