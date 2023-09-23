class_name SettingsData
extends Object

const MIN_DB_VOL = -45 # actually, it is -80db for full off
const MAX_DB_VOL = 0 # it goes up to 24 but we don't allow that

const SETTINGS_FILE :StringName= "user://settings.dat"
const SETTINGS_SECTION :StringName= "Settings"

#These are the default values that we store in the settings file
const S_MASTER :StringName= "masterVol"
const S_SFX :StringName= "sfxVol"
const S_MUSIC :StringName= "musicVol"
const S_AMBIENT :StringName= "ambientVol"
const S_FULLSCREEN :StringName= "fullscreen"
#if true, then the CRT shader is enabled
const S_CRT_EFFECT :StringName= "use_crt_effect"

#this holds any settings that are added via the add() function
var other_settings: Array = []

var cfg:ConfigFile

func _init():
	read()

func _set(key:StringName, val:Variant) -> bool:
	cfg.set_value(SETTINGS_SECTION, key, val)
	return true

func _get(key:StringName):
	match key:
		S_MASTER, S_SFX, S_MUSIC, S_AMBIENT: return cfg.get_value(SETTINGS_SECTION, key, 100)
		S_FULLSCREEN: return cfg.get_value(SETTINGS_SECTION, key, false)
		S_CRT_EFFECT: return cfg.get_value(SETTINGS_SECTION, key, false)
		#Add any more settings default values here
		_: 
			if other_settings.has(key): 
				return cfg.get_value(SETTINGS_SECTION, key)
			printerr("'%s' is not a valid setting!" % key)
			return 0

func add(key:String, val, section:String="Settings"):
	if cfg.has_section_key(section, key): return
	cfg.set_value(section, key, val)
	
# Note: I'm not checking error codes ...
func read(filename:String = SETTINGS_FILE):
	cfg = ConfigFile.new()
	if !FileAccess.file_exists(filename):
		cfg.save(filename)
	else:
		cfg.load(filename)

# Note: I'm not checking error codes ...
func save(filename:String = SETTINGS_FILE):
	if cfg == null:
		printerr("Config is not loaded!")
	else:
		cfg.save(filename)

static func set_vol(bus_name:String, value_db:int):
	var index = AudioServer.get_bus_index(bus_name)
	if index > -1:
		AudioServer.set_bus_volume_db(index, value_db)
		AudioServer.set_bus_mute(index, value_db == MIN_DB_VOL)		
