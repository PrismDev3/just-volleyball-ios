class_name MiiBody
extends Node3D






const TOON: = preload("res://game/fx/toon.gdshader")
const TOON_FACE: = preload("res://game/fx/toon_face.gdshader")
const OUTLINE_COLOR: = Color(0.05, 0.05, 0.08)
const OUTLINE_GROW: = 1.07


const DEFAULT_P: = {
	"head_radius": 0.42, 
	"head_squash": 0.95, 
	"neck_gap": -0.16, 
	"torso_height": 0.28, 
	"torso_radius": 0.27, 
	"shorts_height": 0.16, 
	"leg_length": 0.4, 
	"leg_radius": 0.095, 
	"hip_width": 0.115, 
	"sock_height": 0.11, 
	"foot_length": 0.24, 
	"foot_radius": 0.09, 
	"height_range": 0.16, 
	"weight_range": 0.28, 
	"hair_scale": 1.05, 
}

var config: CharacterConfig
var proportions: = {}
var face: FaceDraw
var show_hands: = false

var _hip_l: Node3D
var _hip_r: Node3D
var _torso_mi: MeshInstance3D
var _shorts_mi: MeshInstance3D
var _sock_mats: Array = []
var _head_root: Node3D
var _face_vp: SubViewport
var _leg_len: = 0.34

func p(key: String) -> float:
	return float(proportions.get(key, DEFAULT_P[key]))

func build(cfg: CharacterConfig) -> void :
	config = cfg
	for child in get_children():
		child.queue_free()
	var hf: = 1.0 + (cfg.height - 0.5) * 2.0 * p("height_range")
	var wf: = 1.0 + (cfg.weight - 0.5) * 2.0 * p("weight_range")
	var skin: = cfg.skin_tone()
	_sock_mats = []
	_leg_len = p("leg_length") * hf
	var torso_h: = p("torso_height") * hf
	var torso_r: = p("torso_radius") * wf
	var head_r: = p("head_radius") * (1.0 + (wf - 1.0) * 0.25)




	var upper_len: = _leg_len * 0.52
	var lower_len: = _leg_len * 0.48
	for side in [-1.0, 1.0]:
		var hip: = Node3D.new()
		hip.name = "HipL" if side < 0 else "HipR"
		hip.position = Vector3(side * p("hip_width") * wf, _leg_len, 0.0)
		add_child(hip)
		var upper: = _mesh_node(hip, _capsule(p("leg_radius") * wf, upper_len), 
			skin, Vector3(0.0, - upper_len * 0.5, 0.0))
		_outline(upper)
		var knee: = Node3D.new()
		knee.name = "KneeL" if side < 0 else "KneeR"
		knee.position = Vector3(0.0, - upper_len, 0.0)
		hip.add_child(knee)
		var lower: = _mesh_node(knee, _capsule(p("leg_radius") * wf * 0.92, 
			lower_len), skin, Vector3(0.0, - lower_len * 0.5, 0.0))
		_outline(lower)

		var sock: = _mesh_node(knee, _cylinder(p("leg_radius") * wf * 1.08, 
			p("sock_height")), Color.WHITE, 
			Vector3(0.0, - lower_len + p("sock_height") * 0.5, 0.0))
		_outline(sock)
		_sock_mats.append((sock.mesh as PrimitiveMesh).material)

		var foot: = _mesh_node(knee, _capsule(p("foot_radius") * wf, 
			p("foot_length")), Color(0.92, 0.92, 0.95), 
			Vector3(0.0, - lower_len + p("foot_radius") * 0.55, 
				p("foot_length") * 0.28))
		foot.rotation.x = PI * 0.5
		_outline(foot)
		if side < 0:
			_hip_l = hip
		else:
			_hip_r = hip


	_shorts_mi = _mesh_node(self, _cylinder(torso_r * 1.05, p("shorts_height")), 
		Color.WHITE, Vector3(0.0, _leg_len + p("shorts_height") * 0.5 - 0.04, 0.0))
	_outline(_shorts_mi)

	var torso_center: = _leg_len + p("shorts_height") - 0.04\
	+ torso_h * 0.5 + torso_r * 0.25
	var torso_mesh: = _capsule(torso_r, torso_h)
	_torso_mi = _mesh_node(self, torso_mesh, Color.WHITE, 
		Vector3(0.0, torso_center, 0.0))
	_outline(_torso_mi)
	var torso_top: = torso_center + torso_h * 0.5 + torso_r


	_head_root = Node3D.new()
	var head_y: = torso_top + head_r * p("head_squash") + p("neck_gap")
	_head_root.position = Vector3(0.0, head_y, 0.0)
	add_child(_head_root)
	_face_vp = SubViewport.new()
	_face_vp.size = Vector2i(512, 256)
	_face_vp.transparent_bg = true
	_face_vp.disable_3d = true
	_face_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_face_vp)
	face = FaceDraw.new()
	face.config = cfg
	_face_vp.add_child(face)
	var head_mesh: = SphereMesh.new()
	head_mesh.radius = head_r
	head_mesh.height = head_r * 2.0
	var head_mat: = ShaderMaterial.new()
	head_mat.shader = TOON_FACE
	head_mat.set_shader_parameter("albedo", skin)
	head_mat.set_shader_parameter("face_tex", _face_vp.get_texture())
	head_mesh.material = head_mat
	var head_mi: = MeshInstance3D.new()
	head_mi.mesh = head_mesh
	head_mi.scale = Vector3(1.0, p("head_squash"), 1.0)

	head_mi.rotation.y = PI
	_head_root.add_child(head_mi)
	_outline(head_mi)
	_build_hair(head_r)
	if show_hands:

		for side in [-1.0, 1.0]:
			var hand: = _mesh_node(self, _capsule(0.13, 0.0), skin, 
				Vector3(side * (torso_r + 0.19), torso_center + 0.02, 0.08))
			_outline(hand)
	set_kit(cfg.kit_home[0], cfg.kit_home[1], cfg.kit_home[2])

