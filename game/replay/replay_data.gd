class_name ReplayData
extends RefCounted

















const DIR: = "user://replays"
const MAGIC: = "VBRP"
const VERSION: = 8











const MIN_DECODABLE: = 8






enum Compat{CURRENT, OUTDATED, INCOMPATIBLE}

static func compat_for(version: int) -> int:
	if version == VERSION:
		return Compat.CURRENT
	if version >= MIN_DECODABLE and version < VERSION:
		return Compat.OUTDATED
	return Compat.INCOMPATIBLE

const RATE: = 30.0
const MAX_SLOTS: = 24
const MAX_EVENTS: = 4096
const MAX_FRAME_FLOATS: = 8000000
const BALL_FLOATS: = 8
const NET_PLAYER_FLOATS: = Player.NET_FLOATS
const PLAYER_FLOATS: = NET_PLAYER_FLOATS + 1
const HEAD_FLOATS: = 2 + BALL_FLOATS


var slots: Array = []
var frames: = PackedFloat32Array()
var meta: = {}


var format_version: = VERSION
var compat: = Compat.CURRENT




var events: Array = []

func stride() -> int:
	return HEAD_FLOATS + slots.size() * PLAYER_FLOATS

func frame_count() -> int:
	var s: = stride()
	return 0 if s == 0 else frames.size() / s

func time_at(index: int) -> float:
	var s: = stride()
	if s == 0 or index < 0 or index >= frame_count():
		return 0.0
	return frames[index * s]

func duration() -> float:
	var n: = frame_count()
	return 0.0 if n == 0 else time_at(n - 1) - time_at(0)

func sweat_at(index: int) -> float:
	var s: = stride()
	if s == 0 or index < 0 or index >= frame_count():
		return 0.0
	return frames[index * s + 1]

func ball_at(index: int) -> PackedFloat32Array:
	var s: = stride()
	return frames.slice(index * s + 2, index * s + 2 + BALL_FLOATS)

func player_at(index: int, slot: int) -> PackedFloat32Array:
	var s: = stride()
	var base: = index * s + HEAD_FLOATS + slot * PLAYER_FLOATS
	return frames.slice(base, base + PLAYER_FLOATS)

func index_before(t: float) -> int:

	var n: = frame_count()
	if n == 0:
		return -1
	var lo: = 0
	var hi: = n - 1
	while lo < hi:
		var mid: = (lo + hi + 1) / 2
		if time_at(mid) <= t:
			lo = mid
		else:
			hi = mid - 1
	return lo



func _clamp_cues() -> void :
	var last: = duration()
	if last <= 0.0:
		return


	var edge: = last - 0.001
	for e in events:
		if float(e["t"]) > edge:
			e["t"] = edge
		elif float(e["t"]) < 0.0:
			e["t"] = 0.0

func save_to(path: String) -> bool:





	_clamp_cues()


	var dir: = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var f: = FileAccess.open_compressed(path, FileAccess.WRITE, 
		FileAccess.COMPRESSION_GZIP)
	if f == null:
		push_warning("replay: cannot write %s" % path)
		return false
	f.store_string(MAGIC)
	f.store_32(VERSION)
	f.store_var(meta)
	f.store_var(slots)
	f.store_var(events)
	f.store_32(frames.size())
	f.store_buffer(frames.to_byte_array())
	f.close()
	return true

static func load_from(path: String) -> ReplayData:
	var f: = FileAccess.open_compressed(path, FileAccess.READ, 
		FileAccess.COMPRESSION_GZIP)
	if f == null:
		return null
	if f.get_buffer(4).get_string_from_ascii() != MAGIC:
		return null
	var version: = f.get_32()
	var compat: = compat_for(version)
	var r: = ReplayData.new()
	r.format_version = version
	r.compat = compat





	var meta_v: Variant = f.get_var()
	var slots_v: Variant = f.get_var()
	var events_v: Variant = f.get_var()
	r.meta = meta_v if meta_v is Dictionary else {}
	r.slots = (slots_v as Array).slice(0, MAX_SLOTS) if slots_v is Array else []
	r.events = (events_v as Array).slice(0, MAX_EVENTS) if events_v is Array else []
	for i in r.slots.size():
		if not (r.slots[i] is Dictionary):
			r.slots[i] = {}
	if compat == Compat.INCOMPATIBLE:



		f.close()
		return r
	var count: = f.get_32()
	if count < 0 or count > MAX_FRAME_FLOATS:
		f.close()
		return r
	var bytes: = f.get_buffer(count * 4)
	r.frames = bytes.to_float32_array()
	f.close()


	if r.stride() <= 0 or r.frames.size() % r.stride() != 0:
		r.frames.clear()
	if version == 5:
		r._upgrade_v5_frames()
	return r

func _upgrade_v5_frames() -> void :



	var old_stride: = HEAD_FLOATS + slots.size() * NET_PLAYER_FLOATS
	if old_stride <= 0 or frames.size() % old_stride != 0:
		frames.clear()
		return
	var old_count: = frames.size() / old_stride
	var upgraded: = PackedFloat32Array()
	upgraded.resize(old_count * stride())
	var write: = 0
	for frame_index in old_count:
		var read: = frame_index * old_stride
		for i in HEAD_FLOATS:
			upgraded[write] = frames[read + i]
			write += 1
		read += HEAD_FLOATS
		for slot_index in slots.size():
			for i in NET_PLAYER_FLOATS:
				upgraded[write] = frames[read + i]
				write += 1
			read += NET_PLAYER_FLOATS
			upgraded[write] = 0.0
			write += 1
	frames = upgraded

static func header_of(path: String) -> Dictionary:



	var f: = FileAccess.open_compressed(path, FileAccess.READ, 
		FileAccess.COMPRESSION_GZIP)
	if f == null:
		return {}
	if f.get_buffer(4).get_string_from_ascii() != MAGIC:
		return {}
	var version: = f.get_32()
	var mv: Variant = f.get_var()
	f.close()
	var m: Dictionary = mv if mv is Dictionary else {}
	m["_format_version"] = version
	m["_compat"] = compat_for(version)
	return m
