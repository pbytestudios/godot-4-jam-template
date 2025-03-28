@tool
class_name UIEffect
extends Node2D

enum Mode {None, ToMark, FromMark, FadeIn, FadeOut}

@export var target:Control
@export var start:Marker2D
@export var mark:Marker2D
@export_category("Tween Properties")
@export var play_on_ready:bool = false
@export var tween_time:float = 1.0
@export var tween_mode:Mode = Mode.None
@export var play_ease:Tween.EaseType = Tween.EASE_IN
@export var reverse_ease:Tween.EaseType = Tween.EASE_OUT
@export var tween_trans: Tween.TransitionType = Tween.TRANS_LINEAR
@export_category("Editor Controls")
@export var set_mark:bool:
	set(val):
		if val && !_finishing && Engine.is_editor_hint() && is_instance_valid(target):
			mark.global_position = target.global_position
			
@export var play_tween:bool:
	set(val):
		if _finishing || !Engine.is_editor_hint() || (is_instance_valid(_tw) && _tw.is_running()):
			return
			
		_update_play_mode()
		_save_state()
		_finishing = true
		finished_play.connect(func():
			await get_tree().create_timer(0.125).timeout
			_restore_state()
			_finishing = false
			, CONNECT_ONE_SHOT)
		play()
		
var _start_pos:Vector2:
	get: return start.global_position

#func _validate_property(property: Dictionary) -> void:
	#if property.name == "_start_pos":
		#property.usage = PROPERTY_USAGE_NO_EDITOR

var _mark_pos:Vector2:
	get: 
		return mark.global_position
	
var _tw:Tween

var _play:Callable
var _reverse:Callable

## Emitted when the ui action finishes
signal finished_play
## Emitted when the ui action finishes reversing
signal finished_reverse

func _ready() -> void:
	set_process(Engine.is_editor_hint())
	
	if !Engine.is_editor_hint():
		_update_play_mode()
		if tween_mode == Mode.FadeIn:
			target.modulate.a = 0
		if play_on_ready:
			play()

func _process(delta: float) -> void:
	_update_positions()

func _update_positions():
	if target != null && is_instance_valid(start):
		start.global_position = target.global_position
	
func _update_play_mode():
	match tween_mode:
		Mode.None:
			_play = Callable()
			_reverse = Callable()
		Mode.ToMark:
			_play = func(): _do_tween("global_position", play_ease, _mark_pos, tween_time)
			_reverse = func(): _do_tween("global_position",reverse_ease, _start_pos, tween_time, true)
		Mode.FromMark:
			_play = func():
				target.global_position = _mark_pos
				_do_tween("global_position", play_ease, _start_pos, tween_time, true)
			_reverse = func(): _do_tween("global_position", reverse_ease, _mark_pos, tween_time)
		Mode.FadeIn:
			_play = func():_fade(play_ease, 0.0, 1.0, tween_time)
			_reverse = func():_fade(reverse_ease, 1.0, 0.0, tween_time, true)
		Mode.FadeOut:
			_play = func():_fade(play_ease, 1.0, 0.0, tween_time)
			_reverse = func():_fade(reverse_ease, 0.0, 1.0, tween_time, true)

func _do_tween(property:String, ease:Tween.EaseType, value, time:float, reverse:bool = false):
	if is_instance_valid(_tw):
		_tw.kill()

	_tw = create_tween().set_ease(ease).set_trans(tween_trans)
	_tw.tween_property(target, property, value, time)
	if reverse:
		_tw.tween_callback(func(): finished_reverse.emit())
	else:
		_tw.tween_callback(func(): finished_play.emit())

func is_playing(): return is_instance_valid(_tw) && _tw.is_running()
	
func _fade(ease:Tween.EaseType, start_alpha:float, stop_alpha:float, time:float, reverse:bool = false):
	target.modulate.a = start_alpha
	_do_tween("modulate:a", ease, stop_alpha, time, reverse)

func play(): _play.call()
func reverse(): _reverse.call()

##### Editor-specific stuff
var _state:Dictionary 
var _finishing:bool
func _save_state():
	_state = {
		"global_position" = target.global_position,
		"alpha" = target.modulate.a
	}

func _restore_state():
	for key in _state:
		target.set(key, _state[key])
	_state = {}
