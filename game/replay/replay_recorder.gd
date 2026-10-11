class_name ReplayRecorder
extends RefCounted










const MAX_MINUTES: = 20.0
const TRIM_MINUTES: = 2.0

var data: = ReplayData.new()
var recording: = false

var _accum: = 0.0
var _clock: = 0.0
var _bodies: Array = []
var _ball: Node3D = null
var _max_frames: = 0

func begin(bodies: Array, slot_info: Array, ball: Node3D, meta: Dictionary) -> void :
	data = ReplayData.new()
	data.slots = slot_info
	data.meta = meta
	_bodies = bodies
	_ball = ball
	_accum = 0.0
	_clock = 0.0
	_max_frames = int(MAX_MINUTES * 60.0 * ReplayData.RATE)
	recording = true

func stop() -> void :
	recording = false

func tick(delta: float) -> void :
	if not recording or _ball == null:
		return
	_clock += delta
	_accum += delta
	var step: = 1.0 / ReplayData.RATE
	if _accum < step:
		return
	_accum = fmod(_accum, step)
	if data.frame_count() >= _max_frames:
		_trim_oldest()
	_capture()

func _trim_oldest() -> void :
	var drop: = mini(int(TRIM_MINUTES * 60.0 * ReplayData.RATE), data.frame_count())
	if drop <= 0:
		return
	data.frames = data.frames.slice(drop * data.stride())

	var floor_t: = data.time_at(0)
	var keep: Array = []
	for e in data.events:
		if float(e["t"]) >= floor_t:
			keep.append(e)
	data.events = keep

var sweat: = 0.0




var replaying: = false

func cue(kind: String, payload: Dictionary) -> void :

	if not recording or replaying:
		return
	data.events.append({"t": _clock, "k": kind, "d": payload})

func _capture() -> void :
	var row: = PackedFloat32Array()
	row.push_back(_clock)
	row.push_back(sweat)
	row.push_back(_ball.global_position.x)
	row.push_back(_ball.global_position.y)
	row.push_back(_ball.global_position.z)
	row.push_back(_ball.vel.x)
	row.push_back(_ball.vel.y)
	row.push_back(_ball.vel.z)


	row.push_back(-1.0 if _ball.float_serve else (1.0 if _ball.frozen else 0.0))
	row.push_back(_ball.curve)
	for b in _bodies:
		row.append_array((b as Player).replay_capture())
	data.frames.append_array(row)



func window_start_time(lead_in: float) -> float:


	return maxf(_clock - lead_in, data.time_at(0))

func now() -> float:
	return _clock
