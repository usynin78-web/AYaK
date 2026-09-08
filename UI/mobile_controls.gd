extends Control

## Touch-only overlay that translates each mobile gesture into the existing
## InputMap actions used by the gameplay scripts.

const JOYSTICK_ACTIONS := {
	"left": &"ui_left",
	"right": &"ui_right",
	"up": &"ui_up",
	"down": &"ui_down",
}

const BUTTONS := [
	{"id": "shift", "action": &"ui_shift", "label": "SHIFT", "hold": true},
	{"id": "interact", "action": &"interact", "label": "E", "hold": false},
	{"id": "attack", "action": &"attack", "label": "ATTACK", "hold": false},
	# Keep cancel separate so it can later open a pause menu independently.
	{"id": "cancel", "action": &"ui_cancel", "label": "ESC", "hold": false},
]

const TAP_HOLD_TIME := 0.08
const JOYSTICK_DEADZONE := 0.18

var joystick_finger := -1
var joystick_value := Vector2.ZERO
var touch_targets: Dictionary = {}
var held_actions: Dictionary = {}


func _ready() -> void:
	# Platform detection, rather than screen size, keeps the overlay disabled on PCs.
	var is_mobile := OS.get_name() in ["Android", "iOS"]
	visible = is_mobile
	set_process_input(is_mobile)
	if is_mobile:
		queue_redraw()


func _exit_tree() -> void:
	_release_all_actions()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch_pressed(event.index, event.position)
		else:
			_handle_touch_released(event.index)
	elif event is InputEventScreenDrag and event.index == joystick_finger:
		_update_joystick(event.position)


func _handle_touch_pressed(finger: int, position: Vector2) -> void:
	if _is_in_joystick(position) and joystick_finger == -1:
		joystick_finger = finger
		touch_targets[finger] = "joystick"
		_update_joystick(position)
		get_viewport().set_input_as_handled()
		return

	for button in BUTTONS:
		var id: String = button["id"]
		if _button_center(id).distance_to(position) <= _button_radius(id):
			touch_targets[finger] = id
			_press_button(button)
			get_viewport().set_input_as_handled()
			return


func _handle_touch_released(finger: int) -> void:
	if not touch_targets.has(finger):
		return

	var target: String = touch_targets[finger]
	touch_targets.erase(finger)
	if target == "joystick":
		joystick_finger = -1
		joystick_value = Vector2.ZERO
		_set_joystick_actions(Vector2.ZERO)
		queue_redraw()
		return

	for button in BUTTONS:
		if button["id"] == target and button["hold"]:
			var action: StringName = button["action"]
			held_actions.erase(action)
			Input.action_release(action)
			queue_redraw()
			return


func _press_button(button: Dictionary) -> void:
	var action: StringName = button["action"]
	if button["hold"]:
		held_actions[action] = true
		Input.action_press(action)
	else:
		# Preserve just_pressed behaviour for attack, interaction and ui_cancel.
		Input.action_press(action)
		_release_tap_after_delay(action)
	queue_redraw()


func _release_tap_after_delay(action: StringName) -> void:
	await get_tree().create_timer(TAP_HOLD_TIME).timeout
	if is_inside_tree():
		Input.action_release(action)


func _update_joystick(position: Vector2) -> void:
	var offset := position - _joystick_center()
	var radius := _joystick_radius()
	joystick_value = offset.limit_length(radius) / radius
	if joystick_value.length() < JOYSTICK_DEADZONE:
		joystick_value = Vector2.ZERO
	_set_joystick_actions(joystick_value)
	queue_redraw()


func _set_joystick_actions(value: Vector2) -> void:
	_set_direction_action(JOYSTICK_ACTIONS.left, maxf(-value.x, 0.0))
	_set_direction_action(JOYSTICK_ACTIONS.right, maxf(value.x, 0.0))
	_set_direction_action(JOYSTICK_ACTIONS.up, maxf(-value.y, 0.0))
	_set_direction_action(JOYSTICK_ACTIONS.down, maxf(value.y, 0.0))


func _set_direction_action(action: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _release_all_actions() -> void:
	_set_joystick_actions(Vector2.ZERO)
	for action in held_actions:
		Input.action_release(action)
	held_actions.clear()


func _is_in_joystick(position: Vector2) -> bool:
	return _joystick_center().distance_to(position) <= _joystick_radius() * 1.35


func _joystick_radius() -> float:
	return clampf(get_viewport_rect().size.y * 0.105, 72.0, 128.0)


func _joystick_center() -> Vector2:
	var radius := _joystick_radius()
	return Vector2(radius * 1.35, get_viewport_rect().size.y - radius * 1.35)


func _button_radius(id: String) -> float:
	if id == "cancel":
		return _joystick_radius() * 0.48
	return _joystick_radius() * 0.66


func _button_center(id: String) -> Vector2:
	var viewport_size := get_viewport_rect().size
	var radius := _joystick_radius()
	match id:
		"attack":
			return Vector2(viewport_size.x - radius * 1.2, viewport_size.y - radius * 1.35)
		"shift":
			return Vector2(viewport_size.x - radius * 2.75, viewport_size.y - radius * 0.95)
		"interact":
			return Vector2(viewport_size.x - radius * 1.15, viewport_size.y - radius * 2.85)
		"cancel":
			return Vector2(viewport_size.x - radius * 0.85, radius * 0.85)
	return Vector2.ZERO


func _draw() -> void:
	var joystick_center := _joystick_center()
	var joystick_radius := _joystick_radius()
	draw_circle(joystick_center, joystick_radius, Color(0.08, 0.1, 0.14, 0.45))
	draw_arc(joystick_center, joystick_radius, 0.0, TAU, 48, Color(0.8, 0.9, 1.0, 0.65), 3.0)
	draw_circle(joystick_center + joystick_value * joystick_radius, joystick_radius * 0.38, Color(0.65, 0.85, 1.0, 0.72))

	for button in BUTTONS:
		var id: String = button["id"]
		var action: StringName = button["action"]
		var pressed := held_actions.has(action) or touch_targets.values().has(id)
		var color := Color(0.85, 0.38, 0.25, 0.75) if id == "attack" else Color(0.16, 0.22, 0.32, 0.72)
		if pressed:
			color = color.lightened(0.25)
		var center := _button_center(id)
		var radius := _button_radius(id)
		draw_circle(center, radius, color)
		draw_arc(center, radius, 0.0, TAU, 32, Color(0.9, 0.95, 1.0, 0.75), 2.0)
		var font := ThemeDB.fallback_font
		var font_size := int(radius * (0.34 if id == "attack" else 0.42))
		var text := String(button["label"])
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, center - text_size * 0.5 + Vector2(0, font_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
