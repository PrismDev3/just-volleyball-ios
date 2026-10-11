class_name CharacterConfig
extends RefCounted







const SKIN_TONES: Array[Color] = [
	Color(0.99, 0.95, 0.9), Color(0.98, 0.92, 0.84), Color(1.0, 0.87, 0.73), 
	Color(0.96, 0.8, 0.63), Color(0.9, 0.71, 0.52), Color(0.8, 0.6, 0.42), 
	Color(0.66, 0.47, 0.32), Color(0.52, 0.36, 0.24), Color(0.4, 0.27, 0.18), 
	Color(0.28, 0.19, 0.13), 
]
const HAIR_COLORS: Array[Color] = [
	Color(0.13, 0.1, 0.08), Color(0.28, 0.19, 0.11), Color(0.48, 0.32, 0.15), 
	Color(0.72, 0.55, 0.26), Color(0.87, 0.79, 0.55), Color(0.55, 0.09, 0.06), 
	Color(0.35, 0.35, 0.38), Color(0.88, 0.88, 0.9), Color(0.24, 0.35, 0.65), 
	Color(0.55, 0.25, 0.6), Color(0.85, 0.45, 0.65), Color(0.2, 0.55, 0.4), 
]







const HAIR_DIR: = "res://game/character/hair"
static var _hair_cache: Array[String] = []
















static func hair_style_from_file(file_name: String) -> String:
	var base: = file_name
	for wrapper in [".remap", ".import"]:
		if base.ends_with(wrapper):
			base = base.trim_suffix(wrapper)
			break
	if not base.ends_with(".blend"):
		return ""
	return base.trim_suffix(".blend")

static func hair_meshes() -> Array[String]:


	if not _hair_cache.is_empty():
		return _hair_cache
	var found: Array[String] = []
	var dir: = DirAccess.open(HAIR_DIR)
	if dir != null:
		for f in dir.get_files():
			var style: = hair_style_from_file(String(f))
			if style != "" and not found.has(style):
				found.append(style)
		found.sort()
	_hair_cache = ([""] as Array[String]) + found
	return _hair_cache

static func hair_names() -> Array[String]:

	var out: Array[String] = ["bald"]
	var list: = hair_meshes()
	for i in range(1, list.size()):
		out.append(list[i].replace("_", " "))
	return out




static func hair_styles() -> int:
	return hair_meshes().size()
const EYE_SHAPES: = 4
const BROW_SHAPES: = 3
const MOUTH_SHAPES: = 5
const NOSE_SHAPES: = 3

const FACE_TYPES: = 2



const HEAD_SHAPES: Array[String] = ["", "sharp", "square", "round"]
const HEAD_SHAPE_NAMES: Array[String] = ["default", "sharp", "square", "round"]


const SHORTS_SHAPES: Array[String] = ["", "short", "long", "supershort"]
const SHORTS_SHAPE_NAMES: Array[String] = ["regular", "short", "long", "super short"]


const SOCKS_SHAPES: Array[String] = ["Short", ""]
const SOCKS_SHAPE_NAMES: Array[String] = ["short", "long"]



const SHIRT_SHAPES: Array[String] = ["", "tanktop", "sports bra"]
const SHIRT_SHAPE_NAMES: Array[String] = ["tee", "tank top", "sports bra"]




const BLUSH_SHAPES: Array[String] = ["circle", "dashes", "band", "freckles"]
const BLUSH_SHAPE_NAMES: Array[String] = ["circle", "dashes", "band", "freckles"]

static func blush_shape_key(i: int) -> String:
	return BLUSH_SHAPES[clampi(i, 0, BLUSH_SHAPES.size() - 1)]


const VOICE_PITCH: Array[float] = [0.78, 0.92, 1.0, 1.12, 1.3]
const VOICE_NAMES: Array[String] = ["rough", "low", "regular", "high", "squeaky"]

var display_name: = ""
var face: = 0
var skin: = 0
var height: = 0.5
var weight: = 0.5
var hair: = 1
var hair_flip: = false
var hair_color_idx: = 0
var hair_col: = HAIR_COLORS[0]






var hair_cols: Array = []



