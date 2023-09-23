class_name SettingsPanel
extends Dialog

var settings:SettingsData:
	get: return settings

var music_bus_index :int
var sfx_bus_index :int
var ambient_bus_index :int

func write_settings(): settings.save()
func read_settings(): 
	settings.read()
	update_from_settings()
	
func _button_pressed(btn:Button):
	super._button_pressed(btn)
	if result == "Cancel" or result == "No":
		read_settings()
	else:
		write_settings()

func _init():
	settings = SettingsData.new()

func _ready():
	music_bus_index = AudioServer.get_bus_index("Music")
	sfx_bus_index = AudioServer.get_bus_index("Sfx")
	ambient_bus_index = AudioServer.get_bus_index("Ambient")
	
	if OS.get_name() == "Android":
		$MC/Controls/CheckBoxContainer.visible = false
	
	update_from_settings()
	_connect_signals()
	super._ready()

func _closed_with_escape():
	result = "Cancel"
	read_settings()
	
func update_from_settings():
	set_slider_settings($MC/Controls/MasterGroup/MasterSlider, limit_audio_vol(settings.masterVol))
	_on_slider_changed(settings.masterVol, "masterVol", "Master", $MC/Controls/MasterGroup/Value)
	
	# Disable any channels that don't exist in the AudioBus
	# Assume 'Master' always exists!
	if music_bus_index == -1:
		$MC/Controls/MusicGroup.visible = false
	else:
		set_slider_settings($MC/Controls/MusicGroup/MusicSlider, limit_audio_vol(settings.musicVol))
		_on_slider_changed(settings.musicVol, "musicVol", "Music", $MC/Controls/MusicGroup/Value)
		
	if sfx_bus_index == -1:
		$MC/Controls/SfxGroup.visible = false
	else:
		set_slider_settings($MC/Controls/SfxGroup/SfxSlider, limit_audio_vol(settings.sfxVol))
		_on_slider_changed(settings.sfxVol, "sfxVol", "Sfx", $MC/Controls/SfxGroup/Value)
		
	if ambient_bus_index == -1:
		$MC/Controls/AmbientGroup.visible = false
	else:
		set_slider_settings($MC/Controls/AmbientGroup/AmbientSlider, limit_audio_vol(settings.ambientVol))
		_on_slider_changed(settings.ambientVol, "ambientVol", "Ambient", $MC/Controls/AmbientGroup/Value)
	
	if OS.get_name() != "Android":
		$MC/Controls/CheckBoxContainer/FullscreenCheck.set_pressed_no_signal(settings.fullscreen)
		DisplayServer.window_set_mode(settings.fullscreen)

func limit_audio_vol(value:float) -> float: return clamp(value, 0, 100)
func convert_percent_to_db(value:int) -> float:
	return remap(value, 0, 100, SettingsData.MIN_DB_VOL, SettingsData.MAX_DB_VOL)

func set_slider_settings(slider:Slider, value:float = 0):
	if slider == null:
		printerr("Specified slider does not exist!")
	else:
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = value

func _connect_signals():
	var slider:Slider = $MC/Controls/MasterGroup/MasterSlider
	if !slider.value_changed.is_connected(_on_slider_changed):
		slider.value_changed.connect(_on_slider_changed.bind("masterVol", "Master", $MC/Controls/MasterGroup/Value))
	slider = $MC/Controls/SfxGroup/SfxSlider
	if !slider.value_changed.is_connected(_on_slider_changed):
		slider.value_changed.connect(_on_slider_changed.bind("sfxVol", "Sfx", $MC/Controls/SfxGroup/Value))
	slider = $MC/Controls/MusicGroup/MusicSlider
	if !slider.value_changed.is_connected(_on_slider_changed):
		slider.value_changed.connect(_on_slider_changed.bind("musicVol", "Music", $MC/Controls/MusicGroup/Value))
	slider = $MC/Controls/AmbientGroup/AmbientSlider
	if !slider.value_changed.is_connected(_on_slider_changed):
		slider.value_changed.connect(_on_slider_changed.bind("ambientVol", "Ambient", $MC/Controls/AmbientGroup/Value))
	
	var checkbox:CheckBox = $MC/Controls/CheckBoxContainer/FullscreenCheck
	if !checkbox.toggled.is_connected(_on_FullscreenCheck_toggled):
		checkbox.toggled.connect(_on_FullscreenCheck_toggled)
	
func _on_slider_changed(value:int, propName:String, busName:String, label:Label):
	settings._set(propName, value)
	set_bus(busName,label, value)

func set_bus(name:String, label:Label, value:int):
	label.text = "%s%%" % value
	var db = convert_percent_to_db(value)
	settings.set_vol(name, db)

func _on_FullscreenCheck_toggled(checked):
	settings.fullscreen = checked
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if checked else DisplayServer.WINDOW_MODE_WINDOWED)
