extends ProgressBar

@export var fade_after:float = 1.0
@export var start_invisible: bool = true

func _ready() -> void:
	value_changed.connect(func(v):fade_in())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if start_invisible:
		modulate.a = 0.0

var ft:Tween
func fade_in():
	if ft:
		ft.kill()
	ft = create_tween().set_ease(Tween.EASE_OUT)
	
	ft.tween_property(self, "modulate:a", 1.0, 0.5)
	ft.tween_interval(fade_after)
	ft.tween_property(self, "modulate:a", 0.0,  0.5)
