class_name ViewportHUD
extends Control

@onready var balle_vide: CompressedTexture2D = preload("res://sprites/balle_vide_small.png")
@onready var balle_pleine: CompressedTexture2D = preload("res://sprites/ball_pleine_small.png")

@onready var bullets: HBoxContainer = $Bullets
@onready var MAX_BULLET: int = bullets.get_child_count()

var bullet_number: int


func _ready() -> void:
	bullet_number = MAX_BULLET
	_reload_bullets()


func _reload_bullets() -> void:
	bullet_number = MAX_BULLET
	for bullet: TextureRect in bullets.get_children():
		bullet.texture = balle_pleine


func on_bullet_shot() -> void:
	bullets.get_child(bullet_number - 1).texture = balle_vide
	bullet_number -= 1
