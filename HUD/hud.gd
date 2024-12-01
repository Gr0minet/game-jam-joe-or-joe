class_name HUD
extends CanvasLayer


signal started
signal restart

@onready var h_box_container: HBoxContainer = $HBoxContainer
@onready var button: Button = $Button
@onready var timer_label: Label = $Label


func start_time() -> void:
	timer_label.text = "3"
	timer_label.visible = true
	await get_tree().create_timer(1.0).timeout
	timer_label.text = "2"
	await get_tree().create_timer(1.0).timeout
	timer_label.text = "1"
	await get_tree().create_timer(1.0).timeout
	timer_label.text = "GO"
	await get_tree().create_timer(1.0).timeout
	timer_label.visible = false


func show_replay_screen() -> void:
	h_box_container.modulate = h_box_container.modulate.darkened(0.6)
	button.visible = true


func _on_button_pressed() -> void:
	restart.emit()
