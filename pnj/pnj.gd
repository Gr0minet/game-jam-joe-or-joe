class_name PNJ
extends CharacterBody3D


@export var movement_speed: float = 3.0

@onready var _navigation_agent: NavigationAgent3D = $NavigationAgent3D


func _ready() -> void:
	_actor_setup.call_deferred()


func _actor_setup():
	await get_tree().physics_frame
	_update_target_position(position + global_basis * Vector3.FORWARD * 100)


func _physics_process(delta: float) -> void:
	if _navigation_agent.is_navigation_finished():
		return
	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = _navigation_agent.get_next_path_position()

	velocity = current_agent_position.direction_to(next_path_position) * movement_speed
	rotation.y = atan2(-velocity.x, -velocity.z)
	move_and_slide()


func _update_target_position(target_position: Vector3):
	_navigation_agent.target_position = target_position
