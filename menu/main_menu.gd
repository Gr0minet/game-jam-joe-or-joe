extends Control


enum State {MENU, HOWTOPLAY, CREDIT, DISCONNECTED, LAN}
const TRANSITION_TIMES: Array[float] = [1.0, 2.0, 5.0, 5.7]
const INTRO_TIME: float = 2.0

@onready var background: TextureRect = $Background
@onready var buttons: VBoxContainer = $BaseMenu/MarginContainer/Buttons
@onready var how_to_play: TextureRect = $HowToPlay
@onready var credits: TextureRect = $Credits
@onready var jouer_button: TextureButton = $BaseMenu/MarginContainer/Buttons/JouerButton
@onready var how_to_button: TextureButton = $BaseMenu/MarginContainer/Buttons/HowToButton
@onready var credit_button: TextureButton = $BaseMenu/MarginContainer/Buttons/CreditButton
@onready var lan: Control = $LAN
@onready var base_menu: Control = $BaseMenu
@onready var disconnected_container: PanelContainer = $DisconnectedContainer

var menu_background: CompressedTexture2D = preload("res://HUD/sprites/background.jpg")
var story_background: CompressedTexture2D = preload("res://sprites/story_background.jpg")
var game_scene: PackedScene = preload("res://game.tscn")
var game_scene_path: NodePath = "res://game.tscn"
var state: State = State.MENU
var doing_introduction: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	disconnected_container.hide()
	lan.visible = false
	background.texture = menu_background
	background.modulate = Color.WHITE
	base_menu.modulate = Color.WHITE
	base_menu.visible = true
	AudioManager.play_music(SoundBank.main_menu_music)
	if Global.back_to_menu_because_disconnect:
		base_menu.hide()
		disconnected_container.show()
		Global.back_to_menu_because_disconnect = false
		state = State.DISCONNECTED


func _process(_delta: float) -> void:
	for button: BaseButton in buttons.get_children():
		if button.is_hovered() and button != get_viewport().gui_get_focus_owner():
			get_viewport().gui_release_focus()


func _unhandled_input(event: InputEvent) -> void:
	var new_focused_button: TextureButton = null
	if event.is_action_pressed("ui_accept"):
		if doing_introduction:
			get_tree().change_scene_to_packed(game_scene)
		elif state != State.MENU:
			if state == State.HOWTOPLAY:
				new_focused_button = how_to_button
				how_to_play.visible = false
			elif state == State.CREDIT:
				new_focused_button = credit_button
				credits.visible = false
			elif state == State.DISCONNECTED:
				disconnected_container.hide()
			base_menu.visible = true
			state = State.MENU
	elif get_viewport().gui_get_focus_owner() == null and event is InputEventJoypadButton:
		new_focused_button = jouer_button

	if new_focused_button:
		new_focused_button.grab_focus()


func _on_jouer_button_pressed() -> void:
	Global.mode = Global.Mode.SPLITSCREEN
	doing_introduction = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	AudioManager.fade_out_music(TRANSITION_TIMES[1])
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(background, "modulate", Color.BLACK, TRANSITION_TIMES[0])
	tween.parallel().tween_property(base_menu, "modulate", Color.BLACK, TRANSITION_TIMES[0])
	await tween.finished
	buttons.visible = false
	base_menu.visible = false
	AudioManager.play_music(SoundBank.intro_music)
	await get_tree().create_timer(TRANSITION_TIMES[1]).timeout
	background.texture = story_background
	tween = get_tree().create_tween()
	tween.tween_property(background, "modulate", Color.WHITE, TRANSITION_TIMES[2])
	await tween.finished
	await get_tree().create_timer(INTRO_TIME).timeout
	tween = get_tree().create_tween()
	tween.tween_property(background, "modulate", Color.BLACK, TRANSITION_TIMES[3])
	await tween.finished
	doing_introduction = false
	get_tree().change_scene_to_packed(game_scene)


func _on_how_to_button_pressed() -> void:
	base_menu.visible = false
	how_to_play.visible = true
	state = State.HOWTOPLAY


func _on_credit_button_pressed() -> void:
	base_menu.visible = false
	credits.visible = true
	state = State.CREDIT


func _on_quitter_button_pressed() -> void:
	get_tree().quit()


func _on_lan_button_pressed() -> void:
	base_menu.visible = false
	lan.visible = true
	state = State.LAN


func _on_back_to_menu_pressed() -> void:
	lan.visible = false
	base_menu.visible = true
	state = State.MENU


func _on_start_button_pressed() -> void:
	Lobby.load_game.rpc(game_scene_path)
