extends CanvasLayer

# emitted when the screen is fully "wiped" i.e. you cant see behind the rect
signal wiped
# emitted when the screen is fully "unwiped" i.e. you can see the screen
signal unwiped

#animation player that contains the "wipe" (and optionally "unwipe") animation
@export var anim:AnimationPlayer
#The ColorRect on which to operate
@export var wipe_rect:ColorRect
#The texture to use in the shader for fading
@export var default_wipe_texture:Texture2D

# sets the speed_scale on the animation player
# speed_scale = (1 / wipe_speed) so 
# wipe speed is more like play time in seconds with higher being longer
# When creating the "wipe" animation, make it 1 second long
# This allows the wipe_speed to = seconds to wipe
var wipe_speed: float:
	get: return 1 / anim.speed_scale
	set(val): 
		if val <= 0:
			anim.speed_scale = 1 / 0.01
		else:
			anim.speed_scale = 1 / val

#
# Color used for the wipe
#
var cover_color: Color:
	get: return wipe_rect.color
	set(val): 
		wipe_rect.color = val
		wipe_rect.material.set_shader_parameter("wipe_color", val)

#
# Alpha texture used for the wipe
#
var wipe_texture: Texture2D:
	get: return wipe_texture
	set(val):
		if val == null:
			wipe_texture = default_wipe_texture
		else:
			wipe_texture = val
		wipe_rect.material.set_shader_parameter("wipe_texture", wipe_texture)
			
# if the animation player has an "unwipe" anim, we'll use it for unwipe,
# otherwise we just play "wipe" in reverse
var has_unwipe_anim: bool

func _ready() -> void:
	wipe_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	has_unwipe_anim = anim.has_animation("unwipe")
	wipe_texture = default_wipe_texture

# wipes the screen
# awaitable: await wipe()
func wipe():
	if anim.is_playing():
		anim.stop()
	
	wipe_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	anim.play("wipe")
	await anim.animation_finished
	wiped.emit()

func wipe_immediate():
	if anim.is_playing():
		anim.stop()
	
	wipe_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	$WipeRect.material.set_shader_parameter("dissolve_value", 1.0)

# unwipes the screen
# awaitable: await unwipe()
func unwipe():
	if anim.is_playing():
		anim.stop()
	
	if has_unwipe_anim:
		anim.play("unwipe")
	else:
		anim.play_backwards("wipe")
	await anim.animation_finished
	
	wipe_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unwiped.emit()

# wipes loads another scene, then unwopes
# awaitable: await wipe_to_scene()
func wipe_to_scene(scene_path:String, delay:float = 0):
	await wipe()
	Scene.change(get_tree(), scene_path)
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	await unwipe()
