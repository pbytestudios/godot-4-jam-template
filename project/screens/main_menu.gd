extends Node2D

@export var game_scene:PackedScene
@export var title_label: Label
@export var menu_effects:UIEffect

func _ready():
	if !Engine.is_editor_hint():
		#Wiper.wipe_speed = 0.5
		Wiper.wipe_immediate()
		await Wiper.unwipe()
		
	await menu_effects.play().finished
	
	if OS.get_name() == "Web":
		$Ui/PanelContainer/MarginContainer/VBoxContainer/Exit.visible = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		if title_label != null:
			title_label.text = ProjectSettings.get_setting("application/config/name")
			
func disable_buttons():
	for element in $Ui/MainMenu/MarginContainer/VBoxContainer.get_children():
		if element is Button:
			element.disabled = true
	
func _on_play():
	if game_scene != null:
		disable_buttons()
		await menu_effects.reverse().finished
		Wiper.wipe_to_packed(game_scene)
	else:
		printerr("game_scene must be specified!")

func _on_settings():
	$Ui/MainMenu.visible = false
	$Ui/SettingsPanel.show_dlg()
	await $Ui/SettingsPanel.hidden
	$Ui/MainMenu.visible = true

func _on_exit():
	disable_buttons()
	await menu_effects.reverse().finished
	await Wiper.wipe()
	get_tree().quit()
