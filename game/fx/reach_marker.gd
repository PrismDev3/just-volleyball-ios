class_name ReachMarker
extends Node3D




























const TEX_SHADER: = preload("res://game/fx/reach_tex.gdshader")
const TEX_OUTER: = preload("res://game/fx/reticle_outer.png")
const TEX_INNER: = preload("res://game/fx/reticle_inner.png")

enum State{OFF, EARLY, READY, QUEUED, TAKEN, MISSED, STRANDED}






const COLOR_READY: = Color(0.35, 0.78, 1.0)
const COLOR_EARLY: = Color(0.62, 0.68, 0.78)
const COLOR_QUEUED: = Color(1.0, 0.92, 0.22)
const COLOR_TAKEN: = Color(0.22, 0.94, 0.42)
const COLOR_MISSED: = Color(1.0, 0.28, 0.26)
const COLOR_STRANDED: = Color(1.0, 0.36, 0.3)

const RADIUS: = 0.95
const SCREEN_SCALE: = 0.085
const PULSE_HZ: = 2.6
const PULSE_DEPTH: = 0.09




const APPEAR_TIME: = 0.14
const APPEAR_FROM: = 1.45
const GLOW_BASE: = 1.35
const GLOW_BURST: = 1.6
const BURST_DECAY: = 5.0
const STATE_FLASH_DECAY: = 9.0
const STATE_FLASH_GLOW: = 2.4





const TAKEN_TIME: = 0.1
const TAKEN_HOLD: = 0.4
const TAKEN_FADE: = 0.12
const WRAP_RADIUS: = 0.45
const MISSED_TIME: = 0.3
const EARLY_TIME: = 0.28







const REACH_HOLD: = 0.16
const MISSED_SHAKE: = 0.13
const MISSED_SHAKE_HZ: = 19.0
const FADE_IN: = 0.07
const RADIUS_EASE: = 0.09




signal entered_reach
signal action_queued
signal took
signal missed
signal early





const FRAME_SCALE: = 2.15


const INNER_CATCH_TIGHTEN: = 0.82
var _outer: MeshInstance3D = null
var _outer_mat: ShaderMaterial = null
var _inner: MeshInstance3D = null
var _inner_mat: ShaderMaterial = null
var _camera: Camera3D = null
var _state: = State.OFF
var _t: = 0.0
var _pulse: = 0.0
var _alpha: = 0.0
var _radius: = RADIUS * APPEAR_FROM
var _radius_want: = RADIUS
var _appear: = 0.0
var _burst: = 0.0
var _state_flash: = 0.0
var _take_from: = RADIUS
var _wrap_k: = 1.0
var _target: = Vector3.ZERO

var _touch_seq: = -1
var _strike_seq: = -1
var _early_seq: = -1
var _hold_left: = 0.0

func _ready() -> void :
	process_mode = Node.PROCESS_MODE_PAUSABLE

	_outer_mat = _make_tex_mat(TEX_OUTER, 13)
	_outer = _make_quad(_outer_mat)


	_inner_mat = _make_tex_mat(TEX_INNER, 14)
	_inner_mat.set_shader_parameter("bold", 2.3)
	_inner_mat.set_shader_parameter("fatten", 0.012)


	_inner_mat.set_shader_parameter("outline", 0.03)
	_inner = _make_quad(_inner_mat)
	set_process(true)

func _make_tex_mat(tex: Texture2D, priority: int) -> ShaderMaterial:
	var mat: = ShaderMaterial.new()
	mat.shader = TEX_SHADER
	mat.render_priority = priority
	mat.set_shader_parameter("tex", tex)
	mat.set_shader_parameter("tint", Color.WHITE)
	mat.set_shader_parameter("alpha", 0.0)
	mat.set_shader_parameter("glow", 1.0)
	return mat

func _make_quad(mat: ShaderMaterial) -> MeshInstance3D:
	var quad: = QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	quad.material = mat
	var mi: = MeshInstance3D.new()
	mi.mesh = quad
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	add_child(mi)
	return mi

func setup(camera: Camera3D) -> void :
	_camera = camera





