class_name AccessoryCatalog
extends RefCounted










const DIRS: = [
	"res://game/character/accessories/", 
	"res://game/character/hats/", 
]

static var _cache: Array = []
static var _scanned: = false

static func all() -> Array:
	if not _scanned:
		_scanned = true
		_cache = _scan()
	return _cache

static func for_category(category: String) -> Array:
	var out: Array = []
	for it in all():
		if it.category == category:
			out.append(it)
	return out

static func by_id(id: String) -> AccessoryItem:
	if id == "":
		return null
	for it in all():
		if it.id == id:
			return it
	return null

static func _scan() -> Array:
	var found: Array = []
	var seen: = {}
	for base in DIRS:
		var dir: = DirAccess.open(base)
		if dir == null:
			continue
		for f in dir.get_files():
			var path: = _res_path(base, String(f))
			if path == "" or seen.has(path):
				continue
			if not ResourceLoader.exists(path):
				continue
			var res: = load(path)
			if res is AccessoryItem:
				var item: = res as AccessoryItem
				if item.id == "":


					item.id = path.get_file().trim_suffix(".tres")
				seen[path] = true
				found.append(item)
	found.sort_custom( func(a, b): return a.id < b.id)
	return found


static func _res_path(base: String, file_name: String) -> String:
	var name: = file_name
	for wrapper in [".remap", ".import"]:
		if name.ends_with(wrapper):
			name = name.trim_suffix(wrapper)
			break
	if not name.ends_with(".tres"):
		return ""
	return base + name
