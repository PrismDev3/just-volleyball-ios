class_name Announcer
extends Node















const DIR: = "res://game/sfx/Announcer/"
const DUCK_DB: = -7.0


const P: = {
	"game": 100, "set": 90, "match_point": 75, "set_point": 70, 
	"break_point": 60, "ace": 58, "foot_fault": 55, "fault": 55, "line": 50, 
	"out": 48, "deuce": 45, 

	"count_3": 39, "count_2": 38, "count_1": 37, "nice_serve": 25, 
}

const QUEUE_MAX: = 2

var _clips: Dictionary = {}
var _player: AudioStreamPlayer
var _cur_priority: = -1
var _queue: Array = []
var _music: Node = null

func _ready() -> void :
	_player = AudioStreamPlayer.new()
	_player.bus = "announcer"
	add_child(_player)
	_player.finished.connect(_on_finished)
	_music = get_node_or_null("/root/MusicManager")



func _on_finished() -> void :
	if not _queue.is_empty():
		_queue.sort_custom( func(a, b): return int(a.prio) > int(b.prio))
		var nxt: Dictionary = _queue.pop_front()
		_play_now(String(nxt.key), int(nxt.prio))
		return
	_cur_priority = -1
	if _music != null and _music.has_method("duck"):
		_music.duck(0.0)



const ALIASES: = {
	"break_point": ["break point"], 
	"match_point": ["match point"], 
	"set_point": ["set point"], 
	"nice_serve": ["nice serve", "nice_serve"], 
	"game": ["game", "win"], 
	"count_3": ["three", "3"], 
	"count_2": ["two", "2"], 
	"count_1": ["one", "1"], 
}




func _clips_for(key: String) -> Array:
	if _clips.has(key):
		return _clips[key]
	var names: Array = [key]
	if key.contains("_"):
		names.append(key.replace("_", " "))
	for a in ALIASES.get(key, []):
		if a not in names:
			names.append(a)
	var out: Array = []
	for base in names:
		var single: String = DIR + String(base) + ".wav"
		if ResourceLoader.exists(single):
			out.append(load(single))
		else:
			for i in range(1, 9):
				var p: String = DIR + "%s_%02d.wav" % [String(base), i]
				if ResourceLoader.exists(p):
					out.append(load(p))
				elif i > 1:
					break
		if not out.is_empty():
			break
	_clips[key] = out
	return out





func say(key: String, priority: = -1) -> bool:
	if not GameConfig.voice_enabled:
		return false
	if _clips_for(key).is_empty():
		return false
	var prio: int = priority if priority >= 0 else int(P.get(key, 0))
	if _player.playing:
		if prio > _cur_priority:
			_play_now(key, prio)
		else:
			_enqueue(key, prio)
	else:
		_play_now(key, prio)
	return true

func _enqueue(key: String, prio: int) -> void :
	for q in _queue:
		if String(q.key) == key:
			return
	_queue.append({"key": key, "prio": prio})
	if _queue.size() > QUEUE_MAX:

		_queue.sort_custom( func(a, b): return int(a.prio) > int(b.prio))
		_queue.resize(QUEUE_MAX)

func _play_now(key: String, prio: int) -> void :
	var clips: = _clips_for(key)
	if clips.is_empty():
		return
	_player.stream = clips.pick_random()
	_cur_priority = prio
	_player.play()
	if _music != null and _music.has_method("duck"):
		_music.duck(DUCK_DB)



func stop() -> void :
	_queue.clear()
	if _player != null:
		_player.stop()
	_cur_priority = -1
	if _music != null and _music.has_method("duck"):
		_music.duck(0.0)
