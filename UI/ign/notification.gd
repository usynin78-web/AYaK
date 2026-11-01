extends Control

@onready var message: Label = $Message
@onready var hurt_kir: TextureRect = $TextureRect
@onready var happy_kir: TextureRect = $TextureRect2

@export var display_time: float = 2.0
@export var slide_distance: float = 100.0
@export var animation_duration: float = 0.4

var notification_tween: Tween
var target_position: Vector2


func _ready() -> void:
	target_position = position
	hurt_kir.hide()
	happy_kir.hide()
	hide()


func show_notification(text: String, death: bool = false) -> void:
	if notification_tween and notification_tween.is_running():
		notification_tween.kill()

	message.text = text
	message.remove_theme_color_override("font_color")

	if death:
		message.add_theme_color_override("font_color", Color.RED)

	position = target_position + Vector2(0, -slide_distance)
	show()

	notification_tween = create_tween()
	notification_tween.set_parallel(true)
	notification_tween.tween_property(self, "position", target_position, animation_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	notification_tween.tween_property(self, "modulate:a", 1.0, animation_duration)
	notification_tween.set_parallel(false)
	notification_tween.tween_interval(display_time)
	notification_tween.tween_property(self, "position", target_position + Vector2(0, -slide_distance), animation_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	notification_tween.parallel().tween_property(self, "modulate:a", 0.0, animation_duration)
	notification_tween.tween_callback(hide)


func notify_hp_changed(amount: int) -> void:
	if amount == 0:
		return

	hurt_kir.hide()
	happy_kir.hide()

	var text := ("+" if amount > 0 else "") + str(amount) + " HP"

	if amount < 0:
		hurt_kir.show()
	else:
		happy_kir.show()

	show_notification(text)


func notify_death() -> void:
	hurt_kir.hide()
	happy_kir.hide()
	show_notification(tr("ВЫ ПОГИБЛИ"), true)
