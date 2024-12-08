class_name HUD
extends CanvasLayer


signal restart

@onready var _countdown_label: Label = $CountdownLabel
@onready var _replay_container: VBoxContainer = $ReplayContainer
@onready var _countdown: Timer = $Countdown
@onready var _rejouer_button: TextureButton = $ReplayContainer/RejouerButton
@onready var _waiting_joe: Label = $ReplayContainer/WaitingJoe
@onready var _pause_container: VBoxContainer = $PauseContainer


func _ready() -> void:
	_waiting_joe.hide()
	_replay_container.hide()
	_rejouer_button.show()
	_pause_container.hide()


func start_time(start_countdown: int) -> void:
	_countdown_label.visible = true
	_countdown.start(start_countdown)


func _process(_delta: float) -> void:
	if not _countdown.is_stopped():
		_countdown_label.text = "%d" % [int(_countdown.time_left) + 1]
	for node: Node in _replay_container.get_children():
		if node is BaseButton and node.is_hovered() and node != get_viewport().gui_get_focus_owner():
			get_viewport().gui_release_focus()


func show_replay_screen() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_replay_container.visible = true
	_rejouer_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if get_viewport().gui_get_focus_owner() == null and event is InputEventJoypadButton:
		_rejouer_button.grab_focus()


func _on_countdown_timeout() -> void:
	_countdown.stop()
	_countdown_label.text = "GO"
	await get_tree().create_timer(1.0).timeout
	_countdown_label.visible = false


func _on_quitter_button_pressed() -> void:
	get_tree().quit()


func _on_rejouer_button_pressed() -> void:
	if Global.mode == Global.Mode.ONLINE:
		_waiting_joe.show()
		_rejouer_button.hide()
		restart.emit(multiplayer.get_unique_id())
	else:
		restart.emit()


func show_pause_menu() -> void:
	_pause_container.show()


func hide_pause_menu() -> void:
	_pause_container.hide()
