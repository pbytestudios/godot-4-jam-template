class_name ClickableArea
extends Node2D


signal clicked(button:MouseButton)
signal up(button:MouseButton)
signal double_clicked(button:MouseButton)
signal entered()
signal exited()

@export var clickable_area:Area2D

var _last_clicked_index:int = MOUSE_BUTTON_NONE

func _ready() -> void:
	if clickable_area:
		clickable_area.input_event.connect(_on_collision_input)
		clickable_area.mouse_exited.connect(_on_mouse_exited)
		clickable_area.mouse_entered.connect(func(): entered.emit())
		#_setup_timer()
	else:
		printerr("clickable_area is not defined on '%s'!" % name)

func _on_mouse_exited():
	_last_clicked_index = MOUSE_BUTTON_NONE
	exited.emit()

func _on_collision_input(viewport:Viewport, event:InputEvent, shape_idx:int):
	if event is InputEventMouseButton:
		var mbe:InputEventMouseButton = event
		
		if mbe.is_pressed():
			#_update_click_count(mbe.button_index)
			if mbe.double_click:
				double_clicked.emit(mbe.button_index)
			else:
				clicked.emit(mbe.button_index)
		elif mbe.is_released():
			up.emit(mbe.button_index)


#region DoubleClick Detection Stuff
#const DOUBLE_CLICK_WAIT := 0.150 
#var click_count:int
#var _click_timer:Timer
#func _setup_timer():
		#_click_timer = Timer.new()
		#_click_timer.timeout.connect(_on_click_timer_timeout)
		#_click_timer.one_shot = true
		#_click_timer.wait_time = DOUBLE_CLICK_WAIT
		#add_child(_click_timer)
#func _update_click_count(index:MouseButton):
	#if index != _last_clicked_index:
		#_click_timer.stop()
		#click_count = 1
	#else:
		#click_count += 1
		#
	#_last_clicked_index = index
	#
	#if _click_timer.is_stopped():
		#_click_timer.start()	
		
#func _on_click_timer_timeout():
	#if click_count == 1:
		#clicked.emit(_last_clicked_index)
		#print("click")
	#elif click_count == 2:
		#double_clicked.emit(_last_clicked_index)
		#print("Double Click Action")
	#click_count = 0
	#_last_clicked_index = MOUSE_BUTTON_NONE
#endregion
