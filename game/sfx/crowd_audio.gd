class_name CrowdAudio
extends Node






















const MURMUR_STREAM: = "res://game/sfx/Ambiance/freesound_community-audience-77867.mp3"
const CROWD_DIR: = "res://game/sfx/Crowd"
const SERVE_CROSSFADE: = 0.35

var recorder = null

@onready var _murmur: AudioStreamPlayer = get_node_or_null("Murmur")
@onready var _cheer: AudioStreamPlayer = get_node_or_null("Cheer")
@onready var _shock: AudioStreamPlayer = get_node_or_null("Shock")
@onready var _serve_build: AudioStreamPlayer = get_node_or_null("ServeBuild")
@onready var _serve_hit: AudioStreamPlayer = get_node_or_null("ServeHit")
@onready var _stinger: AudioStreamPlayer = get_node_or_null("Stinger")

var _cheers: Array = []
var _shocks: Array = []
var _aww: AudioStream = null



var _cheer_base: = -3.0
var _shock_base: = -2.0
var _build_base: = -8.0
var _hit_base: = -3.0
var _aww_base: = -6.0


var _last_cheer: AudioStream = null
var _last_shock: AudioStream = null
var _serve_tween: Tween = null





var _active: = true



func cheer(intensity: float) -> void :
	if recorder != null:
		recorder.cue("cheer", {"a": intensity})


	CrowdField.cheer(intensity)
	if not _active or _cheer == null or _cheers.is_empty():
		return


	if _cheer.playing and intensity < 0.9:
		return
	_cheer.stream = _pick(_cheers, _last_cheer)
	_last_cheer = _cheer.stream
	_cheer.volume_db = _cheer_base + lerpf(-11.0, 0.0, clampf(intensity, 0.0, 1.0))
	_cheer.pitch_scale = randf_range(0.97, 1.03)
	_cheer.play()



func shock(intensity: = 0.8) -> void :
	if recorder != null:
		recorder.cue("shock", {"a": intensity})

	CrowdField.cheer(intensity * 0.55)
	if not _active or _shock == null or _shocks.is_empty():
		return

	if _shock.playing and intensity < 0.85:
		return
	_shock.stream = _pick(_shocks, _last_shock)
	_last_shock = _shock.stream
	_shock.volume_db = _shock_base + lerpf(-9.0, 0.0, clampf(intensity, 0.0, 1.0))
	_shock.pitch_scale = randf_range(0.97, 1.03)
	_shock.play()


func serve_build() -> void :
	if not _active or _serve_build == null or _serve_build.stream == null:
		return
	_kill_serve_tween()
	_serve_build.volume_db = _build_base
	_serve_build.play()




func serve_hit() -> void :
	_crossfade_serve_out(SERVE_CROSSFADE)
	if not _active or _serve_hit == null or _serve_hit.stream == null:
		return
	_serve_hit.volume_db = _hit_base
	_serve_hit.pitch_scale = randf_range(0.98, 1.02)
	_serve_hit.play()



func serve_stop(fade: = SERVE_CROSSFADE) -> void :
	_crossfade_serve_out(fade)



func aww(intensity: = 0.7) -> void :
	if not _active or _stinger == null or _aww == null:
		return
	_stinger.stream = _aww
	_stinger.volume_db = _aww_base + lerpf(-7.0, 0.0, clampf(intensity, 0.0, 1.0))
	_stinger.pitch_scale = randf_range(0.98, 1.02)
	_stinger.play()





func set_active(active: bool) -> void :
	_active = active
	if _murmur == null:
		return
	if not active:
		_murmur.stop()


	elif _murmur.stream != null and not _murmur.playing:
		_murmur.play()



func _pick(pool: Array, last: AudioStream) -> AudioStream:
	if pool.size() <= 1:
		return pool[0]
	var choice: AudioStream = pool.pick_random()
	var guard: = 0
	while choice == last and guard < 8:
		choice = pool.pick_random()
		guard += 1
	return choice

func _crossfade_serve_out(seconds: float) -> void :
	if _serve_build == null or not _serve_build.playing:
		return
	_kill_serve_tween()
	if seconds <= 0.0:
		_serve_build.stop()
		return
	_serve_tween = create_tween()
	_serve_tween.tween_property(_serve_build, "volume_db", -40.0, seconds)
	_serve_tween.tween_callback(_serve_build.stop)

func _kill_serve_tween() -> void :
	if _serve_tween != null and _serve_tween.is_valid():
		_serve_tween.kill()
	_serve_tween = null

func _ready() -> void :
	if not GameConfig.crowd_enabled:
		return

	if _cheer != null: _cheer_base = _cheer.volume_db
	if _shock != null: _shock_base = _shock.volume_db
	if _serve_build != null: _build_base = _serve_build.volume_db
	if _serve_hit != null: _hit_base = _serve_hit.volume_db
	if _stinger != null: _aww_base = _stinger.volume_db


	var cheer_wav: = _load_crowd("crowd_cheer")
	if cheer_wav != null:
		_cheers.append(cheer_wav)
	else:
		for i in 3:
			_cheers.append(_make_cheer())

	for base in ["crowd_shock", "crowd_shock_3"]:
		var s: = _load_crowd(base)
		if s != null:
			_shocks.append(s)
	if _serve_build != null:
		_serve_build.stream = _load_crowd("crowd_serve_buildup")
	if _serve_hit != null:
		_serve_hit.stream = _load_crowd("crowd_serve_hit")
	_aww = _load_crowd("crowd_aww_sad")

	if _murmur != null:
		var real: = _load_murmur()
		_murmur.stream = real if real != null else _make_murmur()


		if real == null:
			_murmur.volume_db -= 6.0
		_murmur.play()



func _load_crowd(base: String) -> AudioStream:
	var path: = "%s/%s.wav" % [CROWD_DIR, base]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream

func _load_murmur() -> AudioStream:


	if not ResourceLoader.exists(MURMUR_STREAM):
		return null
	var s = load(MURMUR_STREAM)
	if s is AudioStreamMP3:
		s.loop = true
	return s

func _make_murmur() -> AudioStreamWAV:

	var rate: = 22050
	var n: = rate * 3
	var data: = PackedByteArray()
	data.resize(n * 2)
	var brown: = 0.0
	var lowpass: = 0.0
	for i in n:
		var t: = float(i) / rate
		brown = clampf(brown * 0.985 + randf_range(-1.0, 1.0) * 0.1, -1.0, 1.0)
		lowpass += (brown - lowpass) * 0.06
		var swell: = 0.75 + 0.25 * sin(TAU * t / 3.0)
		data.encode_s16(i * 2, int(clampf(lowpass * swell * 2.2, -1.0, 1.0) * 32767.0))
	var wav: = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = n
	return wav

func _make_cheer() -> AudioStreamWAV:

	var rate: = 22050
	var dur: = 1.8
	var n: = int(rate * dur)
	var data: = PackedByteArray()
	data.resize(n * 2)
	var lowpass: = 0.0
	for i in n:
		var t: = float(i) / rate
		var env: = t / 0.22 if t < 0.22 else exp( - (t - 0.22) * 2.1)
		var cutoff: = 0.06 + env * randf_range(0.22, 0.3)
		lowpass += (randf_range(-1.0, 1.0) - lowpass) * cutoff
		data.encode_s16(i * 2, int(clampf(lowpass * env * 1.8, -1.0, 1.0) * 32767.0))
	var wav: = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav
