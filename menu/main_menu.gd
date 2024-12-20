extends Control


enum State {MENU, HOWTOPLAY, CREDIT}
const TRANSITION_TIMES: Array[float] = [1.0, 2.0, 5.0, 5.7]
const INTRO_TIME: float = 2.0

@onready var background: TextureRect = $Background
@onready var buttons: VBoxContainer = $MarginContainer/Buttons
@onready var how_to_play: TextureRect = $HowToPlay
@onready var credits: TextureRect = $Credits
@onready var margin_container_2: MarginContainer = $MarginContainer2

var menu_background: CompressedTexture2D = preload("res://HUD/sprites/background.jpg")
var story_background: CompressedTexture2D = preload("res://sprites/story_background.jpg")
var game_scene: PackedScene = preload("res://game.tscn")
var state: State = State.MENU
var doing_introduction: bool = false

func _ready() -> void:
	background.texture = menu_background
	background.modulate = Color.WHITE
	buttons.modulate = Color.WHITE
	margin_container_2.modulate = Color.WHITE
	buttons.visible = true
	margin_container_2.visible = true
	AudioManager.play_music(SoundBank.main_menu_music)


func _gui_input(event: InputEvent) -> void:
	if event.is_action("ui_accept") and state != State.MENU:
		how_to_play.visible = false
		credits.visible = false
		buttons.visible = true
		state = State.MENU


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("ui_accept") and doing_introduction:
		get_tree().change_scene_to_packed(game_scene)


func _on_jouer_button_pressed() -> void:
	doing_introduction = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	AudioManager.fade_out_music(TRANSITION_TIMES[1])
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(background, "modulate", Color.BLACK, TRANSITION_TIMES[0])
	tween.parallel().tween_property(buttons, "modulate", Color.BLACK, TRANSITION_TIMES[0])
	tween.parallel().tween_property(margin_container_2, "modulate", Color.BLACK, TRANSITION_TIMES[0])
	await tween.finished
	buttons.visible = false
	margin_container_2.visible = false
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
	if state != State.MENU:
		return
	buttons.visible = false
	how_to_play.visible = true
	state = State.HOWTOPLAY


func _on_credit_button_pressed() -> void:
	if state != State.MENU:
		return
	buttons.visible = false
	credits.visible = true
	state = State.CREDIT


func _on_quitter_button_pressed() -> void:
	get_tree().quit()
