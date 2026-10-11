class_name Sfx
extends Node3D





const POOL: = 14
const VOICE_POOL: = 8


var _players: Array[AudioStreamPlayer3D] = []
var _voice_players: Array[AudioStreamPlayer3D] = []
var _next: = 0
var _next_voice: = 0
var _sets: = {}

func _ready() -> void :



	_sets["reach_in"] = [
		load("res://game/sfx/Prio_Sys/ball_target.wav"), 
		load("res://game/sfx/Prio_Sys/ball_target_variation.wav"), 
	]
	_sets["reach_queue"] = [
		load("res://game/sfx/Prio_Sys/ball_queue.wav"), 
	]
	_sets["reach_take"] = [
		load("res://game/sfx/Prio_Sys/ball_confirm.wav"), 
	]
	_sets["reach_miss"] = [
		load("res://game/sfx/Prio_Sys/ball_deny.wav"), 
	]

	_sets["count_tick"] = [
		load("res://game/sfx/hits/impactPlate_heavy_004.ogg"), 
	]
	_load_set("hit_soft", "res://game/sfx/Volleyball_SFX/Volleyball_Hit_Soft_%02d.wav", 10)
	_load_set("hit_medium", "res://game/sfx/Volleyball_SFX/Volleyball_Hit_Medium_%02d.wav", 10)
	_load_set("hit_hard", "res://game/sfx/Volleyball_SFX/Volleyball_Hit_Hard_%02d.wav", 10)
	_load_set("spike", "res://game/sfx/Volleyball_SFX/Volleyball_Spike_%02d.wav", 5)
	_load_set("block_soft", "res://game/sfx/Volleyball_SFX/Volleyball_Block_Soft_%02d.wav", 5)
	_load_set("block_medium", "res://game/sfx/Volleyball_SFX/Volleyball_Block_Medium_%02d.wav", 5)
	_load_set("block_hard", "res://game/sfx/Volleyball_SFX/Volleyball_Block_Hard_%02d.wav", 5)





	_load_one("combo_home_1", "res://game/sfx/streak/Rising Combo Hit 04.wav")
	_load_one("combo_home_2", "res://game/sfx/streak/Rising Combo Hit 06.wav")
	_load_one("combo_home_3", "res://game/sfx/streak/Rising Combo Hit 08.wav")
	_load_one("combo_away_1", "res://game/sfx/streak/Rising Combo Hit 01.wav")
	_load_one("combo_away_2", "res://game/sfx/streak/Rising Combo Hit 02.wav")
	_load_one("combo_away_3", "res://game/sfx/streak/Rising Combo Hit 08.wav")
	_load_one("combo_fail", "res://game/sfx/streak/Rising Combo Hit Fail.wav")



	for i in range(1, 9):
		_load_one("combo_tut_%d" % i, 
			"res://game/sfx/fullstreak/Rising Combo Hit %02d.wav" % i)
	_load_one("combo_tut_bonus", "res://game/sfx/fullstreak/Rising Combo Hit Bonus.wav")
	_load_one("combo_tut_fail", "res://game/sfx/fullstreak/Rising Combo Hit Fail.wav")



	_sets["squeak"] = [
		load("res://game/sfx/ShoeSfx/162495__pipelyd__shoe-sole-rubber-squeak-tile-hall-3.wav"), 
		load("res://game/sfx/ShoeSfx/187343__baidonovan__rubber-shoe-squeak.wav"), 
	]


	_sets["footstep_sand"] = []
	_sets["footstep_grass"] = []
	for i in range(1, 5):
		_sets["footstep_sand"].append(load(
			"res://game/sfx/Footsteps/NA_Character Footsteps (Dirt & Grass) - Pack 1/Run/Dirt/DIRT - Run %d.wav" % i))
		_sets["footstep_grass"].append(load(
			"res://game/sfx/Footsteps/NA_Character Footsteps (Dirt & Grass) - Pack 1/Run/Grass/GRASS - Run %d.wav" % i))



	_sets["footstep_water"] = []
	for wpath in [
		"res://game/sfx/Footsteps/CHP/Steps_water-002.ogg", 
	]:
		if ResourceLoader.exists(wpath):
			_sets["footstep_water"].append(load(wpath))
	_sets["whip"] = [
		load("res://game/sfx/WhipSfx/734689__geoff-bremner-audio__whip-12.wav"), 
	]
	_sets["whistle"] = [
		load("res://game/sfx/GymSfx/218318__splicesound__referee-whistle-blow-gymnasium.wav"), 
	]



	_load_set("v_jump", "res://game/sfx/PlayerSfx/jump%d.wav", 3, 1)
	_load_set("v_dive", "res://game/sfx/PlayerSfx/dive%d.wav", 3, 1)
	_load_set("v_receive", "res://game/sfx/PlayerSfx/recieve%d.wav", 1, 1)




	_load_set("v_2_jump", "res://game/sfx/PlayerSfx/2/jump%d.wav", 3, 1)
	_load_set("v_2_dive", "res://game/sfx/PlayerSfx/2/dive%d.wav", 3, 1)
	_load_set("v_2_receive", "res://game/sfx/PlayerSfx/2/recieve%d.wav", 1, 1)
	_make_footsteps()
	_load_wood_footsteps()
	_make_jump_sounds()
	for i in POOL:
		var p: = AudioStreamPlayer3D.new()
		p.max_distance = 60.0
		p.bus = "sfx"
		add_child(p)
		_players.append(p)
	for i in VOICE_POOL:
		var v: = AudioStreamPlayer3D.new()
		v.max_distance = 45.0
		v.bus = "voice"
		add_child(v)
		_voice_players.append(v)

	for i in FEEDBACK_POOL:
		var f: = AudioStreamPlayer3D.new()
		f.max_distance = 60.0
		f.bus = "feedback"
		add_child(f)
		_feedback_players.append(f)


	for i in POOL_2D:
		var p2: = AudioStreamPlayer.new()
		p2.bus = "feedback"
		add_child(p2)
		_players_2d.append(p2)

