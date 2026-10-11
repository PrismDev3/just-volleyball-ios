class_name ServeZoneMarker
extends MeshInstance3D








const ZONE_SIDE: = 1.5
const ZONE_FRONT: = 2.2
const ZONE_DEPTH: = 7.0
const COLOR_IN: = Color(0.35, 0.95, 0.42, 1.0)
const COLOR_OUT: = Color(1.0, 0.34, 0.28, 1.0)

var _mat: ShaderMaterial
var _cx: = 0.0
var _half_l: = 9.0
var _size: = Vector2.ONE

func _init() -> void :
	var quad: = QuadMesh.new()
	quad.orientation = PlaneMesh.FACE_Y
	mesh = quad
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://game/fx/serve_zone.gdshader")
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false

func setup(center_x: float, half_w: float, half_l: float) -> void :
	_cx = center_x
	_half_l = half_l
	_size = Vector2((half_w + ZONE_SIDE) * 2.0, ZONE_DEPTH)
	(mesh as QuadMesh).size = _size
	_mat.set_shader_parameter("size", _size)



func tick(active: bool, side: float, inside: bool) -> void :
	if visible != active:
		visible = active
	if not active:
		return

	var center_z: = side * (_half_l - ZONE_FRONT + ZONE_DEPTH * 0.5)
	global_position = Vector3(_cx, 0.04, center_z)
	_mat.set_shader_parameter("tint", COLOR_IN if inside else COLOR_OUT)
