@tool
extends EditorPlugin

const PIXELCAM2D = "PixelCam2D"
const DIALOG = "DialogBox"
const FLASHBAR = "FlashBar"

func _enter_tree() -> void:
	add_custom_type(PIXELCAM2D, "Camera2D", preload("scripts/PixelCam2D.gd"), null)
#	add_custom_type(DIALOG, "PanelContainer", preload("scripts/ui/DialogBox.gd"), null)
#	add_custom_type(FLASHBAR, "PanelContainer", preload("scripts/ui/FlashBar.gd"), null)

func _exit_tree() -> void:
	remove_custom_type(PIXELCAM2D)
	#remove_custom_type(DIALOG)
	#remove_custom_type(FLASHBAR)
