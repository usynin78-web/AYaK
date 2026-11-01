extends Control

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var start_button: Button = $VBoxContainer/start
@onready var continue_button: Button = $VBoxContainer/continue
@onready var exit_button: Button = $VBoxContainer/exit
@onready var setting_button: Button = $VBoxContainer/setting
@onready var loading_screen: AnimatedSprite2D = $loading
@onready var start_prompt: Label = $TextureRect/Label

var started: bool = false

func _ready() -> void:
	start_button.visible = false
	continue_button.visible = false
	exit_button.visible = false
	setting_button.visible = false
	loading_screen.visible = false

	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	setting_button.pressed.connect(_on_setting_pressed)

	if not LocalisationManager.locale_changed.is_connected(_on_locale_changed):
		LocalisationManager.locale_changed.connect(_on_locale_changed)
	_refresh_translated_text()

func _refresh_translated_text() -> void:
	start_prompt.text = tr("Press any key to start")
	start_button.text = tr("Начать")
	continue_button.text = tr("Продолжить")
	setting_button.text = tr("Настройки")
	exit_button.text = tr("Выйти")


func _on_locale_changed(_locale: String) -> void:
	_refresh_translated_text()


func _input(event: InputEvent) -> void:
	if started:
		return

	if (event is InputEventKey and event.pressed) \
	or (event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT):

		started = true
		anim_player.play("title_up")

		start_button.visible = true
		exit_button.visible = true
		setting_button.visible = true

		if CheckpointManager.has_save():
			continue_button.visible = true

func _on_start_pressed():
	var tree = get_tree()
	await _play_loading_full_animation()

	if tree:
		CheckpointManager.clear_save()
		
		tree.change_scene_to_file("res://loc/roomtest/main.tscn")
	else:
		push_error(tr("SceneTree не найден"))

func _on_continue_pressed() -> void:
	var tree := get_tree()
	await _play_loading_full_animation()

	if tree:
		tree.change_scene_to_file("res://loc/roomtest/main.tscn")
	else:
		push_error(tr("SceneTree не найден"))

func _on_setting_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/settings/setting.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _play_loading_full_animation() -> void:
	if not _has_valid_loading_animation_frames():
		return

	loading_screen.visible = true
	loading_screen.play()

	var duration := _get_loading_animation_duration()
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
	else:
		await get_tree().process_frame

func _get_loading_animation_duration() -> float:
	if loading_screen.sprite_frames == null:
		return 0.0
	var animation_name := loading_screen.animation
	if animation_name == &"":
		return 0.0
	var frame_count := loading_screen.sprite_frames.get_frame_count(animation_name)
	if frame_count <= 0:
		return 0.0
	var total_frame_duration := 0.0
	for frame in frame_count:
		total_frame_duration += loading_screen.sprite_frames.get_frame_duration(animation_name, frame)
	var playback_speed := loading_screen.sprite_frames.get_animation_speed(animation_name) * absf(loading_screen.speed_scale)
	if playback_speed <= 0.0:
		return 0.0
	return total_frame_duration / playback_speed

func _has_valid_loading_animation_frames() -> bool:
	if loading_screen == null or loading_screen.sprite_frames == null:
		return false
	var animation_name := loading_screen.animation
	if animation_name == &"":
		return false
	var frame_count := loading_screen.sprite_frames.get_frame_count(animation_name)
	if frame_count <= 0:
		return false
	for frame in frame_count:
		if loading_screen.sprite_frames.get_frame_texture(animation_name, frame) == null:
			return false
	return true
