extends Node

# Ссылка на сцену заставки игрового дня.
@export var day_transition: Control

# Продолжительность игрового дня в секундах.
@export var day_duration: float = 1200.0

# Номер дня, который сейчас проходит.
var current_day: int = 1

# Флаг остановки цикла, например при смерти Кира.
var stopped: bool = false


func _ready() -> void:
	# Менеджер должен продолжать работу во время паузы.
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("day_manager")

	if day_transition == null:
		push_error("DayTransition не назначен!")
		return

	# Показываем чёрный экран до завершения загрузки сцены.
	day_transition.show()
	await get_tree().process_frame

	# Регистрируем исходные координаты мира.
	CheckpointManager.capture_initial_world_state()

	# Загружаем день из сохранения.
	current_day = CheckpointManager.get_saved_day(1)

	# При каждом входе в игровую сцену показываем заставку
	# текущего дня: и при новой игре, и после продолжения.
	_run_day_cycle()


# Запускает один игровой день и ожидает его завершения.
func _run_day_cycle() -> void:
	if stopped:
		return

	# Показываем номер дня перед началом игрового процесса.
	get_tree().paused = true
	await day_transition.show_day(current_day)

	if stopped:
		return

	get_tree().paused = false
	print("Начался день ", current_day)

	# Ждём окончания игрового дня.
	await get_tree().create_timer(day_duration, false, false, true).timeout

	if stopped:
		return

	# Останавливаем игровой процесс перед показом статистики.
	get_tree().paused = true

	# Возвращаем Кира и NPC на исходные позиции.
	# HP и мотивация при этом не меняются.
	CheckpointManager.reset_world()

	# Сохраняем итоги завершившегося дня.
	var player := get_tree().get_first_node_in_group("player")

	if player == null:
		push_error("Не удалось найти игрока для сохранения статистики дня.")
		get_tree().paused = false
		return

	var health_component = player.get_node_or_null("HealthComponent")

	if health_component == null:
		push_error("У игрока не найден HealthComponent.")
		get_tree().paused = false
		return

	# CheckpointManager также сохранит мотивацию и номер текущего дня.
	CheckpointManager.save_checkpoint(
		player.global_position,
		health_component.current_health
	)

	# Открываем отдельный экран статистики.
	# Следующий день пока НЕ увеличиваем: это произойдёт
	# только после нажатия игроком кнопки продолжения.
	get_tree().change_scene_to_file("res://UI/day/static_day.tscn")


# Останавливает ожидание окончания дня.
func stop_day_cycle() -> void:
	stopped = true
