
extends RefCounted

var settings_list: VBoxContainer


# Получает контейнер для отображения настроек.
func _init(list: VBoxContainer) -> void:
	settings_list = list


# Показывает настройки языка.
func show_settings() -> void:
	_clear_settings()

	var language_button := _add_setting(
		tr("Язык интерфейса"),
		_get_language_name()
	)

	language_button.pressed.connect(_toggle_language)


# Безопасно удаляет элементы предыдущей вкладки.
func _clear_settings() -> void:
	for child in settings_list.get_children():
		settings_list.remove_child(child)
		child.queue_free()


# Создаёт название настройки и кнопку значения.
func _add_setting(label_text: String, button_text: String) -> Button:
	var label := Label.new()
	label.text = label_text

	var button := Button.new()
	button.text = button_text

	settings_list.add_child(label)
	settings_list.add_child(button)

	return button


# Переключает язык.
func _toggle_language() -> void:
	var next_locale := "en" if LocalisationManager.current_locale == "ru" else "ru"
	LocalisationManager.set_locale(next_locale)


# Возвращает название текущего языка.
func _get_language_name() -> String:
	if LocalisationManager.current_locale == "ru":
		return tr("Русский")

	return tr("Английский")
