extends Node






















signal unlocked(def: AchievementDef, scope: String)
signal progressed(def: AchievementDef, value: int, scope: String)

const FILE: = "achievements.json"
const SAVE_DELAY: = 1.5
const SAVE_DELAY_QUIET: = 30.0
const DAY: = 86400

var _defs: Array = []
var _by_event: = {}
var _steam_done: = {}
var _dirty: = false
var _save_in: = 0.0
var _opened_for: = {}



signal unseen_changed(count: int)

func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	_defs = AchievementCatalog.all()
	for def in _defs:
		if not _by_event.has(def.event):
			_by_event[def.event] = []
		_by_event[def.event].append(def)
	_load_machine()
	if ProfileStore.has_signal("changed"):
		ProfileStore.changed.connect(_on_profile_changed)


	_boot.call_deferred()

func _boot() -> void :
	_reconcile_steam()
	_on_profile_changed()

func _process(delta: float) -> void :
	if _dirty:
		_save_in -= delta
		if _save_in <= 0.0:
			_flush()

func _exit_tree() -> void :
	_flush()



func notify(event: String, data: = {}) -> void :



	if LaunchGate.public_beta():
		return
	var p: SavedProfile = ProfileStore.active()
	if p == null or not _by_event.has(event):
		return
	var store: = _profile_store(p)
	_roll_periods(store)
	for def in _by_event[event]:
		var d: AchievementDef = def
		if not d.counts(data):
			continue
		var amount: = maxi(1, int(data.get("amount", 1)))
		var bucket: Dictionary = _bucket(store, d.kind)
		var row: Dictionary = bucket.get(d.id, {"v": 0, "done": false, "at": 0})
		if bool(row.get("done", false)):
			continue
		row["v"] = mini(int(row.get("v", 0)) + amount, d.target)
		var finished: = int(row["v"]) >= d.target
		if finished:
			row["done"] = true
			row["at"] = int(Time.get_unix_time_from_system())
		bucket[d.id] = row
		_mark_dirty(bool(data.get("quiet", false)) and not finished)
		if not finished:
			progressed.emit(d, int(row["v"]), d.kind if d.kind != "global" else "profile")
			continue
		match d.kind:
			"global":
				unlocked.emit(d, "profile")
				if not _steam_done.has(d.id):
					_earn_machine(d)
			_:
				if d.coins > 0:
					Progression.add_coins(d.coins)
				unlocked.emit(d, d.kind)
		_add_unseen(store, d.id)



func _add_unseen(store: Dictionary, id: String) -> void :
	var list: Array = store.get("unseen", [])
	if not id in list:
		list.append(id)
	store["unseen"] = list
	unseen_changed.emit(list.size())


func unseen_ids() -> Array:
	var p: SavedProfile = ProfileStore.active()
	if p == null:
		return []
	return (_profile_store(p).get("unseen", []) as Array).duplicate()

func unseen_count() -> int:
	var p: SavedProfile = ProfileStore.active()
	if p == null:
		return 0
	return (_profile_store(p).get("unseen", []) as Array).size()


func mark_seen(id: String) -> void :
	var p: SavedProfile = ProfileStore.active()
	if p == null:
		return
	var store: = _profile_store(p)
	var list: Array = store.get("unseen", [])
	if not id in list:
		return
	list.erase(id)
	store["unseen"] = list
	_mark_dirty()
	unseen_changed.emit(list.size())


func unseen_count_for(kind: String) -> int:
	var n: = 0
	var ids: = unseen_ids()
	for d in _defs:
		if d.kind == kind and d.id in ids:
			n += 1
	return n


func mark_all_seen() -> void :
	var p: SavedProfile = ProfileStore.active()
	if p == null:
		return
	var store: = _profile_store(p)
	if (store.get("unseen", []) as Array).is_empty():
		return
	store["unseen"] = []
	_mark_dirty()
	unseen_changed.emit(0)



func defs(kind: = "") -> Array:
	if kind == "":
		return _defs.duplicate()
	var out: Array = []
	for d in _defs:
		if d.kind == kind:
			out.append(d)
	return out


func progress(def: AchievementDef) -> Dictionary:
	var p: SavedProfile = ProfileStore.active()
	if p == null:
		return {"v": 0, "done": false, "at": 0, "target": def.target}
	var store: = _profile_store(p)
	_roll_periods(store)
	var row: Dictionary = _bucket(store, def.kind).get(def.id, {"v": 0, "done": false, "at": 0})
	return {"v": int(row.get("v", 0)), "done": bool(row.get("done", false)), 
		"at": int(row.get("at", 0)), "target": def.target}


