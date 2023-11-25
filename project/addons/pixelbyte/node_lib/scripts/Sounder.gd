class_name Sounder
extends AudioStreamPlayer

const MIN_PITCH := 0.1 
const MIN_INCREMENT := 0.05

# This is a property
@export var sounds:Array[AudioStream]
#if != 0 this adds a random +/- offset to the pitch each time it plays
@export_range(-1, 0, 0.1) var random_pitch_min := -0.3
@export_range(0, 1, 0.1) var random_pitch_max := 0.3

var sound_count:int:
	get: return sounds.size()

@onready var original_pitch: float = pitch_scale
var rnd := RandomNumberGenerator.new()

func _ready() -> void:
	rnd.randomize()

func set_random_sound():
	if sounds.size() > 1:
		stream = sounds[rnd.randi_range(0, sounds.size() - 1)]
	else:
		stream = sounds[0]

func play_rnd(from_pos := 0.0):
	if sounds.size() == 0: 
		return
	
	set_random_sound()
	
	#we want the increments to be in discrete increments
	var u = random_pitch_min / MIN_INCREMENT
	var m = random_pitch_max / MIN_INCREMENT
	var offset = rnd.randi_range(u, m)
	
	if offset != 0:
		pitch_scale = max(MIN_PITCH, original_pitch + offset * MIN_INCREMENT)
	else:
		pitch_scale = original_pitch
	super.play(from_pos)
