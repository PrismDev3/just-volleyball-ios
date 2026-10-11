class_name CameraRig
extends Node3D
















enum Mode{ACTION, DYNAMIC, BROADCAST, STATIC, FIRST_PERSON}

const MODE_NAMES: = ["action", "dynamic", "broadcast", "static", "first person"]

const MOUSE_SENS: = 0.006
const STICK_LOOK_SPEED: = 4.0

const FP_EYE: = 1.58
const FP_PITCH_MIN: = -1.35
const FP_PITCH_MAX: = 1.35
const PITCH_MIN: = -1.1
const PITCH_MAX: = 0.7
const FREE_DIST: = 3.6
const FREE_DIST_MIN: = 2.0
const FREE_DIST_MAX: = 12.0
const FREE_ZOOM_STEP: = 0.4
const TRACK_ZOOM_STEP: = 0.1




const ZOOM_PRESETS_FREE: = [2.8, 5.5, 9.0]
const ZOOM_PRESETS_TRACK: = [0.8, 1.2, 1.6]
const FREE_PIVOT: = Vector3(0.0, 1.4, 0.0)
const ACTION_SHOULDER: = 0.8




const TRACK_OFFSET: = Vector3(0.0, 4.2, 6.8)


const SERVE_OFFSET: = Vector3(0.0, 7.9, 7.2)

const TV_REF_SPAN: = 11.0
const TV_DIST: = 13.0
const TV_HEIGHT: = 9.0
const TRACK_PULL_UP: = 0.12


const TRACK_FOCUS_BALL_WEIGHT: = 0.35
const TRACK_FOLLOW_SPEED: = 5.0
const TRACK_LOOK_SPEED: = 4.5



const TRACK_FLIP_WITH_POSSESSION: = false

var mode: = Mode.DYNAMIC
var player: Player
var ball: Ball
var possession: = 1.0
var home_side: = 1.0
var roam: = false
var focus_boost: = 0.0
var serve_view: = false
var tv_center_x: = 0.0




var court_span: = TV_REF_SPAN

var cinematic: = false
var cine_eye: = Vector3.ZERO
var cine_target: = Vector3.ZERO
var cine_snap: = false

var _boost: = 0.0
var _serve_blend: = 0.0

var _yaw: = PI
var _pitch: = -0.2
var _shake: = 0.0
var _look: = Vector3.ZERO
var _free_dist: = FREE_DIST
var _track_zoom: = 1.0
var _zoom_preset: = 2

@onready var camera: Camera3D = $Camera3D

func _ready() -> void :



	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF




	process_priority = -50
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED\
	if mode == Mode.ACTION else Input.MOUSE_MODE_VISIBLE

func _ipos(n: Node3D) -> Vector3:


	return n.get_global_transform_interpolated().origin

var _cam_cycle_frame: = -1

func _unhandled_input(event: InputEvent) -> void :
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:



		if GameConfig.debug_menu and get_viewport().gui_get_focus_owner() == null:
			_toggle_cam_debug()
		return



	if input_frozen:
		return
	if event.is_action_pressed("camera_toggle"):


		if not watched and not mode_locked:






			var f: = Engine.get_process_frames()
			if f != _cam_cycle_frame:
				_cam_cycle_frame = f
				cycle_mode()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("camera_zoom"):
		if not watched:
			_cycle_zoom_preset()
			get_viewport().set_input_as_handled()
	elif (mode == Mode.ACTION or mode == Mode.FIRST_PERSON) and not input_frozen and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:




		var msens: = MOUSE_SENS * GameConfig.mouse_sensitivity
		_yaw -= event.relative.x * msens
		var lo: = FP_PITCH_MIN if mode == Mode.FIRST_PERSON else PITCH_MIN
		var hi: = FP_PITCH_MAX if mode == Mode.FIRST_PERSON else PITCH_MAX
		_pitch = clampf(_pitch - event.relative.y * msens, lo, hi)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(-1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0)





