extends RefCounted
class_name FuncMachine

# Suffixes considered valid state suffixes (_fixed_update must come before _update here or it wil not work!)
const VALID_METHOD_SUFFIXES :Array[StringName] = ["_enter", "_fixed_update", "_update", "_exit"]

# 2024 Pixelbyte Studios
# a state machine using Callables
# this allows all states ot be contained within 1 script

var current_state_name:StringName:
	get: 
		if _current_state_functions.is_empty():
			return ""
		else:
			return _current_state_functions.name

var previous_state_name:StringName:
	get: 
		if _previous_state_functions.is_empty():
			return ""
		else:
			return _previous_state_functions.name

var transitioning_to:StringName = "":
	get: return transitioning_to
	
var stopped:bool = true:
	get: return stopped

# true when the machine is changing to another state
# set to false AFTER the new state's enter method is called
var changing_states:bool:
	get: return changing_states

## If true, then any state changes are ignored
## Useful for death states
var locked:bool = false:
	get: return locked

# this holds all the states and their functions
var _map = {}
# holds the previous state functions
var _previous_state_functions:Dictionary = {}
# holds the current state functions
var _current_state_functions:Dictionary = {}

var current_update:Callable = _update_empty
var current_fixed_update:Callable = _update_empty

# emitted AFTER the new state's enter method has been called
signal changed_state

# function naming: the 'enter' callable will be used to name the state
# if there is no enter function, then update, then exit
func add(enter:Callable, _update:Callable = Callable(), exit:Callable = Callable(), _fixed_update = Callable(), call_enter_on_same:bool = true, call_exit_on_same:bool = true):
	var state_name:String = ""
	
	# Get the name of the state by trying the enter function 1st, then the other twqo
	if enter.is_valid():
		state_name = _get_state_name(enter)
	if state_name.is_empty() && _update.is_valid():
		state_name = _get_state_name(_update)
	if state_name.is_empty() && exit.is_valid():
		state_name = _get_state_name(exit)
	if state_name.is_empty() && _fixed_update.is_valid():
		state_name = _get_state_name(_fixed_update)

	#Create a 'map' of this state and its methods
	var state_info:Dictionary = {}
	state_info.enter = enter
	state_info.update = _update
	state_info.fixed_update = _fixed_update
	state_info.exit = exit
	state_info.name = state_name
	
	# if true and the next state is the same as the current, it's enter function (if valid) is called
	state_info.allow_reentry = call_enter_on_same
	# if true and the next state is the same as the current, it's exit function (if valid) is called
	state_info.allow_reexit = call_exit_on_same
	
	if _map.has(state_name):
		push_warning("[FuncMachine] State '%s' already in map!" % state_name)
		
	_map[state_name] = state_info
	
func remove(state_func:Callable):
	var state_name:String = ""
	state_name = _get_state_name(state_func)
	if state_name.is_empty():
		push_warning("[FuncMachine] Unable to get state name from %s" % state_func.get_method().get_basename())
	elif !_map.has(state_name):
		push_warning("[FuncMachine] Map does not contain '%s'" % state_name)
	else:
		_map.erase(state_name)

## Starts the state machine with the given state
func start(starting:Callable):
	stopped = false
	change(starting)
	
## Stops the state machine
## Note: the currently-running state's exit function will be called if it exists
##
func stop():
	stopped = true
	current_state_name = ""
	_change_state({})

func lock(): locked = true
func unlock(): locked = false

func change_prev() -> bool:
	if _previous_state_functions.is_empty():
		printerr("[FuncMachine]: No previous state recorded!")
		return false
	else:
		#_change_state.call_deferred(_change_state, _previous_state_functions)
		_change_state(_previous_state_functions)
		return true
		
func change(to:Callable, _lock:bool = false):
	if stopped:
		push_warning("[FuncMachine]: call start() to start the machine!")
		return
	elif locked:
		push_warning("[FuncMachine]:'locked' is true. ignoring change %s -> %s" % [current_state_name, _get_state_name(to)])
		return
	
	locked = _lock
	
	
	var state_name = _get_state_name(to)
	#print("%s => %s" % [current_state_name, state_name])
	if !_map.has(state_name):
		printerr("[FuncMachine]:Cannot find state: %s!" % to)
		transitioning_to = ""
		return
	if state_name == current_state_name:
		printerr("[FuncMachine]:Cannot change to the same state '%s'!" % state_name)
		return

	transitioning_to = state_name
	await _change_state(_map[state_name])

func _get_state_name(callable:Callable) -> String: 
	var name:String = ""
	if callable.is_valid():
		name =  callable.get_method().get_basename().trim_prefix("_")
		# trim all possible suffixes for a state function
		for suffix in VALID_METHOD_SUFFIXES:
			name = name.trim_suffix(suffix)
	return name

func _change_state(state_funcs:Dictionary):
	if changing_states:
		await changed_state
			
	changing_states = true
	
	#clear the update function, so we don't run it during the transition
	current_update = _update_empty
	current_fixed_update = _update_empty

	if !_current_state_functions.is_empty() && _current_state_functions.exit.is_valid() && \
	(state_funcs != _current_state_functions || _current_state_functions.allow_reexit):
		await _current_state_functions.exit.call()
	
	if state_funcs != _current_state_functions:
		_previous_state_functions = _current_state_functions
		
	#print("Change:%s -> %s" % [current_state_name, state_funcs.name] )	
	#print("%s" % [state_funcs.name] )	
	_current_state_functions = state_funcs
	transitioning_to = ""
	#print(state_funcs)
	
	#call the new state's enter if there is one
	if !state_funcs.is_empty() && state_funcs.enter.is_valid() &&\
	(state_funcs != state_funcs || state_funcs.allow_reentry):
		await state_funcs.enter.call()

	#setup the update and physics functions if they exist
	if !_current_state_functions.is_empty() && !stopped:
		if _current_state_functions.update.is_valid():
			current_update = _current_state_functions.update
		if _current_state_functions.fixed_update.is_valid():
			current_fixed_update = _current_state_functions.fixed_update

	changing_states = false
	changed_state.emit()

#an empty update function
func _update_empty(delta:float): pass

## Call this function in your script's _process()
func update(delta:float):
	if !stopped && !changing_states:
		current_update.call(delta)

## Call this function in your script's fixed_process()
func fixed_update(delta:float):
	if !stopped && !changing_states:
		current_fixed_update.call(delta)
