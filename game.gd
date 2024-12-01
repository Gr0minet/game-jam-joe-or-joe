extends Node3D


@onready var _sub_viewports: Array[SubViewport] = [
	$Control/HBoxContainer/SubViewportContainer/SubViewport,
	$Control/HBoxContainer/SubViewportContainer2/SubViewport
]


func _ready() -> void:
	var viewport_size: Vector2 = get_viewport().size
	for _sub_viewport: SubViewport in _sub_viewports:
		_sub_viewport.size.y = viewport_size.y
		_sub_viewport.size.x = viewport_size.x / 2
