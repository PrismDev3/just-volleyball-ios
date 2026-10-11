extends Node
































const TRACKS: = {
	"menu": {"node": "MainTheme", "loop": true}, 
	"replay": {"node": "ReplayTheme", "loop": true}, 
	"gym": {"node": "OpenGymTheme", "loop": true}, 
	"match": {"node": "MatchTheme", "loop": true}, 











	"match_bass": {"node": "MatchBass", "loop": true}, 
	"match_l1": {"node": "MatchLayer1", "loop": true}, 
	"match_l2": {"node": "MatchLayer2", "loop": true}, 

	"win": {"node": "WinJingle", "loop": false}, 
}

const BUS: = "music"

const FULL_FADE: = 1.2

const QUICK_FADE: = 0.4
const JINGLE_FADE: = 0.45

const MUFFLE_FADE: = 0.3
const MUFFLE_OPEN_HZ: = 20000.0
const MUFFLE_SHUT_HZ: = 380.0
const DUCK_FADE: = 0.25


var _gain: = {}
var _target: = {}
var _rate: = {}


var _duck: = 1.0
var _duck_target: = 1.0
var _duck_rate: = 0.0


var _muffle: = 0.0
var _muffle_target: = 0.0
var _muffle_rate: = 0.0
var _lowpass: AudioEffectLowPassFilter = null

var _primary: = ""
var _layers: = {}


var _intensity: = 0
const INTENSITY_STEMS: = ["match_l1", "match_l2"]
const MATCH_BED: = ["match_bass"]








const MATCH_BPM: = 155.0
const SWELL_GRID_BEATS: = 1.0
const SWELL_MIN: = 0.15
var _swell: = {}









const CLIMAX_AT: = 99.067
var _floor: = 0




var _tree_paused: = false

func _ready() -> void :




	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus()
	for key in TRACKS:
		var p: = _player(key)
		if p == null:
			continue
		p.bus = BUS


		p.finished.connect(_on_track_finished.bind(key))
		_gain[key] = 0.0
		_target[key] = 0.0
		_rate[key] = 0.0




func _ensure_bus() -> void :
	if AudioServer.get_bus_index(BUS) == -1:
		var idx: = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS)
		AudioServer.set_bus_send(idx, "Master")
	var bi: = AudioServer.get_bus_index(BUS)

	for e in AudioServer.get_bus_effect_count(bi):
		var eff: = AudioServer.get_bus_effect(bi, e)
		if eff is AudioEffectLowPassFilter:
			_lowpass = eff
			break
	if _lowpass == null:
		_lowpass = AudioEffectLowPassFilter.new()
		AudioServer.add_bus_effect(bi, _lowpass)
	_lowpass.cutoff_hz = MUFFLE_OPEN_HZ

func _player(key: String) -> AudioStreamPlayer:
	var info: Dictionary = TRACKS.get(key, {})
	if info.is_empty():
		return null
	return get_node_or_null(NodePath(info["node"])) as AudioStreamPlayer







func play(key: String, fade: = FULL_FADE, restart: = false) -> void :
	if not TRACKS.has(key):
		return
	_primary = key
	_layers.clear()
	_swell.clear()
	for k in TRACKS:
		_set_target(k, 1.0 if k == key else 0.0, fade)
	_start(key, restart)


	if key == "match":
		_apply_intensity(fade)


func stinger(key: String, fade: = JINGLE_FADE) -> void :
	play(key, fade, true)

func stop(fade: = FULL_FADE) -> void :
	_primary = ""
	_layers.clear()
	_swell.clear()
	for k in TRACKS:
		_set_target(k, 0.0, fade)



func set_layer(key: String, on: bool, fade: = QUICK_FADE) -> void :
	if not TRACKS.has(key):
		return
	if on:
		_layers[key] = true
		_set_target(key, 1.0, fade)
		var p: = _player(key)
		var lead: = _player(_primary)
		if p != null and p.stream != null and not p.playing and not _tree_paused:
			p.play(lead.get_playback_position() if lead != null and lead.playing else 0.0)
	else:
		_layers.erase(key)
		_set_target(key, 0.0, fade)





