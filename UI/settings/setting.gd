
extends Control

const ScreenSettings = preload("res://UI/settings/screen_settings.gd")
const GraphicSettings = preload("res://UI/settings/graphic_settings.gd")
const LanguageSettings = preload("res://UI/settings/language_settings.gd")

@onready var title_label: Label = $Label
@onready var settings_list: VBoxContainer = $RightPanel/ScrollContainer/SettingsList
@onready var screen_button: Button = $LeftPanel/screen
@onready var graphic_button: Button = $LeftPanel/graphic
@onready var exit_button: Button = $LeftPanel/exit_to_menu
@onready var language_button: Button = $LeftPanel/language

var screen_settings
var graphic_settings
var language_settings

# Запоминает открытую вкладку.
var current_tab: String = "screen"


func _ready() -> void:
	# Создаём модули настроек.
	screen_settings = ScreenSettings.new(settings_list)

	graphic_settings = GraphicSettings.new()
	graphic_settings.setup(settings_list)

	language_settings = LanguageSettings.new(settings_list)

	# Подключаем кнопки боковой панели.
	screen_button.pressed.connect(_show_screen_settings)
	graphic_button.pressed.connect(_show_graphic_settings)
	language_button.pressed.connect(_show_language_settings)
	exit_button.pressed.connect(_show_exit_settings)

	# Подписываемся на изменение языка.
	if not LocalisationManager.locale_changed.is_connected(_on_locale_changed):
		LocalisationManager.locale_changed.connect(_on_locale_changed)

	_refresh_static_text()
	_show_screen_settings()


# Обновляет надписи боковой панели и заголовок.
func _refresh_static_text() -> void:
	title_label.text = tr("Настройки")
	screen_button.text = tr("Экран")
	graphic_button.text = tr("Графика")
	language_button.text = tr("Язык")
	exit_button.text = tr("В меню")


# Обновляет интерфейс после смены языка.
func _on_locale_changed(_locale: String) -> void:
	_refresh_static_text()

	match current_tab:
		"screen":
			_show_screen_settings()
		"graphic":
			_show_graphic_settings()
		"language":
			_show_language_settings()


# Показывает настройки экрана.
func _show_screen_settings() -> void:
	current_tab = "screen"
	screen_settings.show_settings()


# Показывает настройки графики.
func _show_graphic_settings() -> void:
	current_tab = "graphic"
	graphic_settings.show_settings()


# Показывает настройки языка.
func _show_language_settings() -> void:
	current_tab = "language"
	language_settings.show_settings()


# Возвращает игрока в главное меню.
func _show_exit_settings() -> void:
	get_tree().change_scene_to_file("res://UI/main menu/main menu.tscn")
