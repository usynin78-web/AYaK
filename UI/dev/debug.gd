
extends Label

@onready var player = $"../../c3"
@onready var room = $"../../Node2D"


func _ready() -> void:
	add_to_group("fps_counter")
	visible = SettingsManager.show_fps


func _process(_delta: float) -> void:
	# Получаем актуальную ссылку на менеджер дней.
	var day_manager = get_tree().get_first_node_in_group("day_manager")

	# По умолчанию отображаем первый день.
	var current_day: int = 1

	if is_instance_valid(day_manager):
		current_day = day_manager.current_day

	text = """
FPS: %d
X: %d
Y: %d
Локация: %s
День: %02d
""" % [
		Engine.get_frames_per_second(),
		int(player.global_position.x),
		int(player.global_position.y),
		room.location_id,
		current_day
	]


func _input(event) -> void:
	if event.is_action_pressed("fps_toggle"):
		SettingsManager.show_fps = !SettingsManager.show_fps
		visible = SettingsManager.show_fps
