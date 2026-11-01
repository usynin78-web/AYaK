extends Control

# Получаем доступ к TextureProgressBar внутри сцены hp.tscn
@onready var hp_bar: TextureProgressBar = $TextureProgressBar

# Сюда будет записан HealthComponent игрока
var health_component: Node


func _ready() -> void:
	# Ищем игрока по группе player
	var player = get_tree().get_first_node_in_group("player")
	
	if player == null:
		push_error(tr("Игрок не найден."))
		return
	
	# Ищем HealthComponent внутри игрока
	health_component = player.get_node_or_null("HealthComponent")
	
	if health_component == null:
		push_error(tr("HealthComponent не найден."))
		return
	
	# Подключаем сигналы
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	
	# Сразу обновляем HP
	_on_health_changed(
		health_component.current_health,
		health_component.max_health
	)


func _on_health_changed(current_health: int, max_health: int) -> void:
	# Вот сюда вставляются строки обновления полоски
	hp_bar.max_value = max_health
	hp_bar.value = current_health


func _on_died() -> void:
	print("Кир умер")
