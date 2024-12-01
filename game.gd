extends Node3D


@export var pnj_number: int = 50

@onready var _players: Array[Player] = [
	$Control/HBoxContainer/SubViewportContainer/SubViewport/Player,
	$Control/HBoxContainer/SubViewportContainer2/SubViewport/Player
]
@onready var _sub_viewports: Array[SubViewport] = [
	$Control/HBoxContainer/SubViewportContainer/SubViewport,
	$Control/HBoxContainer/SubViewportContainer2/SubViewport
]
@onready var _viewport_huds: Array[ViewportHUD] = [
	$HUD/HBoxContainer/ViewportHUD,
	$HUD/HBoxContainer/ViewportHUD2
]
@onready var pnj_spawn_zone: Node3D = $PNJSpawnZone
@onready var pnj_container: Node3D = $PNJContainer

@onready var side_region: NavigationRegion3D = $SideRegion
@onready var center_region: NavigationRegion3D = $CenterRegion
@onready var outside_region: NavigationRegion3D = $OutsideRegion

var pnj_scene: PackedScene = preload("res://pnj/pnj.tscn")


func _ready() -> void:
	var viewport_size: Vector2 = get_viewport().size
	for _sub_viewport: SubViewport in _sub_viewports:
		_sub_viewport.size.y = viewport_size.y
		_sub_viewport.size.x = viewport_size.x / 2
	
	for i in len(_players):
		_players[i].shot.connect(_viewport_huds[i].on_bullet_shot)
	
	_setup_initial_pnj.call_deferred()


func _setup_initial_pnj() -> void:
	await get_tree().physics_frame
	for i in range(pnj_number):
		_spawn_pnj()


func _spawn_pnj() -> void:
	var new_pnj: PNJ = pnj_scene.instantiate()
	var random_position = _get_random_position(side_region.get_rid())
	random_position.y = 0
	new_pnj.position = random_position
	new_pnj.add_next_position(_get_random_position(center_region.get_rid()))
	new_pnj.add_next_position(_get_random_position(outside_region.get_rid()))
	pnj_container.add_child(new_pnj)


func _get_random_position(region: RID) -> Vector3:
	return NavigationServer3D.region_get_random_point(
		region,
		1,
		true
	)
