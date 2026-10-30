
extends Control

# Узлы уведомления.
@onready var message: Label = $Message

# Сколько секунд уведомление находится на экране.
@export var display_time: float = 0.8

# Расстояние, с которого уведомление начинает спускаться.
@export var slide_distance: float = 100.0

# Длительность спуска и подъёма.
@export var animation_duration: float = 0.4

# Ссылка на анимацию уведомления.
var notification_tween: Tween

# Позиция уведомления, заданная в редакторе.
var target_position: Vector2


func _ready() -> void:
	# Запоминаем исходную позицию уведомления.
	target_position = position

	# Скрываем уведомление при запуске.
	hide()


# Универсальная функция отображения уведомления.
func show_notification(text: String, death: bool = false) -> void:
	# Останавливаем предыдущую анимацию, если она ещё работает.
	if notification_tween and notification_tween.is_running():
		notification_tween.kill()

	message.text = text

	# Для смерти устанавливаем красный цвет.
	# Для остальных уведомлений используем LabelSettings.
	if death:
		message.add_theme_color_override("font_color", Color.RED)
	else:
		message.remove_theme_color_override("font_color")

	# Начальная позиция: выше заданной точки.
	position = target_position + Vector2(0, -slide_distance)

	# Показываем уведомление.
	show()

	# Создаём последовательность анимаций.
	notification_tween = create_tween()

	# Плавное появление и спуск до заданной позиции.
	notification_tween.set_parallel(true)
	notification_tween.tween_property(
		self, "position", target_position, animation_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	notification_tween.tween_property(
		self, "modulate:a", 1.0, animation_duration
	)

	# Ожидание после появления.
	notification_tween.set_parallel(false)
	notification_tween.tween_interval(display_time)

	# Подъём обратно.
	notification_tween.tween_property(
		self, "position",
		target_position + Vector2(0, -slide_distance),
		animation_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Одновременно постепенно исчезаем.
	notification_tween.parallel().tween_property(
		self, "modulate:a", 0.0, animation_duration
	)

	# Скрываем уведомление после завершения анимации.
	notification_tween.tween_callback(hide)


# Потеря или восстановление HP.
func notify_hp_changed(amount: int) -> void:
	if amount == 0:
		return

	var text := ("+" if amount > 0 else "") + str(amount) + " Здоровья"
	show_notification(text)


# Смерть Кира.
func notify_death() -> void:
	show_notification("ВЫ ПОГИБЛИ", true)
