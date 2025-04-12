extends Label

enum LabelReadyState {None, ClearOnReady, PrefixOnReady}

@export var prefix:String = ""
@export var suffix:String = ""

@export var label_ready_state:LabelReadyState = LabelReadyState.None

func _ready() -> void:
	match label_ready_state:
		LabelReadyState.ClearOnReady:
			text = ""
		LabelReadyState.PrefixOnReady:
			text = prefix


func _receive_int(val:int):
	text = "%s%d%s" % [prefix, val, suffix]
	
func _receive_float(val:float):
	text = "%s%.2f%s" % [prefix, val, suffix]

func _receive_str(val:String):
	text = "%s%s%s" % [prefix, val, suffix]
