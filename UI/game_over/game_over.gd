extends Control

# Длительность плавного появления экрана проигрыша.
@export var fade_duration: float = 1.0
@export var slide_distance: float = 28.0

@onready var start_button: Button = $VBoxContainer/start
@onready var menu_button: Button = $VBoxContainer/menu
@onready var title_container: VBoxContainer = $TitleContainer

var entrance_tween: Tween
var start_position: Vector2


func _ready() -> void:
	# Экран и его анимация должны работать во время паузы.
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	start_button.pressed.connect(_on_start_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

	# Запоминаем исходное положение корневого элемента.
	start_position = position

	# Переводим надписи при запуске сцены.
	$TitleContainer/Title.text = tr("Хорошее начало")
	$TitleContainer/Subtitle.text = tr("Жаль недолгое")
	start_button.text = tr("Начать заново")
	menu_button.text = tr("В главное меню")


# Показывает экран проигрыша с плавным появлением.
func show_screen() -> void:
	if entrance_tween and entrance_tween.is_running():
		entrance_tween.kill()

	visible = true
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


# Начинает новую игру с первого дня.
func _on_start_pressed() -> void:
	get_tree().paused = false
	CheckpointManager.clear_save()
	get_tree().change_scene_to_file("res://loc/roomtest/main.tscn")


# Возвращается в главное меню.
func _on_menu_pressed() -> void:
	get_tree().paused = false
	CheckpointManager.clear_save()
	get_tree().change_scene_to_file("res://UI/main menu/main menu.tscn")
