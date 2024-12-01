class_name HUD
extends CanvasLayer


signal restart

@onready var h_box_container: HBoxContainer = $HBoxContainer
@onready var _countdown_label: Label = $CountdownLabel
@onready var _victorious_joe: Label = $ReplayContainer/VictoriousJoe
@onready var _replay_container: VBoxContainer = $ReplayContainer
@onready var _countdown: Timer = $Countdown


func start_time(start_countdown: int) -> void:
	_countdown_label.visible = true
	_countdown.start(start_countdown)


func _process(delta: float) -> void:
	if not _countdown.is_stopped():
		_countdown_label.text = "%d" % [int(_countdown.time_left) + 1]


func show_replay_screen(victorious_joe: String) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_victorious_joe.text = victorious_joe + " gagne !"
	h_box_container.modulate = h_box_container.modulate.darkened(0.6)
	_replay_container.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if _replay_container.visible and event.is_action_pressed("ui_accept"):
		restart.emit()


func _on_countdown_timeout() -> void:
	_countdown.stop()
	_countdown_label.text = "GO"
	await get_tree().create_timer(1.0).timeout
	_countdown_label.visible = false


func _on_quitter_button_pressed() -> void:
	get_tree().quit()


func _on_rejouer_button_pressed() -> void:
	restart.emit()
