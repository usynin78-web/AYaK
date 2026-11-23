extends Node

# Сообщает интерфейсу или другим объектам, что здоровье изменилось.
# Третий параметр — сколько урона было нанесено.
signal health_changed(current_health: int, max_health: int, damage_taken: int)

# Сообщает, что объект умер.
signal died

# Максимальное здоровье кубика.
@export var max_health: int = 100

# Текущее здоровье.
var current_health: int


func _ready() -> void:
 # Кубик всегда появляется с полным HP.
 current_health = max_health

 health_changed.emit(current_health, max_health, 0)


func take_damage(amount: int) -> void:
 # Защита от некорректного урона.
 if amount <= 0:
  return

 # Уменьшаем HP.
 current_health = clamp(current_health - amount, 0, max_health)

 # Передаём реальный урон в сигнал.
 health_changed.emit(current_health, max_health, amount)

 print("Кубик получил ", amount, " урона. Осталось HP:", current_health)

 if current_health <= 0:
  died.emit()


func _on_health_changed(current_health: int, max_health: int, damage_taken: int) -> void:
 print("Кубик HP: ", current_health, "/", max_health)