## Look input from the on-screen pad, in viewport pixels of finger travel. The
## mouse branch above also demands [constant Input.MOUSE_MODE_CAPTURED], which
## no mobile display server ever reports, so touch drives the rig directly and
## keeps whatever mouse sensitivity the player has chosen.
func touch_look(relative: Vector2) -> void :
	if input_frozen or (mode != Mode.ACTION and mode != Mode.FIRST_PERSON):
		return
	var msens: = MOUSE_SENS * GameConfig.mouse_sensitivity
	_yaw -= relative.x * msens
	var lo: = FP_PITCH_MIN if mode == Mode.FIRST_PERSON else PITCH_MIN
	var hi: = FP_PITCH_MAX if mode == Mode.FIRST_PERSON else PITCH_MAX
	_pitch = clampf(_pitch - relative.y * msens, lo, hi)

func _zoom(dir: float) -> void :
	if mode == Mode.FIRST_PERSON:
		return
	if mode == Mode.ACTION:
		_free_dist = clampf(_free_dist + dir * FREE_ZOOM_STEP, FREE_DIST_MIN, FREE_DIST_MAX)
	else:
		_track_zoom = clampf(_track_zoom + dir * TRACK_ZOOM_STEP, 0.6, 1.7)




func zoom_value() -> float:
	return _free_dist if mode == Mode.ACTION else _track_zoom




func _cycle_zoom_preset() -> void :
	if mode == Mode.FIRST_PERSON:
		return
	_zoom_preset = (_zoom_preset + 1) % ZOOM_PRESETS_FREE.size()
	_free_dist = ZOOM_PRESETS_FREE[_zoom_preset]
	_track_zoom = ZOOM_PRESETS_TRACK[_zoom_preset]

func shake(amount: float) -> void :


	if not GameConfig.camera_shake:
		return
	_shake = maxf(_shake, amount)

func face_net() -> void :

	_yaw = PI if home_side > 0.0 else 0.0
	_pitch = -0.2




var watched: = false




var mode_locked: = false



var input_frozen: = false


var shake_offset: = Vector3.ZERO

func _process(delta: float) -> void :
	if watched:
		return








	camera.position = Vector3.ZERO
	if cinematic:
		_cine_update(delta)
		if _shake > 0.001:
			camera.position = Vector3(randf_range( - _shake, _shake), 
				randf_range( - _shake, _shake), 0.0)
			_shake *= exp(-9.0 * delta)
		else:
			camera.position = Vector3.ZERO
		shake_offset = _world_shake_offset()
		return
	if player == null:
		return
	if mode == Mode.ACTION:
		_action_update(delta)
	elif mode == Mode.FIRST_PERSON:
		_fp_update(delta)
	elif roam or ball == null:
		_roam_update(delta)
	elif mode == Mode.BROADCAST:
		_broadcast_update(delta)
	elif mode == Mode.STATIC:
		_static_update(delta)
	else:
		_dynamic_update(delta)

	if _shake > 0.001:
		camera.position = Vector3(
			randf_range( - _shake, _shake), 
			randf_range( - _shake, _shake), 0.0)
		_shake *= exp(-9.0 * delta)
	else:
		camera.position = Vector3.ZERO



	shake_offset = _world_shake_offset()

func _world_shake_offset() -> Vector3:






	var par: = camera.get_parent()
	var b: = (par as Node3D).global_transform.basis if par is Node3D else Basis.IDENTITY
	return b * camera.position

func _cine_update(delta: float) -> void :


	if cine_snap:
		global_position = cine_eye
		_look = cine_target
		cine_snap = false
	else:
		global_position = global_position.lerp(cine_eye, 1.0 - exp(-9.0 * delta))
		_look = _look.lerp(cine_target, 1.0 - exp(-9.0 * delta))
	camera.look_at(_look)

func forward_dir() -> Vector3:
	return Vector3(sin(_yaw) * cos(_pitch), sin(_pitch), cos(_yaw) * cos(_pitch))

func _toggle_cam_debug() -> void :
	GameConfig.show_cam_debug = not GameConfig.show_cam_debug

func debug_line() -> String:



	return "cam %s  zoom %.2f  serve %.2f  span %.1f" % [
		MODE_NAMES[mode], _track_zoom, _serve_blend, court_span]



signal mode_changed(name: String)







