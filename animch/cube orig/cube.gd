extends CharacterBody2D

@export var unique_id: String = ""
@export var speed: float = 100.0
@export var walk_sway := 4.0
@export var walk_speed := 10.0
@export var min_wait_time := 1.0
@export var max_wait_time := 3.0

@onready var health_component: Node = $AnimatedSprite2D/Hurtbox/HealthComponent
@onready var navigation: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var feet_marker: Marker2D = $FeetMarker
@onready var vision_controller = $VisionController

var is_waiting := false
var sway_time := 0.0
var base_scale: Vector2


func _ready() -> void:
	base_scale = sprite.scale

	add_to_group("damageable")
	add_to_group("npc")

	vision_controller.player_spotted.connect(_on_player_spotted)
	vision_controller.player_lost.connect(_on_player_lost)

	unique_id = str(get_path())

	if CheckpointManager.removed_objects.has(unique_id):
		queue_free()
		return

	if CheckpointManager.npc_positions.has(unique_id):
		global_position = CheckpointManager.npc_positions[unique_id]

	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)


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
	CheckpointManager.removed_objects[unique_id] = true
	queue_free()


func _process(delta: float) -> void:
	z_index = int(feet_marker.global_position.y)
	update_perspective()

	if velocity.length() > 1:
		sway_time += delta * walk_speed
		sprite.rotation = sin(sway_time) * deg_to_rad(walk_sway)
	else:
		sprite.rotation = lerp_angle(sprite.rotation, 0.0, delta * 8.0)


func _physics_process(_delta: float) -> void:
	_move()


func _move() -> void:
	if is_waiting:
		return

	# Проверяем, дошли ли мы до конца.
	if navigation.is_navigation_finished():
		velocity = Vector2.ZERO

		if sprite.animation != "idle":
			sprite.play("idle")

		return

	# Получаем следующую точку маршрута.
	var next_point := navigation.get_next_path_position()

	# Направление к следующей точке.
	var direction := global_position.direction_to(next_point)

	vision_controller.set_direction(direction)
	velocity = direction * speed

	if sprite.animation != "walk":
		sprite.play("walk")

	move_and_slide()


func move_to(target: Vector2) -> void:
	print(sprite.animation)

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
