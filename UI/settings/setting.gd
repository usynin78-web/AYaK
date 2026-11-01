extends Control

const ScreenSettings = preload("res://UI/settings/screen_settings.gd")
const GraphicSettings = preload("res://UI/settings/graphic_settings.gd")

@onready var title_label: Label = $Label
@onready var settings_list: VBoxContainer = $RightPanel/ScrollContainer/SettingsList
@onready var screen_button: Button = $LeftPanel/screen
@onready var graphic_button: Button = $LeftPanel/graphic
@onready var exit_button: Button = $LeftPanel/exit_to_menu
@onready var language_button: Button = $LeftPanel/language

var screen_settings: RefCounted
var graphic_settings: Node
var showing_graphics: bool = false


func _ready() -> void:
	screen_settings = ScreenSettings.new(settings_list)
	graphic_settings = GraphicSettings.new()
	graphic_settings.setup(settings_list)

	screen_button.pressed.connect(_show_screen_settings)
	graphic_button.pressed.connect(_show_graphic_settings)
	exit_button.pressed.connect(_show_exit_settings)
	language_button.pressed.connect(_toggle_language)

	if not LocalisationManager.locale_changed.is_connected(_on_locale_changed):
		LocalisationManager.locale_changed.connect(_on_locale_changed)

	_refresh_static_text()
	_show_screen_settings()


func _get_language_button_text() -> String:
	if LocalisationManager.current_locale == "ru":
		return tr("Язык: Русский")
	return tr("Язык: Английский")


func _toggle_language() -> void:
	var next_locale := "en" if LocalisationManager.current_locale == "ru" else "ru"
	LocalisationManager.set_locale(next_locale)


func _refresh_static_text() -> void:
	# Reapply each scene label from its source key after a locale change.
	title_label.text = tr("Настройки")
	screen_button.text = tr("Экран")
	graphic_button.text = tr("Графика")
	exit_button.text = tr("В меню")
	language_button.text = _get_language_button_text()


func _on_locale_changed(_locale: String) -> void:
	_refresh_static_text()

	# Rebuild dynamic settings so their labels and values use the new locale.
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
