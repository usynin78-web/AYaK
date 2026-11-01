
extends Resource
class_name ItemData

# Уникальный идентификатор предмета.
@export var item_id: String = ""

# Название предмета.
@export var item_name: String = "Предмет"

# Описание предмета.
@export_multiline var description: String = ""

# Иконка предмета.
@export var icon: Texture2D

# Можно ли складывать несколько одинаковых предметов.
@export var stackable: bool = false

# Максимальное количество предметов в одной ячейке.
@export_range(1, 999) var max_stack: int = 1
