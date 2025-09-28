class_name Trail
extends Line2D

@export var parent:Node2D
@export var max_points: int = 50
@export var distance_between_points: float = 10.0
@export var fade_time: float = 1.0

enum State {Stopped, Fading, Trailing}

var last_point: Vector2
var timer:float
var state:int = State.Stopped

func _ready():
	set_as_top_level(true)
	
func clear():
	modulate = Color.WHITE
	state = State.Stopped
	clear_points()
	last_point = Vector2.ZERO

func fade():
	if get_point_count() == 0:
		clear()
	else:
		state = State.Fading
	
func start():
	clear()
	state = State.Trailing
	timer = fade_time

func _do_fade(delta:float):
	timer -= delta
	if timer <= 0:
		remove_point(0)

		if get_point_count() == 0:
			clear()
		else:
			timer = fade_time
	modulate.a = lerp(modulate.a, 0.0, 2 * delta)

func _process(delta):
	if state == State.Stopped:
		return
	elif state == State.Fading:
		_do_fade(delta)
	else:
		if parent.global_position.distance_squared_to(last_point) > distance_between_points * distance_between_points:
			add_point(parent.global_position)
			last_point = parent.global_position

		if get_point_count() > max_points:
			remove_point(0)
			timer = fade_time
		else:
			_do_fade(delta)
