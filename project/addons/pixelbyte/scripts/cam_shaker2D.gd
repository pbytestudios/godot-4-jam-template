extends Camera2D
class_name CamShaker2D

var amount:Vector2 = Vector2.ONE
var shake_time:float
var frequency: float 
var time:float
var random_y_phase: float
var rnd:RandomNumberGenerator = RandomNumberGenerator.new()

var shaking:bool:
	get: return shaking

# emitted when a cam shake finishes
signal finished

func _ready() -> void:
	rnd.randomize()

func shake(_amount:Vector2 = Vector2.ONE * 10, _time:float = 0.25, freq:float = 10.0):
	time = 0
	shake_time = max(0, _time)
	amount = _amount
	frequency = freq
	random_y_phase = rnd.randf_range(-PI/ 4, PI/ 4)
	
	if _amount == Vector2.ZERO:
		shake_time = 0
	else:
		shaking = true

func stop(stop_time:float = 0.25):
	if !shaking:
		return
	time = min(stop_time, shake_time * .9)

func _process(delta: float) -> void:
	if time < shake_time:
		time += delta
		offset = Vector2(amount.x * cos(TAU * frequency * time), amount.y * sin((TAU + random_y_phase)  * frequency * time)) * lerp(Vector2.ONE, Vector2.ZERO, time / shake_time)
		if time >= shake_time:
			offset = Vector2.ZERO
			shaking = false
			finished.emit()
