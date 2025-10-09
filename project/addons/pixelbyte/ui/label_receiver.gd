extends Label

enum LabelReadyState {None, ClearOnReady, PrefixOnReady}

@export var prefix:String = ""
@export var suffix:String = ""

@export var fade_time:float = 0.0
@export var wait_to_fade_time:float = 0.0

@export var label_ready_state:LabelReadyState = LabelReadyState.None

func _ready() -> void:
	match label_ready_state:
		LabelReadyState.ClearOnReady:
			text = ""
		LabelReadyState.PrefixOnReady:
			text = prefix
	# make sure there is SOME fade time if there is wait_fade time
	fade_time = max(0.25, fade_time)

func _receive_int(val:int):
	text = "%s%d%s" % [prefix, val, suffix]
	start_fade()

func _receive_float_to_int(val:float):
	text = "%s%d%s" % [prefix, val, suffix]
	start_fade()
	
func _receive_float(val:float):
	text = "%s%.2f%s" % [prefix, val, suffix]
	start_fade()

func _receive_str(val:String):
	text = "%s%s%s" % [prefix, val, suffix]
	start_fade()

func start_fade():
	if wait_to_fade_time > 0:
		if modulate.a < 1.0:
			fade(1.0, .25).tween_callback(func(): fade(0.0, fade_time, wait_to_fade_time))
		else:
			fade(0.0, fade_time, wait_to_fade_time)

var tw:Tween
func fade(to:float, time:float = 0.25, time_before_start:float = 0.0) -> Tween:
	if tw && tw.is_running():
		tw.kill()
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		
	if time_before_start > 0:
		tw.tween_interval(time_before_start)
	tw.tween_property(self, "modulate:a", to, time * abs(to - modulate.a))

	return tw
