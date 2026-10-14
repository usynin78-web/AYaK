extends CharacterBody2D

const SPEED: int = 360
const RUN_MULTIPLIER: int = 2
const ATTACK_COOLDOWN: float = 0.4

@onready var sprite_front: Sprite2D = $c3f
@onready var sprite_back: Sprite2D = $c3b
@onready var sprite_left: Sprite2D = $c3l
@onready var sprite_right: Sprite2D = $c3r
@onready var feer_marker: Marker2D = $Marker2D
@onready var health_component: Node = $HealthComponent

var direction: Vector2 = Vector2.ZERO
var look_direction: Vector2 = Vector2.DOWN
var base_scale: Vector2 = Vector2.ONE
var is_dead: bool = false
var attack_timer: float = 0.0

func _ready() -> void:
	global_position = CheckpointManager.get_spawn_position(global_position)
	hide_all_sprites()
	sprite_front.visible = true
	health_component.died.connect(_on_died)

func _process(_delta: float) -> void:
	z_index = int(feer_marker.global_position.y)

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Работа с кулдауном атаки
	if attack_timer > 0.0:
		attack_timer -= delta

	# Ввод направления
	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	direction = input_vector

	if input_vector != Vector2.ZERO:
		look_direction = input_vector

	velocity = direction * SPEED

	if Input.is_action_pressed("ui_shift"):
		velocity *= RUN_MULTIPLIER

	# Атака: проверка таймера вместо can_attack
	if Input.is_action_just_pressed("attack") and attack_timer <= 0.0:
		_attack()

	move_and_slide()
	_update_sprite_animation()
	update_perspective()

func _attack() -> void:
	attack_timer = ATTACK_COOLDOWN
	
	var targets: Array[Node] = get_tree().get_nodes_in_group("damageable")
	var attack_range_sq: float = 250.0 * 250.0 

	for target in targets:
		if not is_instance_valid(target) or target == self:
			continue

		var to_target: Vector2 = target.global_position - global_position
		var dist_sq: float = to_target.length_squared()

		# Проверка дистанции
		if dist_sq > attack_range_sq:
			continue

		# Проверка направления взгляда
		if look_direction.dot(to_target.normalized()) < 0.5:
			continue

		# Гибкий поиск компонента здоровья
		var hp: Node = _find_health_component(target)
		
		if hp:
			var damage: int = randi_range(20, 30)
			hp.take_damage(damage)
			break # Удар по одной цели

func _find_health_component(node: Node) -> Node:
	if node.has_method("take_damage"):
		return node
	for child in node.get_children():
		var found = _find_health_component(child)
		if found:
			return found
	return null

func _update_sprite_animation() -> void:
	if direction != Vector2.ZERO:
		hide_all_sprites()
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				sprite_right.visible = true
			else:
				sprite_left.visible = true
		else:
			if direction.y > 0:
				sprite_front.visible = true
			else:
				sprite_back.visible = true

func hide_all_sprites() -> void:
	sprite_front.visible = false
	sprite_back.visible = false
	sprite_left.visible = false
	sprite_right.visible = false

func update_perspective() -> void:
	var scale_factor: float = clamp(0.5 + global_position.y / 1000.0, 0.5, 1.5)
	var final_scale: Vector2 = base_scale * scale_factor
	
	sprite_front.scale = final_scale
	sprite_back.scale = final_scale
	sprite_left.scale = final_scale
	sprite_right.scale = final_scale

func _on_died() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	print("Кир умер.")
	
