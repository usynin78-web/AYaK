extends Control

# Текстовые элементы экрана статистики.
@onready var static_text: Button = $static
@onready var comment_text: Button = $comment

# Кнопки управления.
@onready var next_day_button: Button = $next_day
@onready var retry_day_button: Button = $retry_day
@onready var menu_button: Button = $menu


func _ready() -> void:
	# Экран должен работать, даже если игровое дерево поставлено на паузу.
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Подключаем сигналы нажатия кнопок.
	next_day_button.pressed.connect(_on_next_day_pressed)
	retry_day_button.pressed.connect(_on_retry_day_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

	# Берём реальные сохранённые показатели завершившегося дня.
	update_statistics(
		CheckpointManager.last_health,
		CheckpointManager.last_motivation
	)


# Выводит HP, мотивацию и комментарий по итогам дня.
func update_statistics(hp: int, mtv: int) -> void:
	static_text.text = "Здоровье: %d\nМотивация: %d" % [hp, mtv]
	comment_text.text = get_day_comment(hp, mtv)


# Подбирает комментарий по заданным диапазонам.
func get_day_comment(hp: int, mtv: int) -> String:
	if hp == 225 and mtv == 100:
		return "Все подозрительно хорошо идёт!"

	elif hp >= 170 and hp <= 215 and mtv >= 75 and mtv <= 85:
		return "Неплохо идут дела!"

	elif hp >= 100 and hp <= 169 and mtv >= 45 and mtv <= 74:
		return "Норм"

	elif hp < 100 and mtv < 45:
		return "Такое себе дело!"

	# Нейтральный комментарий для сочетаний,
	# которым пока не назначена отдельная реплика.
	return "Без комментариев."


# Продолжает игру со следующего дня.
func _on_next_day_pressed() -> void:
	# Увеличиваем сохранённый номер дня только по нажатию кнопки.
	if not CheckpointManager.advance_day():
		return

	get_tree().paused = false
	get_tree().change_scene_to_file("res://loc/roomtest/main.tscn")


# Начинает новую игру с первого дня.
func _on_retry_day_pressed() -> void:
	get_tree().paused = false
	CheckpointManager.clear_save()
	get_tree().change_scene_to_file("res://loc/roomtest/main.tscn")


# Возвращается в главное меню и удаляет текущее сохранение.
func _on_menu_pressed() -> void:
	get_tree().paused = false
	CheckpointManager.clear_save()
	get_tree().change_scene_to_file("res://UI/main menu/main menu.tscn")