var hair_grads: Array = []
var eye_shape: = 0
var eye_color: = Color(0.15, 0.25, 0.45)
var eye_size: = 0.5
var eye_width: = 0.5
var eye_size_y: = 0.5
var eye_height: = 0.5
var eye_spacing: = 0.5
var eye_rot: = 0.5
var eye_x: = 0.5
var brow_shape: = 0
var brow_height: = 0.5
var brow_rot: = 0.5
var brow_spacing: = 0.5
var brow_size: = 0.5
var brow_width: = 0.5
var brow_size_y: = 0.5
var brow_x: = 0.5
var mouth_shape: = 0
var mouth_size: = 0.5
var mouth_width: = 0.5
var mouth_size_y: = 0.5
var mouth_height: = 0.5
var mouth_rot: = 0.5
var mouth_x: = 0.5
var nose_shape: = 0
var nose_size: = 0.5
var nose_width: = 0.5
var nose_size_y: = 0.5
var nose_height: = 0.5
var nose_x: = 0.5
var nose_flip: = false
var blush: = false


var blush_shape: = 0
var blush_color: = Color(0.96, 0.52, 0.52)
var blush_size: = 0.5
var blush_width: = 0.5
var blush_height: = 0.5
var blush_spacing: = 0.5
var blush_opacity: = 0.5
var head_shape: = 0
var shorts_len: = 0
var socks_len: = 0
var gym_shirt: = 0
var voice: = 2



var v_pitch: = 0.5
var v_speed: = 0.5



var voice_pack: = 1




const VOICE_PACK_COUNT: = 1


var left_handed: = false
const KIT_BLACK: = Color(0.09, 0.09, 0.11)

var kit_home: Array = [Color(0.3, 0.55, 0.95), KIT_BLACK, Color.WHITE]
var kit_away: Array = [Color(0.88, 0.3, 0.26), KIT_BLACK, Color.WHITE]
var kneepad: = KIT_BLACK
var socks: = KIT_BLACK
var shoe_color: = KIT_BLACK
var number: = 1

const ACC_SLOTS: = ["head", "face", "extra"]






var accessories: Dictionary = {}







var gym_tee: = Color(0.93, 0.92, 0.89)
var gym_shorts: = Color(0.38, 0.56, 0.84)



var wear_socks: = true
var wear_kneepads: = true



var casual: = false





var wear_pinny: = false
var pinny_color: = Color(0.55, 0.85, 0.72)
var pinny_accent: = Color(0.1, 0.11, 0.14)


const GYM_TEE_COLORS: Array[Color] = [
	Color(0.93, 0.92, 0.89), Color(0.82, 0.82, 0.84), Color(0.25, 0.26, 0.3), 
	Color(0.3, 0.45, 0.8), Color(0.75, 0.28, 0.26), Color(0.32, 0.55, 0.38), 
	Color(0.88, 0.75, 0.35), Color(0.55, 0.38, 0.65), 
]
const GYM_SHORT_COLORS: Array[Color] = [
	Color(0.2, 0.21, 0.24), Color(0.93, 0.92, 0.89), Color(0.36, 0.42, 0.52), 
	Color(0.62, 0.78, 0.88), Color(0.42, 0.3, 0.26), Color(0.3, 0.45, 0.8), 
]




func gym_kit() -> Array:
	return [gym_tee, gym_shorts, gym_tee]



func gym_look() -> CharacterConfig:
	var c: = CharacterConfig.from_dict(to_dict())
	c.casual = true
	return c

func voice_pitch() -> float:

	var base: = lerpf(0.78, 1.3, clampf(v_pitch, 0.0, 1.0))
	var spd: = lerpf(0.85, 1.18, clampf(v_speed, 0.0, 1.0))
	return base * spd

func skin_tone() -> Color:
	return SKIN_TONES[clampi(skin, 0, SKIN_TONES.size() - 1)]

func hair_style_name() -> String:
	var list: = hair_meshes()
	return list[clampi(hair, 0, list.size() - 1)]



static func hair_index_of(value: Variant) -> int:
	var list: = hair_meshes()
	if value is String:
		var i: = list.find(String(value))
		return i if i >= 0 else 0
	return clampi(int(value), 0, list.size() - 1)

static var _hair_slot_cache: = {}





static func hair_slot_defaults(style: int) -> Array:
	if _hair_slot_cache.has(style):
		return _hair_slot_cache[style]
	var out: Array = []
	var list: = hair_meshes()
	if style > 0 and style < list.size():
		var path: = "%s/%s.blend" % [HAIR_DIR, list[style]]
		if ResourceLoader.exists(path):
			var root: Node = (load(path) as PackedScene).instantiate()
			for g in AccessoryItem.build_groups(root):
				out.append(AccessoryItem._albedo_of(g["src"]))
			root.free()
	_hair_slot_cache[style] = out
	return out

func hair_color() -> Color:

	return hair_color_at(0, hair_col)








