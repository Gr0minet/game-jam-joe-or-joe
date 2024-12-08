extends Node

enum Mode {SPLITSCREEN, ONLINE}

var mode: Mode = Mode.ONLINE
var not_host_player_id: int
var back_to_menu_because_disconnect: bool = false
var game_paused: bool = false
