class_name PNJ
extends CharacterBody3D


var movement_speed: float = 3.0

@onready var _navigation_agent: NavigationAgent3D = $NavigationAgent3D

var position_list: Array[Vector3] = []


func add_next_position(position: Vector3) -> void:
	position_list.append(position)


func _physics_process(delta: float) -> void:
	if _navigation_agent.is_navigation_finished():
		if position_list.is_empty():
			return
		_navigation_agent.target_position = position_list.pop_front()
		#_update_target_position(position_list.pop_back())
	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = _navigation_agent.get_next_path_position()
	next_path_position.y = 0
	velocity = current_agent_position.direction_to(next_path_position) * movement_speed
	rotation.y = atan2(-velocity.x, -velocity.z)
	move_and_slide()