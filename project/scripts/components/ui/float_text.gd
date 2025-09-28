class_name FloatText
extends Label

@export var fade_time := 1.5
@export var move_vel := Vector2.UP * 10
@export var tween_ease: Tween.EaseType = Tween.EASE_IN_OUT
@export var tween_trans: Tween.TransitionType = Tween.TRANS_LINEAR

func _ready():
	var t := create_tween()
	t.set_ease(tween_ease)
	t.set_trans(tween_trans)
	t.tween_property(self, "modulate:a", 0.0, fade_time)
	t.parallel()
	# move up while fading out
	t.tween_property(self, "global_position", global_position + move_vel * fade_time, fade_time)
	await t.finished
	queue_free()