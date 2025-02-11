class_name SettingsData
extends RefCounted

const SETTINGS_SECTION := "Settings"

var cfg:ConfigFile
var cfg_storage:CfgStore
var _defaults : Dictionary
var _settings_filename:String

func _init(filename:String = "settings.dat"):
	_settings_filename = filename
	cfg_storage = CfgStore.new()
	read()

func _set(key:StringName, val) -> bool:
	#only set the value if there is no default for it or if it is not the default
	if !_key_is_default(key, val):
		# snap all floats to 2 decimal places
		if typeof(_defaults[key]) == TYPE_FLOAT:
			cfg.set_value(SETTINGS_SECTION, key, snapped(val, 0.01))
		else:
			cfg.set_value(SETTINGS_SECTION, key, val)
	else: 
		#erase this key in the config because it is a default. no need to save it
		cfg.set_value(SETTINGS_SECTION, key, null)
	return true

func _key_is_default(key:StringName, val):
	if !_defaults.has(key):
		return false
	
	if typeof(_defaults[key]) == TYPE_FLOAT:
		return snapped(_defaults[key], 0.01) == snapped(val, 0.01)
	else:
		return _defaults.has(key) and _defaults[key] == val

# this allows me to add default settings values so that if a value is 
# not present in the cfg file, these will be returned instead
func set_default(key:StringName, val):
	_defaults[key] = val

# this will setup the defaults dictionary
# note: this will overwrite any matching keys
func set_defaults(new_defaults:Dictionary):
	if new_defaults && !new_defaults.is_empty():
		for k in new_defaults.keys():
			_defaults[k] = new_defaults[k]

# overridden _get(key)
func _get(key:StringName):
	if cfg.has_section_key(SETTINGS_SECTION, key):
		return cfg.get_value(SETTINGS_SECTION, key)
	elif _defaults.has(key):
		return _defaults[key]
	else:
		return null
	
func read():
	if !cfg_storage.exists(_settings_filename):
		cfg = ConfigFile.new()
	else:
		cfg = cfg_storage.read(_settings_filename)
	
func save():
	if cfg == null:
		push_error("Config is not loaded!")
	elif cfg.has_section(SETTINGS_SECTION):
		cfg_storage.write(_settings_filename, cfg)
