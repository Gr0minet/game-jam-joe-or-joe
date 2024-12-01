@tool
class_name Player
extends StaticBody3D


signal shot

const MAX_BULLET: int = 3
const DEAD_ZONE: float = 0.1
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
@export var color: Color = Color.BLUE:
	set(value):
		if not Engine.is_editor_hint():
			return
		if not is_node_ready():
			await ready
		color = value
		_chapeau.get_surface_override_material(0).albedo_color = color
		_cowboy.get_surface_override_material(0).albedo_color = color
		_gun.material.albedo_color = value

@onready var _chapeau: MeshInstance3D = $Skin/CHAPEAU
@onready var _cowboy: MeshInstance3D = $Skin/COWBOYYY
@onready var _camera_rotation: Node3D = $CameraRotation
@onready var _camera_3d: Camera3D = $CameraRotation/Camera3D
@onready var _gun: CSGBox3D = $CameraRotation/Gun
@onready var _gunfire: GPUParticles3D = $CameraRotation/Gun/GunFire
@onready var _ray_cast_3d: RayCast3D = $CameraRotation/Camera3D/RayCast3D

var mouse_sensitivity: float = 0.002

var _rotation_direction: Vector2 = Vector2.ZERO
var _bullet_count


func _ready() -> void:
	_chapeau.layers = 2**(1 + player_id)
	_cowboy.layers = 2**(1 + player_id)
	_camera_3d.set_cull_mask_value(2 + player_id, 0)
	_gun.layers = 2**(1 + (1 - player_id))
	_bullet_count = MAX_BULLET


func _process(delta: float) -> void:
	var viewport: Viewport = get_viewport()
	var scale_factor: float = min(
			(float(viewport.size.x) / viewport.size.x),
			(float(viewport.size.y) / viewport.size.y)
	)
	_rotate_camera(_rotation_direction * joystick_rotation_speed * scale_factor)


func _unhandled_input(event: InputEvent) -> void:
	if event.device != player_id:
		return
	if event is InputEventJoypadMotion :
		var motion_event: InputEventJoypadMotion = event as InputEventJoypadMotion
		match motion_event.axis:
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
				if is_equal_approx(motion_event.axis_value, 1.0):
					_shoot()


func _rotate_camera(move: Vector2) -> void:
	rotate_y(-move.x)
	# After relative transforms, camera needs to be renormalized.
	orthonormalize()
	_camera_rotation.rotation.x = clamp(_camera_rotation.rotation.x - move.y, CAMERA_X_ROT_MIN, CAMERA_X_ROT_MAX)
	

func _shoot() -> void:
	if _bullet_count == 0:
		return
	_gunfire.restart()
	_ray_cast_3d.enabled = true
	_ray_cast_3d.force_raycast_update()
	if _ray_cast_3d.is_colliding() and _ray_cast_3d.get_collider() is Player:
		print("hit")
	_bullet_count -= 1
	shot.emit()
	_ray_cast_3d.enabled = false
	
