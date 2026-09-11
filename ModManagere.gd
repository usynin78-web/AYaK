extends Node

signal mods_loaded

const MODS_FOLDER := "mods"

var loaded_mods: Array[String] = []
var loaded_files := {}


func _ready() -> void:
	load_mods()


func load_mods() -> void:
	loaded_mods.clear()
	loaded_files.clear()

	# Пользовательская папка
	var user_mods := ProjectSettings.globalize_path("user://mods")
	load_mods_from_folder(user_mods, true)

	# Папка рядом с игрой
	var game_dir := OS.get_executable_path().get_base_dir()
	var game_mods := game_dir.path_join(MODS_FOLDER)
	load_mods_from_folder(game_mods, false)

	print("Загружено модов: ", loaded_mods.size())
	mods_loaded.emit()


func load_mods_from_folder(path: String, create_if_missing: bool) -> void:
	if !DirAccess.dir_exists_absolute(path):
		if create_if_missing:
			var err := DirAccess.make_dir_recursive_absolute(path)
			if err != OK:
				push_warning("Не удалось создать папку модов: " + path)
				return
		else:
			return

	var dir := DirAccess.open(path)

	if dir == null:
		push_warning("Не удалось открыть папку модов: " + path)
		return

	dir.list_dir_begin()

	var file := dir.get_next()

	while file != "":
		if !dir.current_is_dir() and file.get_extension().to_lower() == "pck":
			if loaded_files.has(file):
				file = dir.get_next()
				continue

			var mod_path := path.path_join(file)

			if ProjectSettings.load_resource_pack(mod_path):
				loaded_mods.append(file)
				loaded_files[file] = true
				print("✓ Загружен мод: ", mod_path)
			else:
				push_warning("✗ Не удалось загрузить мод: " + mod_path)

		file = dir.get_next()

	dir.list_dir_end()
