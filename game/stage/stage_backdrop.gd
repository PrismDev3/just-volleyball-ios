class_name StageBackdrop























static func build(parent: Node3D, spec: Dictionary, half_w: float, 
		half_l: float) -> Node3D:
	var root: = Node3D.new()
	root.name = "Backdrop"
	parent.add_child(root)
	var reach: = maxf(half_w, half_l) + 6.0
	if spec.has("ground"):
		var g: = _group(root, "Ground")

		_box(g, "GroundPlane", _flat(spec["ground"]), 
			Vector3(0, -0.3, 0), Vector3(reach * 6.0, 0.1, reach * 6.0))



	if spec.has("env_floor"):
		var e: = _group(root, "EnvFloor")
		_box(e, "EnvFloor", _flat(spec["env_floor"]), 
			Vector3(0, -0.02, 0), Vector3(reach * 6.0, 0.04, reach * 6.0))
	match String(spec.get("silhouette", "")):
		"arena":
			_arena_bowl(_group(root, "Bowl"), half_w, half_l, 
				spec.get("sil_color", Color(0.05, 0.06, 0.09)), 
				spec.get("tier_rim", Color(0, 0, 0, 0)))
		"skyline":
			_skyline(_group(root, "Skyline"), reach, 
				spec.get("sil_color", Color(0.04, 0.05, 0.08)))
	var apron: Dictionary = spec.get("apron", {})
	if not apron.is_empty():
		_apron(_group(root, "Apron"), apron.get("ext", Vector2(15, 22)), 
			apron.get("color", Color(0.035, 0.63, 0.68)))
	var banners: Dictionary = spec.get("banners", {})
	if not banners.is_empty():
		_banners(_group(root, "Banners"), banners["ext"], String(banners["path"]), 
			banners.get("y", 0.0))
	var model: Dictionary = spec.get("model", {})
	if not model.is_empty():
		_model(root, String(model["path"]), model.get("scale", 1.0), 
			model.get("y", 0.0))
	var seat: Dictionary = spec.get("seating", {})
	if not seat.is_empty():
		_seating(_group(root, "Seating"), half_w, half_l, seat)
	if spec.has("rim"):




		var re: Vector2 = spec.get("rim_extent", Vector2(half_w + 1.4, half_l + 1.4))
		_led_rim(_group(root, "CourtRim"), re.x, re.y, spec["rim"])
	var shafts: Array = spec.get("shafts", [])
	if not shafts.is_empty():
		var sg: = _group(root, "Shafts")
		for i in shafts.size():
			_shaft(sg, "Shaft%d" % i, shafts[i])
	return root



static func _arena_bowl(root: Node3D, half_w: float, half_l: float, 
		color: Color, tier_rim: = Color(0, 0, 0, 0)) -> void :
	var mat: = _flat(color)


	var rim: Material = null
	if tier_rim.a > 0.0:
		var rm: = _flat(tier_rim)
		rm.emission_enabled = true
		rm.emission = tier_rim
		rm.emission_energy_multiplier = 1.4
		rim = rm
	var tiers: = 8
	for t in tiers:
		var f: = float(t)



		var out: = 13.0 + f * 3.6
		var y: = 1.2 + f * 1.7
		var w: = half_w + out
		var l: = half_l + out
		var thick: = 3.4
		var h: = 1.4
		var tag: = "Tier%d" % t
		_box(root, tag + "_far", mat, Vector3(0, y, l), Vector3(w * 2.0 + thick, h, thick))
		_box(root, tag + "_near", mat, Vector3(0, y, - l), Vector3(w * 2.0 + thick, h, thick))
		_box(root, tag + "_east", mat, Vector3(w, y, 0), Vector3(thick, h, l * 2.0))
		_box(root, tag + "_west", mat, Vector3( - w, y, 0), Vector3(thick, h, l * 2.0))
		if rim != null:
			var ty: = y + h * 0.5 + 0.05
			var st: = 0.14
			var iw: = w - thick * 0.5
			var il: = l - thick * 0.5
			_box(root, tag + "_rimfar", rim, Vector3(0, ty, il), Vector3(iw * 2.0, st, st))
			_box(root, tag + "_rimnear", rim, Vector3(0, ty, - il), Vector3(iw * 2.0, st, st))
			_box(root, tag + "_rimeast", rim, Vector3(iw, ty, 0), Vector3(st, st, il * 2.0))
			_box(root, tag + "_rimwest", rim, Vector3( - iw, ty, 0), Vector3(st, st, il * 2.0))



static func _skyline(root: Node3D, reach: float, color: Color) -> void :
	var mat: = _flat(color)
	var rng: = RandomNumberGenerator.new()
	rng.seed = 20260805
	var ring: = reach + 26.0
	var count: = 46
	for i in count:
		var a: = TAU * float(i) / float(count)
		var d: = ring + rng.randf_range(-2.0, 2.0)
		var pos: = Vector3(sin(a) * d, 0.0, cos(a) * d)
		var bw: = rng.randf_range(4.0, 9.0)
		var bh: = rng.randf_range(8.0, 26.0)
		_box(root, "Building%d" % i, mat, Vector3(pos.x, bh * 0.5, pos.z), 
			Vector3(bw, bh, bw))