func hair_color_at(i: int, _fallback: Color) -> Color:
	if i >= 0 and i < hair_cols.size() and String(hair_cols[i]) != "":
		return Color.html(str(hair_cols[i]))
	return hair_col

func set_hair_color_at(i: int, color: Color) -> void :
	while hair_cols.size() <= i:
		hair_cols.append("")
	hair_cols[i] = color.to_html(false)
	if i == 0:
		hair_col = color


func _hair_grad(i: int) -> Dictionary:
	if i >= 0 and i < hair_grads.size() and hair_grads[i] is Dictionary:
		return hair_grads[i]
	return {}

func _hair_grad_slot(i: int) -> Dictionary:
	while hair_grads.size() <= i:
		hair_grads.append({})
	if not (hair_grads[i] is Dictionary):
		hair_grads[i] = {}
	return hair_grads[i]

func hair_gradient_on(i: int) -> bool:
	return bool(_hair_grad(i).get("on", false))

func set_hair_gradient_on(i: int, on: bool) -> void :
	_hair_grad_slot(i)["on"] = on

func hair_gradient_bottom(i: int, fallback: Color) -> Color:
	var b: = String(_hair_grad(i).get("b", ""))
	return Color.html(b) if b != "" else fallback

func set_hair_gradient_bottom(i: int, color: Color) -> void :
	_hair_grad_slot(i)["b"] = color.to_html(false)



func hair_gradient_fade(i: int) -> Vector2:
	var g: = _hair_grad(i)
	return Vector2(float(g.get("fs", 0.0)), float(g.get("fe", 1.0)))

func set_hair_gradient_fade(i: int, start: float, end: float) -> void :
	var g: = _hair_grad_slot(i)
	g["fs"] = clampf(start, 0.0, 1.0)
	g["fe"] = clampf(end, 0.0, 1.0)

func to_dict() -> Dictionary:
	return {
		"name": display_name, "face": face, "skin": skin, "h": height, "w": weight, 



		"hair": hair_style_name(), "hc": hair_color_idx, "hfl": hair_flip, 
		"hcol": hair_col.to_html(false), 
		"hcols": hair_cols.duplicate(), 
		"hgrad": hair_grads.duplicate(true), 
		"vp": v_pitch, "vs": v_speed, "lh": left_handed, 
		"es": eye_shape, "ec": eye_color.to_html(false), "ez": eye_size, 
		"ew": eye_width, "eyz": eye_size_y, "eh": eye_height, 
		"ex": eye_spacing, "er": eye_rot, "epx": eye_x, 
		"bs": brow_shape, "bh": brow_height, "br": brow_rot, 
		"bsp": brow_spacing, "bsz": brow_size, "bwid": brow_width, 
		"bht": brow_size_y, "bpx": brow_x, 
		"ms": mouth_shape, "mz": mouth_size, "mw": mouth_width, 
		"my": mouth_size_y, "mh": mouth_height, "mr": mouth_rot, "mpx": mouth_x, 
		"ns": nose_shape, "nz": nose_size, "nw": nose_width, 
		"ny": nose_size_y, "nh": nose_height, "nx": nose_x, "nfl": nose_flip, 
		"bz": blush_size, "bw": blush_width, "bhy": blush_height, "bx": blush_spacing, 
		"bo": blush_opacity, "bl": blush, "blsh": blush_shape, 
		"blc": blush_color.to_html(false), 
		"hs": head_shape, "sl": shorts_len, "skl": socks_len, "vo": voice, 
		"vpk": voice_pack, 
		"num": number, 
		"kp": kneepad.to_html(false), "sk": socks.to_html(false), 
		"sh": shoe_color.to_html(false), 
		"kh": kit_home.map( func(c): return (c as Color).to_html(false)), 
		"ka": kit_away.map( func(c): return (c as Color).to_html(false)), 


		"gt": gym_tee.to_html(false), "gs": gym_shorts.to_html(false), 
		"gsh": gym_shirt, 

		"gso": wear_socks, "gkp": wear_kneepads, 


		"acc": accessories.duplicate(true), 
	}







static func _unit(d: Dictionary, key: String, def: float) -> float:
	var v: = float(d.get(key, def))
	return clampf(v, 0.0, 1.0) if is_finite(v) else def







const INT_BOUNDS: = {"face": 63, "skin": 15, "hc": 11, "es": EYE_SHAPES - 1, 
	"bs": BROW_SHAPES - 1, "ms": MOUTH_SHAPES - 1, "ns": NOSE_SHAPES - 1, 
	"blsh": 3, "hs": 3, "sl": 3, "skl": 1, 
	"vo": 4, "num": 99, "gsh": 15, "vpk": VOICE_PACK_COUNT}
