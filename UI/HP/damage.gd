extends Area2D

@onready var feer_marker = $"../Marker2D"

# Урон по здоровью и мотивации.
@export var damage: int = 25
@export var motivation_damage: int = 10

# Интервал между повторными атаками.
@export var damage_interval: float = 1.0

var player_inside: Node2D = null
var can_damage: bool = true


func _process(_delta: float) -> void:
	z_index = int(feer_marker.global_position.y)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = body
		_damage_player()


func _on_body_exited(body: Node2D) -> void:
	if body == player_inside:
		player_inside = null


func _damage_player() -> void:
	if player_inside == null:
		return

	if not can_damage:
		return

	# Получаем компонент здоровья.
	var health_component = player_inside.get_node_or_null("HealthComponent")

	# Получаем компонент мотивации.
	var motivation_component = player_inside.get_node_or_null("MotivationComponent")

	# Наносим урон здоровью.
	if health_component != null:
		health_component.take_damage(damage)
		print("Кир ранен на ", damage, " HP")

	# Понижаем мотивацию.
	if motivation_component != null:
		motivation_component.change_motivation(-motivation_damage)
		print("Мотивация Кира снижена на ", motivation_damage)

	# Запускаем перезарядку атаки.
	can_damage = false

	await get_tree().create_timer(damage_interval).timeout

	can_damage = true

	# Если Кир всё ещё находится внутри зоны, повторяем атаку.
	if player_inside != null:
		_damage_player()