func drive(body: Player, ball: Node3D, playable: bool) -> void :
	if body == null or ball == null or not playable:
		_touch_seq = -1
		_strike_seq = -1
		_early_seq = -1
		track(_target, false, false)
		return



	var mine: = int(body.touch_seq)
	var any: = int(ball.strike_seq)
	var early: = int(body.early_contact_seq)
	var i_touched: = _touch_seq >= 0 and mine != _touch_seq
	var anyone: = _strike_seq >= 0 and any != _strike_seq
	var pressed_early: = _early_seq >= 0 and early != _early_seq
	_touch_seq = mine
	_strike_seq = any
	_early_seq = early
	if i_touched:
		flash_taken()
	elif anyone:
		flash_missed()
	elif pressed_early:
		flash_early()



	var queued: = body.contact_intent_queued() or body.charging_set()
	var can: bool = not body.touch_barred and body.contact_opportunity_available()



	var lost: = queued and body.queued_ball_abandoned()
	track(ball.global_position, can, lost, queued)






func track(ball_pos: Vector3, in_reach: bool, lost: = false, 
		queued: = false) -> void :
	_target = ball_pos
	if _state == State.TAKEN or _state == State.MISSED:
		return
	if _state == State.EARLY and not queued and not in_reach:
		return



	if in_reach:
		_hold_left = REACH_HOLD
	var covered: = in_reach or _hold_left > 0.0




	var want: int
	if queued:
		want = State.STRANDED if lost else State.QUEUED
	elif covered:
		want = State.READY
	else:
		want = State.OFF
	if want == _state:
		return


	if want == State.READY:
		_state_flash = 1.0
		entered_reach.emit()
		_appear = APPEAR_TIME
		_burst = 1.0
		_radius = RADIUS * APPEAR_FROM
	elif want == State.QUEUED:





		_state_flash = 1.0
		if _state == State.OFF:
			entered_reach.emit()
		action_queued.emit()
		_burst = 1.0
		_radius_want = RADIUS * 0.78
	elif want == State.STRANDED:


		_state_flash = 1.0
		_burst = 0.5
		_radius_want = RADIUS * 0.9
	elif want == State.OFF and (_state == State.READY or _state == State.STRANDED):



		_alpha = 0.0
	_state = want
	_t = 0.0

func flash_taken() -> void :
	_state = State.TAKEN
	_t = 0.0
	_state_flash = 1.0



	_take_from = _radius if _radius > 0.0 else RADIUS * 0.6
	_wrap_k = 0.0
	_burst = 1.0
	_alpha = 1.0
	took.emit()

func flash_early() -> void :
	if _state == State.TAKEN or _state == State.MISSED:
		return
	_state = State.EARLY
	_t = 0.0
	_state_flash = 1.0
	_alpha = 1.0
	_radius = RADIUS * 1.12
	_radius_want = _radius
	early.emit()

func flash_missed() -> void :



	if _state != State.READY and _state != State.QUEUED\
	and _state != State.STRANDED:
		return
	_state = State.MISSED
	_t = 0.0
	_state_flash = 1.0
	_alpha = 1.0
	missed.emit()




func authoritative_touch(was_mine: bool) -> void :


	if _state != State.READY and _state != State.QUEUED\
	and _state != State.STRANDED:
		return
	if was_mine:
		flash_taken()
	else:
		flash_missed()

func state() -> int:
	return _state

func is_showing() -> bool:
	return _alpha > 0.01






func reset() -> void :
	_state = State.OFF
	_hold_left = 0.0
	_alpha = 0.0
	_touch_seq = -1
	_strike_seq = -1
	_early_seq = -1
	if _outer != null:
		_outer.visible = false
	if _inner != null:
		_inner.visible = false

