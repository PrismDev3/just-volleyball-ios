class_name CpuNames
extends RefCounted









const MASTER_PATH: = "res://game/data/cpu_names/cpu_name_master.txt"



const FALLBACK: = ["Ace", "Bolt", "Comet", "Dash", "Echo", "Fox", "Ghost", 
	"Hawk", "Jet", "Nova", "Onyx", "Rocket", "Sky", "Vex", "Wolf", "Zane"]


static func master() -> Array:
	var out: Array = []
	if FileAccess.file_exists(MASTER_PATH):
		var f: = FileAccess.open(MASTER_PATH, FileAccess.READ)
		if f != null:
			while not f.eof_reached():
				var line: = f.get_line().strip_edges()
				if line != "":
					out.append(line)
	if out.is_empty():
		return FALLBACK.duplicate()
	return out



static func shuffled(seed_val: int) -> Array:
	var rng: = RandomNumberGenerator.new()
	rng.seed = seed_val
	var arr: = master()

	for i in range(arr.size() - 1, 0, -1):
		var j: = rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t
	return arr
