class_name GymProps







const BANNER_SHADER: = preload("res://game/court/banner.gdshader")



const BANNER_CENTER_FRAC: = 0.72
const BANNER_HEIGHT_FRAC: = 0.34
const BANNER_ASPECT: = 0.42
const BANNER_INSET: = 0.4
const BANNER_SPACING: = 7.0

static func dress(shell: Node3D, court: Node3D, accent: Color) -> void :

	_post_shadows(court)

static func _shell_aabb(shell: Node) -> AABB:



	var wall: = shell.find_child("Gym walls", true, false) as MeshInstance3D
	if wall != null and wall.mesh != null:
		return wall.global_transform * wall.get_aabb()


	var box: = AABB()
	var first: = true
	for node in shell.find_children("*", "MeshInstance3D", true, false):
		var mi: = node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var a: = mi.global_transform * mi.get_aabb()
		var c: = a.position + a.size * 0.5
		if c.length() > 60.0 or a.size.length() > 120.0:
			continue
		if first:
			box = a
			first = false
		else:
			box = box.merge(a)
	return box

static func _hang_banners(shell: Node3D, accent: Color) -> void :
	var box: = _shell_aabb(shell)
	if box.size.y <= 0.0:
		return
	var top: = box.position.y + box.size.y
	var by: = top * BANNER_CENTER_FRAC
	var bh: = box.size.y * BANNER_HEIGHT_FRAC
	var bw: = bh * BANNER_ASPECT


	var walls: = [
		["x", box.position.x, Vector3(1, 0, 0)], 
		["x", box.position.x + box.size.x, Vector3(-1, 0, 0)], 
		["z", box.position.z, Vector3(0, 0, 1)], 
		["z", box.position.z + box.size.z, Vector3(0, 0, -1)], 
	]
	for w in walls:
		var axis: String = w[0]
		var fixed: float = w[1]
		var n: Vector3 = w[2]
		var length: = box.size.z if axis == "x" else box.size.x
		var vmin: = box.position.z if axis == "x" else box.position.x
		var count: = maxi(2, int(length / BANNER_SPACING))
		for i in count:
			var t: = (float(i) + 0.5) / float(count)
			var along: = vmin + t * length
			var pos: = Vector3(fixed + n.x * BANNER_INSET, by, along) if axis == "x"\
			else Vector3(along, by, fixed + n.z * BANNER_INSET)
			_add_banner(shell, pos, n, bw, bh, accent)

static func _add_banner(shell: Node3D, pos: Vector3, n: Vector3, 
		bw: float, bh: float, accent: Color) -> void :
	var mi: = MeshInstance3D.new()
	var qm: = QuadMesh.new()
	qm.size = Vector2(bw, bh)
	mi.mesh = qm
	var mat: = ShaderMaterial.new()
	mat.shader = BANNER_SHADER
	mat.set_shader_parameter("accent", accent)
	mi.material_override = mat


	var zc: = n.normalized()
	var xc: = Vector3.UP.cross(zc).normalized()
	var yc: = zc.cross(xc).normalized()
	var world_xform: = Transform3D(Basis(xc, yc, zc), pos)

	mi.transform = shell.global_transform.affine_inverse() * world_xform
	shell.add_child(mi)

static func _post_shadows(court: Node3D) -> void :
	if court == null:
		return
	var tex: = _shadow_tex()
	for name in ["PostWest", "PostEast"]:
		var p: = court.get_node_or_null(name) as Node3D
		if p == null:
			continue
		var mi: = MeshInstance3D.new()
		var pm: = PlaneMesh.new()
		pm.size = Vector2(1.15, 1.15)
		mi.mesh = pm
		var mat: = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_texture = tex
		mat.albedo_color = Color(0.0, 0.0, 0.0, 0.32)
		mi.material_override = mat
		mi.position = Vector3(p.position.x, 0.02, p.position.z)
		court.add_child(mi)

static func _shadow_tex() -> ImageTexture:

	var n: = 128
	var img: = Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c: = (n - 1) * 0.5
	for y in n:
		for x in n:
			var d: = Vector2((x - c) / c, (y - c) / c).length()
			var a: = clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(0, 0, 0, a * a))
	return ImageTexture.create_from_image(img)
