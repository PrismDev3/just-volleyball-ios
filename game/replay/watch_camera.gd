class_name WatchCamera
extends RefCounted













enum Cam{DYNAMIC, BROADCAST, SPECTATE, FREE}
const CAM_NAMES: = ["dynamic", "broadcast", "spectate", "free"]

const FLY_SPEED: = 9.0
const FLY_FAST: = 22.0
const LOOK_SENS: = 0.0022
const PITCH_LIMIT: = 1.45



const HALL_X: = 20.6
const HALL_Z: = 26.6
const HALL_Y_MIN: = 0.8
const HALL_Y_MAX: = 13.0

var mode: Cam = Cam.DYNAMIC
var follow: = -1
var bodies: Array = []
var ball: Node3D = null
var half_w: = 4.5
var half_l: = 9.0


var time: = 0.0




const SHOT_SECONDS: = 5.0

var _cam: Camera3D = null
var _yaw: = 0.0
var _pitch: = -0.35
var _looking: = false
var _shot_idx: = -1
var _replay_side: = 0.0

func setup(cam: Camera3D) -> void :
	_cam = cam

func is_free() -> bool:
	return mode == Cam.FREE

func mode_name() -> String:
	return CAM_NAMES[mode]

func follow_name(names: Array) -> String:
	if follow >= 0 and follow < names.size():
		return String(names[follow])
	return "ball"

func cycle_mode() -> void :
	set_mode(((mode + 1) % Cam.size()) as Cam)

func set_mode(m: Cam) -> void :
	var was_free: = is_free()
	mode = m
	if is_free() and not was_free and _cam != null:


		var e: = _cam.global_transform.basis.get_euler()
		_pitch = clampf(e.x, - PITCH_LIMIT, PITCH_LIMIT)
		_yaw = e.y
	if not is_free():
		_looking = false

func cycle_follow() -> void :
	follow += 1
	if follow >= bodies.size():
		follow = -1

func follow_point() -> Vector3:




	if follow >= 0 and follow < bodies.size() and is_instance_valid(bodies[follow]):
		return (bodies[follow] as Node3D).get_global_transform_interpolated()\
		.origin + Vector3(0.0, 1.0, 0.0)
	if ball != null and is_instance_valid(ball):
		return ball.get_global_transform_interpolated().origin
	return Vector3.ZERO


func handle_input(event: InputEvent) -> bool:
	if not is_free():
		return false
	if event is InputEventMouseButton\
	and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
		_looking = (event as InputEventMouseButton).pressed
		return true
	if _looking and event is InputEventMouseMotion:
		var rel: = (event as InputEventMouseMotion).relative
		_yaw -= rel.x * LOOK_SENS
		_pitch = clampf(_pitch - rel.y * LOOK_SENS, - PITCH_LIMIT, PITCH_LIMIT)
		_aim()
		return true
	return false

func drive(delta: float) -> void :
	if _cam == null:
		return
	if is_free():
		_fly(delta)
		_aim()
		return
	var focus: = follow_point()
	match mode:
		Cam.BROADCAST:
			var want: = Vector3(half_w + 13.0, 9.0, focus.z * 0.3)
			_cam.global_position = _in_hall(_cam.global_position.lerp(want, 
				1.0 - exp(-3.0 * delta)))
			_look_at_safe(Vector3(0.0, 1.2, 0.0).lerp(focus, 0.4))
		Cam.SPECTATE:

			var side: float = signf(focus.z)
			if side == 0.0:
				side = 1.0
			var want2: = focus + Vector3(1.4, 1.9, side * 4.0)
			_cam.global_position = _in_hall(_cam.global_position.lerp(want2, 
				1.0 - exp(-6.0 * delta)))
			_look_at_safe(focus)
		Cam.DYNAMIC:






			var shot: = int(time / SHOT_SECONDS) % 3

			if _replay_side == 0.0:
				_replay_side = 1.0 if focus.x >= 0.0 else -1.0
			var sx: = _replay_side
			var eye: = Vector3.ZERO
			match shot:

				0: eye = Vector3(sx * (half_w + 9.0), 5.2, focus.z * 0.5)

				1: eye = focus + Vector3(sx * 5.0, 2.2, 0.0)

				_: eye = Vector3(sx * (half_w + 12.0), 8.5, 0.0)
			var snap: = shot != _shot_idx
			_shot_idx = shot

			_cam.global_position = _in_hall(eye if snap else
				_cam.global_position.lerp(eye, 1.0 - exp(-4.0 * delta)))
			_look_at_safe(focus)

func _fly(delta: float) -> void :
	var basis: = _cam.global_transform.basis
	var dir: = Vector3.ZERO
	dir -= basis.z * Input.get_axis("move_back", "move_forward")
	dir += basis.x * Input.get_axis("move_left", "move_right")

	if Input.is_key_pressed(KEY_E):
		dir.y += 1.0
	if Input.is_key_pressed(KEY_Q):
		dir.y -= 1.0
	if dir.length() > 0.01:
		var fast: = Input.is_key_pressed(KEY_SHIFT)
		_cam.global_position = _in_hall(_cam.global_position
			+ dir.normalized() * (FLY_FAST if fast else FLY_SPEED) * delta)

func _aim() -> void :
	if _cam != null:
		_cam.global_transform.basis = Basis.from_euler(Vector3(_pitch, _yaw, 0.0))





func _look_at_safe(target: Vector3) -> void :
	var to: = target - _cam.global_position
	if to.length_squared() < 0.04:
		return
	if absf(to.normalized().dot(Vector3.UP)) > 0.999:
		return
	_cam.look_at(target)

func _in_hall(pos: Vector3) -> Vector3:
	return Vector3(
		clampf(pos.x, - HALL_X, HALL_X), 
		clampf(pos.y, HALL_Y_MIN, HALL_Y_MAX), 
		clampf(pos.z, - HALL_Z, HALL_Z))
