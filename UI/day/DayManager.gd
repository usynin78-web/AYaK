
extends Node

# Ссылка на сцену заставки.
@export var day_transition: Control

# Продолжительность игрового дня в секундах.
@export var day_duration: float = 12.0

# Номер текущего дня.
var current_day: int = 1

# Нужно ли показывать заставку при запуске.
var show_start_animation: bool = true


func _ready() -> void:
	# Менеджер работает даже во время паузы.
	process_mode = Node.PROCESS_MODE_ALWAYS

	add_to_group("day_manager")

	if day_transition == null:
		push_error(tr("DayTransition не назначен!"))
		return

	# Сразу показываем чёрный экран.
	# Это происходит до ожидания загрузки остальных узлов.
	day_transition.show()

	# Ждём завершения загрузки сцены.
	await get_tree().process_frame

	# Регистрируем исходные координаты мира.
	CheckpointManager.capture_initial_world_state()

	# Загружаем сохранённый день.
	current_day = CheckpointManager.get_saved_day(1)

	# Проверяем, новая это игра или продолжение.
	show_start_animation = not CheckpointManager.has_save()

	# При продолжении скрываем заставку.
	if not show_start_animation:
		day_transition.hide()

	_run_day_cycle()


# Основной цикл игровых дней.
func _run_day_cycle() -> void:
	# При новой игре показываем первую заставку.
	if show_start_animation:
		get_tree().paused = true
		await day_transition.show_day(current_day)

	# Начинаем игровой день.
	get_tree().paused = false
	print("Начался день ", current_day)

	while true:
		# Ждём окончания игрового дня.
		await get_tree().create_timer(day_duration).timeout

		# Останавливаем игровой процесс.
		get_tree().paused = true

		# Переходим к следующему дню.
		current_day += 1

		# Сбрасываем позиции Кира и живых NPC.
		CheckpointManager.reset_world()

		# Сохраняем новое состояние игрока.
		var player = get_tree().get_first_node_in_group("player")

		if player != null:
			var health_component = player.get_node_or_null("HealthComponent")

			if health_component != null:
				CheckpointManager.save_checkpoint(
					player.global_position,
					health_component.current_health
				)

		# Показываем заставку нового дня.
		await day_transition.show_day(current_day)

		# Запускаем следующий день.
		get_tree().paused = false
		print("Начался день ", current_day)
