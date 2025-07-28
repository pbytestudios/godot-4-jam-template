class_name Area2DClickDetector
extends Node2D


signal clicked(button:MouseButton)
signal double_clicked(button:MouseButton)
signal up(button:MouseButton)

signal hovering(is_hovering:bool)

@export var clickable_area:Area2D

var _last_clicked_index:int = MOUSE_BUTTON_NONE

func _ready() -> void:
	if clickable_area:
		clickable_area.input_event.connect(_on_collision_input)
		clickable_area.mouse_exited.connect(_on_mouse_exited)
		clickable_area.mouse_entered.connect(_on_mous_enterd)
		#_setup_timer()
	else:
		printerr("clickable_area is not defined on '%s'!" % name)

func _on_mouse_exited():
	_last_clicked_index = MOUSE_BUTTON_NONE
	hovering.emit(false)

func _on_mous_enterd():
	hovering.emit(true)	

func _on_collision_input(viewport:Viewport, event:InputEvent, shape_idx:int):
	if event is InputEventMouseButton:
		var mbe:InputEventMouseButton = event
			
		if mbe.is_pressed():
			#_update_click_count(mbe.button_index)
			if mbe.double_click:
				double_clicked.emit(mbe.button_index)
			else:
				clicked.emit(mbe.button_index)
		elif mbe.is_released():
			up.emit(mbe.button_index)
			