func set_kit(primary: Color, secondary: Color, accent: Color) -> void :

	((_torso_mi.mesh as PrimitiveMesh).material as ShaderMaterial)\
	.set_shader_parameter("albedo", primary)
	((_shorts_mi.mesh as PrimitiveMesh).material as ShaderMaterial)\
	.set_shader_parameter("albedo", secondary)
	for mat in _sock_mats:
		(mat as ShaderMaterial).set_shader_parameter("albedo", accent)

func total_height() -> float:
	return _head_root.position.y + p("head_radius") * p("head_squash") * 2.0

func animate(gait_phase: float, planar_speed: float, grounded: bool, 
		vel_y: float, delta: float) -> void :




	var gait: = clampf(planar_speed / 6.0, 0.0, 1.0)
	var hip_l: = 0.0
	var hip_r: = 0.0
	var knee_l: = 0.0
	var knee_r: = 0.0
	if grounded:
		var swing_l: = sin(gait_phase)
		var swing_r: = sin(gait_phase + PI)
		hip_l = swing_l * 0.8 * gait
		hip_r = swing_r * 0.8 * gait

		knee_l = - maxf( - swing_l, 0.0) * 1.1 * gait
		knee_r = - maxf( - swing_r, 0.0) * 1.1 * gait
	else:

		var tuck: = clampf(vel_y * 0.06, -0.35, 0.5)
		hip_l = -0.4 - tuck * 0.4
		hip_r = -0.15 - tuck * 0.2
		knee_l = -0.9 - tuck
		knee_r = -0.5 - tuck * 0.5
	var w: = 1.0 - exp(-14.0 * delta)
	_hip_l.rotation.x = lerpf(_hip_l.rotation.x, hip_l, w)
	_hip_r.rotation.x = lerpf(_hip_r.rotation.x, hip_r, w)
	var kl: = _hip_l.get_node("KneeL") as Node3D
	var kr: = _hip_r.get_node("KneeR") as Node3D
	kl.rotation.x = lerpf(kl.rotation.x, knee_l, w)
	kr.rotation.x = lerpf(kr.rotation.x, knee_r, w)