const BOOL_KEYS: = ["nfl", "hfl", "bl", "lh", "gso", "gkp"]
const COLOR_KEYS: = ["hcol", "ec", "blc", "sk", "kp", "sh", "gt", "gs"]
const UNIT_KEYS: = ["h", "w", "ez", "ew", "eyz", "eh", "ex", "er", "epx", "bh", "br", 
	"bsp", "bsz", "bwid", "bht", "bpx", "mz", "mw", "my", "mh", "mr", "mpx", "nz", 
	"nw", "ny", "nh", "nx", "bz", "bw", "bhy", "bx", "bo", "vp", "vs"]
const ACC_MAX_SLOTS: = 8
const ACC_MAX_KEYS: = 16
const ACC_MAX_COLORS: = 8
const HAIR_MAX_SLOTS: = 8





const FACE_PART_KEYS: = {"es": "eyes", "bs": "brows", "ms": "mouth", "ns": "nose"}
static func _int_bound(k: String) -> int:
	var hi: = int(INT_BOUNDS[k])
	if FACE_PART_KEYS.has(k):
		hi = maxi(hi, FaceParts.count(FACE_PART_KEYS[k]) - 1)
	return hi




const NONEABLE_INT_KEYS: = ["bs", "ns"]




static func _scalar_int(v: Variant, hi: int, lo: = 0) -> int:
	if v is int:
		return clampi(v, lo, hi)
	if v is float and is_finite(v):
		return clampi(int(v), lo, hi)
	return lo - 1

static func sanitize_dict(d: Dictionary) -> Dictionary:
	var out: = {}
	var name: Variant = d.get("name", "")
	if name is String:
		out["name"] = (name as String).substr(0, 24)
	for k in INT_BOUNDS:
		if d.has(k):
			var lo: = -1 if NONEABLE_INT_KEYS.has(k) else 0
			var iv: = _scalar_int(d[k], _int_bound(k), lo)
			if iv >= lo:
				out[k] = iv
	var hair: Variant = d.get("hair", 1)
	if hair is int or hair is float or hair is String:
		out["hair"] = hair_index_of(hair)
	for k in BOOL_KEYS:
		if d.has(k) and d[k] is bool:
			out[k] = d[k]
	for k in UNIT_KEYS:
		if d.has(k):
			var v: Variant = d[k]
			if v is float or v is int:
				var f: = float(v)
				if is_finite(f):
					out[k] = clampf(f, 0.0, 1.0)
	for k in COLOR_KEYS:
		if d.has(k) and d[k] is String and Color.html_is_valid(d[k]):
			out[k] = d[k]

	var hcols: Variant = d.get("hcols")
	if hcols is Array:
		var clean_h: Array = []
		for v in (hcols as Array):
			if clean_h.size() >= HAIR_MAX_SLOTS:
				break
			if v is String and (String(v) == "" or Color.html_is_valid(v)):
				clean_h.append(String(v))
			else:
				clean_h.append("")
		out["hcols"] = clean_h

	var hgrad: Variant = d.get("hgrad")
	if hgrad is Array:
		var clean_g: Array = []
		for v in (hgrad as Array):
			if clean_g.size() >= HAIR_MAX_SLOTS:
				break
			var g: = {}
			if v is Dictionary:
				var src: = v as Dictionary
				if src.get("on") is bool:
					g["on"] = src["on"]
				if src.get("b") is String and Color.html_is_valid(src["b"]):
					g["b"] = String(src["b"])
				for fk in ["fs", "fe"]:
					var fv: Variant = src.get(fk)
					if (fv is float or fv is int) and is_finite(float(fv)):
						g[fk] = clampf(float(fv), 0.0, 1.0)
			clean_g.append(g)
		out["hgrad"] = clean_g
	for k in ["kh", "ka"]:
		var arr: Variant = d.get(k)
		if arr is Array and (arr as Array).size() == 3:
			var ok: = true
			for c in arr:
				ok = ok and c is String and Color.html_is_valid(c)
			if ok:
				out[k] = (arr as Array).duplicate()
	var acc: Variant = d.get("acc", {})
	if acc is Dictionary:
		var clean: = {}
		for slot in acc:
			if clean.size() >= ACC_MAX_SLOTS:
				break
			var st: Variant = acc[slot]
			if not (slot is String) or not (st is Dictionary) or (slot as String).length() > 24:
				continue
			var cs: = {}
			for key in st:
				if cs.size() >= ACC_MAX_KEYS:
					break
				var v: Variant = st[key]
				if not (key is String) or (key as String).length() > 24:
					continue

				if key == "cols" and v is Array:
					var cc: Array = []
					for e in (v as Array):
						if cc.size() >= ACC_MAX_COLORS:
							break
						if e is String and (String(e) == "" or Color.html_is_valid(e)):
							cc.append(String(e))
						else:
							cc.append("")
					cs["cols"] = cc
					continue

				if key == "grads" and v is Array:
					var gg: Array = []
					for e in (v as Array):
						if gg.size() >= ACC_MAX_COLORS:
							break
						var g: = {}
						if e is Dictionary:
							var src: = e as Dictionary
							if src.get("on") is bool:
								g["on"] = src["on"]
							if src.get("b") is String and Color.html_is_valid(src["b"]):
								g["b"] = String(src["b"])
							for fk in ["fs", "fe"]:
								var fv: Variant = src.get(fk)
								if (fv is float or fv is int) and is_finite(float(fv)):
									g[fk] = clampf(float(fv), 0.0, 1.0)
						gg.append(g)
					cs["grads"] = gg
					continue
				if v is String:
					cs[key] = (v as String).substr(0, 48)
				elif (v is float and is_finite(v)) or v is int or v is bool:
					cs[key] = v
			clean[slot] = cs
		out["acc"] = clean
	return out

