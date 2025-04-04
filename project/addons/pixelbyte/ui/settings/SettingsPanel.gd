class_name SettingsPanel
extends Dialog

var settings:SettingsData:
	get: return settings

var music_bus_index :int:
	get: return music_bus_index

var sfx_bus_index :int:
	get: return sfx_bus_index

var ambient_bus_index :int:
	get: return ambient_bus_index

func _write_settings(): settings.save()
func _read_settings(): 
	settings.read()
	_update_from_settings()
	
func _init():
	settings = SettingsData.new()

func _ready():
	music_bus_index = AudioServer.get_bus_index("Music")
	sfx_bus_index = AudioServer.get_bus_index("Sfx")
	ambient_bus_index = AudioServer.get_bus_index("Ambient")
	
	closed.connect(_on_update_settings)
	
	if OS.get_name() == "Android":
		$MC/Controls/CheckBoxContainer.visible = false
	
	_update_from_settings()
	_connect_signals()
	super._ready()

func _on_update_settings(res:String):
	if res != "Ok":
		_read_settings()
	else:
		_write_settings()	
func _closed_with_escape():
	_read_settings()
	
func _update_from_settings():
	_set_slider_settings($MC/Controls/MasterGroup/MasterSlider, _limit_audio_vol(settings.masterVol))
	_on_slider_changed(settings.masterVol, "masterVol", "Master", $MC/Controls/MasterGroup/Value)
	
	# Disable any channels that don't exist in the AudioBus
	# Assume 'Master' always exists!
	if music_bus_index == -1:
		$MC/Controls/MusicGroup.visible = false
	else:
		_set_slider_settings($MC/Controls/MusicGroup/MusicSlider, _limit_audio_vol(settings.musicVol))
		_on_slider_changed(settings.musicVol, "musicVol", "Music", $MC/Controls/MusicGroup/Value)
		
	if sfx_bus_index == -1:
		$MC/Controls/SfxGroup.visible = false
	else:
		_set_slider_settings($MC/Controls/SfxGroup/SfxSlider, _limit_audio_vol(settings.sfxVol))
		_on_slider_changed(settings.sfxVol, "sfxVol", "Sfx", $MC/Controls/SfxGroup/Value)
		
	if ambient_bus_index == -1:
		$MC/Controls/AmbientGroup.visible = false
	else:
		_set_slider_settings($MC/Controls/AmbientGroup/AmbientSlider, _limit_audio_vol(settings.ambientVol))
		_on_slider_changed(settings.ambientVol, "ambientVol", "Ambient", $MC/Controls/AmbientGroup/Value)
	
	if OS.get_name() != "Android":
		$MC/Controls/CheckBoxContainer/FullscreenCheck.set_pressed_no_signal(settings.fullscreen)
		DisplayServer.window_set_mode(settings.fullscreen)

func _limit_audio_vol(value:float) -> float: return clamp(value, 0, 100)
func _convert_percent_to_db(value:int) -> float:
	return remap(value, 0, 100, SettingsData.MIN_DB_VOL, SettingsData.MAX_DB_VOL)

func _set_slider_settings(slider:Slider, value:float = 0):
	if slider == null:
		printerr("Specified slider does not exist!")
	else:
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = value

func _connect_signals():
	var slider:Slider = $MC/Controls/MasterGroup/MasterSlider
	slider.value_changed.connect(_on_slider_changed.bind("masterVol", "Master", $MC/Controls/MasterGroup/Value))
	slider = $MC/Controls/SfxGroup/SfxSlider
	slider.value_changed.connect(_on_slider_changed.bind("sfxVol", "Sfx", $MC/Controls/SfxGroup/Value))
	slider = $MC/Controls/MusicGroup/MusicSlider
	slider.value_changed.connect(_on_slider_changed.bind("musicVol", "Music", $MC/Controls/MusicGroup/Value))
	slider = $MC/Controls/AmbientGroup/AmbientSlider
	slider.value_changed.connect(_on_slider_changed.bind("ambientVol", "Ambient", $MC/Controls/AmbientGroup/Value))
	
	var checkbox:CheckBox = $MC/Controls/CheckBoxContainer/FullscreenCheck
	if !checkbox.toggled.is_connected(_on_FullscreenCheck_toggled):
		checkbox.toggled.connect(_on_FullscreenCheck_toggled)
	
func _on_slider_changed(value:int, propName:StringName, busName:StringName, label:Label):
	settings._set(propName, value)
	_set_bus(busName,label, value)

func _set_bus(name:String, label:Label, value:int):
	label.text = "%s%%" % value
	var db = _convert_percent_to_db(value)
	settings.set_vol(name, db)

func _on_FullscreenCheck_toggled(checked: bool):
	settings.fullscreen = checked
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if checked else DisplayServer.WINDOW_MODE_WINDOWED)
