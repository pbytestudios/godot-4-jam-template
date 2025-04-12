extends RefCounted
class_name Machine

# Suffixes considered valid state suffixes (_fixed_update must come before _update!)
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
var _state_map = {}
# holds the previous state functions
var _previous_state_functions:Dictionary = {}
# holds the current state functions
var _current_state_functions:Dictionary = {}

# If true, the state machine will call the exit function of the current state even if the next state is the same state
var _allow_exit_to_same:bool
# If true, the state machine will call the enter function of the current state even if the next state is the same state
var _allow_enter_to_same:bool

var current_update:Callable = update_empty
var current_fixed_update:Callable = update_empty

# emitted AFTER the new state's enter method has been called
signal changed_state

# function naming: the 'enter' callable will be used to name the state
# if there is no enter function, then update, then exit
func add(enter:Callable, update:Callable = Callable(), exit:Callable = Callable(), _fixed_update = Callable(), call_enter_on_same:bool = true, call_exit_on_same:bool = true):
	var state_name:String = ""
	
	# Get the name of the state by trying the enter function 1st, then the other twqo
	if enter.is_valid():
		state_name = _get_state_name(enter)
	if state_name.is_empty() && update.is_valid():
		state_name = _get_state_name(update)
	if state_name.is_empty() && exit.is_valid():
		state_name = _get_state_name(exit)
	if state_name.is_empty() && _fixed_update.is_valid():
		state_name = _get_state_name(_fixed_update)

	#Create a 'map' of this state and its methods
	var map:Dictionary = {}
	map.enter = enter
	map.update = update
	map.exit = exit
	map.name = state_name
	
	map.fixed_update = _fixed_update
	# if true and the next state is the same as the current, it's enter function (if valid) is called
	map.allow_reentry = call_enter_on_same
	# if true and the next state is the same as the current, it's exit function (if valid) is called
	map.allow_reexit = call_exit_on_same
	
	if _state_map.has(state_name):
		push_warning("[Machine] Warning: State name '%s' already in map!" % state_name)
		
	_state_map[state_name] = map
	
func remove(state_func:Callable):
	var state_name:String = ""
	state_name = _get_state_name(state_func)
	if state_name.is_empty():
		push_warning("[Machine] Warning: Unable to get state name from %s" % state_func.get_method().get_basename())
	elif !_state_map.has(state_name):
		push_warning("[Machine] Warning: Map does not contain '%s'" % state_name)
	else:
		_state_map.erase(state_name)

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

func lock():
	if locked:
		push_warning("state machine is already locked")
	locked = true

func unlock():
	if locked:
		locked = false
	else:
		push_warning("state machine is not locked")

func change_prev() -> bool:
	if _previous_state_functions.is_empty():
		printerr("No previous state recorded!")
		return false
	else:
		#_change_state.call_deferred(_change_state, _previous_state_functions)
		_change_state(_previous_state_functions)
		return true
		
func change(to:Callable, lock:bool = false):
	if stopped:
		push_warning("You must call start() to start the machine!")
		return
	elif locked:
		push_warning("'locked' is true. ignoring change %s -> %s" % [current_state_name, _get_state_name(to)])
		return
	if lock:
		locked = true
	
	
	var state_name = _get_state_name(to)
	#print("%s => %s" % [current_state_name, state_name])
	if !_state_map.has(state_name):
		printerr("Cannot find state: %s!" % to)
		transitioning_to = ""
		return
	else:
		transitioning_to = state_name
	
	await _change_state(_state_map[state_name])

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
	current_update = update_empty
	current_fixed_update = update_empty

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
	if !_current_state_functions.is_empty() && _current_state_functions.enter.is_valid() &&\
	(state_funcs != _current_state_functions || _current_state_functions.allow_reentry):
		await _current_state_functions.enter.call()

	#setup the update and physics functions if they exist
	if !_current_state_functions.is_empty() && !stopped:
		if _current_state_functions.update.is_valid():
			current_update = _current_state_functions.update
		if _current_state_functions.fixed_update.is_valid():
			current_fixed_update = _current_state_functions.fixed_update

	changing_states = false
	changed_state.emit()

#an empty update function
func update_empty(delta:float): pass

func update(delta:float):
	if !stopped && !changing_states:
		current_update.call(delta)

func fixed_update(delta:float):
	if !stopped && !changing_states:
		current_fixed_update.call(delta)
