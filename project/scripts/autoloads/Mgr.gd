extends Node

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func stutter(duration:float = 0.075):
	if duration <= 0:
		return
	get_tree().paused = true
	await get_tree().create_timer(duration, true, false, true).timeout
	get_tree().paused = false

func scale_time(scale:float = 1.0, duration:float = 0.075):
	if duration <= 0:
		return
	scale = clampf(scale, -2.0, 2.0)
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func set_text(n:Node2D, txt:String, global_position:Vector2, fade_time:float = 1.5, move_vel:Vector2 = Vector2.UP * 20):
	var label:FloatText = FloatText.new()
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = txt
	label.global_position = global_position
	label.fade_time = fade_time
	label.move_vel = move_vel
	label.tween_ease = Tween.EASE_OUT
	label.tween_trans = Tween.TransitionType.TRANS_CUBIC
	label.z_index = 5
	n.add_child(label)

func bounce_text(lbl:Label, start_scale:float = 0.6, time:float = 0.5) -> Tween:	
	lbl.scale = Vector2.ONE * start_scale
	var tw:Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tw.tween_property(lbl, "scale", Vector2.ONE, time)
	return tw

func rand_unit_vector() -> Vector2:
	var angle:float = randf_range(0.0, TAU)
	return Vector2(cos(angle), sin(angle))
