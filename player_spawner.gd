extends MultiplayerSpawner


@export var player: PackedScene

func _init() -> void:
	spawn_function = _spawn_custom

func _spawn_custom(data: Variant) -> Node:
	var scene: Player = player.instantiate() as Player
	#scene.get_node('ServerData').name = data.name
	#scene.get_node('ServerData').joe_name = data.joe_name
	#scene.get_node('ServerData').player_id = data.player_id
	#scene.get_node('ServerData').initial_transform = data.initial_transform
	#scene.get_node('Body').set_multiplayer_authority(str(data.name).to_int())	
	# Lots of other helpful init things you can do here: e.g.
	#scene.is_master = multiplayer.get_unique_id() == data.peer_id
	#scene.get_node('PlayerNetworking').set_multiplayer_authority(data.peer_id)
	return scene