static func from_dict(raw: Dictionary) -> CharacterConfig:
	var d: = sanitize_dict(raw)
	var c: = CharacterConfig.new()
	c.display_name = d.get("name", "")
	c.face = int(d.get("face", 0))
	c.skin = int(d.get("skin", 0))
	c.height = _unit(d, "h", 0.5)
	c.weight = _unit(d, "w", 0.5)
	c.hair = hair_index_of(d.get("hair", 1))
	c.hair_flip = bool(d.get("hfl", false))
	c.hair_color_idx = int(d.get("hc", 0))

	if d.has("hcol"):
		c.hair_col = Color.html(str(d["hcol"]))
	else:
		c.hair_col = HAIR_COLORS[clampi(c.hair_color_idx, 0, HAIR_COLORS.size() - 1)]


	if d.has("hcols") and d["hcols"] is Array:
		c.hair_cols = (d["hcols"] as Array).duplicate()
	if d.has("hgrad") and d["hgrad"] is Array:
		c.hair_grads = (d["hgrad"] as Array).duplicate(true)
	c.eye_shape = int(d.get("es", 0))
	c.eye_color = Color.html(str(d.get("ec", "26406f")))
	c.eye_size = _unit(d, "ez", 0.5)
	c.eye_width = _unit(d, "ew", c.eye_size)
	c.eye_size_y = _unit(d, "eyz", c.eye_size)
	c.eye_height = _unit(d, "eh", 0.5)
	c.eye_spacing = _unit(d, "ex", 0.5)
	c.eye_rot = _unit(d, "er", 0.5)
	c.eye_x = _unit(d, "epx", 0.5)
	c.brow_shape = int(d.get("bs", 0))
	c.brow_height = _unit(d, "bh", 0.5)
	c.brow_rot = _unit(d, "br", 0.5)
	c.brow_spacing = _unit(d, "bsp", 0.5)
	c.brow_size = _unit(d, "bsz", 0.5)
	c.brow_width = _unit(d, "bwid", c.brow_size)
	c.brow_size_y = _unit(d, "bht", c.brow_size)
	c.brow_x = _unit(d, "bpx", 0.5)
	c.mouth_shape = int(d.get("ms", 0))
	c.mouth_size = _unit(d, "mz", 0.5)
	c.mouth_width = _unit(d, "mw", c.mouth_size)
	c.mouth_size_y = _unit(d, "my", c.mouth_size)
	c.mouth_height = _unit(d, "mh", 0.5)
	c.mouth_rot = _unit(d, "mr", 0.5)
	c.mouth_x = _unit(d, "mpx", 0.5)
	c.nose_shape = int(d.get("ns", 0))
	c.nose_size = _unit(d, "nz", 0.5)
	c.nose_width = _unit(d, "nw", c.nose_size)
	c.nose_size_y = _unit(d, "ny", c.nose_size)
	c.nose_height = _unit(d, "nh", 0.5)
	c.nose_x = _unit(d, "nx", 0.5)
	c.nose_flip = bool(d.get("nfl", false))
	c.blush_size = _unit(d, "bz", 0.5)
	c.blush_width = _unit(d, "bw", 0.5)
	c.blush_height = _unit(d, "bhy", 0.5)
	c.blush_spacing = _unit(d, "bx", 0.5)
	c.blush_opacity = _unit(d, "bo", 0.5)
	c.blush = bool(d.get("bl", false))
	c.blush_shape = int(d.get("blsh", 0))
	c.blush_color = Color.html(str(d.get("blc", "f58585")))
	c.head_shape = int(d.get("hs", 0))
	c.shorts_len = int(d.get("sl", 0))
	c.socks_len = int(d.get("skl", 0))
	c.voice = int(d.get("vo", 2))

	if d.has("vp"):
		c.v_pitch = _unit(d, "vp", 0.5)
	else:
		var preset: = VOICE_PITCH[clampi(c.voice, 0, VOICE_PITCH.size() - 1)]
		c.v_pitch = clampf(inverse_lerp(0.78, 1.3, preset), 0.0, 1.0)
	c.v_speed = _unit(d, "vs", 0.5)


	c.voice_pack = clampi(int(d.get("vpk", 1)), 1, VOICE_PACK_COUNT)
	c.left_handed = bool(d.get("lh", false))
	c.socks = Color.html(str(d.get("sk", "17171c")))
	c.number = int(d.get("num", 1))
	c.kneepad = Color.html(str(d.get("kp", "17171c")))
	c.shoe_color = Color.html(str(d.get("sh", "17171c")))
	var kh: Array = d.get("kh", [])
	var ka: Array = d.get("ka", [])
	if kh.size() == 3:
		c.kit_home = kh.map( func(s): return Color.html(str(s)))
	if ka.size() == 3:
		c.kit_away = ka.map( func(s): return Color.html(str(s)))
	c.gym_tee = Color.html(str(d.get("gt", "ecebe3")))
	c.gym_shorts = Color.html(str(d.get("gs", "618fd6")))
	c.gym_shirt = int(d.get("gsh", 0))
	c.wear_socks = bool(d.get("gso", true))
	c.wear_kneepads = bool(d.get("gkp", true))
	var acc = d.get("acc", {})
	if acc is Dictionary:


		c.accessories = (acc as Dictionary).duplicate(true)
	return c




