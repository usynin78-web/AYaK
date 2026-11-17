extends Control

const SLOT_SCENE = preload("res://UI/invetory/inventory_slot.tscn")

@onready var grid: GridContainer = $Panel/ScrollContainer/GridContainer

# Тестовый предмет для проверки инвентаря.
@export var test_item: ItemData
@export var inventory_size: int = 15
@export var columns: int = 5

# Список созданных ячеек.
var slots: Array[Button] = []


func _ready() -> void:
	hide()
	grid.columns = columns
	_create_slots()

	# Добавляем тестовый предмет в первую свободную ячейку.
	if test_item != null:
		add_item(test_item)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory_toggle"):
		visible = not visible


# Создаёт ячейки инвентаря.
func _create_slots() -> void:
	for i in range(inventory_size):
		var slot = SLOT_SCENE.instantiate()
		grid.add_child(slot)
		slot.setup(i)
		slots.append(slot)


# Добавляет предмет в первую свободную ячейку.
func add_item(item: ItemData, amount: int = 1) -> bool:
	for slot in slots:
		if slot.item == null:
			slot.set_item(item, amount)
			return true

	return false
