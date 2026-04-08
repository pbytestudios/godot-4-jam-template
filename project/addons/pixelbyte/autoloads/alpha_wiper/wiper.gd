extends CanvasLayer

## emitted when the screen is fully "wiped" i.e. you cant see behind the rect
signal wiped
## emitted when the screen is fully "unwiped" i.e. you can see the screen
signal unwiped
## emitted when the scene has been changed after wipe completed
signal wiped_to_scene

enum State {None, Wiping, Wiped, Unwiping, Unwiped}

#region Exported variables
## if true, then the wipe texture will be ignored and a simple alpha fade will be performed in the given wipe_color
@export var fade_mode:bool = false:
	get: return fade_mode
	set(val):
		fade_mode = val
		if !is_node_ready():
			await ready
		wipe_rect.material.set_shader_parameter("wipe_alpha_only", val)

## animation player containing a "wipe" (and optionally an "unwipe") animation
@export var anim:AnimationPlayer

## The ColorRect on which to operate
@export var wipe_rect:ColorRect

## An optional transition sound
@export var wipe_sound:AudioStreamPlayer
## An optional transition sound
@export var unwipe_sound:AudioStreamPlayer

## Color used for the wipe
@export var wipe_color: Color:
	get: return wipe_rect.color
	set(val):
		if !is_node_ready():
			await ready
		wipe_rect.color = val
		wipe_rect.material.set_shader_parameter("wipe_color", val)

## sets the speed_scale on the animation player
## speed_scale = (1 / wipe_speed) so 
## wipe speed is more like play time in seconds with higher being longer
## When creating the "wipe" animation, make it 1 second long
## This allows the wipe_speed to = seconds to wipe
@export_range(0.01,5) var wipe_speed: float = 1.0:
	get: return wipe_speed
	set(val): wipe_speed = val
	
## The default texture to use in the shader for fading
@export var default_wipe_texture:Texture2D 
#
# Alpha texture used for the wipe
#
@onready var wipe_texture: Texture2D:
	get: return wipe_texture
	set(val):
		if val == null:
			wipe_texture = default_wipe_texture
		else:
			wipe_texture = val
		wipe_rect.material.set_shader_parameter("wipe_texture", wipe_texture)
		if wipe_texture:
			wipe_rect.material.set_shader_parameter("wipe_alpha_only", 0.0)
		else:
			wipe_rect.material.set_shader_parameter("wipe_alpha_only", 1.0)
#endregion

#region Properties
var state:State = State.None:
	get: return state
	set(val):
		if val != state:
			state = val
			match state:
				State.None:
					wipe_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				State.Wiping:
					wipe_rect.mouse_filter = Control.MOUSE_FILTER_STOP
				#State.Unwiping:
				State.Wiped:
					if anim && anim.is_playing():
						anim.stop()
					wipe_rect.material.set_shader_parameter("progress", 1.0)
					wipe_rect.mouse_filter = Control.MOUSE_FILTER_STOP
					wiped.emit()
				State.Unwiped:
					if anim && anim.is_playing():
						anim.stop()
					wipe_rect.material.set_shader_parameter("progress", 0.0)
					wipe_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
					unwiped.emit()
					
var is_wiped:bool:
	get: return state == State.Wiped

# true when the wiper is wiping
var wiping_or_unwiping:bool:
	get: return state == State.Wiping || state == State.Unwiping
#endregion

#var _tween:Tween
#
#func _tween_progress(finish:float, time:float):
	#if _tween:
		#_tween.kill()
	#_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	#var start:float =  wipe_rect.material.get_shader_parameter("progress")
	#var speed:float = abs(finish - start) / time
	 #if speed == 0.0:
		#
	#_tween.tween_property(wipe_rect.material, "progress", finish, )
	
# if the animation player has an "unwipe" anim, we'll use it for unwipe,
# otherwise we just play "wipe" in reverse
var has_unwipe_anim: bool

func _ready() -> void:
	wipe_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	has_unwipe_anim = anim.has_animation("unwipe")
	wipe_texture = default_wipe_texture
	anim.animation_finished.connect(_anim_finished)
	
	#print("wiping")
	#await wipe().wiped
	#print("done")
	#await unwipe().unwiped

# wipes the screen
# awaitable: await wipe()
func wipe():
	state = State.Wiping
	if anim.is_playing() && anim.current_animation == "unwipe":
		anim.stop()
	
	if !anim.is_playing() or anim.current_animation != "wipe":
		anim.play("wipe", -1, 1.0 / wipe_speed)
		if wipe_sound:
			wipe_sound.play_rnd()
	return self

func wipe_immediate(): state = State.Wiped
func unwipe_immediate(): state = State.Unwiped
	
# unwipes the screen
# awaitable: await unwipe()
func unwipe():
	state = State.Unwiping
	if anim.is_playing():
		anim.stop()
	
	if has_unwipe_anim:
		anim.play("unwipe", -1, 1.0 / wipe_speed)
	else:
		anim.play("wipe", -1, -1.0 / wipe_speed, true)
		
	if unwipe_sound:
		unwipe_sound.play_rnd()
	return self

func _anim_finished(animName:StringName):
	var val:float =  wipe_rect.material.get_shader_parameter("progress")
	if val > 0.99:
		wipe_immediate()
	else:
		unwipe_immediate()

# wipes loads another scene, then un-wipes
# awaitable: await wipe_to_scene()
func wipe_to_scene(scene_path:String, delay:float = 0, _unwipe:bool = false):
	if !is_wiped:
		await wipe().wiped
	get_tree().change_scene_to_file(scene_path)
	
	if _unwipe:
		if delay > 0:
			await get_tree().create_timer(delay).timeout
		await unwipe().unwiped
	wiped_to_scene.emit()

func wipe_reload(delay:float = 0):
	if !is_wiped:
		await wipe().wiped
	get_tree().reload_current_scene()
	
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	await unwipe().unwiped
	wiped_to_scene.emit()
	
func wipe_to_packed(scene:PackedScene, delay: float = 0, _unwipe:bool = false):
	if !is_wiped:
		await wipe().wiped
	get_tree().change_scene_to_packed(scene)
	if _unwipe:
		if delay > 0:
			await get_tree().create_timer(delay).timeout
		await unwipe().unwiped
	wiped_to_scene.emit()