func acc_slot(slot: String) -> Dictionary:
	if not accessories.has(slot):
		accessories[slot] = {}
	return accessories[slot]

func acc_id(slot: String) -> String:
	return String((accessories.get(slot, {}) as Dictionary).get("id", ""))

func set_acc_id(slot: String, id: String) -> void :
	if id == "":
		accessories.erase(slot)
		return
	var st: = acc_slot(slot)
	if String(st.get("id", "")) != id:


		st.clear()
		st["id"] = id

func set_acc(slot: String, key: String, value) -> void :
	acc_slot(slot)[key] = value

func acc_val(slot: String, key: String, default: = 0.5) -> float:
	return float((accessories.get(slot, {}) as Dictionary).get(key, default))

func set_acc_color(slot: String, i: int, color: Color) -> void :
	var st: = acc_slot(slot)
	var cols: Array = st.get("cols", [])
	while cols.size() <= i:
		cols.append("")
	cols[i] = color.to_html(false)
	st["cols"] = cols

func acc_color(slot: String, i: int, fallback: Color) -> Color:
	var cols: Array = (accessories.get(slot, {}) as Dictionary).get("cols", [])
	if i >= 0 and i < cols.size() and String(cols[i]) != "":
		return Color.html(str(cols[i]))
	return fallback




func _acc_grad(slot: String, i: int) -> Dictionary:
	var g: Array = (accessories.get(slot, {}) as Dictionary).get("grads", [])
	if i >= 0 and i < g.size() and g[i] is Dictionary:
		return g[i]
	return {}

func _acc_grad_slot(slot: String, i: int) -> Dictionary:
	var st: = acc_slot(slot)
	var g: Array = st.get("grads", [])
	while g.size() <= i:
		g.append({})
	if not (g[i] is Dictionary):
		g[i] = {}
	st["grads"] = g
	return g[i]

func acc_gradient_on(slot: String, i: int) -> bool:
	return bool(_acc_grad(slot, i).get("on", false))

func set_acc_gradient_on(slot: String, i: int, on: bool) -> void :
	_acc_grad_slot(slot, i)["on"] = on

func acc_gradient_bottom(slot: String, i: int, fallback: Color) -> Color:
	var b: = String(_acc_grad(slot, i).get("b", ""))
	return Color.html(b) if b != "" else fallback

func set_acc_gradient_bottom(slot: String, i: int, color: Color) -> void :
	_acc_grad_slot(slot, i)["b"] = color.to_html(false)

