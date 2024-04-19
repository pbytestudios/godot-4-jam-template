extends RefCounted
class_name Machine

# 2023 Pixelbyte Studios
# a state machine using Callables
# this allows all states ot be contained within 1 script

# this holds all the states and their functions
var state_map = {}

var current_state_name:StringName:
	get: 
		if _current_state_functions.is_empty():
			return "none"
		else:
			return _current_state_functions.name

var stopped:bool = true:
	get: return stopped

# true when the machine is changing to another state
# set to false AFTER the new state's enter method is called
var changing_states:bool:
	get: return changing_states

var _previous_state_functions:Dictionary = {}
var _current_state_functions:Dictionary = {}

var current_update:Callable

# emitted AFTER the new state's enter method has been called
signal changed_state

# function naming: the 'enter' callable will be used to name the state
func add(enter:Callable, update:Callable = Callable(), exit:Callable = Callable()):
	var methods = {}
	var state_name:String = "n/a"
	
	if enter.is_valid():
		var slices:Array = enter.get_method().get_basename().trim_prefix("_").split('_', false, 2)
	state_name = _get_state_name(enter)
	if state_name.is_empty():
		state_name = _get_state_name(update)

	methods["enter"] = enter
	methods["update"] = update
	methods["exit"] = exit
	methods["name"] = state_name
	state_map[state_name] = methods

func _get_state_name(callable:Callable) -> String: 
	if callable.is_valid():
		return callable.get_method().get_basename().trim_prefix("_").trim_suffix("_enter").trim_suffix("_update").trim_suffix("_exit")
	return ""	
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
	change(starting)


func change_prev() -> bool:
	if _previous_state_functions.is_empty():
		printerr("No previous state recorded!")
		return false
	else:
		#_change_state.call_deferred(_change_state, _previous_state_functions)
		_change_state(_previous_state_functions)
		return true
		
func change(to:Callable):
	if stopped:
		#print_stack()
		#push_warning("You must call start() to start the machine!")
		return
	
	var state_name = _get_state_name(to)
	if !state_map.has(state_name):
		printerr("Cannot find state: %s!" % to)
		return
	
	await _change_state(state_map[state_name])

func _change_state(state_funcs:Dictionary):
	if changing_states:
		await changed_state
			
	changing_states = true
	
	#clear the update function, so we don't run it during the transition
	current_update = Callable()

	if !_current_state_functions.is_empty() && _current_state_functions["exit"].is_valid():
		_current_state_functions["exit"].call()
	
	if state_funcs != _current_state_functions:
		_previous_state_functions = _current_state_functions
		
	#print("Change:%s -> %s" % [current_state_name, state_funcs.name] )	
	_current_state_functions = state_funcs
	#print(state_funcs)
	
	#call the new state's enter if there is one
	if !_current_state_functions.is_empty() && _current_state_functions["enter"].is_valid():
		_current_state_functions["enter"].call()

	#setup the update and physics functions if they exist
	if !_current_state_functions.is_empty() && _current_state_functions["update"].is_valid() && !stopped:
		current_update = _current_state_functions["update"]

	changing_states = false
	changed_state.emit()
	
func update(delta:float):
	if current_update.is_valid():
		current_update.call(delta)
