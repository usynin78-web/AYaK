extends Node

# Ссылка на сцену заставки.
@export var day_transition: Control

# Продолжительность игрового дня.
# 1200 секунд = 20 минут.
@export var day_duration: float = 12.0

# Номер текущего дня.
var current_day: int = 1


func _ready() -> void:
	# Менеджер продолжает работать во время паузы.
	process_mode = Node.PROCESS_MODE_ALWAYS

	if day_transition == null:
		push_error("DayTransition не назначен!")
		return

	# Запускаем первый игровой день.
	_run_day_cycle()


# Основной цикл игровых дней.
func _run_day_cycle() -> void:
	while true:
		# Останавливаем игровой процесс.
		get_tree().paused = true

		# Показываем заставку и ждём её завершения.
		await day_transition.show_day(current_day)

		# Начинаем новый игровой день.
		get_tree().paused = false

		print("Начался день ", current_day)

		# Ждём окончания игрового дня.
		await get_tree().create_timer(day_duration).timeout

		# Завершаем день.
		get_tree().paused = true

		# Переходим к следующему дню.
		current_day += 1
