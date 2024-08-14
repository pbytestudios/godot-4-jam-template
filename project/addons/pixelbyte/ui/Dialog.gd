class_name Dialog
extends PanelContainer

@export var escape_closes:bool = false
@export var hide_on_ready:bool = true

@export var title_label:Label
@export var msg_label:RichTextLabel

@export var button_holder:Container
@export var veil:Control
@export var button_size:Vector2 = Vector2(100,50)

@export var animator:AnimationPlayer

signal mouse_entered_button
## Called when the dialog is closed
signal closed(result:String)

var focus_index: int = -1
# if true, then the hide_dlg() func was called internally and should ignore visible check
var _closing_with_escape:bool

var speed_scale: float:
	set(val): speed_scale = val

var title:String = "":
	get:
		if !is_instance_valid(title_label): return ""
		return title_label.text
	set(val): if is_instance_valid(title_label): title_label.text = val

var msg:String:
	get:if !is_instance_valid(msg_label): return "" 
	else: return msg_label.text
	set(val): if is_instance_valid(msg_label): msg_label.text = val

func _ready():
	if hide_on_ready:
		visible = false
	_hook_up_existing_buttons()
	
func _hook_up_existing_buttons():
	if !is_instance_valid(button_holder):
		push_warning("[%s] No Button holder to place buttons in!" % name)
		return
	#Existing buttons? hook 'em up'
	for btn in button_holder.get_children():
		var b:Button = btn
		b.pressed.connect(_button_pressed.bind(b))
		b.custom_minimum_size = button_size
		b.mouse_entered.connect(_mouse_entered.bind(b))
	focus_index = 0

func set_button_min_size():
	for btn in button_holder.get_children():
		var b:Button = btn
		b.custom_minimum_size = button_size
	
func _focus_button(index:int):
	if index < 0 || index >= button_holder.get_child_count():
		return
	var button:Button = button_holder.get_child(index)
	button.grab_focus()

func _add_button(text:String) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = button_size
	button_holder.add_child(b)
	b.pressed.connect(_button_pressed.bind(b))
	b.mouse_entered.connect(_mouse_entered.bind(b))
	return b

func _button_pressed(btn:Button):
	closed.emit(btn.text)
	hide_dlg()
	
func _remove_all_buttons():
	for child in button_holder.get_children():
		child.queue_free()
	focus_index = -1

func _remove_buttons_from_end(to_remove:int):
	if to_remove <= 0: 
		return
	var num_current = button_holder.get_child_count()
	
	for i in range(num_current - 1, num_current - 1 - to_remove,  -1):
		button_holder.get_child(i).queue_free()

func _make_buttons(num_needed:int):
	var num_current = button_holder.get_child_count()
	var to_add = num_needed - num_current
	
#	print("add: %d" % to_add)
	if to_add > 0:
		for _i in range(to_add):
			_add_button("")
	elif to_add < 0:
		_remove_buttons_from_end(-to_add)

func show_dlg() -> Dialog:
	if visible: return
	if veil:
		veil.visible = true
	
	set_button_min_size()
	
	if button_holder.get_child_count() == 0:
		_add_button("Ok")
		focus_index = 0
		
	if is_instance_valid(animator):
		if animator.has_animation("in"):
			animator.play("in")
		elif animator.has_animation("pop"):
			animator.play("pop")
		else:
			push_warning("[%s] Unable to find either 'pop' or 'in' animations!")
			await get_tree().process_frame
		
		if animator.is_playing():
			await animator.animation_finished
	show()
	_focus_button(focus_index)
	return self

#region awaitables
func inform(message:String, _title:String):
	title = _title
	msg = message
	set_buttons(["Ok"], 0)
	show_dlg()
	return self

func confirm(question:String, _title:String = "Confirm", yes:String ="Yes", no:String="No", focusYes:bool = false):
	title = _title
	msg = question
	set_buttons([yes, no], 0 if focusYes else 1)
	show_dlg()
	return self

func ask(question:String, _title:String, buttons:Array[StringName] =["Yes", "No"], default_btn_index:int = 0):
	title = _title
	msg = question
	set_buttons(buttons, min(default_btn_index, buttons.size() - 1))
	show_dlg()
	return self
#endregion

func _unhandled_input(event):
	if !visible:
		return
	
	#handle all inputs when the dialog is visible so nothing else gets them
	get_viewport().set_input_as_handled()
	
	if event is InputEventKey and event.is_pressed() and !event.is_echo() and escape_closes and visible:
		var ek : InputEventKey = event as InputEventKey
		if ek.keycode == KEY_ESCAPE:
			visible = false
			_closing_with_escape = true
			hide_dlg.call_deferred(true)
			
#override this to do something 'special' when 'escape_closes = true' and the escape key is pressed
func _closed_with_escape(): pass

func hide_dlg(closed_with_esc: bool = false):
	if !visible && !_closing_with_escape:
		return

	_closing_with_escape = false
	
	if is_instance_valid(animator):
		animator.playback_speed = speed_scale
		if animator.has_animation("out"):
			animator.play("out")
		elif animator.has_animation("pop"):
			animator.play_backwards("pop")
		else:
			push_warning("[%s] Unable to find either 'pop' or 'out' animations!")
			await get_tree().process_frame
		
		if animator.is_playing():
			await animator.animation_finished

	if is_instance_valid(veil):
		veil.visible = false

	hide()
	if closed_with_esc:
		_closed_with_escape()
		closed.emit("")
		
func set_buttons(button_names:Array[StringName], focus:int = -1):
	if button_names == null or button_names.size() == 0:
		_remove_all_buttons()
		return
	#make/delete any needed buttons
	_make_buttons(button_names.size())

	#update the button labels
	for i in range(0, button_names.size()):
		button_holder.get_child(i).text = button_names[i]
	focus_index = focus

func _mouse_entered(btn:Button):
	#don't emit the mouse_entered_button signal if the button already has focus
	if btn == get_viewport().gui_get_focus_owner():
		return
	mouse_entered_button.emit()
