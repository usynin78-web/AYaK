extends Control


func _ready() -> void:
	# Экран продолжает работать во время паузы.
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Подключаем кнопки и сразу переводим все статичные надписи.
	$next_day.pressed.connect(_on_next_day_pressed)
	$retry_day.pressed.connect(_on_retry_day_pressed)
	$menu.pressed.connect(_on_menu_pressed)

	$"static name".text = tr("Статистика дня")
	$next_day.text = tr("Продолжить")
	$retry_day.text = tr("Начать заново")
	$menu.text = tr("В главное меню")

	# Выводим сохранённую статистику.
	update_statistics(
		CheckpointManager.last_health,
		CheckpointManager.last_motivation
	)


# Обновляет показатели и комментарий.
func update_statistics(hp: int, mtv: int) -> void:
	$static.text = "%s %d\n%s %d" % [
		tr("Здоровье:"), hp,
		tr("Мотивация:"), mtv
	]
	$comment.text = get_day_comment(hp, mtv)


# Выбирает комментарий по результатам дня.
func get_day_comment(hp: int, mtv: int) -> String:
	var result_comment := ""

	if hp == 225 and mtv == 100:
		result_comment = tr("Все подозрительно хорошо идёт!")

	elif hp >= 170 and hp <= 215 and mtv >= 75 and mtv <= 85:
		result_comment = tr("Неплохо идут дела!")

	elif hp >= 100 and hp <= 169 and mtv >= 45 and mtv <= 74:
		result_comment = tr("Норм")

	elif hp < 100 and mtv < 45:
		result_comment = tr("Такое себе дело!")

	else:
		result_comment = tr("Без комментариев.")

	return tr("Комментарий:") + " " + result_comment


# Продолжает игру со следующего дня.
func _on_next_day_pressed() -> void:
	if not CheckpointManager.advance_day():
		return

	get_tree().paused = false
	get_tree().change_scene_to_file("res://loc/roomtest/main.tscn")


# Начинает новую игру с первого дня.
func _on_retry_day_pressed() -> void:
	get_tree().paused = false
	CheckpointManager.clear_save()
	get_tree().change_scene_to_file("res://loc/roomtest/main.tscn")


# Возвращается в главное меню.
func _on_menu_pressed() -> void:
	get_tree().paused = false
	CheckpointManager.clear_save()
	get_tree().change_scene_to_file("res://UI/main menu/main menu.tscn")
