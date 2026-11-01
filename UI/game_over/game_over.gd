extends Control

@onready var start_button = $VBoxContainer/start
@onready var menu_button = $VBoxContainer/menu


func _ready():
 start_button.visible = false
 menu_button.visible = false

 start_button.pressed.connect(_on_start_pressed)
 menu_button.pressed.connect(_on_menu_pressed)


func _on_start_pressed():
 var tree = get_tree()

 if tree:
  if CheckpointManager.has_save():
   CheckpointManager.clear_save()
  tree.change_scene_to_file("res://loc/roomtest/roomtest.tscn")
 else:
  push_error(tr("SceneTree не найден"))

func _on_menu_pressed():
 var tree = get_tree()

 if tree:
  if CheckpointManager.has_save():
   CheckpointManager.clear_save()
  tree.change_scene_to_file("res://UI/main menu/main menu.tscn")
 else:
  push_error(tr("SceneTree не найден"))
