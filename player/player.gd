@tool
class_name Player
extends CharacterBody3D


signal reloaded(id: int)
signal died(id: int)
signal shot

const MOUSE_SENSITIVITY: float = 0.001
const RECOIL_ANGLE: float = deg_to_rad(-30.0)
const RELOAD_GUN_ANGLE: float = deg_to_rad(-40.0)
const FIRE_RATE: float = 0.5
const DEGAINING_TIME: float = 0.3
const RELOADING_TIME: float = 0.5
const SPEED: float = 6.0
const MAX_BULLET: int = 3
const CAMERA_X_ROT_MIN: float = deg_to_rad(-80)
const CAMERA_X_ROT_MAX: float = deg_to_rad(80)
const BASE_ACTIONS: Array[String] = [
	"rotate_left",
	"rotate_right",
	"rotate_down",
	"rotate_up",
]

@export var player_id: int = 0
@export var joystick_rotation_speed: float = 0.05
@export var DEAD_ZONE: float = 0.1
@export var joe_name: String = "Anderson"
@export var color: Color = Color.BLUE:
	set(value):
		if not Engine.is_editor_hint():
			return
		if not is_node_ready():
			await ready
		color = value
		_chemise_repos.get_surface_override_material(0).albedo_color = color
		_chemise_degaine.get_surface_override_material(0).albedo_color = color

@onready var _camera_rotation: Node3D = $CameraRotation
@onready var _camera_3d: Camera3D = $CameraRotation/Camera3D
@onready var _gun: Node3D = $CameraRotation/GunPivot/Colt
@onready var _gun_pivot: Node3D = $CameraRotation/GunPivot
@onready var _gunfire: GPUParticles3D = $CameraRotation/GunPivot/Colt/GunFire
@onready var _ray_cast_3d: RayCast3D = $CameraRotation/Camera3D/RayCast3D
@onready var _reload_timer: Timer = $ReloadTimer
@onready var _shot_timer: Timer = $ShotTimer
@onready var _cowboy_degaine: Node3D = $COWBOY_DEGAINE
@onready var _cowboy_repos: Node3D = $COWBOY_REPOS
@onready var _chemise_repos: MeshInstance3D = $COWBOY_REPOS/COWBOYYY/COWBOY_CHEMISE
@onready var _chemise_degaine: MeshInstance3D = $COWBOY_DEGAINE/COWBOY_CHEMISE
@onready var _viewport_hud: ViewportHUD = $ViewportHUD
@onready var server_data: ServerData = $ServerData

var _blood_vfx: PackedScene = preload("res://vfx/blood.tscn")


var _rotation_direction: Vector2 = Vector2.ZERO
var _controler_movement_direction: Vector2 = Vector2.ZERO
var _bullet_count
var _is_degained: bool = false


func initialize() -> void:
	set_multiplayer_authority(str(name).to_int())
	server_data.set_multiplayer_authority(1)
	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_camera_3d.current = true
		_viewport_hud.show()
		_viewport_hud.set_joe_name(joe_name)


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
		return
	
	if Global.mode == Global.Mode.ONLINE:
		_viewport_hud.hide()
	#player_id = 0 if str(name).to_int() == 1 else 1
	_cowboy_degaine.visible = false
	_cowboy_repos.visible = true
	
	recursive_set_visual_layer(_cowboy_degaine, 2**(1 + player_id))
	recursive_set_visual_layer(_cowboy_repos, 2**(1 + player_id))
	#_chapeau.layers = 2**(1 + player_id)
	#_cowboy.layers = 2**(1 + player_id)
	_camera_3d.set_cull_mask_value(2 + player_id, 0)
	for node: Node3D in _gun.get_children():
		if node is MeshInstance3D:
			node.layers = 2**(1 + (1 - player_id))
	
	_bullet_count = MAX_BULLET
	server_data.game_started = false


func _process(_delta: float) -> void:
	if not server_data.game_started or not is_multiplayer_authority():
		return
	var viewport: Viewport = get_viewport()
	var scale_factor: float = min(
		(float(viewport.size.x) / viewport.size.x),
		(float(viewport.size.y) / viewport.size.y)
	)
	_rotate_camera(_rotation_direction * joystick_rotation_speed * scale_factor)


