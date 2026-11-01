extends Node

signal player_spotted(player)
signal player_lost(player)

@export var vision_area: Area2D
@export var vision_ray: RayCast2D
@export var max_look_angle: float = 60.0
@export var look_deadzone: float = 5.0

var default_rotation: float = 0.0
var detected_player: Node2D = null
var last_player_position: Vector2 = Vector2.ZERO
var last_wall_state: bool = false

func _ready() -> void:
	if vision_area == null:
		push_error(tr("VisionArea не назначена!"))
		return

	if vision_ray == null:
		push_error(tr("VisionRayCast не назначен!"))
		return

	vision_area.body_entered.connect(_on_body_entered)
	vision_area.body_exited.connect(_on_body_exited)
	default_rotation = vision_area.rotation

func _process(delta: float) -> void:
	if detected_player != null:
		var current_player_position: Vector2 = detected_player.global_position
		var player_movement: float = current_player_position.distance_to(
			last_player_position
		)
		var player_visible: bool = can_see_player()
		if player_visible and player_movement >= look_deadzone:
			var direction: Vector2 = (
				current_player_position - vision_area.global_position
			)
			set_direction(direction, delta)
		last_player_position = current_player_position
	else:
		var weight: float = 1.0 - exp(-2.5 * delta)
		vision_area.rotation = lerp_angle(
			vision_area.rotation,
			default_rotation,
			weight
		)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		detected_player = body
		last_player_position = body.global_position
		player_spotted.emit(body)

func _on_body_exited(body: Node2D) -> void:
	if body == detected_player:
		detected_player = null
		player_lost.emit(body)

func can_see_player() -> bool:
	if detected_player == null:
		return false

	vision_ray.target_position = vision_ray.to_local(
		detected_player.global_position
	)

	vision_ray.force_raycast_update()

	var sees_wall: bool = false

	if vision_ray.is_colliding():
		var collider: Object = vision_ray.get_collider()

		if collider != detected_player:
			sees_wall = true
			
	if sees_wall != last_wall_state:
		if sees_wall:
			print("Вижу стену")
		else:
			print("Не вижу стену")

		last_wall_state = sees_wall

	return not sees_wall

func can_see_player_in_vision() -> bool:
	return detected_player != null


func get_player() -> Node2D:
	return detected_player
func set_direction(direction: Vector2, delta: float = 0.016) -> void:
	if direction.length_squared() > 0.0:
		var target_rotation: float = direction.angle() - PI / 2.0
		var max_angle: float = deg_to_rad(max_look_angle)
		var min_rotation: float = default_rotation - max_angle
		var max_rotation: float = default_rotation + max_angle
		target_rotation = clamp(
			target_rotation,
			min_rotation,
			max_rotation
		)

		var weight: float = 1.0 - exp(-2.5 * delta)
		vision_area.rotation = lerp_angle(
			vision_area.rotation,
			target_rotation,
			weight
		)
		
