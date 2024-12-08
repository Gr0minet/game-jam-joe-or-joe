extends Node3D


@export var start_countdown: int = 3
@export var pnj_number: int = 50

@onready var _players: Array[Player] = [$Player, $Player2]
@onready var _sub_viewports: Array[SubViewport] = [
	$SplitScreenControl/HBoxContainer/SubViewportContainer/SubViewport,
	$SplitScreenControl/HBoxContainer/SubViewportContainer2/SubViewport
]

@onready var pnj_container: Node3D = $PNJContainer
@onready var side_region: NavigationRegion3D = $SideRegion
@onready var center_region: NavigationRegion3D = $CenterRegion
@onready var outside_region: NavigationRegion3D = $OutsideRegion
@onready var split_screen: Control = $SplitScreenControl
@onready var main_hud: HUD = $MainHUD
@onready var voxel_gi: VoxelGI = $VoxelGI
@onready var directional_light_3d: DirectionalLight3D = $DirectionalLight3D

var player_scene: PackedScene = preload("res://player/player.tscn")
var pnj_scene: PackedScene = preload("res://pnj/pnj_anim.tscn")
var main_menu_scene: PackedScene = load("res://menu/main_menu.tscn")
var restart_players_count: int = 0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Global.potato:
		voxel_gi.hide()
		directional_light_3d.shadow_enabled = false
	restart_players_count = 0
	if Global.mode == Global.Mode.SPLITSCREEN:
		_initialize_split_screen.call_deferred()
	elif Global.mode == Global.Mode.ONLINE:
		_initialize_online.call_deferred()

	_players[0].died.connect(_on_player_died)
	_players[1].died.connect(_on_player_died)


func _initialize_split_screen() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	split_screen.visible = true
	for i: int in len(_players):
		_players[i].reparent(_sub_viewports[i])
	_spawn_initial_pnj()
	_setup_initial_pnj_position()
	_start_countdown()


func _initialize_online() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	split_screen.visible = false
	_players[0].name = str(1)
	for peer_id: int in Lobby.players.keys():
		if peer_id != 1:
			_players[1].name = str(peer_id)
	Lobby.player_disconnected.connect(_on_player_disconnected)
	_players[0].initialize()
	_players[1].initialize()
	if multiplayer.is_server():
		_spawn_initial_pnj()
		_setup_initial_pnj_position()
		_start_countdown.rpc()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not Global.game_paused:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			main_hud.show_pause_menu()
			Global.game_paused = true
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			main_hud.hide_pause_menu()
			Global.game_paused = false


@rpc("call_local", "reliable")
func _start_countdown() -> void:	
	main_hud.restart.connect(_restart_game)
	main_hud.start_time(start_countdown)
	await get_tree().create_timer(start_countdown).timeout
	AudioManager.play_music(SoundBank.main_music, 0.0, false)
	
	for player: Player in _players:
		player.server_data.can_move = true
		player.server_data.game_started = true
	for pnj: PNJ in pnj_container.get_children():
		pnj.dont_move = false


func _spawn_initial_pnj() -> void:
	for i in range(pnj_number):
		var new_pnj: PNJ = pnj_scene.instantiate()
		new_pnj.died.connect(_on_pnj_died)
		pnj_container.add_child(new_pnj, true)
		new_pnj.dont_move = true


func _setup_initial_pnj_position() -> void:
	for pnj: PNJ in pnj_container.get_children():
		var random_position = _get_random_position(side_region.get_rid())
		random_position.y = 0
		pnj.position = random_position
		pnj.add_next_position(_get_random_position(center_region.get_rid()))
		pnj.add_next_position(_get_random_position(outside_region.get_rid()))


func _spawn_pnj() -> void:
	var new_pnj: PNJ = pnj_scene.instantiate()
	var random_position = _get_random_position(side_region.get_rid())
	random_position.y = 0
	new_pnj.position = random_position
	new_pnj.add_next_position(_get_random_position(center_region.get_rid()))
	new_pnj.add_next_position(_get_random_position(outside_region.get_rid()))
	new_pnj.died.connect(_on_pnj_died)
	pnj_container.add_child(new_pnj, true)
	new_pnj.dont_move = false


func _get_random_position(region: RID) -> Vector3:
	return NavigationServer3D.region_get_random_point(
		region,
		1,
		true
	)


func _on_pnj_died() -> void:
	if multiplayer.is_server():
		_spawn_pnj()


func _on_player_died(player_id: int) -> void:
	await get_tree().create_timer(Const.END_ANIMATION_TIME).timeout
	split_screen.modulate = split_screen.modulate.darkened(0.7)
	_players[1 - player_id].show_win_label(true)
	_players[player_id].show_win_label(false)
	main_hud.show_replay_screen()


func _restart_game(peer_id: int = -1) -> void:
	if peer_id == -1:
		get_tree().reload_current_scene()
	else:
		player_wants_to_restart.rpc()


func _go_to_main_menu() -> void:
	get_tree().change_scene_to_packed(main_menu_scene)


@rpc("any_peer", "call_local", "reliable")
func player_wants_to_restart() -> void:
	if is_multiplayer_authority():
		restart_players_count += 1
		if restart_players_count == 2:
			reload_game.rpc()


@rpc("call_local", "reliable")
func reload_game():
	if is_multiplayer_authority():
		for pnj: PNJ in pnj_container.get_children():
			pnj.queue_free()
	await get_tree().create_timer(0.1).timeout
	get_tree().reload_current_scene()


func _on_player_disconnected(_peer_id: int) -> void:
	get_tree().change_scene_to_packed(main_menu_scene)
	Global.back_to_menu_because_disconnect = true


func _on_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		voxel_gi.hide()
		directional_light_3d.shadow_enabled = false
		Global.potato = true
	else:
		voxel_gi.show()
		directional_light_3d.shadow_enabled = true
		Global.potato = false


func _on_reprendre_button_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	main_hud.hide_pause_menu()
	Global.game_paused = false