func _physics_process(_delta: float) -> void:
	if not server_data.game_started or not server_data.can_move or not is_multiplayer_authority():
		return 
	
	var movement_dir: Vector3
	if Global.mode == Global.Mode.ONLINE and _controler_movement_direction == Vector2.ZERO:
		var input_vect: Vector2 = Input.get_vector("left", "right", "forward", "backward")
		movement_dir = transform.basis * Vector3(-input_vect.x, 0, -input_vect.y)
	else:
		movement_dir = transform.basis * Vector3(-_controler_movement_direction.x, 0, -_controler_movement_direction.y)
	velocity = SPEED * movement_dir
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if not server_data.game_started:
		return
	if Global.mode == Global.Mode.SPLITSCREEN and event.device != player_id:
		return
	if Global.mode == Global.Mode.ONLINE and not is_multiplayer_authority():
		return
	if event.is_action_pressed("reload"):
		_reload.rpc()
	elif event is InputEventMouseMotion:
		if Global.mode != Global.Mode.ONLINE:
			return
		var motion: InputEventMouseMotion = event as InputEventMouseMotion 
		rotate_y(-motion.relative.x * MOUSE_SENSITIVITY)
		_camera_rotation.rotate_x(motion.relative.y * MOUSE_SENSITIVITY)
		_camera_rotation.rotation.x = clamp(
			_camera_rotation.rotation.x,
			CAMERA_X_ROT_MIN,
			CAMERA_X_ROT_MAX
		)
	elif event.is_action_pressed("shoot"):
		if _is_degained and _shot_timer.is_stopped():
			_shoot.rpc()
	elif event.is_action_pressed("degaine"):
		if _reload_timer.is_stopped():
			_switch_degained.rpc()
	elif event is InputEventJoypadMotion :
		var motion_event: InputEventJoypadMotion = event as InputEventJoypadMotion
		match motion_event.axis:
			JOY_AXIS_LEFT_X:
				if abs(motion_event.axis_value) >= DEAD_ZONE:
					_controler_movement_direction.x = motion_event.axis_value
				else:
					_controler_movement_direction.x = 0.0
			JOY_AXIS_LEFT_Y:
				if abs(motion_event.axis_value) >= DEAD_ZONE:
					_controler_movement_direction.y = motion_event.axis_value
				else:
					_controler_movement_direction.y = 0.0
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
				if _is_degained and _shot_timer.is_stopped() and is_equal_approx(motion_event.axis_value, 1.0):
					_shoot.rpc()
			JOY_AXIS_TRIGGER_LEFT:
				if _reload_timer.is_stopped() and is_equal_approx(motion_event.axis_value, 1.0):
					_switch_degained.rpc()


func _rotate_camera(move: Vector2) -> void:
	rotate_y(-move.x)
	# After relative transforms, camera needs to be renormalized.
	orthonormalize()
	_camera_rotation.rotation.x = clamp(_camera_rotation.rotation.x - move.y, CAMERA_X_ROT_MIN, CAMERA_X_ROT_MAX)
	

@rpc("call_local")
func _shoot() -> void:
	if _bullet_count == 0:
		return
	_shot_timer.start(FIRE_RATE)
	_gunfire.restart()
	_ray_cast_3d.enabled = true
	_ray_cast_3d.force_raycast_update()
	_bullet_count -= 1
	_viewport_hud.on_bullet_shot()
	shot.emit()
	AudioManager.play_sound_effect(SoundBank.gunshot_effect)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(_gun_pivot, "rotation:x", RECOIL_ANGLE, 0.1)
	tween.tween_property(_gun_pivot, "rotation:x", 0, 0.1)
	if _ray_cast_3d.is_colliding():
		var collision_point: Vector3 = _ray_cast_3d.get_collision_point()
		var blood_effect: AnimatedSprite3D = _blood_vfx.instantiate()
		var effect_direction: Vector3 = (position - _ray_cast_3d.get_collider().position).normalized()
		get_tree().root.add_child(blood_effect)
		blood_effect.look_at(effect_direction)
		blood_effect.position = collision_point
		if _ray_cast_3d.get_collider() is Player:
			_ray_cast_3d.get_collider().got_shot()
			process_mode = PROCESS_MODE_DISABLED
		if _ray_cast_3d.get_collider() is PNJ:
			_ray_cast_3d.get_collider().got_shot.rpc()
	_ray_cast_3d.enabled = false
	

func got_shot() -> void:
	_viewport_hud.on_got_shot()
	died.emit(player_id)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "rotation:z", deg_to_rad(90), Const.END_ANIMATION_TIME).set_trans(Tween.TRANS_QUART)
	await tween.finished
	process_mode = PROCESS_MODE_DISABLED


@rpc("call_local")
func _reload() -> void:
	if _bullet_count == MAX_BULLET:
		return
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(_gun_pivot, "rotation:x", RELOAD_GUN_ANGLE, 0.1)
	await get_tree().create_timer(0.1).timeout
	_viewport_hud.reload_bullets()
	server_data.can_move = false
	_reload_timer.start(RELOADING_TIME)


func _on_reload_timer_timeout() -> void:
	reloaded.emit(player_id)
	_bullet_count = MAX_BULLET
	var new_angle: float = deg_to_rad(0.0) if _is_degained else deg_to_rad(90.0)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(_gun_pivot, "rotation:x", new_angle, 0.1)
	if not _is_degained:
		server_data.can_move = true


@rpc("call_local")
func _switch_degained() -> void:
	var target_rotation: float = deg_to_rad(0.0)
	var tween: Tween = get_tree().create_tween()
	if _is_degained:
		_cowboy_repos.visible = true
		_cowboy_degaine.visible = false
		target_rotation = deg_to_rad(90.0)
		server_data.can_move = true
	else:
		target_rotation = deg_to_rad(0.0)
		server_data.can_move = false
	tween.tween_property(_gun_pivot, "rotation:x", target_rotation, DEGAINING_TIME)
	await tween.finished
	_is_degained = not _is_degained
	if _is_degained:
		_cowboy_degaine.visible = true
		_cowboy_repos.visible = false
		

func recursive_set_visual_layer(node: Node3D, layer: int) -> void:
	for child: Node3D in node.get_children():
		if child is VisualInstance3D:
			child.layers = layer
		recursive_set_visual_layer(child, layer)


func show_win_label(has_won: bool) -> void:
	if is_multiplayer_authority():
		_viewport_hud.show_win_label(has_won)
