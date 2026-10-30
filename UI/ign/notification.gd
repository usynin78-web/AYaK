extends Control

# Узлы уведомления.
@onready var message: Label = $Message
@onready var hurt_kir: TextureRect = $TextureRect
@onready var happy_kir: TextureRect = $TextureRect2

# Сколько секунд уведомление находится на экране.
@export var display_time: float = 2.0

# Расстояние, с которого уведомление начинает спускаться.
@export var slide_distance: float = 100.0

# Длительность спуска и подъёма.
@export var animation_duration: float = 0.4

# Ссылка на анимацию уведомления.
var notification_tween: Tween

# Позиция уведомления, заданная в редакторе.
var target_position: Vector2


func _ready() -> void:
	target_position = position

	# Скрываем картинки при запуске.
	hurt_kir.hide()
	happy_kir.hide()

	hide()


func show_notification(text: String, death: bool = false) -> void:
	if notification_tween and notification_tween.is_running():
		notification_tween.kill()

	message.text = text

	# Сбрасываем оформление текста.
	message.remove_theme_color_override("font_color")

	if death:
		message.add_theme_color_override("font_color", Color.RED)

	# Начальная позиция уведомления.
	position = target_position + Vector2(0, -slide_distance)

	show()

	# Анимация появления и спуска.
	notification_tween = create_tween()

	notification_tween.set_parallel(true)

	notification_tween.tween_property(
		self, "position", target_position, animation_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	notification_tween.tween_property(
		self, "modulate:a", 1.0, animation_duration
	)

	# Ожидание.
	notification_tween.set_parallel(false)
	notification_tween.tween_interval(display_time)

	# Анимация подъёма и исчезновения.
	notification_tween.tween_property(
		self, "position",
		target_position + Vector2(0, -slide_distance),
		animation_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	notification_tween.parallel().tween_property(
		self, "modulate:a", 0.0, animation_duration
	)

	notification_tween.tween_callback(hide)


# Потеря или восстановление HP.
func notify_hp_changed(amount: int) -> void:
	if amount == 0:
		return

	# Скрываем обе картинки перед выбором нужной.
	hurt_kir.hide()
	happy_kir.hide()

	var text := ("+" if amount > 0 else "") + str(amount) + " HP"

	if amount < 0:
		hurt_kir.show()
	else:
		happy_kir.show()

	show_notification(text)


# Смерть Кира.
func notify_death() -> void:
	hurt_kir.hide()
	happy_kir.hide()

	show_notification("ВЫ ПОГИБЛИ", true)
