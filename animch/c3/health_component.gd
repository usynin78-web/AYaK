
extends Node

# Сообщает интерфейсу, что здоровье изменилось.
signal health_changed(current_health: int, max_health: int)

# Сообщает другим узлам, насколько изменилось здоровье.
# Положительное число — восстановление, отрицательное — урон.
signal health_amount_changed(amount: int)

# Сообщает другим узлам, что игрок умер.
signal died

# Максимальное здоровье игрока.
@export var max_health: int = 225

# Текущее здоровье игрока.
var current_health: int

# Проверяет, умер ли игрок.
var is_dead: bool = false


func _ready() -> void:
	# Загружаем HP из сохранения или используем максимум.
	current_health = CheckpointManager.get_saved_health(max_health)

	# Проверяем, не загрузился ли игрок уже мёртвым.
	is_dead = current_health <= 0

	# Сразу отправляем сигнал, чтобы HP-бар обновился.
	health_changed.emit(current_health, max_health)

	# Если игрок загрузился с 0 HP, сообщаем о смерти.
	if is_dead:
		died.emit()


func take_damage(amount: int) -> void:
	# amount — сколько урона получил игрок.
	if amount <= 0 or is_dead:
		return

	# Запоминаем здоровье до получения урона.
	var previous_health: int = current_health

	# Уменьшаем HP, но не даём ему уйти ниже 0.
	current_health = clamp(current_health - amount, 0, max_health)

	# Вычисляем фактически полученный урон.
	var actual_damage: int = previous_health - current_health

	# Сообщаем интерфейсу новое значение HP.
	health_changed.emit(current_health, max_health)

	# Сообщаем об изменении количества HP.
	if actual_damage > 0:
		health_amount_changed.emit(-actual_damage)

	# Если HP закончилось — смерть.
	if current_health <= 0:
		is_dead = true
		died.emit()


func heal(amount: int) -> void:
	# amount — сколько HP восстановить.
	if amount <= 0 or is_dead:
		return

	# Запоминаем здоровье до лечения.
	var previous_health: int = current_health

	# Лечим, но не выше максимального здоровья.
	current_health = clamp(current_health + amount, 0, max_health)

	# Вычисляем фактически восстановленное здоровье.
	var actual_healing: int = current_health - previous_health

	# Сообщаем интерфейсу новое значение HP.
	health_changed.emit(current_health, max_health)

	# Сообщаем об изменении количества HP.
	if actual_healing > 0:
		health_amount_changed.emit(actual_healing)
