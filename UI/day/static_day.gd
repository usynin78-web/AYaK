
extends Control


func _ready() -> void:
	# Экран продолжает работать во время паузы.
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Автоматически подключаем кнопки.
	$next_day.pressed.connect(_on_next_day_pressed)
	$retry_day.pressed.connect(_on_retry_day_pressed)
	$menu.pressed.connect(_on_menu_pressed)

	# Выводим сохранённую статистику.
	update_statistics(
		CheckpointManager.last_health,
		CheckpointManager.last_motivation
	)


# Обновляет показатели и комментарий.
func update_statistics(hp: int, mtv: int) -> void:
	$static.text = "Здоровье: %d\nМотивация: %d" % [hp, mtv]
	$comment.text = get_day_comment(hp, mtv)


# Выбирает комментарий по результатам дня.
func get_day_comment(hp: int, mtv: int) -> String:
	if hp == 225 and mtv == 100:
		return "Комментарий: Все\nподозрительно хорошо идёт!"

	elif hp >= 170 and hp <= 215 and mtv >= 75 and mtv <= 85:
		return "Комментарий: \nНеплохо идут дела!"

	elif hp >= 100 and hp <= 169 and mtv >= 45 and mtv <= 74:
		return "Комментарий: Норм"

	elif hp <= 100 and mtv <= 45:
		return "Коментарий: Плохо дело!"

	return "Комментарий: Без\nкомментариев."


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