func acc_gradient_fade(slot: String, i: int) -> Vector2:
	var g: = _acc_grad(slot, i)
	return Vector2(float(g.get("fs", 0.0)), float(g.get("fe", 1.0)))

func set_acc_gradient_fade(slot: String, i: int, start: float, end: float) -> void :
	var g: = _acc_grad_slot(slot, i)
	g["fs"] = clampf(start, 0.0, 1.0)
	g["fe"] = clampf(end, 0.0, 1.0)

func reset_acc_transform(slot: String) -> void :
	var st: = acc_slot(slot)
	for k in ["px", "py", "pz", "rx", "ry", "rz", "sc", "sx", "sy", "sz"]:
		st.erase(k)

static func random(rng: RandomNumberGenerator = null, owned_only: = false) -> CharacterConfig:




	var r: = rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		r.randomize()
	var c: = CharacterConfig.new()
	c.face = r.randi_range(0, FACE_TYPES - 1)
	c.skin = r.randi_range(0, SKIN_TONES.size() - 1)
	c.height = r.randf_range(0.15, 0.85)
	c.weight = r.randf_range(0.15, 0.85)
	c.hair = r.randi_range(0, hair_meshes().size() - 1)
	c.hair_flip = r.randf() < 0.5
	c.hair_color_idx = r.randi_range(0, HAIR_COLORS.size() - 1)
	c.hair_col = HAIR_COLORS[c.hair_color_idx]


	c.eye_shape = _rand_opt(r, "eyes")
	c.eye_color = [Color(0.15, 0.25, 0.45), Color(0.25, 0.16, 0.1), 
		Color(0.18, 0.38, 0.25), Color(0.1, 0.1, 0.12)][r.randi_range(0, 3)]
	c.eye_size = r.randf_range(0.35, 0.65)
	c.eye_width = r.randf_range(0.35, 0.65)
	c.eye_size_y = r.randf_range(0.35, 0.65)
	c.eye_height = r.randf_range(0.4, 0.6)
	c.eye_spacing = r.randf_range(0.4, 0.6)
	c.eye_rot = r.randf_range(0.42, 0.58)
	c.eye_x = r.randf_range(0.45, 0.55)

	c.brow_shape = -1 if r.randf() < 0.12 else _rand_opt(r, "brows")
	c.brow_height = r.randf_range(0.4, 0.6)
	c.brow_rot = r.randf_range(0.42, 0.58)
	c.brow_spacing = r.randf_range(0.4, 0.6)
	c.brow_size = r.randf_range(0.4, 0.6)
	c.brow_width = r.randf_range(0.4, 0.6)
	c.brow_size_y = r.randf_range(0.4, 0.6)
	c.brow_x = r.randf_range(0.45, 0.55)
	c.mouth_shape = _rand_opt(r, "mouth")
	c.mouth_size = r.randf_range(0.4, 0.6)
	c.mouth_width = r.randf_range(0.4, 0.6)
	c.mouth_size_y = r.randf_range(0.4, 0.6)
	c.mouth_height = r.randf_range(0.4, 0.6)
	c.mouth_rot = r.randf_range(0.44, 0.56)
	c.mouth_x = r.randf_range(0.45, 0.55)
	c.nose_shape = -1 if r.randf() < 0.1 else _rand_opt(r, "nose")
	c.nose_size = r.randf_range(0.35, 0.65)
	c.nose_width = r.randf_range(0.35, 0.65)
	c.nose_size_y = r.randf_range(0.35, 0.65)
	c.nose_height = r.randf_range(0.4, 0.6)
	c.nose_x = r.randf_range(0.44, 0.56)
	c.nose_flip = r.randf() < 0.5
	c.blush = r.randf() < 0.25
	c.blush_shape = r.randi_range(0, BLUSH_SHAPES.size() - 1)
	c.blush_opacity = r.randf_range(0.35, 0.7)
	c.number = r.randi_range(1, 99)


	c.gym_tee = GYM_TEE_COLORS[r.randi_range(0, GYM_TEE_COLORS.size() - 1)]
	c.gym_shorts = GYM_SHORT_COLORS[r.randi_range(0, GYM_SHORT_COLORS.size() - 1)]


	c.gym_shirt = [0, 0, 1, 2][r.randi_range(0, 3)]
	c.wear_socks = r.randf() < 0.85
	c.wear_kneepads = r.randf() < 0.6


	c.head_shape = r.randi_range(0, HEAD_SHAPES.size() - 1)
	c.shorts_len = r.randi_range(0, SHORTS_SHAPES.size() - 1)
	c.socks_len = r.randi_range(0, SOCKS_SHAPES.size() - 1)


	c.socks = _gear_color(r)
	c.kneepad = _gear_color(r)
	c.shoe_color = _gear_color(r)
	c.voice = r.randi_range(0, VOICE_PITCH.size() - 1)
	c.v_pitch = r.randf()
	c.v_speed = r.randf_range(0.3, 0.7)
	c.voice_pack = r.randi_range(1, VOICE_PACK_COUNT)

	c.left_handed = r.randf() < 0.15


	c.kit_home = [_bold_color(r), _dark_color(r), _bold_color(r)]
	c.kit_away = [_bold_color(r), _dark_color(r), _bold_color(r)]

	var home_hue: float = (c.kit_home[0] as Color).h
	if absf((c.kit_away[0] as Color).h - home_hue) < 0.25:
		c.kit_away[0] = Color.from_hsv(fmod(home_hue + 0.5, 1.0), 
			(c.kit_away[0] as Color).s, (c.kit_away[0] as Color).v)
	_random_accessories(c, r, owned_only)
	return c


