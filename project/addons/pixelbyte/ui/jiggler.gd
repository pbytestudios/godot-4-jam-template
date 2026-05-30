class_name JiggleControl
extends Node

@export var target:CanvasItem
@export var duration:float = 0.5
@export_range(0.1, 3.0, 0.05) var start_scale_percentage: float = 0.8

@onready var original_scale = target.scale

var jiggling:bool:
	get: return jiggling

var _jiggler:Tween

func _ready():
	if target is Control:
		target.pivot_offset = target.size / 2.0

func stop():
	if _jiggler && _jiggler.is_running():
		_jiggler.kill()
	jiggling = false
	target.scale = original_scale
	
func jiggle(force:bool = false, repeat:bool = false):
	if jiggling && !force:
		return
	stop()
	
	jiggling = true
	_jiggler = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	target.scale= original_scale * start_scale_percentage
	_jiggler.tween_property(target, "scale", original_scale, duration)
	_jiggler.tween_callback(func(): jiggling = false)
	if repeat:
		_jiggler.tween_callback(jiggle.bind(true,true))
