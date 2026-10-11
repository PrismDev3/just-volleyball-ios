class_name CpuSlots





















const DIFF_NAMES: = ["easy", "normal", "hard"]
const DIFF_CUSTOM: = -1
const DIFF_NONE: = -2
const NAME_MAX: = 24

static func id_for(side: int, k: int) -> String:
	return "%s%d" % ["h" if side > 0 else "a", k]

static func valid(e: Variant) -> bool:
	if not (e is Dictionary):
		return false
	var d: Dictionary = e
	return d.has("side") and d.has("k") and d.has("cfg") and d.has("diff")\
	and d.has("name") and (int(d.side) == 1 or int(d.side) == -1)\
	and int(d.k) >= 0 and int(d.k) < 6 and d.cfg is Dictionary\
	and not (d.cfg as Dictionary).is_empty()\
	and int(d.diff) >= 0 and int(d.diff) < DIFF_NAMES.size()\
	and String(d.name) != ""


static func lookup(slots: Dictionary, side: int, k: int) -> Dictionary:
	var e: Variant = slots.get(id_for(side, k), null)
	return e if valid(e) else {}





static func reconcile(slots: Dictionary, team_size: int, humans: Dictionary, 
		default_diff: int) -> bool:
	var changed: = false
	var want: = {}
	for side in [1, -1]:
		var fill: int = maxi(team_size - int(humans.get(side, 0)), 0)
		for k in fill:
			want[id_for(side, k)] = [side, k]
	for id in slots.keys():
		if not want.has(id) or not valid(slots[id]):
			slots.erase(id)
			changed = true
	for id in want:
		if slots.has(id):
			continue
		var pair: Array = want[id]
		slots[id] = make(int(pair[0]), int(pair[1]), default_diff, used_names(slots))
		changed = true
	return changed

static func used_names(slots: Dictionary) -> Array:
	var out: Array = []
	for id in slots:
		if valid(slots[id]):
			out.append(String(slots[id].name))
	return out



static func make(side: int, k: int, diff: int, taken: Array) -> Dictionary:
	var rng: = RandomNumberGenerator.new()
	rng.randomize()
	var pool: Array = CpuNames.shuffled(rng.randi())
	var name: = ""
	for raw in pool:
		if not taken.has(String(raw)):
			name = String(raw)
			break
	if name == "":
		name = "cpu %d" % (k + 1)
	return {"side": side, "k": k, "name": name.left(NAME_MAX), 
		"cfg": CharacterConfig.random(rng).to_dict(), 
		"diff": clampi(diff, 0, DIFF_NAMES.size() - 1)}


static func reroll(slots: Dictionary, id: String) -> void :
	if not slots.has(id) or not valid(slots[id]):
		return
	var old: Dictionary = slots[id]


	var taken: = used_names(slots)
	slots[id] = make(int(old.side), int(old.k), int(old.diff), taken)



static func global_diff(slots: Dictionary) -> int:
	var seen: = -1
	for id in slots:
		if not valid(slots[id]):
			continue
		var d: = int(slots[id].diff)
		if seen == -1:
			seen = d
		elif d != seen:
			return DIFF_CUSTOM
	return DIFF_NONE if seen == -1 else seen

static func set_all_diff(slots: Dictionary, diff: int) -> void :
	for id in slots:
		if valid(slots[id]):
			slots[id]["diff"] = clampi(diff, 0, DIFF_NAMES.size() - 1)

static func set_diff(slots: Dictionary, id: String, diff: int) -> void :
	if slots.has(id) and valid(slots[id]):
		slots[id]["diff"] = clampi(diff, 0, DIFF_NAMES.size() - 1)

static func diff_name(diff: int) -> String:
	if diff == DIFF_CUSTOM:
		return "custom"
	if diff < 0 or diff >= DIFF_NAMES.size():
		return "none"
	return DIFF_NAMES[diff]



static func sanitize(raw: Variant) -> Dictionary:
	var out: = {}


	if not (raw is Dictionary) or (raw as Dictionary).size() > 32:
		return out
	for id in raw:
		var e: Variant = raw[id]
		if not (e is Dictionary):
			continue
		var d: Dictionary = e
		if not d.has("side") or not d.has("k") or not d.has("cfg"):
			continue
		var side: = int(d.side)
		var k: = int(d.k)
		if (side != 1 and side != -1) or k < 0 or k >= 6:
			continue
		if String(id) != id_for(side, k):
			continue
		if not (d.cfg is Dictionary):
			continue
		out[String(id)] = {"side": side, "k": k, 
			"name": String(d.get("name", "cpu")).left(NAME_MAX), 
			"cfg": CharacterConfig.sanitize_dict(d.cfg), 
			"diff": clampi(int(d.get("diff", 1)), 0, DIFF_NAMES.size() - 1)}
		if not valid(out[String(id)]):
			out.erase(String(id))
	return out


static func ordered(slots: Dictionary, side: int) -> Array:
	var out: Array = []
	var k: = 0
	while slots.has(id_for(side, k)):
		if valid(slots[id_for(side, k)]):
			out.append(slots[id_for(side, k)])
		k += 1
	return out
