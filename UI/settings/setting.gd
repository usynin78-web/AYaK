extends Control

const ScreenSettings = preload("res://UI/settings/screen_settings.gd")
const GraphicSettings = preload("res://UI/settings/graphic_settings.gd")

@onready var settings_list: VBoxContainer = $RightPanel/ScrollContainer/SettingsList
@onready var screen_button: Button = $LeftPanel/screen
@onready var graphic_button: Button = $LeftPanel/graphic
@onready var exit_button: Button = $LeftPanel/exit_to_menu
@onready var left_panel: Panel = $LeftPanel

var screen_settings: RefCounted
var graphic_settings: Node
var language_button: Button
var showing_graphics: bool = false


func _ready() -> void:
	screen_settings = ScreenSettings.new(settings_list)
	graphic_settings = GraphicSettings.new()
	graphic_settings.setup(settings_list)

	screen_button.pressed.connect(_show_screen_settings)
	graphic_button.pressed.connect(_show_graphic_settings)
	exit_button.pressed.connect(_show_exit_settings)

	# Кнопка переключения языка создаётся здесь, чтобы не менять вручную сцену.
	language_button = Button.new()
	language_button.position = Vector2(30, 230)
	language_button.size = Vector2(450, 90)
	language_button.theme = screen_button.theme
	language_button.text = _get_language_button_text()
	left_panel.add_child(language_button)
	language_button.pressed.connect(_toggle_language)

	LocalisationManager.locale_changed.connect(_on_locale_changed)
	_show_screen_settings()


func _get_language_button_text() -> String:
	if LocalisationManager.current_locale == "ru":
		return tr("Язык: Русский")
	return tr("Язык: Английский")


func _toggle_language() -> void:
	var next_locale := "en" if LocalisationManager.current_locale == "ru" else "ru"
	LocalisationManager.set_locale(next_locale)


func _on_locale_changed(_locale: String) -> void:
	language_button.text = _get_language_button_text()

	# Пересоздаём динамические пункты настроек на новом языке.
	if showing_graphics:
		_show_graphic_settings()
	else:
		_show_screen_settings()


func _show_screen_settings() -> void:
	showing_graphics = false
	screen_settings.show_settings()


func _show_graphic_settings() -> void:
	showing_graphics = true
	graphic_settings.show_settings()


func _show_exit_settings() -> void:
	get_tree().change_scene_to_file("res://UI/main menu/main menu.tscn")
