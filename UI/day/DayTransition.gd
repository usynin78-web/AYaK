extends Control

@onready var background: ColorRect = $Background
@onready var day_label: Label = $Background/DayLabel

@export var text_fade_duration: float = 1.0
@export var background_fade_duration: float = 1.0
@export var hold_duration: float = 1.5
@export var text_offset: float = 25.0

var animation_tween: Tween
var label_start_position: Vector2


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	label_start_position = day_label.position
	background.color = Color.BLACK
	background.modulate.a = 1.0
	day_label.modulate.a = 0.0
	show()


# Показывает заставку с номером дня на выбранном языке.
func show_day(day_number: int) -> void:
	if animation_tween and animation_tween.is_running():
		animation_tween.kill()

	day_label.text = tr("ДЕНЬ") + " " + str(day_number).pad_zeros(2)
	background.modulate.a = 1.0
	day_label.modulate.a = 0.0
	day_label.position = label_start_position + Vector2(0, text_offset)
	show()

	animation_tween = create_tween()
	animation_tween.tween_property(day_label, "modulate:a", 1.0, text_fade_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animation_tween.parallel().tween_property(day_label, "position", label_start_position, text_fade_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animation_tween.tween_interval(hold_duration)
	animation_tween.tween_property(day_label, "modulate:a", 0.0, text_fade_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	animation_tween.tween_property(background, "modulate:a", 0.0, background_fade_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	await animation_tween.finished
	hide()
	background.modulate.a = 1.0
