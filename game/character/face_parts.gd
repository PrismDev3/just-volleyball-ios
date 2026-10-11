class_name FaceParts










const DIR: = "res://game/character/faces"
const FEATURES: = ["eyes", "brows", "nose", "mouth"]

static var _cache: = {}
static var _thumbs: = {}
static var _centers: = {}

static func _scan(feature: String) -> Array:
	if _cache.has(feature):
		return _cache[feature]
	var names: = {}
	var d: = DirAccess.open("%s/%s" % [DIR, feature])
	if d != null:
		for entry in d.get_files():
			var file: = entry
			if file.ends_with(".import"):
				file = file.substr(0, file.length() - 7)
			if not file.to_lower().ends_with(".png"):
				continue
			var base: = file.get_basename()

			if base.ends_with("_iris") or base.ends_with("_fill"):
				continue
			names[base] = "%s/%s/%s" % [DIR, feature, file]
	var keys: Array = names.keys()
	keys.sort_custom( func(a, b): return _trailing_num(a) < _trailing_num(b))
	var out: Array = []
	for k in keys:
		out.append(names[k])
	_cache[feature] = out
	return out

static func _trailing_num(s: String) -> int:
	var re: = RegEx.new()
	re.compile("([0-9]+)$")
	var m: = re.search(s)
	return int(m.get_string(1)) if m != null else 0

static func options(feature: String) -> Array:
	return _scan(feature)

static func count(feature: String) -> int:
	return _scan(feature).size()

static func texture(feature: String, idx: int) -> Texture2D:
	var list: = _scan(feature)
	if idx < 0 or idx >= list.size():
		return null
	var p: String = list[idx]
	return load(p) as Texture2D if ResourceLoader.exists(p) else null


static func tint_texture(feature: String, idx: int) -> Texture2D:
	var list: = _scan(feature)
	if idx < 0 or idx >= list.size():
		return null
	var base: String = (list[idx] as String).get_basename()
	for suf in ["_iris", "_fill"]:
		var p: String = base + str(suf) + ".png"
		if ResourceLoader.exists(p):
			return load(p) as Texture2D
	return null



static func has_tint(feature: String) -> bool:
	for i in count(feature):
		if tint_texture(feature, i) != null:
			return true
	return false



static func thumb(feature: String, idx: int) -> Texture2D:
	var key: = "%s:%d" % [feature, idx]
	if _thumbs.has(key):
		return _thumbs[key]
	var base: = texture(feature, idx)
	if base == null:
		return null
	var img: = base.get_image()
	img.convert(Image.FORMAT_RGBA8)
	var used: = img.get_used_rect()
	var t: Texture2D = base
	if used.size.x > 0 and used.size.y > 0:
		t = ImageTexture.create_from_image(img.get_region(used))
	_thumbs[key] = t
	return t




static func used_center(feature: String, idx: int) -> Vector2:
	var key: = "%s:%d" % [feature, idx]
	if _centers.has(key):
		return _centers[key]
	var c: = Vector2(0.5, 0.5)
	var base: = texture(feature, idx)
	if base != null:
		var img: = base.get_image()
		img.convert(Image.FORMAT_RGBA8)
		var u: = img.get_used_rect()
		if u.size.x > 0 and u.size.y > 0:
			var ctr: = Vector2(u.position) + Vector2(u.size) * 0.5
			c = Vector2(ctr.x / img.get_width(), ctr.y / img.get_height())
	_centers[key] = c
	return c



static func right_half_center(feature: String, idx: int) -> Vector2:
	var key: = "%s:%d:r" % [feature, idx]
	if _centers.has(key):
		return _centers[key]
	var c: = Vector2(0.5, 0.45)
	var base: = texture(feature, idx)
	if base != null:
		var img: = base.get_image()
		img.convert(Image.FORMAT_RGBA8)
		var hw: = int(img.get_width() * 0.5)
		var region: = img.get_region(Rect2i(hw, 0, img.get_width() - hw, img.get_height()))
		var u: = region.get_used_rect()
		if u.size.x > 0 and u.size.y > 0:
			var ctr: = Vector2(u.position) + Vector2(u.size) * 0.5
			c = Vector2(ctr.x / region.get_width(), ctr.y / region.get_height())
	_centers[key] = c
	return c
