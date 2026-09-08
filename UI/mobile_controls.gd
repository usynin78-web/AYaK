extends Control

## Touch-only overlay that translates each mobile gesture into the existing
## InputMap actions used by the gameplay scripts.

const JOYSTICK_ACTIONS := {
	"left": &"ui_left",
	"right": &"ui_right",
	"up": &"ui_up",
	"down": &"ui_down",
}

# Картинки мобильного управления.
# preload() загружает ресурс из проекта и позволяет использовать его напрямую
# из кода, без добавления отдельного узла в сцену.
const ATTACK_TEXTURE: Texture2D = preload(
	"res://Gameplay object button/Mob.V/Attack.png"
)

const SHIFT_TEXTURE: Texture2D = preload(
	"res://Gameplay object button/Mob.V/Shift.png"
)

const E_TEXTURE: Texture2D = preload(
	"res://Gameplay object button/Mob.V/E.png"
)

const ESC_TEXTURE: Texture2D = preload(
	"res://Gameplay object button/Mob.V/Esc.png"
)

const JOYSTICK_BASE_TEXTURE: Texture2D = preload(
	"res://Gameplay object button/Mob.V/Joystick1.png"
)

const JOYSTICK_HANDLE_TEXTURE: Texture2D = preload(
	"res://Gameplay object button/Mob.V/Joystick2.png"
)

const BUTTONS := [
	{
		"id": "shift",
		"action": &"ui_shift",
		"hold": true,
		"texture": SHIFT_TEXTURE
	},
	{
		"id": "interact",
		"action": &"interact",
		"hold": false,
		"texture": E_TEXTURE
	},
	{
		"id": "attack",
		"action": &"attack",
		"hold": false,
		"texture": ATTACK_TEXTURE
	},
	{
		"id": "cancel",
		"action": &"ui_cancel",
		"hold": false,
		"texture": ESC_TEXTURE
	},
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
	_set_direction_action(
		JOYSTICK_ACTIONS.left,
		maxf(-value.x, 0.0)
	)

	_set_direction_action(
		JOYSTICK_ACTIONS.right,
		maxf(value.x, 0.0)
	)

	_set_direction_action(
		JOYSTICK_ACTIONS.up,
		maxf(-value.y, 0.0)
	)

	_set_direction_action(
		JOYSTICK_ACTIONS.down,
		maxf(value.y, 0.0)
	)


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
	return clampf(
		get_viewport_rect().size.y * 0.105,
		72.0,
		128.0
	)


func _joystick_center() -> Vector2:
	var radius := _joystick_radius()

	return Vector2(
		radius * 1.35,
		get_viewport_rect().size.y - radius * 1.35
	)


func _button_radius(id: String) -> float:
	if id == "cancel":
		return _joystick_radius() * 0.48

	return _joystick_radius() * 0.66


func _button_center(id: String) -> Vector2:
	var viewport_size := get_viewport_rect().size
	var radius := _joystick_radius()

	match id:
		"attack":
			return Vector2(
				viewport_size.x - radius * 1.2,
				viewport_size.y - radius * 1.35
			)

		"shift":
			return Vector2(
				viewport_size.x - radius * 2.75,
				viewport_size.y - radius * 0.95
			)

		"interact":
			return Vector2(
				viewport_size.x - radius * 1.15,
				viewport_size.y - radius * 2.85
			)

		"cancel":
			return Vector2(
				viewport_size.x - radius * 0.85,
				radius * 0.85
			)

	return Vector2.ZERO


func _draw() -> void:
	# Большой джойстик в оригинальном размере картинки.
	var joystick_center := _joystick_center()

	draw_texture(
		JOYSTICK_BASE_TEXTURE,
		joystick_center - JOYSTICK_BASE_TEXTURE.get_size() / 2.0
	)

	# Маленький джойстик в оригинальном размере картинки.
	var handle_center := (
		joystick_center + joystick_value * _joystick_radius()
	)

	draw_texture(
		JOYSTICK_HANDLE_TEXTURE,
		handle_center - JOYSTICK_HANDLE_TEXTURE.get_size() / 2.0
	)

	# Кнопки в оригинальном размере PNG.
	for button in BUTTONS:
		var id: String = button["id"]
		var center := _button_center(id)
		var texture: Texture2D = button["texture"]

		draw_texture(
			texture,
			center - texture.get_size() / 2.0
		)