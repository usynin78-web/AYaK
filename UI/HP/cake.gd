
extends Area2D

@onready var feer_marker = $"../Marker2D"

# Уникальный ID предмета для сохранения.
var unique_id := ""

# Сколько здоровья восстанавливает торт.
@export var heal_amount: int = 25

# Сколько мотивации восстанавливает торт.
@export var motivation_heal_amount: int = 15

# Если true — торт исчезнет после использования.
@export var destroy_after_heal: bool = true

var _is_used: bool = false


func _ready() -> void:
	# Получаем путь до объекта как временный уникальный ID.
	unique_id = str(_get_pickup_root().get_path())

	print("cake", unique_id)
	print("словарь", CheckpointManager.removed_objects)

	if CheckpointManager.removed_objects.has(unique_id):
		_get_pickup_root().queue_free()
		return


func _process(_delta: float) -> void:
	z_index = int(feer_marker.global_position.y)


func _on_body_entered(body: Node2D) -> void:
	# Проверяем, что торт коснулся именно игрока.
	if _is_used or not body.is_in_group("player"):
		return

	# Ищем компонент здоровья у игрока.
	var health_component := _find_health_component(body)

	# Ищем компонент мотивации у игрока.
	var motivation_component := _find_motivation_component(body)

	# Если ни один показатель нельзя восстановить, ничего не делаем.
	if health_component == null and motivation_component == null:
		return

	var health_before: int = 0
	var health_after: int = 0

	var motivation_before: int = 0
	var motivation_after: int = 0

	# Восстанавливаем здоровье.
	if health_component != null:
		health_before = health_component.current_health
		health_component.heal(heal_amount)
		health_after = health_component.current_health

	# Восстанавливаем мотивацию.
	if motivation_component != null:
		motivation_before = motivation_component.current_motivation
		motivation_component.change_motivation(motivation_heal_amount)
		motivation_after = motivation_component.current_motivation

	# Проверяем, изменился ли хотя бы один показатель.
	var health_restored := health_after > health_before
	var motivation_restored := motivation_after > motivation_before

	if not health_restored and not motivation_restored:
		return

	if health_restored:
		print("Кир восстановил ", health_after - health_before, " HP")

	if motivation_restored:
		print("Кир восстановил ", motivation_after - motivation_before, " мотивации")

	# Удаляем весь торт, а не только Area2D с этим скриптом.
	if destroy_after_heal:
		_is_used = true

		# Запоминаем, что этот торт уже был использован.
		CheckpointManager.removed_objects[unique_id] = true

		print("Сохранён торт:", unique_id)

		_get_pickup_root().queue_free()


# Поиск компонента здоровья.
func _find_health_component(body: Node2D) -> Node:
	var health_component := body.get_node_or_null("HealthComponent")

	if health_component != null:
		return health_component

	for child in body.get_children():
		if child.is_in_group("hp") and child.has_method("heal"):
			return child

	return null


# Поиск компонента мотивации.
func _find_motivation_component(body: Node2D) -> Node:
	var motivation_component := body.get_node_or_null("MotivationComponent")

	if motivation_component != null:
		return motivation_component

	for child in body.get_children():
		if child.has_method("change_motivation"):
			return child

	return null


func _get_pickup_root() -> Node:
	if get_parent() != null:
		return get_parent()

	return self
