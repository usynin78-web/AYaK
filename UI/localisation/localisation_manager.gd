extends Node

# Supported language codes. Russian is the fallback and first-run language.
const SUPPORTED_LOCALES := ["ru", "en"]
const CONFIG_PATH := "user://localisation.cfg"

signal locale_changed(locale: String)

var current_locale: String = "ru"


func _ready() -> void:
	var config := ConfigFile.new()
	var error := config.load(CONFIG_PATH)

	if error == OK:
		var saved_locale := str(config.get_value("localisation", "locale", "ru"))
		if SUPPORTED_LOCALES.has(saved_locale):
			current_locale = saved_locale
	elif error != ERR_FILE_NOT_FOUND:
		push_warning("Could not load localisation settings: %s" % error)

	TranslationServer.set_locale(current_locale)


# Applies a supported locale immediately and stores it for the next launch.
func set_locale(locale: String) -> void:
	if not SUPPORTED_LOCALES.has(locale):
		push_warning("Unsupported locale: " + locale)
		return

	var changed := current_locale != locale
	current_locale = locale
	TranslationServer.set_locale(locale)

	var config := ConfigFile.new()
	config.set_value("localisation", "locale", locale)
	var error := config.save(CONFIG_PATH)
	if error != OK:
		push_warning("Could not save localisation settings: %s" % error)

	if changed:
		locale_changed.emit(locale)
