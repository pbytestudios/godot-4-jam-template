extends Node

# This script should be added to autoloads
# then, the player (or interactor) should set InteractMgr.target
#

@export var interact_label:Label
@export var prefix_text:String = ""
@export var interact_action_name:String = "interact"

#
# The target is the interactor and should be set by the interactor
#
var target:Node2D:
	get: return target
	set(val): target = val

var _active_areas : Array[Interactable] = []
var _can_interact := true

func register(area:Interactable):
	if !_active_areas.has(area):
		_active_areas.push_back(area)

func unregister(area:Interactable):
	_active_areas.erase(area)
	
func _process(delta: float) -> void:
	if _active_areas.size() == 0 || !_can_interact:
		interact_label.hide()
		return

	#determine which interactable is closest to the target and display that
	_active_areas.sort_custom(_sort_by_distance_to_target)
	interact_label.text = prefix_text + _active_areas[0].action_name
	#doing it this way keeps the text from rotating if the object does
	interact_label.global_position = _active_areas[0].global_position + _active_areas[0].label_offset_local
	interact_label.global_position.x -= interact_label.size.x / 2
	interact_label.global_position.y -= interact_label.size.y
	interact_label.show()

func _sort_by_distance_to_target(areaA:Interactable, areaB:Interactable):
	var AtoTarget :float = target.global_position.distance_squared_to(areaA.global_position)
	var BtoTarget :float = target.global_position.distance_squared_to(areaB.global_position)
	return AtoTarget < BtoTarget

func _unhandled_input(event: InputEvent) -> void:
	if _active_areas.size() > 0 && _can_interact && event.is_action_pressed(interact_action_name):
		get_viewport().set_input_as_handled()
		_can_interact = false
		interact_label.hide()
		#if the interact method is async, await it, otherwise it will return immediately
		await _active_areas[0].interact.call()
		_can_interact = true
