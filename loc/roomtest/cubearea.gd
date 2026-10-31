extends Area2D

# Элементы интерфейса контрольной точки.
@export var e_icon: TextureRect
@export var save_label: Label

# Смещение значка относительно игрока.
@export var offset_icon: Vector2 = Vector2(0, -50)

# Ссылка на игрока.
var player: CharacterBody2D = null

# Находится ли игрок внутри зоны.
var player_inside: bool = false


func _ready() -> void:
	# Проверяем назначение значка взаимодействия.
	if not e_icon:
		push_error("E_icon не назначен!")
	else:
		e_icon.visible = false

	# Проверяем назначение надписи сохранения.
	if not save_label:
		push_error("SaveLabel не назначен!")
	else:
		save_label.visible = false

	# Подключаем сигналы входа и выхода из зоны.
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	# Перемещаем значок над головой игрока.
	if player_inside and player != null and e_icon != null:
		var world_pos = player.global_position + offset_icon
		var screen_pos = get_viewport().get_canvas_transform() * world_pos

		e_icon.position = screen_pos

	# Проверяем нажатие кнопки взаимодействия.
	if player_inside and Input.is_action_just_pressed("interact"):
		_activate_checkpoint()


# Игрок вошёл в область контрольной точки.
func _on_body_entered(body: Node2D) -> void:
	if player == null:
		player = _find_player(body)

	if body == player:
		player_inside = true

		if e_icon != null:
			e_icon.visible = true


# Игрок покинул область контрольной точки.
func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player_inside = false

		if e_icon != null:
			e_icon.visible = false


# Активирует контрольную точку и сохраняет прогресс.
func _activate_checkpoint() -> void:
	if player == null:
		push_error("Игрок не найден!")
		return

	# Получаем компонент здоровья.
	var health_component = player.get_node_or_null("HealthComponent")

	if health_component == null:
		push_error("HealthComponent не найден!")
		return

	# Сохраняем позицию и здоровье.
	# Мотивацию менеджер сохранит самостоятельно.
	CheckpointManager.save_checkpoint(
		player.global_position,
		health_component.current_health
	)

	print(
		"Чекпоинт сохранён: ",
		player.global_position,
		" HP: ",
		health_component.current_health
	)

	# Показываем уведомление об успешном сохранении.
	if save_label != null:
		_show_save_label()


# Показывает сообщение об успешном сохранении.
func _show_save_label() -> void:
	save_label.visible = true
	save_label.text = "Сохранение успешно выполнено"

	await get_tree().create_timer(2.0).timeout

	# Проверяем, что узел ещё существует.
	if is_instance_valid(save_label):
		save_label.visible = false


# Находит игрока по группе.
func _find_player(body: Node) -> CharacterBody2D:
	if body.is_in_group("player"):
		return body as CharacterBody2D

	# Если вошедший объект не игрок, ищем его среди участников группы.
	var players = get_tree().get_nodes_in_group("player")

	if players.size() > 0:
		return players[0] as CharacterBody2D

	return null
