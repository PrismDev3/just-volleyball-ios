class_name ForceWall
extends Node3D








const WALL_SHADER: = preload("res://game/court/force_wall.gdshader")
const HEX_METRES: = 1.5
const MAX_PROBES: = 16
const REFRESH_EVERY: = 0.5

var _mats: Array[ShaderMaterial] = []
var _probes: Array[Node3D] = []
var _since_refresh: = 999.0
var _buf: = PackedVector3Array()


func build(extent: Vector3, tint: Color) -> void :
	var hw: = extent.x
	var h: = extent.y
	var hl: = extent.z

	for w in [
		[Vector3(hw, h * 0.5, 0.0), hl * 2.0, - PI * 0.5], 
		[Vector3( - hw, h * 0.5, 0.0), hl * 2.0, PI * 0.5], 
		[Vector3(0.0, h * 0.5, hl), hw * 2.0, PI], 
		[Vector3(0.0, h * 0.5, - hl), hw * 2.0, 0.0], 
	]:
		var width: float = w[1]
		var mi: = MeshInstance3D.new()
		var qm: = QuadMesh.new()
		qm.size = Vector2(width, h)
		mi.mesh = qm
		mi.position = w[0]
		mi.rotation.y = w[2]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		mi.custom_aabb = AABB(Vector3( - width, - h, -2), Vector3(width * 2.0, h * 2.0, 4))
		var mat: = ShaderMaterial.new()
		mat.shader = WALL_SHADER


		mat.render_priority = -8
		mat.set_shader_parameter("tint", tint)

		mat.set_shader_parameter("uv_scale", 
			Vector2(width / HEX_METRES, h / HEX_METRES))


		mat.set_shader_parameter("base_vis", 1.0)
		mat.set_shader_parameter("wall_height", h)
		mi.material_override = mat
		add_child(mi)
		_mats.append(mat)

func _process(delta: float) -> void :
	if _mats.is_empty():
		return
	_since_refresh += delta
	if _since_refresh >= REFRESH_EVERY:
		_since_refresh = 0.0
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
	for m in _mats:
		m.set_shader_parameter("probe_count", n)
		m.set_shader_parameter("probe_pos", _buf)



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