func apply_mouse_mode(announce: = false) -> void :
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mode == Mode.ACTION or mode == Mode.FIRST_PERSON else Input.MOUSE_MODE_VISIBLE
	if announce:
		mode_changed.emit(MODE_NAMES[mode])

func cycle_mode() -> void :


	match mode:
		Mode.DYNAMIC:
			mode = Mode.BROADCAST
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Mode.BROADCAST:
			mode = Mode.STATIC
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Mode.STATIC:
			mode = Mode.ACTION
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			var dir: = - camera.global_basis.z
			_yaw = atan2(dir.x, dir.z)
			_pitch = asin(clampf(dir.y, -1.0, 1.0))
		Mode.ACTION:
			mode = Mode.DYNAMIC
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_look = camera.global_position - camera.global_basis.z * 6.0
		Mode.FIRST_PERSON:






			mode = Mode.DYNAMIC
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_look = camera.global_position - camera.global_basis.z * 6.0
	mode_changed.emit(MODE_NAMES[mode])







func _fp_update(delta: float) -> void :
	var stick: = Vector2.ZERO if input_frozen else Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	var look: = STICK_LOOK_SPEED * GameConfig.stick_sensitivity
	_yaw -= stick.x * look * delta
	_pitch = clampf(_pitch - stick.y * look * delta, 
		FP_PITCH_MIN, FP_PITCH_MAX)
	global_position = _ipos(player) + Vector3(0.0, FP_EYE, 0.0)
	camera.look_at(camera.global_position + forward_dir())

func _clip(from: Vector3, to: Vector3) -> Vector3:


	var space: = get_world_3d().direct_space_state
	var query: = PhysicsRayQueryParameters3D.create(from, to, 2)
	var hit: = space.intersect_ray(query)
	if hit:
		return hit.position + (from - to).normalized() * 0.3
	return to

func _action_update(delta: float) -> void :
	var stick: = Vector2.ZERO if input_frozen else Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	var look: = STICK_LOOK_SPEED * GameConfig.stick_sensitivity
	_yaw -= stick.x * look * delta
	_pitch = clampf(_pitch - stick.y * look * delta, PITCH_MIN, PITCH_MAX)




	var f: = forward_dir()
	var right: = Vector3(f.x, 0.0, f.z).normalized().cross(Vector3.UP)
	var pivot: = _ipos(player) + FREE_PIVOT + right * ACTION_SHOULDER
	var target: = _clip(pivot, pivot - forward_dir() * _free_dist)

	global_position = global_position.lerp(target, 1.0 - exp(-22.0 * delta))
	camera.look_at(pivot)

const ROAM_OFFSET: = Vector3(0.0, 11.0, 8.5)

func _roam_update(delta: float) -> void :


	var pp: = _ipos(player)
	var target: = pp + ROAM_OFFSET * _track_zoom
	global_position = global_position.lerp(target, 1.0 - exp( - TRACK_FOLLOW_SPEED * delta))
	global_position = _clip(pp + Vector3(0, 1.5, 0), global_position)
	var focus: = pp + Vector3(0.0, 0.8, 0.0)
	_look = _look.lerp(focus, 1.0 - exp( - TRACK_LOOK_SPEED * delta))
	camera.look_at(_look)

func _broadcast_update(delta: float) -> void :


	var bp: = _ipos(ball)
	var fit: = clampf(court_span / TV_REF_SPAN, 0.72, 1.5)
	var target: = Vector3(tv_center_x + TV_DIST * _track_zoom * fit, 
		TV_HEIGHT * _track_zoom * fit, bp.z * 0.3)
	global_position = global_position.lerp(target, 1.0 - exp( - TRACK_FOLLOW_SPEED * delta))
	global_position = _clip(Vector3(tv_center_x, 3.0, 0.0), global_position)
	var focus: = Vector3(tv_center_x, 1.2, 0.0).lerp(bp, 0.4)
	focus.y = clampf(focus.y, 0.5, 3.0)
	_look = _look.lerp(focus, 1.0 - exp( - TRACK_LOOK_SPEED * delta))
	camera.look_at(_look)

























const STATIC_STANDOFF: = 6.0





const STATIC_RISE: = 0.95
const STATIC_LIFT: = 3.0











const STATIC_CEILING: = 15.2
const STATIC_LOOK_Y: = 1.0










