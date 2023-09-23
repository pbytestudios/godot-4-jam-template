extends MarginContainer
class_name TextBubble

const SPEECH_BUBBLE_WRAP_MODE := TextServer.AUTOWRAP_WORD

enum YAlign {Top, Middle, Bottom}
enum XAlign {Left, Middle, Right}

@export var yAlignment:YAlign = YAlign.Middle
@export var xAlignment:XAlign = XAlign.Middle

# If true, the text is set to fit its content and 
# the margin container will resize to fit it.
# When true, this also uses max_speech_bubble_width
@export var speech_bubble_mode := true
@export var max_speech_bubble_width:float = 250
# optional: if > 0 we scale up the popup window
@export var popup_time :float = 0
@export var letter_time : = 0.03
@export var space_time := 0.06
@export var punctuation_time := 0.2
@export var msg:RichTextLabel
# optional: if specified, this will be shown when text completes typing
@export var continue_prompt:Control
# optional: if you have a tail for a speech box, put it here
@export var tail:Control
# optional: Holds a type sound that we will play if valid
@export var type_sound:AudioStreamPlayer

# Once the dialog is showing, you can await
signal skip_pressed

#internal signal indicating when a line is done typoing
signal _finished_line

@onready var timer: Timer = $Timer

var typing := false
var skip:bool = false

# If you want to move the dialog around, use this
# since we offset it based on the H and V alignment.
var dlg_pos:Vector2:
	get: return dlg_pos
	set(val): dlg_pos = val

func _ready():
	randomize()
	dlg_pos = global_position
	visible = false
#	msg.fit_content = speech_bubble_mode
	clip_contents = !speech_bubble_mode
	msg.fit_content = true
	set_wrap_mode()
	
#	call_deferred("show_line", "Hello there my name is not all that important so ask if you need it.")
#	show_lines(["ok now.", "This is not acceptable!", "I need answers ... NOW!"], true)

func _unhandled_input(event: InputEvent) -> void:
	if !visible: return
	if !InputMap.has_action("skip_dialog"):
		push_warning("Input action 'skip_dialog' needs to be defined!", true)
		return
		
	if event.is_action_pressed("skip_dialog"):
		skip = true
		skip_pressed.emit()
		_show_continue(false)
		get_viewport().set_input_as_handled()

func set_wrap_mode():
	if speech_bubble_mode:
		msg.autowrap_mode = TextServer.AUTOWRAP_OFF
	else:
		msg.autowrap_mode = TextServer.AUTOWRAP_WORD

func say(lines:PackedStringArray, center:bool = false, pause:bool = true):
	if lines.is_empty():
		printerr("Lines are empty!")
		return
	
	#make sure we continue to process
	if pause:
		process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true	
	
	for line in lines:
		await _show_line(line, center, false)
	
	if pause:
		get_tree().paused = false
	hide()
	
func _show_line(text:String, center:bool = false, hide_when_finished:bool = true):
	skip = false
	msg.text = ""
	var was_visible = visible
	_show_continue(false)
	show()
	set_wrap_mode()
		
	if center:
		text = "[center]" + text + "[/center]"
	
	#Reset the panel's size
	if speech_bubble_mode:
		custom_minimum_size = Vector2.ZERO
		size = Vector2.ZERO

	msg.visible_characters = -1
	msg.text = text
	await msg.finished
		
	#in speech bubble mode, use the height of the margin container
	# ,set the min width, and turn on autowrap mode
	if speech_bubble_mode:	
		var desired_width = msg.get_content_width()
		custom_minimum_size.x = min(desired_width, max_speech_bubble_width)
		if desired_width > size.x:
			await resized #wait for margin container to resize to the text
		
		if desired_width > max_speech_bubble_width && max_speech_bubble_width > 0:
			msg.autowrap_mode = SPEECH_BUBBLE_WRAP_MODE
			await resized #wait for x resize
			var desired_height = msg.get_content_height()
			await resized #wait for y resize
	
	msg.visible_characters = 0
	_set_box_alignment()

	if popup_time > 0 && !was_visible:
		scale = Vector2.ZERO
		var tw = create_tween().set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(self, "scale", Vector2.ONE, popup_time)
		await tw.finished
	
	_type_text()
	await _finished_line

	_show_continue(true)
	await skip_pressed
	if hide_when_finished:
		hide()

func _type_text():
	var wait_time:float = letter_time
	typing = true
	
	#grab the parsed text without bbcode!
	var parsed_text :String = msg.get_parsed_text()
	var num_chars:int = parsed_text.length()
	
	for count in num_chars:
		msg.visible_characters = count + 1
		
		match parsed_text[count]:
			"!",".",",","?":
				timer.start(punctuation_time)
			" ":
				timer.start(space_time)
			_:
				timer.start(letter_time)
		
		if type_sound != null:
			if parsed_text[count] in ["a","e","i","o","u"]:
				type_sound.pitch_scale = randf_range(1.1, 1.4)
			else:
				type_sound.pitch_scale = randf_range(0.9, 1.1)
			type_sound.play()
			await  type_sound.finished
		
		if count < num_chars -1:
			await timer.timeout
		if skip:
			break
			
	msg.visible_characters = num_chars
	typing = false    
	_finished_line.emit()

func _set_box_alignment():
	match yAlignment:
		YAlign.Top:
			pivot_offset.y = 0
			global_position.y = dlg_pos.y
		YAlign.Middle:
			pivot_offset.y = size.y / 2
			global_position.y = dlg_pos.y - size.y / 2
		YAlign.Bottom:
			pivot_offset.y = size.y
			if tail != null:
				global_position.y = dlg_pos.y - size.y - tail.size.y
			else:
				global_position.y = dlg_pos.y - size.y
	
	match xAlignment:
		XAlign.Left:
			pivot_offset.x = 0
			global_position.x = dlg_pos.x
		XAlign.Middle:
			pivot_offset.x = size.x / 2
			global_position.x = dlg_pos.x - size.x / 2
		XAlign.Right:
			pivot_offset.x = size.x
			global_position.x = dlg_pos.x - size.x

func _show_continue(visible:bool = true):
	if continue_prompt == null:
		return
	var anim :AnimationPlayer = continue_prompt.get_node_or_null("Anim")
	if anim != null:
		if visible:
			anim.play("RESET")
			await anim.animation_finished
			anim.play("default")
			#typing = false
			#stop_type_sound()
		else:
			anim.stop()
	continue_prompt.visible = visible
