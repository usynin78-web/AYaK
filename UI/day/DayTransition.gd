
extends Control

@onready var background: ColorRect = $Background
@onready var day_label: Label = $Background/DayLabel

# Длительность появления и исчезновения текста.
@export var text_fade_duration: float = 1.0

# Длительность исчезновения фона.
@export var background_fade_duration: float = 1.0

# Время отображения надписи.
@export var hold_duration: float = 1.5

# Начальное смещение текста вниз.
@export var text_offset: float = 25.0

# Анимация заставки.
var animation_tween: Tween

# Исходная позиция текста.
var label_start_position: Vector2


func _ready() -> void:
	# Заставка работает даже во время паузы.
	process_mode = Node.PROCESS_MODE_ALWAYS

	label_start_position = day_label.position

	# Подготавливаем чёрный экран.
	background.color = Color.BLACK
	background.modulate.a = 1.0

	# Текст пока невидим.
	day_label.modulate.a = 0.0

	# Не скрываем Control!
	# Чёрный экран должен закрывать игру с первого кадра.
	show()


# Показывает заставку нового дня.
func show_day(day_number: int) -> void:
	if animation_tween and animation_tween.is_running():
		animation_tween.kill()

	day_label.text = "ДЕНЬ " + str(day_number).pad_zeros(2)

	# Возвращаем чёрный фон.
	background.modulate.a = 1.0

	# Подготавливаем текст.
	day_label.modulate.a = 0.0
	day_label.position = label_start_position + Vector2(0, text_offset)

	show()

	animation_tween = create_tween()

	# Проявляем надпись и поднимаем её.
	animation_tween.tween_property(
		day_label,
		"modulate:a",
		1.0,
		text_fade_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	animation_tween.parallel().tween_property(
		day_label,
		"position",
		label_start_position,
		text_fade_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Удерживаем надпись.
	animation_tween.tween_interval(hold_duration)

	# Скрываем текст.
	animation_tween.tween_property(
		day_label,
		"modulate:a",
		0.0,
		text_fade_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Растворяем чёрный фон.
	animation_tween.tween_property(
		background,
		"modulate:a",
		0.0,
		background_fade_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Ждём завершения анимации.
	await animation_tween.finished

	# Скрываем заставку.
	hide()

	# Возвращаем фон в исходное состояние.
	background.modulate.a = 1.0