func _process(delta: float) -> void :
	_t += delta
	_hold_left = maxf(_hold_left - delta, 0.0)
	var want_alpha: = 0.0
	var tint: = COLOR_READY
	var snap: = false
	match _state:
		State.EARLY:
			tint = COLOR_EARLY
			snap = true
			_radius_want = RADIUS * 1.12
			want_alpha = 1.0 - clampf(_t / EARLY_TIME, 0.0, 1.0)
			if _t > EARLY_TIME:
				_state = State.OFF
		State.READY:
			want_alpha = 1.0
			_appear = maxf(_appear - delta, 0.0)
			_pulse += delta

			var settle: = 1.0 - _appear / APPEAR_TIME
			settle = 1.0 - (1.0 - settle) * (1.0 - settle)
			_radius_want = RADIUS * lerpf(APPEAR_FROM, 1.0, settle)\
			* (1.0 + sin(_pulse * TAU * PULSE_HZ) * PULSE_DEPTH)
		State.QUEUED:
			tint = COLOR_QUEUED
			want_alpha = 1.0
			_pulse += delta
			_radius_want = RADIUS * 0.78\
			* (1.0 + sin(_pulse * TAU * PULSE_HZ) * PULSE_DEPTH * 0.35)
		State.STRANDED:



			tint = COLOR_STRANDED
			want_alpha = 1.0
			_pulse += delta
			_radius_want = RADIUS * 0.9\
			* (1.0 + sin(_pulse * TAU * PULSE_HZ) * PULSE_DEPTH * 0.7)
		State.TAKEN:
			tint = COLOR_TAKEN
			snap = true





			var k: = clampf(_t / TAKEN_TIME, 0.0, 1.0)
			_wrap_k = 1.0 - (1.0 - k) * (1.0 - k)
			_radius = -1.0
			_radius_want = _radius


			want_alpha = 1.0
			if _t > TAKEN_TIME + TAKEN_HOLD:
				want_alpha = clampf(
					1.0 - (_t - TAKEN_TIME - TAKEN_HOLD) / TAKEN_FADE, 0.0, 1.0)
				if want_alpha <= 0.01:
					_state = State.OFF
		State.MISSED:
			tint = COLOR_MISSED
			snap = true
			_radius_want = RADIUS


			want_alpha = 1.0 - clampf(_t / MISSED_TIME, 0.0, 1.0)
			if _t > MISSED_TIME:
				_state = State.OFF
		State.OFF:
			want_alpha = 0.0
	if snap:
		_alpha = want_alpha
	else:
		_alpha = lerpf(_alpha, want_alpha, 1.0 - exp( - (1.0 / FADE_IN) * delta))


		_radius = lerpf(_radius, _radius_want, 
			1.0 - exp( - (1.0 / RADIUS_EASE) * delta))
	_burst = maxf(_burst - delta * BURST_DECAY, 0.0)
	_state_flash = maxf(_state_flash - delta * STATE_FLASH_DECAY, 0.0)
	var showing: = _alpha > 0.01
	var flash_mix: = clampf(_state_flash, 0.0, 1.0) * 0.82
	var display_tint: = tint.lerp(Color.WHITE, flash_mix)
	_outer.visible = showing
	_inner.visible = showing
	if showing:


		_outer_mat.set_shader_parameter("tint", 
			Color.WHITE.lerp(display_tint, flash_mix * 0.5))
		_outer_mat.set_shader_parameter("alpha", _alpha)
		_outer_mat.set_shader_parameter("glow", 1.0 + STATE_FLASH_GLOW * _state_flash * 0.35)
		_inner_mat.set_shader_parameter("tint", display_tint)
		_inner_mat.set_shader_parameter("alpha", _alpha)
		_inner_mat.set_shader_parameter("glow", 
			GLOW_BASE + GLOW_BURST * _burst + STATE_FLASH_GLOW * _state_flash)
	if not showing or _camera == null:
		return
	_place()

func _place() -> void :
	global_position = _target


	var to_cam: Vector3 = _camera.global_position - _target
	var dist: = maxf(to_cam.length(), 0.5)
	var scale_k: = dist * SCREEN_SCALE


	var radius: = _radius * scale_k
	if _radius < 0.0:



		radius = lerpf(_take_from * scale_k, 
			maxf(WRAP_RADIUS, scale_k * 0.48), _wrap_k)
	var fwd: = to_cam / dist
	var cam_up: Vector3 = _camera.global_basis.y
	var right: = cam_up.cross(fwd)
	if right.length() < 0.001:
		right = Vector3.RIGHT
	right = right.normalized()
	var up: = fwd.cross(right).normalized()
	var shake: = Vector3.ZERO
	if _state == State.MISSED:
		var life: = 1.0 - clampf(_t / MISSED_TIME, 0.0, 1.0)
		shake = (right * sin(_t * TAU * MISSED_SHAKE_HZ)\
		+ up * cos(_t * TAU * MISSED_SHAKE_HZ * 0.73))\
		* scale_k * MISSED_SHAKE * life



	var fs: = maxf(radius, WRAP_RADIUS) * FRAME_SCALE
	var inner_k: = 1.0
	if _radius < 0.0:
		inner_k = lerpf(1.0, INNER_CATCH_TIGHTEN, _wrap_k)
	var face: = Basis(right, up, fwd)
	_outer.global_position = _target + shake * 0.4
	_outer.global_basis = face.scaled(Vector3(fs, fs, fs))
	var ins: = fs * inner_k
	_inner.global_position = _target + shake
	_inner.global_basis = face.scaled(Vector3(ins, ins, ins))
