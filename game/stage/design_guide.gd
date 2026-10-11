@tool
class_name StageDesignGuide
extends Node3D












const SMALL: = Vector2(4.0, 8.4)
const BIG: = Vector2(7.6, 13.6)
const NET_HEIGHT: = 2.2

func _ready() -> void :
	visible = Engine.is_editor_hint()
	if get_child_count() > 0:
		return
	_frame(SMALL, Color(1.0, 0.55, 0.15, 0.85))
	_frame(BIG, Color(0.25, 0.95, 0.45, 0.85))

	_box(Vector3(0.0, NET_HEIGHT * 0.5, 0.0), 
		Vector3(BIG.x * 2.0 + 0.6, NET_HEIGHT, 0.06), 
		Color(0.3, 0.55, 1.0, 0.35))

func _frame(half: Vector2, color: Color) -> void :
	var t: = 0.14


	const line_y: = 0.006
	const line_height: = 0.012
	_box(Vector3(0.0, line_y, - half.y), 
		Vector3(half.x * 2.0, line_height, t), color)
	_box(Vector3(0.0, line_y, half.y), 
		Vector3(half.x * 2.0, line_height, t), color)
	_box(Vector3( - half.x, line_y, 0.0), 
		Vector3(t, line_height, half.y * 2.0), color)
	_box(Vector3(half.x, line_y, 0.0), 
		Vector3(t, line_height, half.y * 2.0), color)

func _box(at: Vector3, size: Vector3, color: Color) -> void :
	var mat: = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	var mesh: = BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	var mi: = MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = at
	add_child(mi)
