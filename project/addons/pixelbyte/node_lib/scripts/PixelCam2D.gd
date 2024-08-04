class_name PixelCam2D
extends Camera2D

#Camera shake parameters
enum ShakeType {Random, Sine, Noise}

@export var sine_freq := 10.0
@export var noise_octaves := 4
@export var noise_period := 20
@export var noise_persistence := 0.8

var is_shaking :bool = false:
	get: return _duration > 0

var _intensity :Vector2 = Vector2.ZERO
var _type = ShakeType.Random
var _noise : FastNoiseLite
var _duration :float = 0.0
#######

func _ready():
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	_noise.seed = rng.randi()
	
	# These parameters change the shape of the noise
	# and the feel of the shake
	_noise.fractal_octaves = noise_octaves
	_noise.fractal_gain = noise_period
	_noise.fractal_lacunarity = noise_persistence
	set_process(false)	

func shake(shake_duration: float, shake_intensity : Vector2 = Vector2.ONE, type:int = ShakeType.Random):
	if shake_duration > _duration:
		_intensity = shake_intensity
		_duration = shake_duration
		_type = type
		set_process(true)
		
func stop(): 
	set_process(false)
	await get_tree().process_frame
	_duration = 0
	_intensity = Vector2.ZERO
	offset = Vector2.ZERO
	
func _process(delta):
	if _duration > 0:
		_duration -= delta
		
		match _type:
			ShakeType.Random:
				offset = Vector2(randf(), randf()) * _intensity
			ShakeType.Sine:
				offset = Vector2(cos(Time.get_unix_time_from_system() * TAU * sine_freq) * _intensity.x, sin(Time.get_unix_time_from_system() * TAU * sine_freq) * _intensity.y) * 0.5
			ShakeType.Noise:
				var _noise_value_x = _noise.get_noise_1d(Time.get_unix_time_from_system() * 0.1)
				var _noise_value_y = _noise.get_noise_1d(Time.get_unix_time_from_system() * 0.1 + 100.0)
				offset = Vector2(_noise_value_x, _noise_value_y) * _intensity * 2.0
				
		if _duration <= 0:
			stop()

func set_limits(limits:Rect2):
	limit_left = int(limits.position.x)
	limit_top = int(limits.position.y)
	limit_right = int(limits.end.x)
	limit_bottom = int(limits.end.y)

func zoom_to_limits(limits:Rect2, set_center:bool = true):
	var zoom = get_viewport_rect().size / Vector2(limits.size)
	#take the larger number to keep the aspect ratio correct while fitting everything within the camera
	set_zoom(Vector2.ONE * min(snapped(zoom.x, 0.05), snapped(zoom.y, 0.05)))
	if set_center:
		global_position = limits.get_center()

#zoom camera in/out to fit the size of the rect
func zoom_to_fit(fit_rect:Rect2, minRect:Rect2 = Rect2(Vector2.ZERO,Vector2.ZERO)):
	#Get the center of the fit rect
	var rect_center = fit_rect.get_center()	
	
	#Don't go any smaller than the min rect
	fit_rect = fit_rect.merge(minRect)

	zoom_to_limits(fit_rect, false)
	global_position = rect_center
