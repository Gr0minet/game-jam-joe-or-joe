class_name LAN
extends Control

enum State {NONE, CLIENT, SERVER}

@onready var lan_menu: VBoxContainer = $LanMenu
@onready var host_game_menu: Control = $HostGameMenu
@onready var join_game_menu: Control = $JoinGameMenu
@onready var joined_player_label: Label = $HostGameMenu/VBoxContainer/JoinedPlayerLabel
@onready var connected_label: Label = $JoinGameMenu/VBoxContainer/ConnectedLabel
@onready var ui_before_connect: VBoxContainer = $JoinGameMenu/VBoxContainer/UIBeforeConnect
@onready var join_button: Button = $JoinGameMenu/VBoxContainer/UIBeforeConnect/JoinButton
@onready var join_ip: LineEdit = $JoinGameMenu/VBoxContainer/UIBeforeConnect/HBoxContainer2/JoinIP
@onready var joe_name: LineEdit = $JoinGameMenu/VBoxContainer/UIBeforeConnect/HBoxContainer3/JoeName
@onready var start_button: Button = $HostGameMenu/VBoxContainer/StartButton

var state: State = State.NONE

func _ready() -> void:
	lan_menu.visible = true
	host_game_menu.visible = false
	join_game_menu.visible = false
	ui_before_connect.visible = true
	connected_label.visible = false
	start_button.visible = false
	Lobby.player_connected.connect(_on_player_joined)
	Lobby.player_disconnected.connect(_on_player_disconnected)
	Lobby.player_info["name"] = "Williams"


func _on_host_game_pressed() -> void:
	lan_menu.visible = false
	host_game_menu.visible = true
	state = State.SERVER
	Lobby.create_game()


func _on_join_game_pressed() -> void:
	lan_menu.visible = false
	join_game_menu.visible = true


func _on_back_button_pressed() -> void:
	if state != State.NONE:
		Lobby.call_deferred("remove_multiplayer_peer")
		if state == State.CLIENT:
			ui_before_connect.visible = true
			connected_label.visible = false
		else:
			start_button.visible = false
			host_game_menu.visible = false
			lan_menu.visible = true
			joined_player_label.text = "En attente d'un autre Joe..."
	else:
		join_game_menu.visible = false
		host_game_menu.visible = false
		lan_menu.visible = true
	state = State.NONE


func _on_join_button_pressed() -> void:
	state = State.CLIENT
	Lobby.join_game()


func _on_player_joined(peer_id: int, _player_info: Dictionary) ->  void:
	if state == State.SERVER and peer_id != 1:
		_update_joined_player_label()
		start_button.visible = true
	elif state == State.CLIENT:
		if peer_id == 1:
			ui_before_connect.visible = false
			connected_label.visible = true


func _on_player_disconnected(player_id: int) -> void:
	if state == State.SERVER and player_id != 1:
		_update_joined_player_label()
		start_button.visible = false
	if state == State.CLIENT and player_id == 1:
		state = State.NONE
		ui_before_connect.visible = true
		connected_label.visible = false


func _update_joined_player_label() -> void:
	if len(Lobby.players) <= 1:
		joined_player_label.text = "En attente d'un autre Joe..."
	else:
		joined_player_label.text = ""
		for player in Lobby.players:
			if player != 1:
				joined_player_label.text += "Joined player: " + Lobby.players[player]["name"] + "\n"


func _on_joe_name_text_changed(new_text: String) -> void:
	Lobby.player_info["name"] = new_text