const STATIC_HUD_MARGIN: = 0.22
const STATIC_FOOT_MARGIN: = 0.04

func _static_update(delta: float) -> void :


	var h: = minf((court_span * STATIC_RISE + STATIC_LIFT) * _track_zoom, 
		STATIC_CEILING)
	var back: = (court_span + STATIC_STANDOFF) * _track_zoom
	var target: = Vector3(tv_center_x, h, home_side * back)
	global_position = global_position.lerp(target, 
		1.0 - exp( - TRACK_FOLLOW_SPEED * delta))



	var rise: = maxf(h - STATIC_LOOK_Y, 0.5)

	var to_far: = atan2(rise, back + court_span)
	var to_near: = atan2(rise, maxf(back - court_span, 0.5))


	var fov: = deg_to_rad(camera.fov)

	var look_ang: = to_far + fov * (0.5 - STATIC_HUD_MARGIN)


	look_ang = maxf(look_ang, to_near - fov * (0.5 - STATIC_FOOT_MARGIN))
	var run: = rise / maxf(tan(look_ang), 0.05)
	var focus: = Vector3(tv_center_x, STATIC_LOOK_Y, home_side * (back - run))
	_look = _look.lerp(focus, 1.0 - exp( - TRACK_LOOK_SPEED * delta))
	camera.look_at(_look)

func _dynamic_update(delta: float) -> void :




	_boost = lerpf(_boost, focus_boost, 1.0 - exp(-4.0 * delta))
	var pp: = _ipos(player)
	var bp: = _ipos(ball)
	var depth_behind: = (bp.z - pp.z) * home_side
	var behind: = clampf(depth_behind / 6.0, 0.0, 1.0)
	var eff: = maxf(_boost, behind)






	var anchor: = pp.lerp(bp, 0.8 * eff)
	var ball_air: = clampf(bp.y - 1.0, 0.0, 6.0)
	var focus: = anchor.lerp(bp, TRACK_FOCUS_BALL_WEIGHT)






	focus.y = clampf(focus.y, 0.5, 5.0)
	var bp_fit: = Vector3(bp.x, minf(bp.y, anchor.y + TRACK_BALL_FIT_CAP), bp.z)









	var fit: = clampf(_track_fit_distance(focus, pp, bp_fit, eff), 
		TRACK_MIN_DIST, TRACK_MAX_DIST)









	if absf(fit - _fit_target) > TRACK_FIT_DEADBAND:
		_fit_target = fit





	var closing: = _fit_target <= _fit_dist
	var fit_rate: = TRACK_FIT_IN_SPEED
	var fit_cap: = TRACK_FIT_MAX_MPS
	if not closing:
		var urgency: = clampf((_fit_target - _fit_dist) / TRACK_FIT_URGENT_RANGE, 0.0, 1.0)
		fit_rate = lerpf(TRACK_FIT_OUT_SPEED, TRACK_FIT_URGENT_SPEED, urgency)
		fit_cap = lerpf(TRACK_FIT_MAX_MPS, TRACK_FIT_URGENT_MPS, urgency)
	var fit_step: = absf(_fit_target - _fit_dist) * (1.0 - exp( - fit_rate * delta))
	_fit_dist = move_toward(_fit_dist, _fit_target, minf(fit_step, fit_cap * delta))
	_zoom_smooth = lerpf(_zoom_smooth, _track_zoom, 1.0 - exp( - TRACK_ZOOM_EASE * delta))


	var dir: = TRACK_OFFSET.normalized().lerp(SERVE_OFFSET.normalized(), 0.5 * eff).normalized()
	var offset: = dir * _fit_dist * _zoom_smooth\
	+ Vector3(0.0, ball_air * TRACK_PULL_UP, 0.0)

	_serve_blend = lerpf(_serve_blend, 1.0 if serve_view else 0.0, 
		1.0 - exp(-5.0 * delta))
	offset = offset.lerp(SERVE_OFFSET * _track_zoom, _serve_blend)
	offset.z *= possession if TRACK_FLIP_WITH_POSSESSION else home_side






	_track_side_step(pp, bp, delta)
	var right: = camera.global_basis.x
	right.y = 0.0
	var target: = anchor + offset + right.normalized() * _side_slide * (1.0 - _serve_blend)
	global_position = global_position.lerp(target, 1.0 - exp( - TRACK_FOLLOW_SPEED * delta))
	global_position = _clip(anchor + Vector3(0, 1.5, 0), global_position)







	focus = focus.lerp(Vector3(
		tv_center_x + (pp.x - tv_center_x) * 0.4, 0.4, 
		- home_side * 1.5), _serve_blend * 0.6)
	_look = _look.lerp(focus, 1.0 - exp( - TRACK_LOOK_SPEED * delta))
	camera.look_at(_look)


