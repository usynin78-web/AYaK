extends Control

# Получаем шкалу мотивации из сцены.
@onready var motivation_bar: TextureProgressBar = $TextureProgressBar

# Здесь будет храниться компонент мотивации Кира.
var motivation_component: Node


func _ready() -> void:
	# Ищем игрока по группе.
	var player = get_tree().get_first_node_in_group("player")

	if player == null:
		push_error(tr("Игрок не найден в группе player."))
		return

	# Получаем компонент мотивации игрока.
	motivation_component = player.get_node_or_null("MotivationComponent")

	if motivation_component == null:
		push_error(tr("MotivationComponent не найден у игрока."))
		return

	# Подключаемся к сигналу изменения мотивации.
	motivation_component.motivation_changed.connect(
		_on_motivation_changed
	)

	# Обновляем шкалу при запуске.
	_on_motivation_changed(
		motivation_component.current_motivation,
		motivation_component.max_motivation
	)


func _on_motivation_changed(
	current_motivation: int,
	max_motivation: int
) -> void:
	# Обновляем максимум и текущее значение шкалы.
	motivation_bar.max_value = max_motivation
	motivation_bar.value = current_motivation
