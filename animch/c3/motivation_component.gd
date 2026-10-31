extends Node

# Сигнал для обновления шкалы мотивации.
signal motivation_changed(current_motivation: int, max_motivation: int)

# Максимальная мотивация.
@export var max_motivation: int = 100

# Текущая мотивация.
var current_motivation: int


func _ready() -> void:
    # Загружаем мотивацию из CheckpointManager.
    current_motivation = CheckpointManager.get_saved_motivation(max_motivation)

    # Защищаем значение от выхода за допустимые пределы.
    current_motivation = clampi(current_motivation, 0, max_motivation)

    print("Загружена мотивация Кира: ", current_motivation)

    # Обновляем интерфейс.
    motivation_changed.emit(current_motivation, max_motivation)


# Изменяет мотивацию.
# Положительное значение восстанавливает её, отрицательное снижает.
func change_motivation(amount: int) -> void:
    if amount == 0:
        return

    var previous_motivation := current_motivation

    current_motivation = clampi(
        current_motivation + amount,
        0,
        max_motivation
    )

    if current_motivation != previous_motivation:
        motivation_changed.emit(current_motivation, max_motivation)
