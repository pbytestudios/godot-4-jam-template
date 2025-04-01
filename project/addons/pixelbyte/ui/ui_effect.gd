@tool
class_name UIEffect
extends Node2D

enum Mode {None, ToMark, FromMark, FadeIn, FadeOut}
enum State {Ready, Played}

@export var target:Control
@export var start:Marker2D
@export var mark:Marker2D

@export_category("Tween Properties")
@export var play_on_ready:bool = false
@export var tween_play_time:float = 1.0
@export var tween_reverse_time:float = 0.5
@export var tween_mode:Mode = Mode.None
@export var play_ease:Tween.EaseType = Tween.EASE_IN
@export var reverse_ease:Tween.EaseType = Tween.EASE_OUT
@export var tween_trans: Tween.TransitionType = Tween.TRANS_LINEAR

@export_category("Editor Controls")

var state:State = State.Ready:
	get: return state

var _start_pos:Vector2:
	get: return start.global_position

var _mark_pos:Vector2:
	get: return mark.global_position
	
var _tw:Tween

var _play:Callable
var _reverse:Callable

## Emitted when the ui action finishes
signal finished

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
		Mode.ToMark:
			_play = func(): _do_tween("global_position", play_ease, _mark_pos, tween_play_time)
			_reverse = func(): _do_tween("global_position",reverse_ease, _start_pos, tween_reverse_time, true)
		Mode.FromMark:
			_play = func():
				target.global_position = _mark_pos
				_do_tween("global_position", play_ease, _start_pos, tween_play_time, true)
			_reverse = func(): _do_tween("global_position", reverse_ease, _mark_pos, tween_reverse_time)
		Mode.FadeIn:
			_play = func():_fade(play_ease, 0.0, 1.0, tween_play_time)
			_reverse = func():_fade(reverse_ease, 1.0, 0.0, tween_reverse_time, true)
		Mode.FadeOut:
			_play = func():_fade(play_ease, 1.0, 0.0, tween_play_time)
			_reverse = func():_fade(reverse_ease, 0.0, 1.0, tween_reverse_time, true)
		Mode.None, _:
			_play = Callable()
			_reverse = Callable()

func _do_tween(property:String, ease:Tween.EaseType, value, time:float, reverse:bool = false):
	if is_instance_valid(_tw):
		_tw.kill()

	_tw = create_tween().set_ease(ease).set_trans(tween_trans)
	_tw.tween_property(target, property, value, time)
	_tw.tween_callback(_on_tween_finished)

func _on_tween_finished():
	if state == State.Ready:
		state = State.Played
	else:
		state = State.Ready
	finished.emit()

func is_playing(): return is_instance_valid(_tw) && _tw.is_running()
	
func _fade(ease:Tween.EaseType, start_alpha:float, stop_alpha:float, time:float, reverse:bool = false):
	target.modulate.a = start_alpha
	_do_tween("modulate:a", ease, stop_alpha, time, reverse)

func play(): 
	if _play.is_valid():
		_play.call()
	else:
		_on_tween_finished()
	return self

func reverse(): 
	if _reverse.is_valid():
		_reverse.call()
	else:
		_on_tween_finished()
	return self

##### Editor-specific stuff
# for editor icon string names, visit: https://godot-editor-icons.github.io/
@export_tool_button("Set Mark", "Anchor") var mark_action = set_mark
@export_tool_button("Play Tween", "Play") var play_action = play_tween

func set_mark():
	if !_finishing && Engine.is_editor_hint() && is_instance_valid(target):
		mark.global_position = target.global_position

func play_tween():
	if _finishing || !Engine.is_editor_hint() || (is_instance_valid(_tw) && _tw.is_running()):
		return
		
	_update_play_mode()
	_save_state()
	_finishing = true
	finished.connect(func():
		await get_tree().create_timer(0.125).timeout
		_restore_state()
		_finishing = false
		, CONNECT_ONE_SHOT)
	play()
	
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