const TRACK_MIN_DIST: = 6.0
const TRACK_MAX_DIST: = 21.0
const TRACK_FILL_X: = 0.8
const TRACK_FILL_Y: = 0.6
const TRACK_SIDE_RADIUS: = 0.6
const TRACK_SIDE_MAX: = 2.2



const TRACK_SIDE_SPEED: = 2.8
const TRACK_SIDE_MAX_MPS: = 1.6
const TRACK_FIT_OUT_SPEED: = 2.2
const TRACK_FIT_IN_SPEED: = 1.4
const TRACK_FIT_MAX_MPS: = 2.4


const TRACK_FIT_URGENT_RANGE: = 3.5
const TRACK_FIT_URGENT_SPEED: = 8.0
const TRACK_FIT_URGENT_MPS: = 11.0
const TRACK_FIT_DEADBAND: = 0.7
const TRACK_BALL_FIT_CAP: = 3.0
const TRACK_ZOOM_EASE: = 9.0
var _fit_dist: = 8.0
var _fit_target: = 8.0
var _zoom_smooth: = 1.0
var _side_slide: = 0.0







func _track_fit_distance(focus: Vector3, pp: Vector3, bp: Vector3, 
		holder: = 0.0) -> float:
	var basis: = camera.global_basis
	var view: = - basis.z
	var vfov: = deg_to_rad(camera.fov) * 0.5
	var vp: = get_viewport().get_visible_rect().size
	var aspect: = vp.x / maxf(vp.y, 1.0)
	var tx: = tan(vfov) * aspect * TRACK_FILL_X
	var ty: = tan(vfov) * TRACK_FILL_Y
	var pts: = [pp, pp + Vector3(0.0, 2.2, 0.0), 
		bp + Vector3(0.0, 0.5, 0.0), bp - Vector3(0.0, 0.5, 0.0)]
	if holder > 0.05:


		pts.append(Vector3(bp.x, 0.0, bp.z))
		pts.append(Vector3(bp.x, 2.2, bp.z))
	var need: = 0.0
	for q in pts:
		var rel: Vector3 = q - focus
		var depth: = rel.dot(view)
		need = maxf(need, absf(rel.dot(basis.x)) / tx - depth)
		need = maxf(need, absf(rel.dot(basis.y)) / ty - depth)
	return need

func _track_side_step(pp: Vector3, bp: Vector3, delta: float) -> void :
	var inv: = camera.global_transform.affine_inverse()
	var body_c: = inv * (pp + Vector3(0.0, 1.0, 0.0))
	var ball_c: = inv * bp
	var want: = 0.0

	if body_c.z < -0.2 and ball_c.z < body_c.z:
		var body_d: = - body_c.z
		var dx: = ball_c.x / - ball_c.z - body_c.x / body_d
		var dy: = ball_c.y / - ball_c.z - body_c.y / body_d
		var r: = TRACK_SIDE_RADIUS / body_d
		if absf(dy) < 1.3 / body_d:
			if absf(dx) < r:




				var need: = (r - absf(dx)) * body_d
				want = clampf(_side_slide + signf(dx if dx != 0.0 else 1.0) * need, 
					- TRACK_SIDE_MAX, TRACK_SIDE_MAX)
			elif absf(dx) < r * 1.8:
				want = _side_slide

	var step: = absf(want - _side_slide) * (1.0 - exp( - TRACK_SIDE_SPEED * delta))
	_side_slide = move_toward(_side_slide, want, minf(step, TRACK_SIDE_MAX_MPS * delta))
