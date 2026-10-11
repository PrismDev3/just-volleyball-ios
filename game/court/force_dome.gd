class_name ForceDome
extends Node3D









const DOME_MAT: = "res://game/court/force_dome.tres"
const HEX_METRES: = 2.6
const MAX_PROBES: = 16
const REFRESH_EVERY: = 0.5
const RINGS: = 30
const SEG: = 84
const THETA_MAX: = 1.02
const HEIGHT_MUL: = 1.7
const SUPERELLIPSE_N: = 4.0

var _mat: ShaderMaterial
var _probes: Array[Node3D] = []
var _since: = 999.0
var _buf: = PackedVector3Array()




func build(extent: Vector3, tint: Color, editable: = false) -> void :
	var hw: = extent.x
	var hl: = extent.z
	var height: = extent.y * HEIGHT_MUL
	var mi: = MeshInstance3D.new()
	mi.name = "Dome"
	mi.mesh = _build_mesh(hw, hl, height)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.custom_aabb = AABB(Vector3( - hw * 2.0, -2.0, - hl * 2.0), 
		Vector3(hw * 4.0, height * 1.5, hl * 4.0))

	var base: = load(DOME_MAT) as ShaderMaterial
	var mat: ShaderMaterial = base if editable else base.duplicate()
	if not editable:
		mat.set_shader_parameter("tint", tint)
	mat.set_shader_parameter("wall_height", height)
	var perim: = _perimeter(hw, hl)
	mat.set_shader_parameter("hex_scale", 
		Vector2(maxf(perim / HEX_METRES, 6.0), maxf(height / HEX_METRES, 3.0)))
	mi.material_override = mat
	_mat = mat
	add_child(mi)





func _build_mesh(hw: float, hl: float, height: float) -> ArrayMesh:
	var st: = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sin_max: = sin(THETA_MAX)


	var seg_a: = _arc_angles(hw, hl)
	var grid: = []
	for i in RINGS + 1:
		var h: = float(i) / float(RINGS)
		var rad: = cos(h * THETA_MAX)
		var y: = height * sin(h * THETA_MAX) / sin_max
		var row: = []
		for j in SEG + 1:
			var fp: = _footprint(seg_a[j], hw, hl) * rad
			row.append(Vector3(fp.x, y, fp.y))
		grid.append(row)
	for i in RINGS:
		for j in SEG:
			var p00: Vector3 = grid[i][j]
			var p01: Vector3 = grid[i][j + 1]
			var p10: Vector3 = grid[i + 1][j]
			var p11: Vector3 = grid[i + 1][j + 1]
			var u0: = float(j) / float(SEG)
			var u1: = float(j + 1) / float(SEG)
			var v0: = float(i) / float(RINGS)
			var v1: = float(i + 1) / float(RINGS)
			st.set_uv(Vector2(u0, v0));st.add_vertex(p00)
			st.set_uv(Vector2(u0, v1));st.add_vertex(p10)
			st.set_uv(Vector2(u1, v1));st.add_vertex(p11)
			st.set_uv(Vector2(u0, v0));st.add_vertex(p00)
			st.set_uv(Vector2(u1, v1));st.add_vertex(p11)
			st.set_uv(Vector2(u1, v0));st.add_vertex(p01)
	st.generate_normals()
	return st.commit()


func _footprint(a: float, hw: float, hl: float) -> Vector2:
	var ca: = cos(a)
	var sa: = sin(a)
	var k: = 2.0 / SUPERELLIPSE_N
	return Vector2(pow(absf(ca), k) * signf(ca) * hw, 
		pow(absf(sa), k) * signf(sa) * hl)


func _arc_angles(hw: float, hl: float) -> PackedFloat32Array:
	var fine: = 1024
	var cum: = PackedFloat32Array()
	cum.resize(fine + 1)
	cum[0] = 0.0
	var prev: = _footprint(0.0, hw, hl)
	for k in range(1, fine + 1):
		var p: = _footprint(TAU * float(k) / float(fine), hw, hl)
		cum[k] = cum[k - 1] + p.distance_to(prev)
		prev = p
	var total: float = cum[fine]
	var out: = PackedFloat32Array()
	out.resize(SEG + 1)
	var ki: = 0
	for j in SEG + 1:
		var target: = float(j) / float(SEG) * total
		while ki < fine and cum[ki + 1] < target:
			ki += 1
		var span: float = cum[ki + 1] - cum[ki]
		var t: = 0.0 if span <= 0.0 else (target - cum[ki]) / span
		out[j] = TAU * (float(ki) + t) / float(fine)
	return out

func _perimeter(hw: float, hl: float) -> float:
	var per: = 0.0
	var prev: = _footprint(0.0, hw, hl)
	for j in range(1, 65):
		var p: = _footprint(TAU * float(j) / 64.0, hw, hl)
		per += p.distance_to(prev)
		prev = p
	return per



func _ground_glow(hw: float, hl: float, tint: Color) -> void :
	var mi: = MeshInstance3D.new()
	mi.name = "GroundGlow"
	var pm: = PlaneMesh.new()
	pm.size = Vector2(hw * 2.6, hl * 2.6)
	mi.mesh = pm
	mi.position.y = 0.03
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m: = ShaderMaterial.new()
	m.shader = _GLOW_SHADER
	m.render_priority = -9
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("inner", 0.72)
	mi.material_override = m
	add_child(mi)

const _GLOW_SHADER: = preload("res://game/court/dome_glow.gdshader")



func _process(delta: float) -> void :
	if _mat == null or Engine.is_editor_hint():
		return
	_since += delta
	if _since >= REFRESH_EVERY:
		_since = 0.0
		_refresh_probes()
	_buf.resize(MAX_PROBES)
	var n: = 0
	for p in _probes:
		if n >= MAX_PROBES:
			break
		if is_instance_valid(p):
			_buf[n] = p.global_position
			n += 1
	for i in range(n, MAX_PROBES):
		_buf[i] = Vector3(1000000.0, 1000000.0, 1000000.0)
	_mat.set_shader_parameter("probe_count", n)
	_mat.set_shader_parameter("probe_pos", _buf)

func _refresh_probes() -> void :
	_probes.clear()
	var root: = get_tree().current_scene
	if root == null:
		root = get_tree().root
	_collect(root)

func _collect(node: Node) -> void :
	if node is Ball or node is Player:
		_probes.append(node)
	for c in node.get_children():
		_collect(c)