func machine_done(def: AchievementDef) -> bool:
	return _steam_done.has(def.id)

func machine_done_at(def: AchievementDef) -> int:
	return int(_steam_done.get(def.id, 0))


func period_left(kind: String) -> int:
	var now: = int(Time.get_unix_time_from_system())
	match kind:
		"daily":
			return _day_end(now) - now
		"weekly":
			return _week_end(now) - now
	return 0

func is_steam_live() -> bool:
	return Net.steam_achievements_available()



func _profile_store(p: SavedProfile) -> Dictionary:
	if not (p.achievements is Dictionary):
		p.achievements = {}
	var s: Dictionary = p.achievements
	if not s.has("global"):
		s["global"] = {}
	if not s.has("daily"):
		s["daily"] = {"key": "", "p": {}}
	if not s.has("weekly"):
		s["weekly"] = {"key": "", "p": {}}
	return s

func _bucket(store: Dictionary, kind: String) -> Dictionary:
	match kind:
		"daily":
			return store["daily"]["p"]
		"weekly":
			return store["weekly"]["p"]
	return store["global"]



func _roll_periods(store: Dictionary) -> void :
	var now: = int(Time.get_unix_time_from_system())
	var dk: = _day_key(now)
	if String(store["daily"].get("key", "")) != dk:
		_forget_unseen(store, store["daily"].get("p", {}))
		store["daily"] = {"key": dk, "p": {}}
		_mark_dirty()
	var wk: = _week_key(now)
	if String(store["weekly"].get("key", "")) != wk:
		_forget_unseen(store, store["weekly"].get("p", {}))
		store["weekly"] = {"key": wk, "p": {}}
		_mark_dirty()



func _forget_unseen(store: Dictionary, bucket: Variant) -> void :
	if not (bucket is Dictionary) or not store.has("unseen"):
		return
	var list: Array = store["unseen"]
	for id in (bucket as Dictionary).keys():
		list.erase(id)
	store["unseen"] = list

func _mark_dirty(quiet: = false) -> void :

	if not _dirty:
		_save_in = SAVE_DELAY_QUIET if quiet else SAVE_DELAY
	elif not quiet:
		_save_in = minf(_save_in, SAVE_DELAY)
	_dirty = true

func _flush() -> void :
	if not _dirty:
		return
	_dirty = false
	ProfileStore.save()

func _on_profile_changed() -> void :



	var p: SavedProfile = ProfileStore.active()
	if p == null:
		return
	var key: = p.get_instance_id()
	if _opened_for.has(key):
		return
	_opened_for[key] = true
	notify("opened")



func _day_key(now: int) -> String:
	var d: = Time.get_datetime_dict_from_unix_time(now + _tz_offset())
	return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]

func _week_key(now: int) -> String:
	return _day_key(_week_start(now))

func _week_start(now: int) -> int:
	var local: = now + _tz_offset()
	var d: = Time.get_datetime_dict_from_unix_time(local)

	var since_monday: = (int(d.weekday) + 6) % 7
	var midnight: = local - (local % DAY)
	return midnight - since_monday * DAY - _tz_offset()

func _day_end(now: int) -> int:
	var local: = now + _tz_offset()
	var midnight: = local - (local % DAY)
	return midnight + DAY - _tz_offset()

func _week_end(now: int) -> int:
	return _week_start(now) + 7 * DAY

func _tz_offset() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60



func _earn_machine(def: AchievementDef) -> void :
	_steam_done[def.id] = int(Time.get_unix_time_from_system())
	_save_machine()
	unlocked.emit(def, "global")
	Net.steam_set_achievement(def.steam)



func _reconcile_steam() -> void :
	if not Net.steam_achievements_available():
		return
	var changed: = false
	for def in _defs:
		var d: AchievementDef = def
		if d.kind != "global" or d.steam == "":
			continue
		var on_steam: = Net.steam_has_achievement(d.steam)
		if _steam_done.has(d.id) and not on_steam:
			Net.steam_set_achievement(d.steam)
		elif on_steam and not _steam_done.has(d.id):
			_steam_done[d.id] = int(Time.get_unix_time_from_system())
			changed = true
	if changed:
		_save_machine()

func _load_machine() -> void :
	var path: = AppData.path(FILE)
	if not FileAccess.file_exists(path):
		return
	var f: = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		return
	var done: Variant = parsed.get("steam", {})
	if done is Dictionary:
		for k in done:
			_steam_done[String(k)] = int(done[k])

func _save_machine() -> void :
	AppData.ensure()
	var f: = FileAccess.open(AppData.path(FILE), FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"version": 1, "steam": _steam_done}))
