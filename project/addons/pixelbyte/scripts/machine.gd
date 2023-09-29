extends RefCounted
class_name Machine

# a state machine using Callables
# 2023 Pixelbyte Studios

# this holds all the states and their functions
var state_map = {}

var current_state_name:StringName:
	get: return current_state_name

var stopped:bool = true:
	get: return stopped

# true when the machine is changing to another state
# set to false AFTER the new state's enter method is called
var changing_states:bool:
	get: return changing_states

var current_state_functions:Dictionary = {}
var current_update:Callable

# emitted AFTER the new state's enter method has been called
signal changed_state

# function naming: the 'enter' callable will be used to name the state
func add(enter:Callable, update:Callable = Callable(), exit:Callable = Callable()):
	var methods = {}
	
	var slices:Array = enter.get_method().split('_', false, 2)
	var state_name:StringName = slices[0]
	methods["enter"] = enter
	methods["update"] = update
	methods["exit"] = exit
	state_map[state_name] = methods

#
# Stops the state machine
# Note: the currently-running state's exit function will be called if it exists
#
func stop():
	stopped = true
	current_state_name = ""
	_change_state({})

func start(starting:Callable):
	stopped = false
	change(starting, true)

#
# When calling change, you can use any callable that has the state name with the format
# 'statename' or 'statename_type'
#
func change(to:Callable, immediate:bool = false):
	if stopped:
		printerr("You must call start() to start the machine!")
		return
	
	var slices:Array = to.get_method().split('_', false, 2)
	if !state_map.has(slices[0]):
		printerr("Cannot find state: %s!" % to)
		return
	
	changing_states = true
	current_state_name = slices[0]
	
	if immediate:
		await _change_state(state_map[current_state_name])
	else:
		_change_state.call_deferred(state_map[current_state_name])

func _change_state(state_funcs:Dictionary):
	if !current_state_functions.is_empty() && current_state_functions.has("exit"):
		await current_state_functions["exit"].call()
		
	#clear the update function, so we don't run it during the transition
	current_update = Callable()
		
	current_state_functions = state_funcs
	
	#call the new state's enter if there is one
	if state_funcs.has("enter") && !state_funcs["enter"].is_null():
		await state_funcs["enter"].call()

	changing_states = false
	changed_state.emit()
		
	#setup the update and physics functions if they exist
	if state_funcs.has("update") && !stopped:
		current_update = state_funcs["update"]
	
func update(delta:float):
	if current_update.is_null():
		return
	current_update.call(delta)
