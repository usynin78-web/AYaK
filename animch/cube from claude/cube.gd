
extends CharacterBody2D

@export var unique_id: String = ""
@export var speed: float = 100.0
@export var walk_sway := 4.0
@export var walk_speed := 10.0
@export var min_wait_time := 1.0
@export var max_wait_time := 3.0

# Настройки отталкивания от Кира.
@export var player_push_radius: float = 65.0
@export var player_push_force: float = 700.0

# Защита от застревания.
@export var stuck_check_time := 0.6
@export var stuck_min_distance := 8.0

@onready var separation_manager: Node = get_tree().get_first_node_in_group("character_separation_manager")
@onready var health_component: Node = $AnimatedSprite2D/Hurtbox/HealthComponent
@onready var navigation: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var feet_marker: Marker2D = $FeetMarker
@onready var vision_controller = $VisionController

var is_waiting := false
var sway_time := 0.0
var base_scale: Vector2
var stuck_timer := 0.0
var stuck_check_position := Vector2.ZERO


func _ready() -> void:
	base_scale = sprite.scale

	add_to_group("damageable")
	add_to_group("npc")

	vision_controller.player_spotted.connect(_on_player_spotted)
	vision_controller.player_lost.connect(_on_player_lost)

	# Создаём постоянный идентификатор NPC.
	unique_id = str(get_path())

	# Проверяем, не был ли NPC уничтожен ранее.
	if CheckpointManager.removed_objects.has(unique_id):
		queue_free()
		return

	# Загружаем последнюю сохранённую позицию NPC.
	if CheckpointManager.npc_positions.has(unique_id):
		global_position = CheckpointManager.npc_positions[unique_id]

	# Регистрируем исходную позицию NPC.
	CheckpointManager.register_npc_start_position(self)

	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)

	_reset_stuck_check()


# Возвращает силу, отталкивающую кубика от Кира.
func _get_player_repulsion() -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D

	if not is_instance_valid(player):
		return Vector2.ZERO

	var offset: Vector2 = global_position - player.global_position
	var distance: float = offset.length()

	if player_push_radius <= 0.0 or distance >= player_push_radius:
		return Vector2.ZERO

	# Если персонажи оказались в одной точке,
	# выбираем запасное направление отталкивания.
	if distance < 0.001:
		offset = Vector2.RIGHT.rotated(float(get_instance_id() % 360))
		distance = 0.001

	var strength: float = 1.0 - distance / player_push_radius

	return offset.normalized() * player_push_force * strength


func _on_player_spotted(player: Node2D) -> void:
	print("👀 Вижу Кирчика!")


func _on_player_lost(player: Node2D) -> void:
	print("🙈 Потерял Кирчика!")


func wait_before_next_move() -> void:
	if is_waiting:
		return

	is_waiting = true
	velocity = Vector2.ZERO
	sprite.play("idle")

	await get_tree().create_timer(
		randf_range(min_wait_time, max_wait_time)
	).timeout

	is_waiting = false


func _on_health_changed(_cur, _max, damage_taken) -> void:
	hit_effect()

	var damage_scene = preload("res://UI/damage_number.tscn")
	var damage = damage_scene.instantiate()

	damage.global_position = global_position
	get_tree().current_scene.add_child(damage)
	damage.setup(damage_taken)


func hit_effect() -> void:
	var original_pos := sprite.position
	var tween := create_tween()

	var offset := Vector2(
		randf_range(-15, 15),
		randf_range(-15, 15)
	)

	tween.tween_property(sprite, "position", original_pos + offset, 0.05)
	tween.tween_property(sprite, "position", original_pos, 0.08)


func _on_died() -> void:
	# Запоминаем уничтоженного NPC.
	CheckpointManager.removed_objects[unique_id] = true
	queue_free()


func _process(delta: float) -> void:
	z_index = int(feet_marker.global_position.y)
	update_perspective()

	if velocity.length() > 1.0:
		sway_time += delta * walk_speed
		sprite.rotation = sin(sway_time) * deg_to_rad(walk_sway)
	else:
		sprite.rotation = lerp_angle(sprite.rotation, 0.0, delta * 8.0)


func _physics_process(delta: float) -> void:
	_move(delta)


func _move(delta: float) -> void:
	# Обычное движение по маршруту.
	var route_velocity := Vector2.ZERO

	if not is_waiting and not navigation.is_navigation_finished():
		var next_point: Vector2 = navigation.get_next_path_position()
		var direction: Vector2 = global_position.direction_to(next_point)

		route_velocity = direction * speed

	# Отталкивание от других кубиков.
	var separation := Vector2.ZERO

	if route_velocity != Vector2.ZERO and is_instance_valid(separation_manager):
		separation = separation_manager.get_separation(self)

	# Отталкивание от Кира работает даже во время ожидания.
	var player_push := _get_player_repulsion()

	# Объединяем все силы движения.
	velocity = route_velocity + separation + player_push

	# Двигаемся даже тогда, когда маршрут завершён или кубик ждёт.
	move_and_slide()

	# Проверяем застревание только во время движения по маршруту.
	if route_velocity.length() > 0.0:
		_check_stuck(delta)
	else:
		_reset_stuck_check()

	# Обновляем анимацию.
	if velocity.length() > 1.0:
		if sprite.animation != "walk":
			sprite.play("walk")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")


# Следит, не упёрся ли кубик в препятствие.
func _check_stuck(delta: float) -> void:
	stuck_timer += delta

	if stuck_timer < stuck_check_time:
		return

	var moved := global_position.distance_to(stuck_check_position)
	_reset_stuck_check()

	if moved < stuck_min_distance:
		_on_stuck()


func _reset_stuck_check() -> void:
	stuck_timer = 0.0
	stuck_check_position = global_position


func _on_stuck() -> void:
	velocity = Vector2.ZERO

	# Сообщаем патрулю, что точка достигнута.
	navigation.navigation_finished.emit()

	# Если патруля нет, останавливаемся на месте.
	if not is_waiting:
		navigation.target_position = global_position


func move_to(target: Vector2) -> void:
	print(sprite.animation)

	_reset_stuck_check()
	navigation.target_position = target

	var direction := global_position.direction_to(target)
	vision_controller.set_direction(direction)

	sprite.play("walk")


func update_perspective() -> void:
	var scale_factor := clampf(
		0.5 + global_position.y / 1000.0,
		0.5,
		1.5
	)

	sprite.scale = base_scale * scale_factor
