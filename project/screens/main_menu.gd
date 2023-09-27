@tool
extends Node2D

@export var game_scene:PackedScene
@export var title_label: Label

func _ready():
	if !Engine.is_editor_hint():
		Wiper.wipe_speed = 0.5
		Wiper.wipe_immediate()
		await Wiper.unwipe()
	
	if OS.get_name() == "HTML5":
		$Ui/PanelContainer/MarginContainer/VBoxContainer/Exit.visible = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		if title_label != null:
			title_label.text = ProjectSettings.get_setting("application/config/name")
			
func disable_buttons():
	$Ui/MainMenuContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
func _on_play():
	if game_scene != null:
		disable_buttons()
		await Wiper.wipe()
		Wiper.wipe_to_packed(game_scene)
	else:
		printerr("game_scene must be specified!")

func _on_settings():
	$Ui/MainMenuContainer.visible = false
	$Ui/SettingsPanel.show_dlg()
	await $Ui/SettingsPanel.hidden
	$Ui/MainMenuContainer.visible = true

func _on_exit():
	disable_buttons()
	await Wiper.wipe()
	get_tree().quit()
