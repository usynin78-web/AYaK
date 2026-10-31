extends Node

const SAVE_FILE: String = "user://checkpoint.ayk"

# Последние сохранённые данные игрока.
var last_position: Vector2 = Vector2.ZERO
var last_health: int = 225
var last_motivation: int = 100

var has_checkpoint: bool = false

# Позиции NPC.
var npc_positions: Dictionary = {}

# Объекты, которые были уничтожены или подобраны.
var removed_objects: Dictionary = {}


func _ready() -> void:
	load_save_data()


# Загружает сохранённые данные мира.
func load_save_data() -> void:
	var config := ConfigFile.new()

	if config.load(SAVE_FILE) == OK:
		removed_objects = config.get_value("world", "removed_objects", {})
		npc_positions = config.get_value("world", "npc_positions", {})

		print("Загружены данные мира. Удалённых объектов: ", removed_objects.size())


# Сохраняет позицию и здоровье игрока.
# Мотивацию менеджер получает самостоятельно через группу player.
func save_checkpoint(pos: Vector2, hp: int) -> void:
	last_position = pos
	last_health = hp

	# Ищем Кира и его компонент мотивации.
	var player = get_tree().get_first_node_in_group("player")

	if player != null:
		var motivation_component = player.get_node_or_null("MotivationComponent")

		if motivation_component != null:
			last_motivation = motivation_component.current_motivation

	has_checkpoint = true

	var config := ConfigFile.new()

	# Сохраняем данные игрока.
	config.set_value("player", "x", pos.x)
	config.set_value("player", "y", pos.y)
	config.set_value("player", "hp", hp)
	config.set_value("player", "motivation", last_motivation)

	# Обновляем позиции NPC.
	npc_positions.clear()

	for npc in get_tree().get_nodes_in_group("npc"):
		npc_positions[npc.unique_id] = npc.global_position

	# Сохраняем данные мира.
	config.set_value("world", "removed_objects", removed_objects)
	config.set_value("world", "npc_positions", npc_positions)

	var err := config.save(SAVE_FILE)

	if err != OK:
		push_error("Не удалось сохранить чекпоинт на диск!")
	else:
		print(
			"Чекпоинт сохранён: ",
			pos,
			" HP:", hp,
			" Мотивация:", last_motivation
		)


# Возвращает сохранённую позицию игрока.
func get_spawn_position(default_pos: Vector2) -> Vector2:
	if has_checkpoint:
		return last_position

	var config := ConfigFile.new()

	if config.load(SAVE_FILE) == OK and _is_valid_checkpoint(config):
		var x: float = config.get_value("player", "x", default_pos.x)
		var y: float = config.get_value("player", "y", default_pos.y)

		last_position = Vector2(x, y)
		last_health = config.get_value("player", "hp", 225)
		last_motivation = config.get_value("player", "motivation", 100)

		has_checkpoint = true

		return last_position

	return default_pos


# Возвращает сохранённое здоровье.
func get_saved_health(default_hp: int) -> int:
	if has_checkpoint:
		return last_health

	var config := ConfigFile.new()

	if config.load(SAVE_FILE) == OK:
		return config.get_value("player", "hp", default_hp)

	return default_hp


# Возвращает сохранённую мотивацию.
func get_saved_motivation(default_motivation: int) -> int:
	if has_checkpoint:
		return last_motivation

	var config := ConfigFile.new()

	if config.load(SAVE_FILE) == OK:
		return config.get_value("player", "motivation", default_motivation)

	return default_motivation


# Проверяет, существует ли сохранение.
func has_save() -> bool:
	if has_checkpoint:
		return true

	return FileAccess.file_exists(SAVE_FILE)


# Удаляет сохранение и очищает данные мира.
func clear_save() -> void:
	last_position = Vector2.ZERO
	last_health = 225
	last_motivation = 100

	has_checkpoint = false

	removed_objects.clear()
	npc_positions.clear()

	if FileAccess.file_exists(SAVE_FILE):
		var err := DirAccess.remove_absolute(SAVE_FILE)

		if err != OK:
			push_error("Не удалось удалить файл сохранения!")

	print("Все сохранения и данные о мире очищены.")


# Проверяет наличие основных данных чекпоинта.
func _is_valid_checkpoint(config: ConfigFile) -> bool:
	return (
		config.has_section_key("player", "x")
		and config.has_section_key("player", "y")
		and config.has_section_key("player", "hp")
	)
