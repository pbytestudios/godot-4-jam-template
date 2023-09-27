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

var cfg:ConfigFile

# Defaults values for expected settings
# 
var defaults:Dictionary = {
	S_MASTER : 100, S_AMBIENT : 100, S_MUSIC : 100, S_SFX : 100,
	S_FULLSCREEN : false
}

func _init():
	read()

func _set(key:StringName, val:Variant) -> bool:
	#only set the value if there is no default for it
	# or if it is different from the default
	if cfg.has_section_key(SETTINGS_SECTION, key) or !defaults.has(key) or defaults[key] != val:
		cfg.set_value(SETTINGS_SECTION, key, val)
	return true

# this allows me to add default settings values so that if a value is 
# not present in the cfg file, these will be returned instead
func add_default(key:StringName, default:Variant):
	defaults[key] = default

func get_or_default(key:StringName):
	if cfg.has_section_key(SETTINGS_SECTION, key):
		return cfg.get_value(SETTINGS_SECTION, key)
	elif defaults.has(key):
		return defaults[key]
	else:
		return null

func _get(key:StringName):
	return get_or_default(key)
	
# Note: I'm not checking error codes ...
func read(filename:String = SETTINGS_FILE):
	cfg = ConfigFile.new()
	if FileAccess.file_exists(filename):
		cfg.load(filename)
	else: 
		for k in defaults.keys():
			cfg.set_value(SETTINGS_SECTION, k, defaults[k])
		cfg.save(filename)

# Note: I'm not checking error codes ...
func save(filename:String = SETTINGS_FILE):
	if cfg == null:
		printerr("Config is not loaded!")
	elif cfg.has_section(SETTINGS_SECTION):
		cfg.save(filename)

static func set_vol(bus_name:String, value_db:int):
	var index = AudioServer.get_bus_index(bus_name)
	if index > -1:
		AudioServer.set_bus_volume_db(index, value_db)
		AudioServer.set_bus_mute(index, value_db <= MIN_DB_VOL)		
