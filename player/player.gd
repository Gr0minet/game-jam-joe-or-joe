@tool
class_name Player
extends CharacterBody3D


signal reloaded(id: int)
signal died(id: int)
signal shot

const RELOAD_GUN_ANGLE: float = deg_to_rad(-40.0)
const FIRE_RATE: float = 0.5
const DEGAINING_TIME: float = 0.3
const RELOADING_TIME: float = 0.5
const SPEED: float = 6.0
const MAX_BULLET: int = 3
const CAMERA_X_ROT_MIN: float = deg_to_rad(-89.9)
const CAMERA_X_ROT_MAX: float = deg_to_rad(70)
const BASE_ACTIONS: Array[String] = [
	"rotate_left",
	"rotate_right",
	"rotate_down",
	"rotate_up",
]

@export var player_id: int = 0
@export var joystick_rotation_speed: float = 0.05
@export var DEAD_ZONE: float = 0.1
@export var color: Color = Color.BLUE:
	set(value):
		if not Engine.is_editor_hint():
			return
		if not is_node_ready():
			await ready
		color = value
		_chapeau.get_surface_override_material(0).albedo_color = color
		_cowboy.get_surface_override_material(0).albedo_color = color

@onready var _chapeau: MeshInstance3D = $Skin/CHAPEAU
@onready var _cowboy: MeshInstance3D = $Skin/COWBOYYY
@onready var _camera_rotation: Node3D = $CameraRotation
@onready var _camera_3d: Camera3D = $CameraRotation/Camera3D
@onready var _gun: Node3D = $CameraRotation/GunPivot/Colt
@onready var _gun_pivot: Node3D = $CameraRotation/GunPivot
@onready var _gunfire: GPUParticles3D = $CameraRotation/GunPivot/Colt/GunFire
@onready var _ray_cast_3d: RayCast3D = $CameraRotation/Camera3D/RayCast3D
@onready var _reload_timer: Timer = $ReloadTimer
@onready var _shot_timer: Timer = $ShotTimer

var mouse_sensitivity: float = 0.002
var game_started: bool = false
var can_move: bool = false

var _rotation_direction: Vector2 = Vector2.ZERO
var _movement_direction: Vector2 = Vector2.ZERO
var _bullet_count
var _is_degained: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
		return
	_chapeau.layers = 2**(1 + player_id)
	_cowboy.layers = 2**(1 + player_id)
	_camera_3d.set_cull_mask_value(2 + player_id, 0)
	for node: Node3D in _gun.get_children():
		if node is MeshInstance3D:
			node.layers = 2**(1 + (1 - player_id))
	_bullet_count = MAX_BULLET
	game_started = false


func _process(_delta: float) -> void:
	if not game_started:
		return
	var viewport: Viewport = get_viewport()
	var scale_factor: float = min(
			(float(viewport.size.x) / viewport.size.x),
			(float(viewport.size.y) / viewport.size.y)
	)
	_rotate_camera(_rotation_direction * joystick_rotation_speed * scale_factor)


func _physics_process(_delta: float) -> void:
	if not game_started or not can_move:
		return 
	var movement_dir = transform.basis * Vector3(-_movement_direction.x, 0, -_movement_direction.y)
	velocity = SPEED * movement_dir
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.device != player_id:
		return
	if event.is_action_pressed("reload"):
		_reload()
	elif event is InputEventJoypadMotion :
		var motion_event: InputEventJoypadMotion = event as InputEventJoypadMotion
		match motion_event.axis:
			JOY_AXIS_LEFT_X:
				if abs(motion_event.axis_value) >= DEAD_ZONE:
					_movement_direction.x = motion_event.axis_value
				else:
					_movement_direction.x = 0.0
			JOY_AXIS_LEFT_Y:
				if abs(motion_event.axis_value) >= DEAD_ZONE:
					_movement_direction.y = motion_event.axis_value
				else:
					_movement_direction.y = 0.0
			JOY_AXIS_RIGHT_X:
				if abs(motion_event.axis_value) >= DEAD_ZONE:
					_rotation_direction.x = motion_event.axis_value
				else:
					_rotation_direction.x = 0.0
			JOY_AXIS_RIGHT_Y:
				if abs(motion_event.axis_value) >= DEAD_ZONE:
					_rotation_direction.y = -motion_event.axis_value
				else:
					_rotation_direction.y = 0.0
			JOY_AXIS_TRIGGER_RIGHT:
				if game_started and _is_degained and _shot_timer.is_stopped() and is_equal_approx(motion_event.axis_value, 1.0):
					_shoot()
			JOY_AXIS_TRIGGER_LEFT:
				if game_started and _reload_timer.is_stopped() and is_equal_approx(motion_event.axis_value, 1.0):
					_switch_degained()


func _rotate_camera(move: Vector2) -> void:
	rotate_y(-move.x)
	# After relative transforms, camera needs to be renormalized.
	orthonormalize()
	_camera_rotation.rotation.x = clamp(_camera_rotation.rotation.x - move.y, CAMERA_X_ROT_MIN, CAMERA_X_ROT_MAX)
	

func _shoot() -> void:
	if _bullet_count == 0:
		return
	_shot_timer.start(FIRE_RATE)
	_gunfire.restart()
	_ray_cast_3d.enabled = true
	_ray_cast_3d.force_raycast_update()
	_bullet_count -= 1
	shot.emit()
	if _ray_cast_3d.is_colliding() and _ray_cast_3d.get_collider() is Player:
		_ray_cast_3d.get_collider().got_shot()
		process_mode = PROCESS_MODE_DISABLED
	_ray_cast_3d.enabled = false
	
	
func got_shot() -> void:
	died.emit(player_id)
	process_mode = PROCESS_MODE_DISABLED


func _reload() -> void:
	if _bullet_count == MAX_BULLET:
		return
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(_gun_pivot, "rotation:x", RELOAD_GUN_ANGLE, 0.1)
	await get_tree().create_timer(0.1).timeout
	can_move = false
	_movement_direction = Vector2.ZERO
	_rotation_direction = Vector2.ZERO
	_reload_timer.start(RELOADING_TIME)


func _on_reload_timer_timeout() -> void:
	reloaded.emit(player_id)
	_bullet_count = MAX_BULLET
	var new_angle: float = deg_to_rad(0.0) if _is_degained else deg_to_rad(90.0)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(_gun_pivot, "rotation:x", new_angle, 0.1)
	if not _is_degained:
		can_move = true


func _switch_degained() -> void:
	var target_rotation: float = deg_to_rad(0.0)
	var tween: Tween = get_tree().create_tween()
	if _is_degained:
		target_rotation = deg_to_rad(90.0)
		can_move = true
	else:
		target_rotation = deg_to_rad(0.0)
		_movement_direction = Vector2.ZERO
		_rotation_direction = Vector2.ZERO
		can_move = false
	tween.tween_property(_gun_pivot, "rotation:x", target_rotation, DEGAINING_TIME)
	_is_degained = not _is_degained
	
