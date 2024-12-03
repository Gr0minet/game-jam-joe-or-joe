class_name LAN
extends Control

enum State {NONE, CLIENT, SERVER}

@onready var lan_menu: VBoxContainer = $LanMenu
@onready var host_game_menu: Control = $HostGameMenu
@onready var join_game_menu: Control = $JoinGameMenu
@onready var join_button: Button = $JoinGameMenu/VBoxContainer/JoinButton
@onready var join_ip: LineEdit = $JoinGameMenu/VBoxContainer/HBoxContainer2/JoinIP
@onready var joined_player_label: Label = $HostGameMenu/VBoxContainer/JoinedPlayerLabel

var state: State = State.NONE

func _ready() -> void:
	lan_menu.visible = true
	host_game_menu.visible = false
	join_game_menu.visible = false
	Lobby.player_connected.connect(_on_player_joined)
	Lobby.player_disconnected.connect(_on_player_disconnected)


func _on_host_game_pressed() -> void:
	lan_menu.visible = false
	host_game_menu.visible = true
	state = State.SERVER
	Lobby.create_game()


func _on_join_game_pressed() -> void:
	lan_menu.visible = false
	join_game_menu.visible = true


func _on_back_button_pressed() -> void:
	join_game_menu.visible = false
	host_game_menu.visible = false
	state = State.NONE
	lan_menu.visible = true


func _on_join_button_pressed() -> void:
	state = State.SERVER
	Lobby.join_game()


func _on_player_joined(peer_id: int, player_info: Dictionary) ->  void:
	if state == State.SERVER:
		_update_joined_player_label()
	elif state == State.CLIENT:
		pass

func _on_player_disconnected() -> void:
	if state == State.SERVER:
		joined_player_label.text = "En attente d'un autre Joe..."


func _update_joined_player_label() -> void:
	if len(Lobby.players) <= 1:
		joined_player_label.text = "En attente d'un autre Joe..."
	else:
		joined_player_label.text = ""
		for player in Lobby.players:
			# TODO : ne pas afficher le joueur serveur (donc si player vaut 1
			# Aussi, ajouter un LineEdit "name" quand on join une partie
			joined_player_label.text += "Joined player: " + Lobby.players[player]["name"]
