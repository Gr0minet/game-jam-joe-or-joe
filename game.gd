extends Node3D


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
	for i in range(10):
		_spawn_pnj()


func _spawn_pnj() -> void:
	#var random_zone_idx: int = randi_range(0, pnj_spawn_zone.get_child_count() - 1)
	#var zone: MeshInstance3D = pnj_spawn_zone.get_child(random_zone_idx)
	#var random_position: Vector2 = Vector2.ZERO
	#random_position.x = randf_range(
		#zone.position.x - zone.mesh.size.x / 2,
		#zone.position.x + zone.mesh.size.x / 2
	#)
	#random_position.y = randf_range(
		#zone.position.z - zone.mesh.size.y / 2,
		#zone.position.z + zone.mesh.size.y / 2
	#)
	var random_position = NavigationServer3D.region_get_random_point(
		side_region.get_rid(),
		1,
		true
	)
	print(random_position)
	var new_pnj: PNJ = pnj_scene.instantiate()
	new_pnj.position.x = random_position.x
	new_pnj.position.z = random_position.z
	pnj_container.add_child(new_pnj)
