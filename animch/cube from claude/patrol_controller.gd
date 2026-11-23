extends Node

@export var cube: Array[CharacterBody2D]
@export var routes: Array[Node2D]

var npc_data := {}

func _ready() -> void:
	for npc in cube:
		await npc.ready

		var agent: NavigationAgent2D = npc.get_node("NavigationAgent2D")
		agent.navigation_finished.connect(_on_navigation_finished.bind(npc))

		npc_data[npc] = {
			"points": [],
			"current": 0
		}

		_choose_route(npc)
		_send_to_next_point(npc)


func _choose_route(npc: CharacterBody2D) -> void:
	if routes.is_empty():
		return

	var route: Node2D = routes.pick_random()

	var points: Array[Marker2D] = []

	for child in route.get_children():
		if child is Marker2D:
			points.append(child)

	npc_data[npc]["points"] = points
	npc_data[npc]["current"] = randi() % points.size()


func _send_to_next_point(npc: CharacterBody2D) -> void:
	var points: Array = npc_data[npc]["points"]

	if points.is_empty():
		return

	var current: int = npc_data[npc]["current"]

	npc.move_to(points[current].global_position)


func _on_navigation_finished(npc: CharacterBody2D) -> void:
	await npc.wait_before_next_move()

	npc_data[npc]["current"] += 1

	var current: int = npc_data[npc]["current"]
	var points: Array = npc_data[npc]["points"]

	if current >= points.size():
		_choose_route(npc)

	_send_to_next_point(npc)
