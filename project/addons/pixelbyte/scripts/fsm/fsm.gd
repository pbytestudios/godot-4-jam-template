class_name FSM
extends Node

# 2023 Pixelbyte Studios 
# This is an FSM which uses separate scripts for each state

var prev_state : FSM_State
var current_state : FSM_State

var state_name:StringName:
	get: 
		if current_state == null: return ""
		else: return current_state.scene_file_path.get_basename()
		
func previous() -> void:
	change(prev_state)

func change(new_state:FSM_State) -> void:
	if current_state != null:
		await current_state._exit()
	
	prev_state = current_state
	current_state = new_state
	if current_state != null:
		current_state._enter()
