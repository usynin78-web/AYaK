
extends Node

const SAVE_FILE: String = "user://checkpoint.ayk"

# Последние сохранённые данные игрока.
var last_position: Vector2 = Vector2.ZERO
var last_health: int = 225
var last_motivation: int = 100
var last_day: int = 1

var has_checkpoint: bool = false

# Последние сохранённые позиции NPC.
var npc_positions: Dictionary = {}

# Исчезнувшие или уничтоженные объекты.
var removed_objects: Dictionary = {}

# Исходные позиции Кира и NPC.
var initial_player_position: Vector2 = Vector2.ZERO
var initial_npc_positions: Dictionary = {}

# Проверка регистрации исходной позиции Кира.
var player_start_registered: bool = false


func _ready() -> void:
	load_save_data()


# Загружает сохранённые данные мира.
func load_save_data() -> void:
	var config := ConfigFile.new()

	if config.load(SAVE_FILE) != OK:
		return

	removed_objects = config.get_value("world", "removed_objects", {})
	npc_positions = config.get_value("world", "npc_positions", {})

	# Загружаем исходные позиции, если они уже сохранены.
	initial_npc_positions = config.get_value(
		"world",
		"initial_npc_positions",
		{}
	)

	if config.has_section_key("world", "initial_player_x"):
		var x: float = config.get_value("world", "initial_player_x", 0.0)
		var y: float = config.get_value("world", "initial_player_y", 0.0)

		initial_player_position = Vector2(x, y)
		player_start_registered = true

	print("Загружены данные мира. Удалённых объектов: ", removed_objects.size())


# Регистрирует исходную позицию Кира.
func register_player_start_position(pos: Vector2) -> void:
	if player_start_registered:
		return

	initial_player_position = pos
	player_start_registered = true


# Регистрирует исходную позицию NPC.
func register_npc_start_position(npc: Node2D) -> void:
	if not npc.has_method("get"):
		return

	var id: String = npc.unique_id

	# Если исходная позиция уже сохранена, ничего не меняем.
	if initial_npc_positions.has(id):
		return

	initial_npc_positions[id] = npc.global_position


# Сохраняет исходные позиции мира на диск.
func save_initial_world_state() -> void:
	var config := ConfigFile.new()

	# Загружаем существующие данные, чтобы не затереть чекпоинт.
	config.load(SAVE_FILE)

	if player_start_registered:
		config.set_value(
			"world",
			"initial_player_x",
			initial_player_position.x
		)

		config.set_value(
			"world",
			"initial_player_y",
			initial_player_position.y
		)

	config.set_value(
		"world",
		"initial_npc_positions",
		initial_npc_positions
	)

	var err := config.save(SAVE_FILE)

	if err != OK:
		push_error(tr("Не удалось сохранить исходные позиции мира!"))


# Запоминает исходные позиции после загрузки основной сцены.
func capture_initial_world_state() -> void:
	var player = get_tree().get_first_node_in_group("player")

	if player is Node2D:
		register_player_start_position(player.global_position)

	for npc in get_tree().get_nodes_in_group("npc"):
		if npc is Node2D:
			register_npc_start_position(npc)

	save_initial_world_state()


# Возвращает Кира и существующих NPC на исходные позиции.
# Здоровье, мотивацию и удалённые объекты не изменяет.
func reset_world() -> void:
	if not player_start_registered:
		push_error(tr("Не зарегистрирована исходная позиция Кира!"))
		return

	var player = get_tree().get_first_node_in_group("player")

	if player is Node2D:
		player.global_position = initial_player_position
		player.velocity = Vector2.ZERO

	# Возвращаем только тех NPC, которые существуют в сцене.
	for npc in get_tree().get_nodes_in_group("npc"):
		if not is_instance_valid(npc):
			continue

		var id: String = npc.unique_id

		if initial_npc_positions.has(id):
			npc.global_position = initial_npc_positions[id]
			npc.velocity = Vector2.ZERO

			# Сбрасываем старую цель навигации.
			if npc.has_node("NavigationAgent2D"):
				var navigation = npc.get_node("NavigationAgent2D")
				navigation.target_position = npc.global_position

	print("Мир сброшен. HP и мотивация не изменены.")


# Сохраняет позицию, здоровье, мотивацию и текущий день.
func save_checkpoint(pos: Vector2, hp: int) -> void:
	last_position = pos
	last_health = hp

	# Получаем текущую мотивацию Кира.
	var player = get_tree().get_first_node_in_group("player")

	if player != null:
		var motivation_component = player.get_node_or_null("MotivationComponent")

		if motivation_component != null:
			last_motivation = motivation_component.current_motivation

	# Получаем текущий игровой день.
	var day_manager = get_tree().get_first_node_in_group("day_manager")

	if day_manager != null:
		last_day = day_manager.current_day

	has_checkpoint = true

	var config := ConfigFile.new()

	# Сохраняем данные игрока.
	config.set_value("player", "x", pos.x)
	config.set_value("player", "y", pos.y)
	config.set_value("player", "hp", hp)
	config.set_value("player", "motivation", last_motivation)
	config.set_value("player", "day", last_day)

	# Сохраняем позиции NPC.
	npc_positions.clear()

	for npc in get_tree().get_nodes_in_group("npc"):
		if is_instance_valid(npc):
			npc_positions[npc.unique_id] = npc.global_position

	# Сохраняем данные мира.
	config.set_value("world", "removed_objects", removed_objects)
	config.set_value("world", "npc_positions", npc_positions)

	# Не забываем сохранить исходные позиции.
	config.set_value(
		"world",
		"initial_npc_positions",
		initial_npc_positions
	)

	config.set_value(
		"world",
		"initial_player_x",
		initial_player_position.x
	)

	config.set_value(
		"world",
		"initial_player_y",
		initial_player_position.y
	)

	var err := config.save(SAVE_FILE)

	if err != OK:
		push_error(tr("Не удалось сохранить чекпоинт на диск!"))
	else:
		print(
			"Чекпоинт сохранён: ",
			pos,
			" HP:", hp,
			" Мотивация:", last_motivation,
			" День:", last_day
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
		last_day = config.get_value("player", "day", 1)

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


# Возвращает сохранённый игровой день.
func get_saved_day(default_day: int = 1) -> int:
	if has_checkpoint:
		return last_day

	var config := ConfigFile.new()

	if config.load(SAVE_FILE) == OK:
		last_day = config.get_value("player", "day", default_day)
		return last_day

	return default_day


# Проверяет, существует ли полноценный чекпоинт.
func has_save() -> bool:
	if has_checkpoint:
		return true

	var config := ConfigFile.new()

	return (
		config.load(SAVE_FILE) == OK
		and _is_valid_checkpoint(config)
	)


# Удаляет сохранение и очищает данные мира.
func clear_save() -> void:
	last_position = Vector2.ZERO
	last_health = 225
	last_motivation = 100
	last_day = 1

	has_checkpoint = false

	removed_objects.clear()
	npc_positions.clear()

	initial_npc_positions.clear()
	initial_player_position = Vector2.ZERO
	player_start_registered = false

	if FileAccess.file_exists(SAVE_FILE):
		var err := DirAccess.remove_absolute(SAVE_FILE)

		if err != OK:
			push_error(tr("Не удалось удалить файл сохранения!"))

	print("Все сохранения и данные о мире очищены.")


# Проверяет наличие основных данных чекпоинта.
func _is_valid_checkpoint(config: ConfigFile) -> bool:
	return (
		config.has_section_key("player", "x")
		and config.has_section_key("player", "y")
		and config.has_section_key("player", "hp")
	)