static func _led_rim(root: Node3D, half_w: float, half_l: float, 
		color: Color) -> void :
	var mat: = _flat(color)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.2
	var w: = half_w
	var l: = half_l
	var t: = 0.18
	var y: = 0.04
	_box(root, "RimFar", mat, Vector3(0, y, l), Vector3(w * 2.0, t, t))
	_box(root, "RimNear", mat, Vector3(0, y, - l), Vector3(w * 2.0, t, t))
	_box(root, "RimEast", mat, Vector3(w, y, 0), Vector3(t, t, l * 2.0))
	_box(root, "RimWest", mat, Vector3( - w, y, 0), Vector3(t, t, l * 2.0))


static func _shaft(root: Node3D, name: String, s: Dictionary) -> void :
	var mi: = MeshInstance3D.new()
	mi.name = name
	var qm: = QuadMesh.new()
	qm.size = s.get("size", Vector2(3.0, 18.0))
	mi.mesh = qm
	var m: = ShaderMaterial.new()
	m.shader = load("res://game/court/light_shaft.gdshader")
	m.set_shader_parameter("beam", s.get("color", Color(1, 0.95, 0.78)))
	m.set_shader_parameter("intensity", 0.4)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.custom_aabb = AABB(Vector3(-9, -9, -9), Vector3(18, 18, 18))
	mi.position = s.get("pos", Vector3(0, 8, -6))
	mi.rotation.y = s.get("yaw", 0.0)
	root.add_child(mi)






static func _seating(root: Node3D, half_w: float, half_l: float, 
		spec: Dictionary) -> void :
	var mat: = _flat(spec.get("color", Color(0.05, 0.06, 0.09)))
	var inner: float = spec.get("inner", 13.0)
	var depth: float = spec.get("depth", 24.0)
	var tilt: float = spec.get("tilt", 0.62)


	var base_y: float = spec.get("lift", 0.0)
	var reach: = maxf(half_w, half_l) + inner + depth
	var sides: = [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]
	var names: = ["far", "near", "east", "west"]
	for i in 4:
		var dir: Vector3 = sides[i]
		var base_half: float = half_l if absf(dir.z) > 0.5 else half_w
		var tan: = Vector3(dir.z, 0.0, - dir.x)
		var width: = reach * 2.0
		var pm: = PlaneMesh.new()
		pm.size = Vector2(width, depth)
		pm.subdivide_width = int(width / 1.3)
		pm.subdivide_depth = int(depth / 1.3)
		var mi: = MeshInstance3D.new()
		mi.name = "Seat_" + names[i]
		mi.mesh = pm
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		var up: = Vector3.UP
		var zc: = dir * cos(tilt) + up * sin(tilt)
		var yc: = - dir * sin(tilt) + up * cos(tilt)
		var basis: = Basis(tan, yc, zc)
		var center: = dir * (base_half + inner + depth * 0.5 * cos(tilt))\
		+ up * (depth * 0.5 * sin(tilt) + base_y)
		mi.transform = Transform3D(basis, center)
		root.add_child(mi)


static func _apron(root: Node3D, ext: Vector2, color: Color) -> void :


	_box(root, "TealApron", _flat(color), Vector3(0, -0.3, 0), 
		Vector3(ext.x * 2.0, 0.1, ext.y * 2.0))




const BANNER_LEN: = 15.54
static func _banners(root: Node3D, ext: Vector2, path: String, y: float) -> void :
	var scene: = load(path) as PackedScene
	if scene == null:
		return
	var hw: float = ext.x
	var hl: float = ext.y



	_banner_line(root, scene, "E", Vector3(hw, y, - hl), Vector3(0, 0, 1), 2.0 * hl, PI)
	_banner_line(root, scene, "W", Vector3( - hw, y, hl), Vector3(0, 0, -1), 2.0 * hl, 0.0)
	_banner_line(root, scene, "N", Vector3(hw, y, hl), Vector3(-1, 0, 0), 2.0 * hw, PI * 0.5)
	_banner_line(root, scene, "S", Vector3( - hw, y, - hl), Vector3(1, 0, 0), 2.0 * hw, - PI * 0.5)

static func _banner_line(root: Node3D, scene: PackedScene, tag: String, 
		start: Vector3, dir: Vector3, total: float, yaw: float) -> void :
	var count: = maxi(1, int(ceil(total / BANNER_LEN)))
	var sz: = total / (count * BANNER_LEN)
	var basis: = Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(1, 1, sz))
	for i in count:
		var inst: = scene.instantiate()
		inst.name = "Banner_%s%d" % [tag, i]
		inst.transform = Transform3D(basis, start + dir * (float(i) * BANNER_LEN * sz))
		root.add_child(inst)




static func _model(root: Node3D, path: String, scale: float, y: float) -> void :
	var scene: = load(path) as PackedScene
	if scene == null:
		return
	var inst: = scene.instantiate()
	inst.name = "Background"
	inst.transform = Transform3D(Basis.from_scale(Vector3(scale, scale, scale)), 
		Vector3(0, y, 0))
	root.add_child(inst)

static func _group(parent: Node3D, name: String) -> Node3D:
	var n: = Node3D.new()
	n.name = name
	parent.add_child(n)
	return n

static func _box(root: Node3D, name: String, mat: Material, pos: Vector3, 
		size: Vector3) -> void :
	var mi: = MeshInstance3D.new()
	mi.name = name
	var bm: = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)

static func _flat(color: Color) -> StandardMaterial3D:
	var mat: = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	return mat
