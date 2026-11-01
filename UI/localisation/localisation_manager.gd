extends Node

const RU_TRANSLATION: Translation = preload("res://UI/localisation/translations.ru.translation")
const EN_TRANSLATION: Translation = preload("res://UI/localisation/translations.en.translation")

# Поддерживаемые языки интерфейса.
const SUPPORTED_LOCALES := ["ru", "en"]

# Текущий язык игры.
var current_locale: String = "ru"


func _ready() -> void:
	TranslationServer.add_translation(RU_TRANSLATION)
	TranslationServer.add_translation(EN_TRANSLATION)
	set_locale(current_locale)


# Переключает язык интерфейса.
func set_locale(locale: String) -> void:
	if not SUPPORTED_LOCALES.has(locale):
		push_warning("Unsupported locale: " + locale)
		return

	current_locale = locale
	TranslationServer.set_locale(locale)
	locale_changed.emit(locale)


# Сигнал для обновления динамически созданных элементов интерфейса.
signal locale_changed(locale: String)
