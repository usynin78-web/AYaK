extends Node

# Общий файл пользовательских настроек.
const CONFIG_PATH := "user://settings.cfg"

# Настройки графики.
var show_fps: bool = true
var fps_limit: int = 60

# Настройки экрана.
var resolution: Vector2i = Vector2i(1920, 1080)
var window_mode: int = DisplayServer.WINDOW_MODE_FULLSCREEN
var vsync_mode: int = DisplayServer.VSYNC_ENABLED


func _ready() -> void:
	load_settings()
	apply_settings()


# Загружает настройки из CFG. Если файла ещё нет, создаёт его
# со значениями по умолчанию, не затрагивая уже сохранённые данные.
func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(CONFIG_PATH)

	if error == ERR_FILE_NOT_FOUND:
		save_settings()
		return
	elif error != OK:
		push_warning("Не удалось загрузить настройки: %s" % error)
		return

	show_fps = bool(config.get_value("graphics", "show_fps", show_fps))
	fps_limit = int(config.get_value("graphics", "fps_limit", fps_limit))

	var saved_resolution: Vector2i = config.get_value("screen", "resolution", resolution)
	if saved_resolution.x > 0 and saved_resolution.y > 0:
		resolution = saved_resolution

	window_mode = int(config.get_value("screen", "window_mode", window_mode))
	vsync_mode = int(config.get_value("screen", "vsync_mode", vsync_mode))

	# Не допускаем неизвестные значения из повреждённого или устаревшего CFG.
	if not [30, 60, 120, 144, 0].has(fps_limit):
		fps_limit = 60
	if not [
		DisplayServer.WINDOW_MODE_WINDOWED,
		DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	].has(window_mode):
		window_mode = DisplayServer.WINDOW_MODE_WINDOWED
	if not [
		DisplayServer.VSYNC_DISABLED,
		DisplayServer.VSYNC_ENABLED,
		DisplayServer.VSYNC_ADAPTIVE,
		DisplayServer.VSYNC_MAILBOX
	].has(vsync_mode):
		vsync_mode = DisplayServer.VSYNC_ENABLED


# Применяет загруженные параметры к игровому окну и движку.
func apply_settings() -> void:
	Engine.max_fps = fps_limit
	DisplayServer.window_set_size(resolution)
	DisplayServer.window_set_mode(window_mode)
	DisplayServer.window_set_vsync_mode(vsync_mode)


# Записывает все настройки в один CFG-файл.
func save_settings() -> void:
	var config := ConfigFile.new()

	config.set_value("graphics", "show_fps", show_fps)
	config.set_value("graphics", "fps_limit", fps_limit)

	config.set_value("screen", "resolution", resolution)
	config.set_value("screen", "window_mode", window_mode)
	config.set_value("screen", "vsync_mode", vsync_mode)

	var error := config.save(CONFIG_PATH)
	if error != OK:
		push_warning("Не удалось сохранить настройки: %s" % error)


# Вызывается после изменения отдельного параметра.
func set_show_fps(value: bool) -> void:
	show_fps = value
	save_settings()


func set_fps_limit(value: int) -> void:
	fps_limit = value
	Engine.max_fps = fps_limit
	save_settings()


func set_resolution(value: Vector2i) -> void:
	if value.x <= 0 or value.y <= 0:
		return
	resolution = value
	DisplayServer.window_set_size(resolution)
	save_settings()


func set_window_mode(value: int) -> void:
	window_mode = value
	DisplayServer.window_set_mode(window_mode)
	save_settings()


func set_vsync_mode(value: int) -> void:
	vsync_mode = value
	DisplayServer.window_set_vsync_mode(vsync_mode)
	save_settings()
