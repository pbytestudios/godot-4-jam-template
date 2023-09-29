extends Camera2D
class_name CamShaker2D

var shake_amount:Vector2 = Vector2.ONE
var shake_time:float
var frequency: float = 10
var time:float

var shaking:bool:
	get: return shaking
	
signal finished

func shake(amount:Vector2 = Vector2.ONE, _time:float = 0.25, freq:float = 10.0):
	time = 0
	shake_time = max(0, _time)
	shake_amount = amount
	frequency = freq
	
	if amount == Vector2.ZERO:
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
		offset = Vector2(shake_amount.x * sin(TAU * frequency * time), shake_amount.y * sin((TAU + PI / 2) * frequency * time)) * lerp(Vector2.ONE, Vector2.ZERO, time / shake_time)
		if time >= shake_time:
			offset = Vector2.ZERO
			shaking = false
			finished.emit()
		
		
