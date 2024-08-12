extends CanvasLayer

## emitted when the screen is fully "wiped" i.e. you cant see behind the rect
signal wiped
## emitted when the screen is fully "unwiped" i.e. you can see the screen
signal unwiped

signal wiped_to_scene

var is_wiped:bool:
	get: return $WipeRect.material.get_shader_parameter("dissolve_value") == 1.0

# true when the wiper is wiping
var wiping:bool:
	get: return wiping

## if true, then the wipe texture will be ignored and a simple alpha fade will be performed in the given wipe_color
@export var fade_mode:bool = false:
	get: return fade_mode
	set(val):
		fade_mode = val
		if !is_node_ready():
			await ready
		wipe_rect.material.set_shader_parameter("use_alpha", val)

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
			
# if the animation player has an "unwipe" anim, we'll use it for unwipe,
# otherwise we just play "wipe" in reverse
var has_unwipe_anim: bool

func _ready() -> void:
	wipe_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	has_unwipe_anim = anim.has_animation("unwipe")
	wipe_texture = default_wipe_texture
	
	if default_wipe_texture == null:
		printerr("No default wipe texture selected. Be sure to set 'wipe_texture'!")

# wipes the screen
# awaitable: await wipe()
func wipe():
	wiping = true
	if anim.is_playing() && anim.current_animation == "unwipe":
			anim.stop()
	
	wipe_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	if !anim.is_playing() or anim.current_animation != "wipe":
		anim.play("wipe", -1, 1.0 / wipe_speed)
		if wipe_sound:
			wipe_sound.play_rnd()
			
	await anim.animation_finished
	wiping = false
	wiped.emit()

func wipe_immediate():
	if anim.is_playing():
		anim.stop()
	
	wipe_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	$WipeRect.material.set_shader_parameter("dissolve_value", 1.0)
	wiping = false
	
func unwipe_immediate():
	if anim.is_playing():
		anim.stop()
	wipe_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$WipeRect.material.set_shader_parameter("dissolve_value", 0.0)
	wiping = false
	
# unwipes the screen
# awaitable: await unwipe()
func unwipe():
	wiping = true
	if anim.is_playing():
		anim.stop()
	
	if has_unwipe_anim:
		anim.play("unwipe", -1, 1.0 / wipe_speed)
	else:
		anim.play("wipe", -1, -1.0 / wipe_speed, true)
		
	if unwipe_sound:
		unwipe_sound.play_rnd()
		
	await anim.animation_finished
	
	wipe_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wiping = false
	unwiped.emit()

# wipes loads another scene, then un-wipes
# awaitable: await wipe_to_scene()
func wipe_to_scene(scene_path:String, delay:float = 0, _unwipe:bool = false):
	await wipe()
	Scene.change(get_tree(), scene_path)
	
	if _unwipe:
		if delay > 0:
			await get_tree().create_timer(delay).timeout
		await unwipe()
		
	wiped_to_scene.emit()

func wipe_to_packed(scene:PackedScene, delay: float = 0, _unwipe:bool = false):
	await wipe()
	Scene.change_packed(get_tree(), scene)
	if _unwipe:
		if delay > 0:
			await get_tree().create_timer(delay).timeout
		await unwipe()
		
	wiped_to_scene.emit()
