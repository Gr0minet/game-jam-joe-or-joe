extends Control


const TRANSITION_TIMES: Array[float] = [1.0, 2.0, 5.0, 5.7]
const INTRO_TIME: float = 2.0

@onready var background: TextureRect = $Background
@onready var buttons: VBoxContainer = $Buttons

var menu_background: CompressedTexture2D = preload("res://sprites/menu_background.jpg")
var story_background: CompressedTexture2D = preload("res://sprites/story_background.jpg")
var game_scene: PackedScene = preload("res://game.tscn")


func _ready() -> void:
	background.texture = menu_background
	background.modulate = Color.WHITE
	AudioManager.play_music(SoundBank.main_menu_music)


func _on_play_button_pressed() -> void:
	AudioManager.fade_out_music(TRANSITION_TIMES[1])
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(background, "modulate", Color.BLACK, TRANSITION_TIMES[0])
	await tween.finished
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
	get_tree().change_scene_to_packed(game_scene)
