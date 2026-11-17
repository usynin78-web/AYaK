extends Node

# Поддерживаемые языки интерфейса.
const SUPPORTED_LOCALES := ["ru", "en"]
const CONFIG_PATH := "user://localisation.cfg"

signal locale_changed(locale: String)

var current_locale: String = "ru"


func _ready() -> void:
	var config := ConfigFile.new()
	var error := config.load(CONFIG_PATH)

	if error == OK:
		# Если язык уже был выбран игроком, сохраняем его выбор.
		var saved_locale := str(config.get_value("localisation", "locale", "ru"))
		if SUPPORTED_LOCALES.has(saved_locale):
			current_locale = saved_locale
		else:
			current_locale = _detect_system_locale()
	elif error == ERR_FILE_NOT_FOUND:
		# При первом запуске выбираем язык по настройкам операционной системы.
		current_locale = _detect_system_locale()
		_save_locale(current_locale)
	else:
		push_warning("Could not load localisation settings: %s" % error)
		current_locale = _detect_system_locale()

	TranslationServer.set_locale(current_locale)


# Определяет язык системы и сопоставляет его с поддерживаемыми языками игры.
func _detect_system_locale() -> String:
	var system_language := OS.get_locale_language().to_lower()

	# Учитываем региональные варианты: ru_RU, ru, en_US, en_GB и подобные.
	if system_language.begins_with("en"):
		return "en"
	if system_language.begins_with("ru"):
		return "ru"

	# Если язык системы не поддерживается, используем русский.
	return "ru"


# Сохраняет выбранный язык в отдельный CFG-файл.
func _save_locale(locale: String) -> void:
	var config := ConfigFile.new()
	config.set_value("localisation", "locale", locale)

	var error := config.save(CONFIG_PATH)
	if error != OK:
		push_warning("Could not save localisation settings: %s" % error)


# Применяет выбранный игроком язык и запоминает его для следующих запусков.
func set_locale(locale: String) -> void:
	if not SUPPORTED_LOCALES.has(locale):
		push_warning("Unsupported locale: " + locale)
		return

	var changed := current_locale != locale
	current_locale = locale
	TranslationServer.set_locale(locale)
	_save_locale(locale)

	if changed:
		locale_changed.emit(locale)
