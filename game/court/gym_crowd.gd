class_name GymCrowd






const CROWD_SHADER: = preload("res://game/court/crowd.gdshader")
const PORTRAIT_DIR: = "res://game/crowd/portraits"
const PORTRAIT_COUNT: = 100


static var _cache_path_cached: = ""
static func CACHE_PATH() -> String:
	if _cache_path_cached == "":
		_cache_path_cached = AppData.cache_migrate(
			"user://crowd_fan_array.res", "crowd_fan_array.res")
	return _cache_path_cached
const TEX_SIZE: = Vector2i(160, 311)
const CAPTURE_HEIGHT: = 2.5
const SEAT_SCALE: = 0.82
const SPACING: = 0.78
const FILL: = 0.82
const MAX_FANS: = 1600
const LIFT: = 0.15

static var _array: Texture2DArray = null

static func fill(shell: Node3D, match_seed: int, seat_mats: Array = [], 
		spacing: float = SPACING, max_fans: int = MAX_FANS, 
		fill_frac: float = FILL, lift: float = LIFT, push: float = 0.0, 
		tint: Color = Color.WHITE, 
		haze_color: Color = Color(0.83, 0.87, 0.93), haze_amt: float = 0.0, 
		shade: Dictionary = {}) -> void :








	if spacing <= 0.0:
		spacing = SPACING
	if max_fans <= 0:
		max_fans = MAX_FANS
	if fill_frac <= 0.0:
		fill_frac = FILL
	var pts: = _seat_points(shell, seat_mats, spacing, lift, push)
	if pts.is_empty():
		push_warning("no seat points found")
		return
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash("crowd:%d" % match_seed)
	_seeded_shuffle(pts, rng)
	var keep: = mini(int(pts.size() * fill_frac), max_fans)
	pts.resize(keep)

	var arr: = _fan_array()
	if arr == null:
		return
	var qh: = CAPTURE_HEIGHT * SEAT_SCALE
	var aspect: = float(TEX_SIZE.x) / float(TEX_SIZE.y)
	var qm: = QuadMesh.new()
	qm.size = Vector2(qh * aspect, qh)

	var mm: = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = qm



	var wdir: = Vector2(0.25, 1.0).normalized()
	var proj: = PackedFloat32Array()
	var pmin: = INF
	var pmax: = - INF
	for p in pts:
		var pr: = Vector2(p.x, p.z).dot(wdir)
		proj.append(pr)
		pmin = minf(pmin, pr)
		pmax = maxf(pmax, pr)
	var pspan: = maxf(pmax - pmin, 0.001)

	mm.instance_count = pts.size()
	for i in pts.size():
		mm.set_instance_transform(i, Transform3D(Basis(), pts[i]))

		mm.set_instance_custom_data(i, Color(
			float(rng.randi() % PORTRAIT_COUNT), 
			rng.randf(), 
			(proj[i] - pmin) / pspan, 
			0.0))

	var mi: = CrowdField.new()
	mi.multimesh = mm
	var mat: = ShaderMaterial.new()
	mat.shader = CROWD_SHADER
	mat.set_shader_parameter("fans", arr)
	mat.set_shader_parameter("foot_lift", qh * 0.5)


	mat.set_shader_parameter("tint", tint)
	mat.set_shader_parameter("shade_var", 0.22)



	mat.set_shader_parameter("depth_dim", float(shade.get("depth_dim", 0.72)))
	mat.set_shader_parameter("depth_hi", float(shade.get("depth_hi", 20.0)))

	mat.set_shader_parameter("haze_color", haze_color)
	mat.set_shader_parameter("haze_amt", haze_amt)

	mat.set_shader_parameter("desat", float(shade.get("desat", 0.62)))
	mat.set_shader_parameter("crowd_contrast", float(shade.get("contrast", 0.85)))
	mi.material_override = mat
	mi.bind(mat)


	mi.custom_aabb = AABB(Vector3(-70, -3, -70), Vector3(140, 40, 140))


	mi.transform = shell.global_transform.affine_inverse()
	shell.add_child(mi)

static func _fan_array() -> Texture2DArray:
	if _array != null:
		return _array


	if _cache_fresh():
		var cached: = ResourceLoader.load(CACHE_PATH()) as Texture2DArray
		if cached != null:
			_array = cached
			return cached
	var imgs: Array[Image] = []
	for i in PORTRAIT_COUNT:



		var tex: = load("%s/fan_%03d.png" % [PORTRAIT_DIR, i]) as Texture2D
		if tex == null:
			continue
		var im: = tex.get_image()
		if im == null:
			continue
		im.convert(Image.FORMAT_RGBA8)
		im.resize(TEX_SIZE.x, TEX_SIZE.y, Image.INTERPOLATE_BILINEAR)
		im.generate_mipmaps()
		imgs.append(im)
	if imgs.is_empty():
		push_warning("no portraits loaded from " + PORTRAIT_DIR)
		return null
	var arr: = Texture2DArray.new()
	arr.create_from_images(imgs)
	ResourceSaver.save(arr, CACHE_PATH())
	_array = arr
	return arr

static func _cache_fresh() -> bool:
	var cache_abs: = ProjectSettings.globalize_path(CACHE_PATH())
	var cache_t: = FileAccess.get_modified_time(cache_abs)
	if cache_t == 0:
		return false

	for i in PORTRAIT_COUNT:
		var p: = ProjectSettings.globalize_path("%s/fan_%03d.png" % [PORTRAIT_DIR, i])
		if FileAccess.get_modified_time(p) > cache_t:
			return false
	return true

static func _seat_points(shell: Node, seat_mats: Array = [], 
		spacing: float = SPACING, lift: float = LIFT, push: float = 0.0) -> Array:












	var cells: = {}
	var check_mats: bool = not seat_mats.is_empty()
	for node in shell.find_children("*", "MeshInstance3D", true, false):
		var mi: = node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue




		var name_seat: bool = seat_mats.is_empty()\
		and String(mi.name).to_lower().contains("seat")
		var xf: = mi.global_transform
		for s in mi.mesh.get_surface_count():
			var is_seat: bool = name_seat
			if not is_seat and check_mats:
				var sm: = mi.mesh.surface_get_material(s)
				if sm != null and seat_mats.has(sm.resource_name):
					is_seat = true
			if not is_seat:
				continue
			var vs: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for v in vs:
				var w: = xf * v
				var key: = Vector2i(int(floor(w.x / spacing)), int(floor(w.z / spacing)))
				if not cells.has(key) or w.y > (cells[key] as Vector3).y:
					cells[key] = w
	var pts: = []
	for c in cells.values():
		var p: = c as Vector3



		if push != 0.0:
			var flat: = Vector2(p.x, p.z)
			if flat.length() > 0.01:
				flat = flat.normalized() * push
				p += Vector3(flat.x, 0.0, flat.y)
		pts.append(p + Vector3(0.0, lift, 0.0))
	return pts

static func _seeded_shuffle(arr: Array, rng: RandomNumberGenerator) -> void :
	for i in range(arr.size() - 1, 0, -1):
		var j: = rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
