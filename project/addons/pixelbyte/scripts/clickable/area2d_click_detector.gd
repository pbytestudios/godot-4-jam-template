class_name Area2DClickDetector
extends AbstractClickable

@export var clickable_area:Area2D

func _ready() -> void:
	connect_control(clickable_area)
	clickable_area.input_pickable = true
