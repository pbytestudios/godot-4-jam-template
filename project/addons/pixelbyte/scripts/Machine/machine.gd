extends RefCounted
class_name Machine

# Suffixes considered valid state suffixes
const VALID_METHOD_SUFFIXES :Array[StringName] = ["_enter", "_update", "_exit"]

# 2024 Pixelbyte Studios
# a state machine using Callables
# this allows all states ot be contained within 1 script

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

# this holds all the states and their functions
var _state_map = {}
# holds the previous state functions
var _previous_state_functions:Dictionary = {}
# holds the current state functions
var _current_state_functions:Dictionary = {}

var current_update:Callable

# emitted AFTER the new state's enter method has been called
signal changed_state

# function naming: the 'enter' callable will be used to name the state
# if there is no enter function, then update, then exit
func add(enter:Callable, update:Callable = Callable(), exit:Callable = Callable()):
	var state_name:String = ""
	
	# Get the name of the state by trying the enter function 1st, then the other twqo
	if enter.is_valid():
		state_name = _get_state_name(enter)
	if state_name.is_empty() && update.is_valid():
		state_name = _get_state_name(update)
	if state_name.is_empty() && exit.is_valid():
		state_name = _get_state_name(exit)

	#Create a 'map' of this state and its methods
	var methods:Dictionary = {}
	methods.enter = enter
	methods.update = update
	methods.exit = exit
	methods.name = state_name
	
	if _state_map.has(state_name):
		push_warning("[Machine] Warning: State name '%s' already in map!" % state_name)
		
	_state_map[state_name] = methods

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
	if !_state_map.has(state_name):
		printerr("Cannot find state: %s!" % to)
		return
	
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

	if !_current_state_functions.is_empty() && _current_state_functions.exit.is_valid():
		await _current_state_functions.exit.call()
	
	if state_funcs != _current_state_functions:
		_previous_state_functions = _current_state_functions
		
	#print("Change:%s -> %s" % [current_state_name, state_funcs.name] )	
	_current_state_functions = state_funcs
	#print(state_funcs)
	
	#call the new state's enter if there is one
	if !_current_state_functions.is_empty() && _current_state_functions.enter.is_valid():
		await _current_state_functions.enter.call()

	#setup the update and physics functions if they exist
	if !_current_state_functions.is_empty() && _current_state_functions.update.is_valid() && !stopped:
		current_update = _current_state_functions.update

	changing_states = false
	changed_state.emit()

#an empty update function
func update_empty(delta:float): pass

func update(delta:float):
	current_update.call(delta)