func _capsule(radius: float, mid_height: float) -> CapsuleMesh:
	var m: = CapsuleMesh.new()
	m.radius = radius
	m.height = maxf(mid_height + radius * 2.0, radius * 2.05)
	return m

func _cylinder(radius: float, height: float) -> CylinderMesh:
	var m: = CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	return m

func _toon_mat(color: Color) -> ShaderMaterial:
	var mat: = ShaderMaterial.new()
	mat.shader = TOON
	mat.set_shader_parameter("albedo", color)
	return mat

func _mesh_node(parent: Node, mesh: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	if mesh is PrimitiveMesh:
		(mesh as PrimitiveMesh).material = _toon_mat(color)
	var mi: = MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	return mi

func _outline(mi: MeshInstance3D) -> void :
	var mat: = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_FRONT
	mat.albedo_color = OUTLINE_COLOR
	var shell: = MeshInstance3D.new()
	shell.mesh = mi.mesh
	shell.scale = Vector3.ONE * OUTLINE_GROW
	shell.material_override = mat
	mi.add_child(shell)

func _build_hair(head_r: float) -> void :

	var color: = config.hair_color()
	var hs: = p("hair_scale")
	match config.hair:
		0:
			pass
		1:
			_hair_dome(head_r * 1.06 * hs, color, Vector3(0.0, head_r * 0.12, - head_r * 0.06))
		2:
			var dome: = _hair_dome(head_r * 1.06 * hs, color, 
				Vector3(head_r * 0.08, head_r * 0.1, - head_r * 0.04))
			dome.rotation.z = 0.18
		3:
			_hair_dome(head_r * 1.02 * hs, color, Vector3(0.0, head_r * 0.14, 0.0))
			for i in 3:
				var spike: = CylinderMesh.new()
				spike.top_radius = 0.0
				spike.bottom_radius = head_r * 0.16
				spike.height = head_r * 0.55
				spike.material = _toon_mat(color)
				var mi: = MeshInstance3D.new()
				mi.mesh = spike
				mi.position = Vector3((i - 1) * head_r * 0.35, 
					head_r * (1.0 if i == 1 else 0.88), - head_r * 0.1 * (i - 1))
				mi.rotation.z = (i - 1) * -0.35
				_head_root.add_child(mi)
		4:
			var dome: = _hair_dome(head_r * 1.08 * hs, color, 
				Vector3(0.0, head_r * 0.1, - head_r * 0.02))
			dome.scale.y *= 1.1
			var skirt: = _cylinder(head_r * 1.05, head_r * 0.9)
			skirt.material = _toon_mat(color)
			var mi: = MeshInstance3D.new()
			mi.mesh = skirt
			mi.position = Vector3(0.0, - head_r * 0.25, - head_r * 0.28)
			_head_root.add_child(mi)
			_outline(mi)
		5:
			_hair_dome(head_r * 1.06 * hs, color, Vector3(0.0, head_r * 0.12, - head_r * 0.05))
			var tail: = _capsule(head_r * 0.22, head_r * 0.7)
			tail.material = _toon_mat(color)
			var mi: = MeshInstance3D.new()
			mi.mesh = tail
			mi.position = Vector3(0.0, - head_r * 0.1, - head_r * 1.05)
			mi.rotation.x = 0.5
			_head_root.add_child(mi)
			_outline(mi)

func _hair_dome(radius: float, color: Color, offset: Vector3) -> MeshInstance3D:
	var dome: = SphereMesh.new()
	dome.radius = radius
	dome.height = radius * 2.0
	dome.is_hemisphere = true
	dome.material = _toon_mat(color)
	var mi: = MeshInstance3D.new()
	mi.mesh = dome
	mi.position = offset
	mi.scale = Vector3(1.0, 0.72, 1.0)
	_head_root.add_child(mi)
	_outline(mi)
	return mi
