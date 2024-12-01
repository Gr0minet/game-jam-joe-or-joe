extends Node3D


@export var start_countdown: int = 3
@export var pnj_number: int = 50

@onready var _joes_name: Array[String] = [
	"Joe Williams",
	"Joe Anderson"
]
@onready var _players: Array[Player] = [
	$ViewportControl/HBoxContainer/SubViewportContainer/SubViewport/Player,
	$ViewportControl/HBoxContainer/SubViewportContainer2/SubViewport/Player
]
@onready var _sub_viewports: Array[SubViewport] = [
	$ViewportControl/HBoxContainer/SubViewportContainer/SubViewport,
	$ViewportControl/HBoxContainer/SubViewportContainer2/SubViewport
]
@onready var _viewport_huds: Array[ViewportHUD] = [
	$HUD/HBoxContainer/ViewportHUD,
	$HUD/HBoxContainer/ViewportHUD2
]
@onready var pnj_container: Node3D = $PNJContainer
@onready var side_region: NavigationRegion3D = $SideRegion
@onready var center_region: NavigationRegion3D = $CenterRegion
@onready var outside_region: NavigationRegion3D = $OutsideRegion
@onready var hud: HUD = $HUD
@onready var viewport_control: Control = $ViewportControl


var pnj_scene: PackedScene = preload("res://pnj/pnj.tscn")
var main_menu_scene: PackedScene = preload("res://menu/main_menu.tscn")


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().get_root().size_changed.connect(_window_resize) 
	_window_resize()
	
	for i in len(_players):
		_viewport_huds[i].set_joe_name(_joes_name[i])
		_players[i].shot.connect(_viewport_huds[i].on_bullet_shot)
		_players[i].died.connect(_on_player_died)
		_players[i].reloaded.connect(_on_player_reloaded)
	
	hud.restart.connect(_restart_game)
	hud.start_time(start_countdown)
	await get_tree().create_timer(start_countdown).timeout
	AudioManager.play_music(SoundBank.main_music, 0.0, false)
	
	for player: Player in _players:
		player.can_move = true
		player.game_started = true
	
	_setup_initial_pnj.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


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
	new_pnj.died.connect(_on_pnj_died)
	pnj_container.add_child(new_pnj)


func _get_random_position(region: RID) -> Vector3:
	return NavigationServer3D.region_get_random_point(
		region,
		1,
		true
	)


func _on_pnj_died() -> void:
	_spawn_pnj()


func _on_player_died(player_id: int) -> void:
	_viewport_huds[player_id].on_got_shot()
	await get_tree().create_timer(Const.END_ANIMATION_TIME).timeout
	viewport_control.modulate = viewport_control.modulate.darkened(0.6)
	hud.show_replay_screen(_joes_name[1 - player_id])


func _restart_game() -> void:
	get_tree().reload_current_scene()


func _go_to_main_menu() -> void:
	get_tree().change_scene_to_packed(main_menu_scene)


func _on_player_reloaded(player_id: int) -> void:
	_viewport_huds[player_id]._reload_bullets()


func _window_resize() -> void:
	var viewport_size: Vector2 = get_viewport().size
	for _sub_viewport: SubViewport in _sub_viewports:
		_sub_viewport.size.y = int(viewport_size.y)
		_sub_viewport.size.x = int(viewport_size.x / 2.0)


func _on_button_pressed() -> void:
	pass # Replace with function body.
