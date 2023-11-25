@tool
extends EditorPlugin

const PIXELCAM2D = "PixelCam2D"
const SOUNDER2D = "Sounder2D"
const SOUNDER = "Sounder"
const DIALOG = "DialogBox"
const FLASHBAR = "FlashBar"

func _enter_tree() -> void:
	add_custom_type(PIXELCAM2D, "Camera2D", preload("scripts/PixelCam2D.gd"), null)
	add_custom_type(SOUNDER2D, "AudioStreamPlayer2D", preload("scripts/Sounder2D.gd"), null)
	add_custom_type(SOUNDER, "AudioStreamPlayer", preload("scripts/Sounder.gd"), null)
#	add_custom_type(DIALOG, "PanelContainer", preload("scripts/ui/DialogBox.gd"), null)
#	add_custom_type(FLASHBAR, "PanelContainer", preload("scripts/ui/FlashBar.gd"), null)

func _exit_tree() -> void:
	remove_custom_type(PIXELCAM2D)
	remove_custom_type(SOUNDER2D)
	remove_custom_type(SOUNDER)
	remove_custom_type(FLASHBAR)
