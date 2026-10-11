@tool
class_name NationalsScreens
extends Node3D










const WALL_X: = 22.0
const WALL_Z: = 28.0
const INSET: = 0.35
const Y_CENTER: = 9.5
const SCREEN_H: = 3.6
const PANEL_W: = 5.0
const PANEL_GAP: = 0.5
const PANELS: = 3
const BLOCKOUT: = "Blockout"

func _ready() -> void :
	if Engine.is_editor_hint():
		_build(0.0, 0.0)

func configure(half_w: float, half_l: float) -> void :
	_build(half_w, half_l)

func _build(_half_w: float, _half_l: float) -> void :
	var frame: = _steel(Color(0.08, 0.09, 0.11))

	var feeds: = [
		_emissive(Color(0.1, 0.5, 0.95), 1.8), 
		_emissive(Color(0.95, 0.6, 0.2), 1.8), 
		_emissive(Color(0.2, 0.78, 0.7), 1.8), 
	]
	_wall("ScreenNorth", "z", Vector3(0.0, Y_CENTER, - (WALL_Z - INSET)), frame, feeds)
	_wall("ScreenSouth", "z", Vector3(0.0, Y_CENTER, WALL_Z - INSET), frame, feeds)
	_wall("ScreenEast", "x", Vector3(WALL_X - INSET, Y_CENTER, 0.0), frame, feeds)
	_wall("ScreenWest", "x", Vector3( - (WALL_X - INSET), Y_CENTER, 0.0), frame, feeds)

func _wall(wall_name: String, axis: String, at: Vector3, frame: Material, 
		feeds: Array) -> void :
	var b: = _prep_anchor(wall_name, at)
	if b == null:
		return
	var inward: = Vector3(0.0, 0.0, - signf(at.z)) if axis == "z"\
	else Vector3( - signf(at.x), 0.0, 0.0)
	var span: = PANELS * PANEL_W + (PANELS - 1) * PANEL_GAP
	var start: = - span * 0.5 + PANEL_W * 0.5
	for k in PANELS:
		var along: = start + float(k) * (PANEL_W + PANEL_GAP)
		var feed: Material = feeds[k % feeds.size()]
		if axis == "z":
			_box(b, Vector3(along, 0.0, 0.0), 
				Vector3(PANEL_W, SCREEN_H, 0.2), frame)
			_box(b, Vector3(along, 0.0, 0.0) + inward * 0.14, 
				Vector3(PANEL_W * 0.9, SCREEN_H * 0.84, 0.05), feed)
		else:
			_box(b, Vector3(0.0, 0.0, along), 
				Vector3(0.2, SCREEN_H, PANEL_W), frame)
			_box(b, Vector3(0.0, 0.0, along) + inward * 0.14, 
				Vector3(0.05, SCREEN_H * 0.84, PANEL_W * 0.9), feed)

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