func set_intensity(tier: int, fade: = QUICK_FADE) -> void :
	tier = clampi(tier, 0, INTENSITY_STEMS.size())
	if tier == _intensity:
		return
	var lead: = _player("match")
	if tier > _intensity and _primary == "match" and lead != null and lead.playing:

		var grid: = 60.0 / MATCH_BPM * SWELL_GRID_BEATS
		var pos: = lead.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
		var to_beat: = grid - fmod(maxf(pos, 0.0), grid)
		if to_beat < SWELL_MIN:
			to_beat += grid
		var prev: = _intensity
		_intensity = tier
		_apply_intensity(fade)
		for i in range(prev, tier):
			var key: String = INTENSITY_STEMS[i]
			_gain[key] = 0.0
			_rate[key] = 0.0
			_swell[key] = {"t": 0.0, "T": to_beat}
		return
	_intensity = tier
	if _primary == "match":
		_apply_intensity(fade)



func _tick_swells(delta: float) -> void :
	for key in _swell.keys():
		var sw: Dictionary = _swell[key]
		sw["t"] = float(sw["t"]) + delta
		var u: = clampf(float(sw["t"]) / maxf(float(sw["T"]), 0.001), 0.0, 1.0)
		_gain[key] = u * u * (3.0 - 2.0 * u)
		if u >= 1.0 or float(_target.get(key, 0.0)) < 0.5:
			_swell.erase(key)
			if float(_target.get(key, 0.0)) < 0.5:
				_rate[key] = absf(float(_gain[key])) / QUICK_FADE




func set_floor(tier: int) -> void :
	_floor = clampi(tier, 0, INTENSITY_STEMS.size())

func _apply_intensity(fade: float) -> void :
	for key in MATCH_BED:
		if not _layers.has(key):
			set_layer(key, true, fade)
	for i in INTENSITY_STEMS.size():
		var key: String = INTENSITY_STEMS[i]
		var want: = i < _intensity
		if want != _layers.has(key):
			set_layer(key, want, fade)


func duck(db: = -8.0, fade: = DUCK_FADE) -> void :
	_duck_target = db_to_linear(db)
	_duck_rate = absf(_duck_target - _duck) / maxf(fade, 0.001)

func unduck(fade: = DUCK_FADE) -> void :
	_duck_target = 1.0
	_duck_rate = absf(_duck_target - _duck) / maxf(fade, 0.001)

func set_muffled(on: bool, time: = MUFFLE_FADE) -> void :
	_muffle_target = 1.0 if on else 0.0
	_muffle_rate = absf(_muffle_target - _muffle) / maxf(time, 0.001)



func _set_target(key: String, tgt: float, time: float) -> void :
	_target[key] = tgt
	_rate[key] = absf(tgt - float(_gain.get(key, 0.0))) / maxf(time, 0.001)

func _start(key: String, restart: bool) -> void :
	var p: = _player(key)
	if p == null or p.stream == null:
		return


	if restart or ( not p.playing and not p.stream_paused):

		p.play(CLIMAX_AT if key == "match" and _floor >= 2 else 0.0)

func _on_track_finished(key: String) -> void :



	if _tree_paused:
		return


	if bool(TRACKS[key].get("loop", false)) and float(_target.get(key, 0.0)) > 0.01:
		var p: = _player(key)
		if p != null and p.stream != null:
			p.play(0.0)

func _process(delta: float) -> void :
	var paused: = get_tree().paused
	if paused != _tree_paused:
		_tree_paused = paused
		for key in TRACKS:
			var p: = _player(key)
			if p != null:
				p.stream_paused = paused
	if paused:
		return
	_tick_swells(delta)
	_duck = move_toward(_duck, _duck_target, _duck_rate * delta)
	if _muffle_rate > 0.0:
		_muffle = move_toward(_muffle, _muffle_target, _muffle_rate * delta)
		if _lowpass != null:

			_lowpass.cutoff_hz = exp(lerpf(log(MUFFLE_OPEN_HZ), 
				log(MUFFLE_SHUT_HZ), _muffle))
	for key in TRACKS:
		var p: = _player(key)
		if p == null:
			continue
		_gain[key] = move_toward(float(_gain[key]), float(_target[key]), 
			float(_rate[key]) * delta)
		var g: float = float(_gain[key]) * _duck
		if g <= 0.001:


			if p.playing and float(_target[key]) <= 0.001:
				p.stop()
		else:
			p.volume_db = linear_to_db(clampf(g, 0.0009, 4.0))
