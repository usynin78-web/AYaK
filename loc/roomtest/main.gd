
extends Node2D

@onready var fade_anim: AnimationPlayer = $FadeLayer/AnimationPlayer
@onready var player: Node = $c3
@onready var player_health: Node = $c3/HealthComponent
@onready var notification: Control = $UI/Notification


func _ready() -> void:
	# Подключаем сигналы здоровья к обработчикам интерфейса.
	player_health.health_amount_changed.connect(_on_health_amount_changed)
	player_health.died.connect(_on_player_died)


func _process(_delta: float) -> void:
	# Ловим ESC через InputMap (ui_cancel).
	if Input.is_action_just_pressed("ui_cancel"):
		start_exit_to_menu()


func start_exit_to_menu() -> void:
	# Останавливаем управление игроком.
	if player:
		player.set_physics_process(false)

	# Запускаем анимацию fade out.
	if fade_anim:
		fade_anim.play("fade_out")


# Переход в меню после завершения анимации.
func _on_FadeLayer_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "fade_out":
		get_tree().change_scene_to_file("res://UI/main menu/main menu.tscn")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fade_out":
		get_tree().change_scene_to_file("res://UI/main menu/main menu.tscn")


# Получаем информацию об изменении HP.
func _on_health_amount_changed(amount: int) -> void:
	notification.notify_hp_changed(amount)


# Получаем сигнал о смерти Кира.
func _on_player_died() -> void:
	notification.notify_death()
