class_name AimMarker
extends Node3D
















const SHADER: = preload("res://game/fx/floor_ring_overlay.gdshader")
const SIZE: = 1.9
const RING_OUTER: = 0.59
const PULSE_HZ: = 1.5
const PULSE_DEPTH: = 0.035






const COLOR_OWN: = Color(0.35, 1.0, 0.55)




const COLOR_OPP: = Color(1.0, 0.25, 0.72)
const COLOR: = COLOR_OWN
const TINT_BLEND: = 14.0





const NET_CUT_RADIUS: = 0.19
const NET_CUT_FEATHER: = 0.11
const NET_CUT_BLEND: = 11.0

var net_mat: ShaderMaterial = null
var _mat: ShaderMaterial
var _mesh: MeshInstance3D
var _t: = 0.0
var _tint: = COLOR_OWN
var _tint_want: = COLOR_OWN
var _base_pos: = Vector3.ZERO
var _rig: Node = null



func set_rig(rig: Node) -> void :
	_rig = rig
	process_priority = 500

func _ready() -> void :
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.render_priority = 12



	_mat.set_shader_parameter("ring_radius", 0.62)
	_mat.set_shader_parameter("ring_width", 0.075)
	_mat.set_shader_parameter("outline", 0.05)
	_mat.set_shader_parameter("dot_radius", 0.115)

	_mat.set_shader_parameter("arrow_len", 0.0)
	_mat.set_shader_parameter("arrow_base", 0.6)
	_mat.set_shader_parameter("arrow_half", 0.17)
	_mat.set_shader_parameter("pulse", 0.0)
	set_tint(COLOR)
	var plane: = PlaneMesh.new()
	plane.size = Vector2(SIZE, SIZE)
	plane.material = _mat
	_mesh = MeshInstance3D.new()
	_mesh.mesh = plane
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)








	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	set_process(true)

func _process(delta: float) -> void :




	_t += delta
	_mat.set_shader_parameter("pulse", sin(_t * TAU * PULSE_HZ) * PULSE_DEPTH)
	if not _tint.is_equal_approx(_tint_want):
		_tint = _tint.lerp(_tint_want, 1.0 - exp( - TINT_BLEND * delta))
		set_tint(_tint)






	if _rig != null and visible:
		global_position = _base_pos + _rig.shake_offset
	if net_mat != null:
		_tick_net_cut(delta)




func _tick_net_cut(delta: float) -> void :
	var cv: Variant = net_mat.get_shader_parameter("cut_radius")
	var cur: = float(cv) if cv != null else 0.0
	var target: = 0.0
	var cam: = get_viewport().get_camera_3d() if is_inside_tree() else null
	if visible and _at_opponent and cam != null and GameConfig.net_see_through:
		var vs: = get_viewport().get_visible_rect().size
		if vs.x > 0.0 and vs.y > 0.0:
			var sp: = cam.unproject_position(_base_pos)
			net_mat.set_shader_parameter("cut_center", Vector2(sp.x / vs.x, sp.y / vs.y))
			net_mat.set_shader_parameter("cut_aspect", vs.x / vs.y)
			net_mat.set_shader_parameter("cut_feather", NET_CUT_FEATHER)
			target = NET_CUT_RADIUS
	cur = lerpf(cur, target, 1.0 - exp( - NET_CUT_BLEND * delta))
	if cur < 0.001:
		cur = 0.0
	net_mat.set_shader_parameter("cut_radius", cur)




func follow_point(point: Vector3) -> void :
	_base_pos = Vector3(point.x, maxf(0.02, SandDeform.decal_y), point.z)



func aim_at(point: Vector3, own_side: float, in_bounds: = true, 
		shake: = Vector3.ZERO) -> void :



	_base_pos = Vector3(point.x, maxf(0.02, SandDeform.decal_y), point.z)
	global_position = _base_pos + (_rig.shake_offset if _rig != null else shake)





	if not in_bounds:
		_tint_want = Color.WHITE
	else:


		_tint_want = Rules.half_color(point.z)
	_at_opponent = signf(point.z) != signf(own_side) and point.z != 0.0

var _at_opponent: = false

func aiming_at_opponent() -> bool:
	return _at_opponent



func set_tint(c: Color) -> void :
	_mat.set_shader_parameter("tint", Color(c.r, c.g, c.b, 1.0))


	_mat.set_shader_parameter("edge", Color(c.r, c.g, c.b, 0.94).darkened(0.88))

func tint() -> Color:
	return _mat.get_shader_parameter("tint")
