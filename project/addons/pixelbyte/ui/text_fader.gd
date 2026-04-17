extends CanvasItem
class_name TextFader

signal onscreen
signal offscreen

enum {Off, Showing, Hiding, On}

@export var label:Label
@export var default_fade_time : float = 0.5
@export var tween_type: Tween.TransitionType = Tween.TRANS_LINEAR
#@export var mouseFilter: Control.MouseFilter = Control.MOUSE_FILTER_IGNORE

var state:int = Off:
	get: return state

var on_or_showing:bool:
	get: return state == On or state == Showing

var txt_color:Color:
	get: return label.self_modulate
	set(val): label.self_modulate = val

@onready var _starting_alpha = modulate.a

func _ready():
#	self.mouse_filter = mouseFilter
	
	hide()

func _hide_it():
	state = Off
	hide()
	offscreen.emit()	
	

func on(text:String, time:float = -1):
		
	label.text = text
	
	if self.on_or_showing:
		return

	if _tween != null && _tween.is_valid():
		_tween.kill()
		
	if time < 0:
		time = default_fade_time
	
	if time > 0:
		modulate.a = 0
		show()
		state = Showing
		_tween = _make_tween(time, _starting_alpha, Tween.EASE_OUT)
		await _tween.finished
		_tween = null
		state = On
		onscreen.emit()
	else:
		show()
		modulate.a = _starting_alpha
		state = On
		onscreen.emit()

func off(time:float = 0.5):
	if _tween && _tween.is_valid():
		_tween.kill()
		
	if time < 0:
		time = default_fade_time
	
	if time > 0:
		state = Hiding
		_tween = _make_tween(time, 0.0, Tween.EASE_IN)
		_tween.tween_callback(func(): 
			_tween = null
			_hide_it()
			)
	

var _tween: Tween
func _make_tween(time:float, final_alpha:float, ease_type:int) -> Tween:
	#create a SceneTreeTween and bind it to this node so that 
	#when this node is deleted, the _tween goes with it
	var tw = create_tween()
	tw.set_trans(tween_type)
	tw.set_ease(ease_type)
	tw.tween_property(self, "modulate:a", final_alpha, time)	
	return tw
