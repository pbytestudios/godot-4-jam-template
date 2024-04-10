extends Node2D

enum Mode {None, ToMarkOnReady, FromMarkOnReady}

@export var parent:Control
@export var tween_time:float = 1.0
@export var tween_mode:Mode
@export var to_mark_ease:Tween.EaseType = Tween.EASE_IN
@export var to_start_ease:Tween.EaseType = Tween.EASE_OUT
@export var tween_trans: Tween.TransitionType = Tween.TRANS_LINEAR

var _start_pos:Vector2
var _mark_pos:Vector2
var _tw:Tween

func _ready() -> void:
	_start_pos = parent.global_position
	_mark_pos = $Mark.global_position
	
	if tween_mode == Mode.ToMarkOnReady:
		tween_to_mark()
	elif tween_mode == Mode.FromMarkOnReady:
		parent.global_position = _mark_pos
		tween_to_start()

func tween_to_mark():
	if is_instance_valid(_tw):
		_tw.kill()

	_tw = create_tween().set_ease(to_mark_ease).set_trans(tween_trans)
	_tw.tween_property(parent, "global_position", _mark_pos, tween_time)

func tween_to_start():
	if is_instance_valid(_tw):
		_tw.kill()

	_tw = create_tween().set_ease(to_start_ease).set_trans(tween_trans)
	_tw.tween_property(parent, "global_position", _start_pos, tween_time)
