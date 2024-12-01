class_name HUD
extends CanvasLayer


signal started
signal restart

@onready var h_box_container: HBoxContainer = $HBoxContainer
@onready var timer_label: Label = $Label
@onready var _victorious_joe: Label = $ReplayContainer/VictoriousJoe
@onready var _replay_container: VBoxContainer = $ReplayContainer


func start_time(start_countdown: int) -> void:
	timer_label.visible = true
	for i in range(start_countdown, 0, -1):
		timer_label.text = str(i)
		await get_tree().create_timer(1.0).timeout
	timer_label.text = "GO"
	await get_tree().create_timer(1.0).timeout
	timer_label.visible = false


func show_replay_screen(victorious_joe: String) -> void:
	_victorious_joe.text = victorious_joe + " wins!"
	h_box_container.modulate = h_box_container.modulate.darkened(0.6)
	_replay_container.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if _replay_container.visible and event.is_action_pressed("ui_accept"):
		restart.emit()


func _on_button_pressed() -> void:
	restart.emit()
