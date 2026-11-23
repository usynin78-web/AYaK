extends Control

# Настройки плавного появления экрана.
@export var fade_duration: float = 0.75
@export var slide_distance: float = 22.0

var entrance_tween: Tween
var start_position: Vector2


func _ready() -> void:
	# Экран продолжает работать во время паузы.
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Запоминаем исходное положение корневого элемента.
	start_position = position
	resized.connect(_apply_responsive_font_sizes)
	_apply_responsive_font_sizes()

	# Подключаем кнопки и переводим статичные надписи.
	$next_day.pressed.connect(_on_next_day_pressed)
	$retry_day.pressed.connect(_on_retry_day_pressed)
	$menu.pressed.connect(_on_menu_pressed)

	$"static name".text = tr("Статистика дня")
	$next_day.text = tr("Продолжить")
	$retry_day.text = tr("Начать заново")
	$menu.text = tr("В главное меню")

	# Переносим длинные комментарии внутри ширины левой панели.
	$comment.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Выводим сохранённую статистику.
	update_statistics(
		CheckpointManager.last_health,
		CheckpointManager.last_motivation
	)

	# Показываем экран плавно, даже если игровое дерево на паузе.
	_play_entrance_animation()


# Подбирает размер шрифта под текущее разрешение окна.
func _apply_responsive_font_sizes() -> void:
	# Базовые размеры рассчитаны на проектное разрешение 1920x1080.
	var scale_factor := minf(size.x / 1920.0, size.y / 1080.0)
	scale_factor = clampf(scale_factor, 0.55, 1.15)

	$"static name".label_settings.font_size = roundi(96.0 * scale_factor)
	$static.label_settings.font_size = roundi(91.0 * scale_factor)
	$comment.label_settings.font_size = roundi(54.0 * scale_factor)

	# Размер текста кнопок меняется вместе с размером экрана.
	var button_font_size := roundi(48.0 * scale_factor)
	$next_day.add_theme_font_size_override("font_size", button_font_size)
	$retry_day.add_theme_font_size_override("font_size", button_font_size)
	$menu.add_theme_font_size_override("font_size", button_font_size)


# Плавно проявляет экран и немного сдвигает его на исходное место.
func _play_entrance_animation() -> void:
	if entrance_tween and entrance_tween.is_running():
		entrance_tween.kill()

	modulate.a = 0.0
	position = start_position + Vector2(0.0, slide_distance)

	entrance_tween = create_tween()
	entrance_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	entrance_tween.set_parallel(true)
	entrance_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		fade_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrance_tween.tween_property(
		self,
		"position",
		start_position,
		fade_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


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
