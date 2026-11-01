
extends Button

# Индекс ячейки в инвентаре.
var slot_index: int = -1

# Данные находящегося в ячейке предмета.
var item: ItemData = null

# Количество предметов в ячейке.
var item_count: int = 0


func _ready() -> void:
	custom_minimum_size = Vector2(250, 250)


# Настраивает индекс ячейки.
func setup(index: int) -> void:
	slot_index = index


# Помещает предмет в ячейку.
func set_item(new_item: ItemData, amount: int = 1) -> void:
	item = new_item
	item_count = amount
	_refresh_slot()


# Обновляет внешний вид ячейки.
func _refresh_slot() -> void:
	if item == null:
		icon = null
		text = ""
		return

	icon = item.icon
	text = str(item_count) if item.stackable and item_count > 1 else ""


# Полностью очищает ячейку.
func clear_slot() -> void:
	item = null
	item_count = 0
	_refresh_slot()
