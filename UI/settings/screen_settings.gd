extends RefCounted

var settings_list: VBoxContainer
var resolutions: Array[Vector2i] = [
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1280, 720)
]
var current_resolution_index: int = 0


func _init(list: VBoxContainer) -> void:
	settings_list = list
	# Синхронизируем индекс списка с разрешением, загруженным из CFG.
	var saved_resolution: Vector2i = SettingsManager.resolution
	var saved_index := resolutions.find(saved_resolution)
	if saved_index >= 0:
		current_resolution_index = saved_index
	else:
		# Если сохранено нестандартное разрешение, добавляем его в список.
		resolutions.append(saved_resolution)
		current_resolution_index = resolutions.size() - 1


func show_settings() -> void:
	_clear_settings()

	var resolution_button := _add_setting(tr("Разрешение"), _get_resolution_name())
	resolution_button.pressed.connect(func(): _toggle_resolution(resolution_button))

	if OS.get_name() != "Android":
		var window_mode_button := _add_setting(tr("Режим окна"), _get_window_mode_name())
		window_mode_button.pressed.connect(func(): _toggle_window_mode(window_mode_button))

		var vsync_button := _add_setting(tr("V-Sync (вертикальная синхронизация)"), _get_vsync_name())
		vsync_button.pressed.connect(func(): _toggle_vsync(vsync_button))


# Безопасно очищает контейнер.
func _clear_settings() -> void:
	for child in settings_list.get_children():
		settings_list.remove_child(child)
		child.queue_free()


func _add_setting(label_text: String, button_text: String) -> Button:
	var label := Label.new()
	label.text = label_text

	var button := Button.new()
	button.text = button_text

	settings_list.add_child(label)
	settings_list.add_child(button)

	return button


func _toggle_resolution(button: Button) -> void:
	current_resolution_index = (current_resolution_index + 1) % resolutions.size()
	SettingsManager.set_resolution(resolutions[current_resolution_index])
	button.text = _get_resolution_name()


func _get_resolution_name() -> String:
	var resolution: Vector2i = resolutions[current_resolution_index]
	return "%d × %d" % [resolution.x, resolution.y]


func _toggle_vsync(button: Button) -> void:
	var current_mode: int = SettingsManager.vsync_mode
	var next_mode := (
		DisplayServer.VSYNC_DISABLED
		if current_mode != DisplayServer.VSYNC_DISABLED
		else DisplayServer.VSYNC_ENABLED
	)
	SettingsManager.set_vsync_mode(next_mode)
	button.text = _get_vsync_name()


func _get_vsync_name() -> String:
	return tr("Выкл.") if SettingsManager.vsync_mode == DisplayServer.VSYNC_DISABLED else tr("Вкл.")


func _toggle_window_mode(button: Button) -> void:
	match SettingsManager.window_mode:
		DisplayServer.WINDOW_MODE_WINDOWED:
			SettingsManager.set_window_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			SettingsManager.set_window_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			SettingsManager.set_window_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_:
			SettingsManager.set_window_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	button.text = _get_window_mode_name()


func _get_window_mode_name() -> String:
	match SettingsManager.window_mode:
		DisplayServer.WINDOW_MODE_WINDOWED:
			return tr("Оконный")
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			return tr("Полноэкранный")
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			return tr("Без рамки")
		_:
			return tr("Неизвестно")
