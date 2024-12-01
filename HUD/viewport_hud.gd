class_name ViewportHUD
extends Control

@onready var balle_vide: CompressedTexture2D = preload("res://sprites/balle_vide_small.png")
@onready var balle_pleine: CompressedTexture2D = preload("res://sprites/ball_pleine_small.png")
@onready var got_shot: TextureRect = $GotShot

@onready var bullets: HBoxContainer = $Bullets
@onready var MAX_BULLET: int = bullets.get_child_count()
@onready var _name: Label = $Name

var bullet_number: int


func _ready() -> void:
	got_shot.visible = false
	bullet_number = MAX_BULLET
	_reload_bullets()


func _reload_bullets() -> void:
	bullet_number = MAX_BULLET
	for bullet: TextureRect in bullets.get_children():
		bullet.texture = balle_pleine


func set_joe_name(joy_name: String) -> void:
	_name.text = joy_name


func on_bullet_shot() -> void:
	bullets.get_child(bullet_number - 1).texture = balle_vide
	bullet_number -= 1


func on_got_shot() -> void:
	got_shot.visible = true
