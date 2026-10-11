class_name BeachCrowd








const SHADER: = preload("res://game/court/beach_crowd.gdshader")
const ATLAS: = "res://game/crowd/beach_crowd_atlas.png"
const CHARS: = 24
const ANGLES: = 8
const CELL: = Vector2i(150, 290)
const CAPTURE_HEIGHT: = 2.5

const SCALE: = 0.92
const BEACH_COUNT: = 90
const BOARDWALK_N: = 34
const BOARDWALK_X: = -26.0
const X_TOWN: = -23.0
const X_WATER: = 8.0
const COAST: = 150.0
const KEEP_X: = 16.0
const KEEP_Z: = 22.0

static func populate(shell: Node3D, id: String, half_w: float, half_l: float, 
		crowd_seed: int = 0) -> MultiMeshInstance3D:
	if shell == null or String(Stage.val(id, "surface", "court")) != "sand":
		return null




	var atlas: = ResourceLoader.load(ATLAS) as Texture2D
	var view_dependent: = atlas != null
	var fan_arr: Texture2DArray = null
	if not view_dependent:
		fan_arr = GymCrowd._fan_array()
		if fan_arr == null:
			push_warning("beach crowd: no atlas and no fallback fan array")
			return null
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash("beach_crowd:%d" % crowd_seed)
	var keep_x: = maxf(KEEP_X, half_w + 4.0)
	var keep_z: = maxf(KEEP_Z, half_l + 4.0)
	var foot_y: = maxf(SandDeform.decal_y, 0.05)


	var specs: Array = []

	var z: = - COAST + 14.0
	while z <= COAST - 14.0:
		var bx: = BOARDWALK_X + 3.2 + rng.randf_range(-0.5, 0.5)
		if not (absf(bx) < keep_x and absf(z) < keep_z):
			var dir: = 1.0 if rng.randf() < 0.5 else -1.0
			specs.append([Vector3(bx, foot_y, z), atan2(0.0, dir)])
		z += rng.randf_range(7.0, 11.0)


	var tries: = 0
	while specs.size() < BEACH_COUNT + BOARDWALK_N and tries < (BEACH_COUNT + BOARDWALK_N) * 5:
		tries += 1
		var x: = rng.randf_range(X_TOWN, X_WATER)
		var pz: = rng.randf_range( - COAST, COAST)
		if absf(x) < keep_x and absf(pz) < keep_z:
			continue
		var pos: = Vector3(x, foot_y, pz)
		var roll: = rng.randf()
		if roll < 0.5:
			specs.append([pos, atan2(1.0, 0.0)])
		elif roll < 0.75 and specs.size() + 1 < BEACH_COUNT + BOARDWALK_N:

			var off: = Vector3(rng.randf_range(-0.6, 0.6), 0.0, 1.4)
			var b: = pos + off
			specs.append([pos, atan2(off.x, off.z)])
			specs.append([b, atan2( - off.x, - off.z)])
		else:
			specs.append([pos, rng.randf_range(0.0, TAU)])
	if specs.is_empty():
		return null

	var qh: = CAPTURE_HEIGHT * SCALE
	var aspect: = float(CELL.x) / float(CELL.y)
	var qm: = QuadMesh.new()
	qm.size = Vector2(qh * aspect, qh)

	var mm: = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = qm
	mm.instance_count = specs.size()
	for i in specs.size():
		var pos: Vector3 = specs[i][0]
		var face: float = specs[i][1]
		mm.set_instance_transform(i, Transform3D(Basis(), pos))
		if view_dependent:

			mm.set_instance_custom_data(i, Color(
				float(rng.randi() % CHARS), rng.randf(), fposmod(face, TAU) / TAU, 0.0))
		else:

			mm.set_instance_custom_data(i, Color(
				float(rng.randi() % GymCrowd.PORTRAIT_COUNT), rng.randf(), 0.0, 0.0))

	var mi: = MultiMeshInstance3D.new()
	mi.name = "BeachCrowd"
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat: = ShaderMaterial.new()
	if view_dependent:
		mat.shader = SHADER
		mat.set_shader_parameter("atlas", atlas)
		mat.set_shader_parameter("grid", Vector2(ANGLES, CHARS))
		mat.set_shader_parameter("angles", float(ANGLES))
		mat.set_shader_parameter("foot_lift", qh * 0.5)
		mat.set_shader_parameter("desat", 0.28)
	else:
		mat.shader = preload("res://game/court/crowd.gdshader")
		mat.set_shader_parameter("fans", fan_arr)
		mat.set_shader_parameter("foot_lift", qh * 0.5)
		mat.set_shader_parameter("depth_dim", 0.0)
		mat.set_shader_parameter("shade_var", 0.18)
		mat.set_shader_parameter("desat", 0.3)
		mat.set_shader_parameter("crowd_contrast", 0.9)
	mat.set_shader_parameter("bob_amp", 0.03)
	mat.set_shader_parameter("bob_speed", 1.0)
	mat.set_shader_parameter("haze_color", Color(0.72, 0.82, 0.92))
	mat.set_shader_parameter("haze_start", 40.0)
	mat.set_shader_parameter("haze_end", 150.0)
	mat.set_shader_parameter("haze_amt", 0.7)
	mi.material_override = mat
	mi.custom_aabb = AABB(Vector3(-40, -3, - COAST - 10), Vector3(80, 40, COAST * 2.0 + 20))
	mi.transform = shell.global_transform.affine_inverse()
	shell.add_child(mi)
	return mi
