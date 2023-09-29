extends Node

# TODO: Add more functions below as needed for your specific game

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func stutter(time:float = 0.075):
	if time <= 0:
		return
	get_tree().paused = true
	await get_tree().create_timer(time, true, false, true).timeout
	get_tree().paused = false
