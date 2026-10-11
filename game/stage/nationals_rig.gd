@tool
class_name NationalsRig
extends Node3D

















const CEIL: = 15.5
const JUMBO_Y: = 12.0

const BLOCKOUT: = "Blockout"

const DEFAULT_HALF_W: = 4.5
const DEFAULT_HALF_L: = 9.0

func _ready() -> void :
	if Engine.is_editor_hint():
		_build(DEFAULT_HALF_W, DEFAULT_HALF_L)

func configure(half_w: float, half_l: float) -> void :
	_build(half_w, half_l)

func _build(half_w: float, half_l: float) -> void :
	_build_truss(half_w, half_l)
	_build_jumbotron()
	_build_lights(half_w, half_l)



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

func _build_truss(half_w: float, half_l: float) -> void :
	var b: = _prep_anchor("Truss", Vector3(0.0, CEIL, 0.0))
	if b == null:
		return
	var hx: = maxf(12.0, half_w + 4.0)
	var hz: = maxf(16.0, half_l + 3.0)
	var mat: = _steel(Color(0.13, 0.14, 0.17))

	for x: float in [ - hx, - hx * 0.5, 0.0, hx * 0.5, hx]:
		_box(b, Vector3(x, 0.0, 0.0), Vector3(0.3, 0.34, hz * 2.0), mat)
	for z: float in [ - hz, - hz * 0.5, 0.0, hz * 0.5, hz]:
		_box(b, Vector3(0.0, 0.0, z), Vector3(hx * 2.0, 0.3, 0.3), mat)

func _build_jumbotron() -> void :
	var b: = _prep_anchor("Jumbotron", Vector3(0.0, JUMBO_Y, 0.0))
	if b == null:
		return
	const BW: = 5.0
	const BH: = 2.4
	const BD: = 5.0
	var shell: = _steel(Color(0.05, 0.06, 0.09))
	var glow: = _emissive(Color(0.12, 0.5, 0.7), 1.6)
	var bar: = _emissive(Color(0.98, 0.62, 0.2), 2.4)

	_box(b, Vector3.ZERO, Vector3(BW, BH, BD), shell)

	_screen_face(b, "x", 1.0, BW, BH, BD, glow, bar)
	_screen_face(b, "x", -1.0, BW, BH, BD, glow, bar)
	_screen_face(b, "z", 1.0, BW, BH, BD, glow, bar)
	_screen_face(b, "z", -1.0, BW, BH, BD, glow, bar)

	var top: = BH * 0.5
	var cable_h: = CEIL - JUMBO_Y - top
	var mat: = _steel(Color(0.1, 0.11, 0.13))
	for cx: float in [-1.7, 1.7]:
		for cz: float in [-1.7, 1.7]:
			_box(b, Vector3(cx, top + cable_h * 0.5, cz), 
				Vector3(0.07, cable_h, 0.07), mat)


func _screen_face(b: Node3D, axis: String, sign: float, bw: float, bh: float, 
		bd: float, glow: Material, bar: Material) -> void :
	var panel_w: = (bd if axis == "x" else bw) * 0.82
	if axis == "x":
		var x: = sign * (bw * 0.5 + 0.03)
		_box(b, Vector3(x, 0.0, 0.0), Vector3(0.05, bh * 0.78, panel_w), glow)
		_box(b, Vector3(sign * (bw * 0.5 + 0.06), bh * 0.12, 0.0), 
			Vector3(0.05, 0.3, panel_w * 0.86), bar)
	else:
		var z: = sign * (bd * 0.5 + 0.03)
		_box(b, Vector3(0.0, 0.0, z), Vector3(panel_w, bh * 0.78, 0.05), glow)
		_box(b, Vector3(0.0, bh * 0.12, sign * (bd * 0.5 + 0.06)), 
			Vector3(panel_w * 0.86, 0.3, 0.05), bar)

func _build_lights(half_w: float, half_l: float) -> void :
	var b: = _prep_anchor("Lights", Vector3(0.0, CEIL - 0.5, 0.0))
	if b == null:
		return
	var hx: = maxf(8.0, half_w + 1.5)
	var hz: = maxf(10.0, half_l)
	var housing: = _steel(Color(0.09, 0.1, 0.12))
	var lens: = _emissive(Color(1.0, 0.96, 0.86), 3.0)
	for x: float in [ - hx * 0.7, 0.0, hx * 0.7]:
		for z: float in [ - hz * 0.7, - hz * 0.24, hz * 0.24, hz * 0.7]:
			_box(b, Vector3(x, 0.0, z), Vector3(0.62, 0.42, 0.62), housing)
			_box(b, Vector3(x, -0.26, z), Vector3(0.5, 0.08, 0.5), lens)

func _steel(c: Color) -> StandardMaterial3D:
	var m: = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.65
	m.metallic = 0.3
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
