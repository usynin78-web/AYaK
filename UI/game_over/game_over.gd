extends Control

@onready var start_button: Button = $VBoxContainer/start
@onready var menu_button: Button = $VBoxContainer/menu


func _ready():
 start_button.pressed.connect(_on_start_pressed)
 menu_button.pressed.connect(_on_menu_pressed)


func _on_start_pressed():
 CheckpointManager.clear_save()
 get_tree().change_scene_to_file("res://loc/roomtest/main.tscn")

func _on_menu_pressed():
 CheckpointManager.clear_save()
 get_tree().change_scene_to_file("res://UI/main menu/main menu.tscn")
