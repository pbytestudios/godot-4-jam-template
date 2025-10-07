extends Node

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func stutter(time:float = 0.075):
	if time <= 0:
		return
	get_tree().paused = true
	await get_tree().create_timer(time, true, false, true).timeout
	get_tree().paused = false

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
	n.add_child(label)

func bounce_text(lbl:Label, start_scale:float = 0.6, time:float = 0.5) -> Tween:	
	lbl.scale = Vector2.ONE * start_scale
	var tw:Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tw.tween_property(lbl, "scale", Vector2.ONE, time)
	return tw