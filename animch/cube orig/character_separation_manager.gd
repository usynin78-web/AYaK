extends Node
@export var separation_radius: float = 90.0
@export var separation_speed: float = 1000.0
@export var max_separation_speed: float = 1500.0

var _separation_forces: Dictionary = {}


func _physics_process(_delta: float) -> void:
	_separation_forces.clear()

	var characters: Array[CharacterBody2D] = []

	for node: Node in get_tree().get_nodes_in_group("npc"):
		if node is CharacterBody2D:
			characters.append(node as CharacterBody2D)

	for i: int in range(characters.size()):
		for j: int in range(i + 1, characters.size()):
			var first: CharacterBody2D = characters[i]
			var second: CharacterBody2D = characters[j]
			var offset: Vector2 = first.global_position - second.global_position
			var distance: float = offset.length()

			var push_direction: Vector2

			if distance < 0.001:
				# Даём кубикам разные направления, даже если они точно совпали.
				var angle: float = float(first.get_instance_id() % 360)
				push_direction = Vector2.RIGHT.rotated(deg_to_rad(angle))
			else:
				push_direction = offset / distance

			if distance >= separation_radius:
				continue

			var strength: float = 1.0 - distance / separation_radius
			var push: Vector2 = push_direction * separation_speed * strength

			_separation_forces[first] = _separation_forces.get(first, Vector2.ZERO) + push
			_separation_forces[second] = _separation_forces.get(second, Vector2.ZERO) - push


func get_separation(character: CharacterBody2D) -> Vector2:
	var force: Vector2 = _separation_forces.get(character, Vector2.ZERO)
	return force.limit_length(max_separation_speed)
