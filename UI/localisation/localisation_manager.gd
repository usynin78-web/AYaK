extends Node

# Список языков, которые поддерживает игра.
const SUPPORTED_LOCALES := ["ru", "en"]

# Язык по умолчанию.
var current_locale: String = "ru"

# Сообщает интерфейсу, что язык изменился.
signal locale_changed(locale: String)


func _ready() -> void:
	set_locale(current_locale)


# Меняет язык игры. Переводы загружаются из CSV,
# подключённого в настройках проекта.
func set_locale(locale: String) -> void:
	if not SUPPORTED_LOCALES.has(locale):
		push_warning("Unsupported locale: " + locale)
		return

	current_locale = locale
	TranslationServer.set_locale(locale)
	locale_changed.emit(locale)
