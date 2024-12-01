class_name PNJ
extends CharacterBody3D


signal died

const MIN_SPEED: float = 2.0
const MAX_SPEED: float = 5.0

const MIN_SCALE: float = 0.8
const MAX_SCALE: float = 1.2

var movement_speed: float = 3.0

@onready var _navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _animation_player: AnimationPlayer = $PNJ_ANIM/AnimationPlayer

var position_list: Array[Vector3] = []


func _ready() -> void:
	movement_speed = randf_range(MIN_SPEED, MAX_SPEED)
	scale *= randf_range(MIN_SCALE, MAX_SCALE)
	_animation_player.speed_scale *= 2 * (movement_speed / MAX_SPEED)


func add_next_position(next_position: Vector3) -> void:
	position_list.append(next_position)


func _physics_process(_delta: float) -> void:
	if _navigation_agent.is_navigation_finished():
		if position_list.is_empty():
			died.emit()
			queue_free()
			return
		_navigation_agent.target_position = position_list.pop_front()
	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = _navigation_agent.get_next_path_position()
	next_path_position.y = 0
	velocity = current_agent_position.direction_to(next_path_position) * movement_speed
	rotation.y = atan2(-velocity.x, -velocity.z)
	move_and_slide()


func got_shot() -> void:
	set_physics_process(false)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "rotation:z", deg_to_rad(90), Const.END_ANIMATION_TIME).set_trans(Tween.TRANS_QUART)
	await tween.finished
	died.emit()
	queue_free()