func _make_footsteps() -> void :


	var rate: = 44100
	var variations: Array = []
	for v in 4:
		var n: = int(rate * 0.09)
		var data: = PackedByteArray()
		data.resize(n * 2)
		var freq: = randf_range(68.0, 96.0)
		var lowpass: = 0.0
		for i in n:
			var t: = float(i) / rate
			var thump: = sin(TAU * freq * t) * exp( - t * 42.0)
			var noise: = randf_range(-1.0, 1.0) * exp( - t * 90.0) * 0.5
			lowpass += (noise - lowpass) * 0.22
			var sample: = clampf(thump * 0.8 + lowpass, -1.0, 1.0)
			data.encode_s16(i * 2, int(sample * 32767.0))
		var wav: = AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = rate
		wav.data = data
		variations.append(wav)
	_sets["footstep"] = variations

func _load_wood_footsteps() -> void :


	var authored: Array[AudioStream] = []
	for file_name in [
		"10_Step_wood_01.wav", 
		"11_Step_wood_02.wav", 
		"12_Step_wood_03.wav", 
	]:
		var path: = "res://game/sfx/Footsteps/CHP/%s" % file_name
		if ResourceLoader.exists(path):
			var stream: = load(path) as AudioStream
			if stream != null:
				authored.append(stream)
	if not authored.is_empty():
		_sets["footstep"] = authored

func _make_jump_sounds() -> void :


	var rate: = 44100
	var dur: = 0.1
	var variations: Array = []
	for v in 3:
		var n: = int(rate * dur)
		var data: = PackedByteArray()
		data.resize(n * 2)
		var phase: = 0.0
		var lowpass: = 0.0
		var start_freq: = randf_range(140.0, 170.0)
		for i in n:
			var frac: = float(i) / float(n)
			var env: = sin(PI * frac)
			phase += TAU * lerpf(start_freq, 70.0, frac) / rate
			lowpass += (randf_range(-1.0, 1.0) - lowpass) * 0.1
			var sample: = sin(phase) * env * 0.65 + lowpass * env * 0.2
			data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
		var wav: = AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = rate
		wav.data = data
		variations.append(wav)
	_sets["jump"] = variations


func _load_one(bank: String, path: String) -> void :
	if ResourceLoader.exists(path):
		_sets[bank] = [load(path)]

func _load_set(bank: String, pattern: String, count: int, start: = 1) -> void :
	var streams: Array = []
	for i in range(start, start + count):
		var path: String = pattern % i
		if ResourceLoader.exists(path):
			streams.append(load(path))
	if not streams.is_empty():
		_sets[bank] = streams


const BASE_DB: = {
	"whistle": -9.0, 
	"reach_in": 6.0, 
	"reach_queue": 6.0, 
	"reach_take": 6.0, 
	"reach_miss": 6.0, 





	"v_2_jump": -8.0, 
	"v_2_dive": -8.0, 
	"v_2_receive": -8.0, 
}







var recorder = null
const LOCAL_ONLY_BANKS: = ["reach_in", "reach_queue", "reach_take", "reach_miss"]
const FEEDBACK_POOL: = 4
var _feedback_players: Array = []
var _next_feedback: = 0
const POOL_2D: = 6
var _players_2d: Array[AudioStreamPlayer] = []
var _next_2d: = 0




func play_2d(bank: String, volume_db: = 0.0, pitch: = 1.0) -> void :
	var streams: Array = _sets.get(bank, [])
	if streams.is_empty():
		return
	var p: AudioStreamPlayer = _players_2d[_next_2d]
	_next_2d = (_next_2d + 1) % POOL_2D
	p.stream = streams.pick_random()
	p.volume_db = volume_db + float(BASE_DB.get(bank, 0.0))
	p.pitch_scale = pitch
	p.play()

func play(bank: String, pos: Vector3, volume_db: = 0.0, pitch: = 1.0, jitter: = true, crisp: = false) -> void :


	if recorder != null and not LOCAL_ONLY_BANKS.has(bank):
		recorder.cue("sfx", {"n": bank, "p": pos, "db": volume_db, "pt": pitch})
	var streams: Array = _sets.get(bank, [])
	if streams.is_empty():
		return



	if bank.begins_with("combo_"):
		jitter = false
		crisp = true
	var is_voice: = bank.begins_with("v_")
	if is_voice and not GameConfig.voice_enabled:
		return
	var p: AudioStreamPlayer3D
	if is_voice:
		p = _voice_players[_next_voice]
		_next_voice = (_next_voice + 1) % VOICE_POOL
	elif LOCAL_ONLY_BANKS.has(bank):
		p = _feedback_players[_next_feedback]
		_next_feedback = (_next_feedback + 1) % FEEDBACK_POOL
	else:
		p = _players[_next]
		_next = (_next + 1) % POOL




		p.bus = "feedback" if crisp else "sfx"
		p.attenuation_filter_cutoff_hz = 20500.0 if crisp else 5000.0
	p.stream = streams.pick_random()
	p.global_position = pos
	p.volume_db = volume_db + float(BASE_DB.get(bank, 0.0))


	p.pitch_scale = pitch + (randf_range(-0.06, 0.06) if jitter else 0.0)
	p.play()