static func _rand_opt(r: RandomNumberGenerator, feature: String) -> int:
	var n: = FaceParts.count(feature)
	return r.randi_range(0, n - 1) if n > 0 else 0





const ACC_ROLL_CHANCE: = {"head": 0.15, "face": 0.35, "extra": 0.2}
static func _random_accessories(c: CharacterConfig, r: RandomNumberGenerator, 
		owned_only: = false) -> void :
	for slot in ACC_SLOTS:
		var items: = AccessoryCatalog.for_category(slot)


		if owned_only:
			items = items.filter( func(it: AccessoryItem):
				return Progression.owns(it.id, it.price))
		if items.is_empty() or r.randf() >= float(ACC_ROLL_CHANCE.get(slot, 0.25)):
			continue
		var item: AccessoryItem = items[r.randi_range(0, items.size() - 1)]
		c.set_acc_id(slot, item.id)
		for i in item.color_count():
			c.set_acc_color(slot, i, _acc_random_color(r))

static func _acc_random_color(r: RandomNumberGenerator) -> Color:

	return Color.from_hsv(r.randf(), r.randf_range(0.45, 0.9), r.randf_range(0.55, 0.95))

static func _bold_color(r: RandomNumberGenerator) -> Color:
	return Color.from_hsv(r.randf(), r.randf_range(0.55, 0.9), 
		r.randf_range(0.7, 0.95))

static func _dark_color(r: RandomNumberGenerator) -> Color:
	return Color.from_hsv(r.randf(), r.randf_range(0.0, 0.4), 
		r.randf_range(0.08, 0.22))



static func _gear_color(r: RandomNumberGenerator) -> Color:
	return Color.from_hsv(r.randf(), r.randf_range(0.25, 0.7), 
		r.randf_range(0.3, 0.72))


static var _char_path: = ""
static var _slots_path: = ""

static func char_path() -> String:
	if _char_path == "":
		_char_path = AppData.migrate("user://character.json", "character.json")
	return _char_path

static func slots_path() -> String:
	if _slots_path == "":
		_slots_path = AppData.migrate("user://character_slots.json", "character_slots.json")
	return _slots_path

func save_local() -> void :
	var f: = FileAccess.open(char_path(), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(to_dict()))

static func load_local() -> CharacterConfig:
	if not FileAccess.file_exists(char_path()):
		return CharacterConfig.new()
	var f: = FileAccess.open(char_path(), FileAccess.READ)
	if f == null:
		return CharacterConfig.new()
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return CharacterConfig.new()
	return CharacterConfig.from_dict(parsed)



func clone() -> CharacterConfig:
	return CharacterConfig.from_dict(to_dict())







const SLOT_COUNT: = 20




static func load_slots() -> Array:
	var slots: Array = []
	for _i in SLOT_COUNT:
		slots.append(null)
	if FileAccess.file_exists(slots_path()):
		var f: = FileAccess.open(slots_path(), FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Array:
				for i in mini(SLOT_COUNT, (parsed as Array).size()):
					var e: Variant = parsed[i]
					slots[i] = from_dict(e) if e is Dictionary else null
		return slots

	if FileAccess.file_exists(char_path()):
		slots[0] = load_local()
	return slots

static func save_slots(slots: Array) -> void :
	var out: Array = []
	for i in SLOT_COUNT:
		var e: Variant = slots[i] if i < slots.size() else null
		out.append((e as CharacterConfig).to_dict() if e is CharacterConfig else null)
	var f: = FileAccess.open(slots_path(), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(out))
