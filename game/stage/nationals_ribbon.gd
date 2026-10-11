@tool
class_name NationalsRibbon
extends Node3D









const GAP: = NationalsPerimeter.GAP
const Y_CENTER: = 1.25
const BOARD_H: = 0.85
const BOARD_T: = 0.08
const BLOCKOUT: = "Blockout"
const DEFAULT_HALF_W: = 4.5
const DEFAULT_HALF_L: = 9.0

func _ready() -> void :
	if Engine.is_editor_hint():
		_build(DEFAULT_HALF_W, DEFAULT_HALF_L)

func configure(half_w: float, half_l: float) -> void :
	_build(half_w, half_l)

func _build(half_w: float, half_l: float) -> void :
	var rx: = half_w + GAP
	var rz: = half_l + GAP
	var board: = _steel(Color(0.03, 0.04, 0.06))
	var lit: = _emissive(Color(0.12, 0.58, 1.0), 3.0)
	var accent: = _emissive(Color(0.99, 0.66, 0.16), 3.4)


	_side("RibbonNorth", "x", Vector3(0.0, Y_CENTER, - rz), 2.0 * rx, board, lit, accent)
	_side("RibbonSouth", "x", Vector3(0.0, Y_CENTER, rz), 2.0 * rx, board, lit, accent)
	_side("RibbonEast", "z", Vector3(rx, Y_CENTER, 0.0), 2.0 * rz - 0.2, board, lit, accent)
	_side("RibbonWest", "z", Vector3( - rx, Y_CENTER, 0.0), 2.0 * rz - 0.2, board, lit, accent)

func _side(side_name: String, axis: String, at: Vector3, length: float, 
		board: Material, lit: Material, accent: Material) -> void :
	var b: = _prep_anchor(side_name, at)
	if b == null:
		return

	var inward: = Vector3(0.0, 0.0, - signf(at.z)) if axis == "x"\
	else Vector3( - signf(at.x), 0.0, 0.0)
	if axis == "x":
		_box(b, Vector3.ZERO, Vector3(length, BOARD_H, BOARD_T), board)
		_box(b, inward * 0.05, Vector3(length * 0.97, BOARD_H * 0.8, 0.03), lit)
		_box(b, inward * 0.055 + Vector3(0.0, - BOARD_H * 0.34, 0.0), 
			Vector3(length * 0.9, 0.12, 0.03), accent)
	else:
		_box(b, Vector3.ZERO, Vector3(BOARD_T, BOARD_H, length), board)
		_box(b, inward * 0.05, Vector3(0.03, BOARD_H * 0.8, length * 0.97), lit)
		_box(b, inward * 0.055 + Vector3(0.0, - BOARD_H * 0.34, 0.0), 
			Vector3(0.03, 0.12, length * 0.9), accent)

func _prep_anchor(anchor_name: String, at: Vector3) -> Node3D:
	var anchor: = get_node_or_null(NodePath(anchor_name)) as Node3D
	if anchor == null:
		anchor = Node3D.new()
		anchor.name = anchor_name
		add_child(anchor)
	anchor.position = at
	var old: = anchor.get_node_or_null(BLOCKOUT)
	if old != null:
		anchor.remove_child(old)
		old.queue_free()
	for c in anchor.get_children():
		if c.name != BLOCKOUT:
			return null
	var blockout: = Node3D.new()
	blockout.name = BLOCKOUT
	anchor.add_child(blockout)
	return blockout

func _steel(c: Color) -> StandardMaterial3D:
	var m: = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	return m

func _emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m: = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m

func _box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> void :
	var mesh: = BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	var mi: = MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = at
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
