class_name ModelRig
extends Node3D














const MODEL_PATHS: = [
	"res://game/character/models/player_char.glb", 
	"res://game/character/models/player.glb", 
]
const TOON: = preload("res://game/fx/toon.gdshader")
const WII: = preload("res://game/fx/wii.gdshader")
const TOON_NUMBER: = preload("res://game/fx/toon_number.gdshader")

const TOON_HAIR: = preload("res://game/fx/toon_hair.gdshader")
const BLEND: = 0.18





const BLEND_SNAP: = 0.0
const SNAP_ACTIONS: = ["spike", "spike_L", "spike_light", "spike_light_L", "dive", "dive_r", "dive_l", 
	"block", "block_hit", "kick_r", "kick_l", "approach", "receive", "set", 
	"set_air", "land", "receive_l", "receive_r", "receive_back", "set_low"]
const TARGET_HEIGHT: = 1.8


const HEIGHT_RANGE: = 0.06
const BLUSH_COLOR: = Color(0.96, 0.52, 0.52, 1.0)
const NUMBER_FONT: = "res://game/fonts/VarsityTeam-Bold.otf"
const HAIR_DIR: = "res://game/character/hair/%s.glb"







const TAIL_PREFIX: = "tail"









const TAIL_ROOT_STIFF: = 28.0
const TAIL_ROOT_DAMP: = 11.0


const TAIL_TIP_STIFF: = 19.0
const TAIL_TIP_DAMP: = 6.2






const TAIL_SWING: = 0.12
const TAIL_GRAVITY: = 0.15



const TAIL_FOLLOW: = 1.28
const TAIL_MAX: = 0.42
const GRAV_V: = Vector2(TAIL_GRAVITY, 0.0)
const SHAPE_HEAVY: = "heavy"
const SHAPE_SLIM: = "slim"
const MODEL_YAW: = 0.0
const OUTLINE_WIDTH: = 0.03
const OUTLINE_COLOR: = Color(0.05, 0.05, 0.08)
var _left_handed: = false
var hold_frame: = false
var spike_light: = false
const ANIM_FPS: = 30.0
const SPIKE_STRIKE_FRAME: = 2.0
const CLIP_START_FRAME: = 1.0

const CLIP_ALIASES: = {
	"idle": ["idle"], 
	"run": ["run", "jog"], 
	"jump_rise": ["jump_rise", "jump", "idle"], 
	"jump_fall": ["jump_fall", "fall", "idle"], 
	"charge": ["charge", "jump_charge", "crouch"], 



	"approach": ["approach", "spike_approach", "charge", "run"], 
	"dive": ["dive"], 


	"dive_r": ["dive_r", "dive_R", "dive_right", "dive"], 
	"dive_l": ["dive_l", "dive_L", "dive_left", "dive"], 
	"serve": ["serve", "serve_toss"], 
	"block": ["block"], 


	"block_hit": ["block_hit", "blockhit", "block_fall", "block", "jump_fall"], 


	"kick_r": ["kick_r", "kick_R", "kick_right", "receive", "recieve"], 
	"kick_l": ["kick_l", "kick_L", "kick_left", "receive", "recieve"], 
	"spike": ["spike", "attack", "hit"], 



	"spike_L": ["spike_L", "spike_l", "spike"], 


	"spike_light": ["spike_light", "spikelight", "spike_soft", "spike", "attack", "hit"], 
	"spike_light_L": ["spike_light_L", "spike_light_l", "spike_light", "spike_L", "spike"], 
	"jump_rise_L": ["jump_rise_L", "jump_rise_l", "jump_L", "jump_rise", "jump", "idle"], 


	"set_air": ["set_air", "air_set", "jump_set", "jumpset", "set", "setting", 
		"overhand", "receive", "recieve"], 


	"getup_front": ["getup_front", "getup", "dive"], 
	"getup_back": ["getup_back", "getup", "dive"], 
	"strafe_left": ["strafe_left", "strafe_l", "shuffle_left", "run"], 
	"strafe_right": ["strafe_right", "strafe_r", "shuffle_right", "run"], 
	"run_back": ["run_back", "backpedal", "run"], 



	"strafe_fwd": ["strafe_fwd", "strafe_forward", "shuffle_forward", "run"], 




	"receive": ["receive", "recieve", "dig", "bump"], 




	"receive_l": ["recieve_l", "receive_l", "receive_L", "receive_left", "dig_l", "receive", "recieve"], 
	"receive_r": ["recieve_r", "receive_r", "receive_R", "receive_right", "dig_r", "receive", "recieve"], 
	"receive_back": ["recieve_back", "receive_back", "receive_behind", "dig_back", "receive", "recieve"], 




	"set": ["set", "setting", "overhand", "receive", "recieve"], 


	"set_low": ["set_low", "set_lo", "low_set", "set", "setting", "receive"], 

	"land": ["land", "landing"], 


	"stop": ["stop", "skid", "brake"], 



	"idle_alt": ["idle_alt", "idle"], 
}

func has_action(name: String) -> bool:
	return _clip_map.has(name)




const LOCO_HOOKS: = ["run", "strafe_left", "strafe_right", "strafe_fwd", 
	"run_back"]





func set_head_visible(on: bool) -> void :
	_scrub_shell_maps()
	if _face_root != null and is_instance_valid(_face_root):
		_face_root.visible = on
	if _hair_root != null and is_instance_valid(_hair_root):
		_hair_root.visible = on


	for m in find_children("*", "MeshInstance3D", true, false):
		var mi: = m as MeshInstance3D
		if not String(mi.name).to_lower().contains("head"):
			continue
		mi.visible = on
		var shell: MeshInstance3D = _shells.get(mi)
		if shell != null and is_instance_valid(shell):
			shell.visible = on
		var aura: MeshInstance3D = _hl_shells.get(mi)
		if aura != null and is_instance_valid(aura) and not on:
			aura.visible = false






var _shell_lod_hidden: = false

func set_outline_lod(hidden: bool) -> void :
	if hidden == _shell_lod_hidden:
		return
	_shell_lod_hidden = hidden
	for mi in _shells:
		var s: MeshInstance3D = _shells[mi]
		if is_instance_valid(s) and is_instance_valid(mi):
			s.visible = not hidden and (mi as MeshInstance3D).visible

func stride_phase() -> float:
	if _anim == null or _current == "":
		return -1.0
	var is_loco: = false
	for hook in LOCO_HOOKS:
		if _clip_map.get(hook, "") == _current:
			is_loco = true
			break
	if not is_loco:
		return -1.0
	var length: = _anim.current_animation_length
	if length <= 0.0:
		return -1.0
	return fposmod(_anim.current_animation_position, length) / length

func anim_normalized() -> float:



	if _anim == null or _anim.current_animation == "":
		return 0.0
	var length: = _anim.current_animation_length
	if length <= 0.0:
		return 0.0
	return clampf(_anim.current_animation_position / length, 0.0, 1.0)


const ACTION_LOOP: = {"charge": false, "dive": false, "serve": false, 
	"getup_front": false, "getup_back": false, "receive": false, 
	"receive_l": false, "receive_r": false, "receive_back": false, "set_low": false, 
	"set": false, "land": false, "stop": false, 



	"idle_alt": true, 
	"strafe_left": true, "strafe_right": true, "run_back": true, 
	"strafe_fwd": true}







func clip_name(want: String) -> String:
	return _clip_map.get(want, "")




func action_length(name: String) -> float:
	if not _clip_map.has(name):
		return 0.0
	var anim: Animation = _anim.get_animation(_clip_map[name])
	return anim.length if anim != null else 0.0

const SLOT_ALIASES: = {
	"pants": "shorts", 
	"cleets": "shoes", 
	"cleats": "shoes", 
	"shoe": "shoes", 
	"sock": "socks", 
	"shirt": "jersey", 
	"body": "skin", 




	"jerseyaccent": "accent", 
	"pantsaccent": "pants_accent", 
	"kneepad": "kneepad", 
}

const HAND_BONES: = {"l": ["hand.l", "hand_l", "hand.L"], 
	"r": ["hand.r", "hand_r", "hand.R"]}

var hand_radius: = 0.0
var hand_rest: = Vector3.ZERO

var _anim: AnimationPlayer
var _mats: = {}





var _surface_slots: = {}
var _shells: = {}
var _outline_mat: StandardMaterial3D = null





var _hl_mat: StandardMaterial3D = null
var _hl_shells: = {}
static var _invisible_shell: ShaderMaterial = null



var _pick_targets: = {}
const PICK_GROUPS: = {
	"head": CharacterConfig.HEAD_SHAPES, 
	"shorts": CharacterConfig.SHORTS_SHAPES, 
	"socks": CharacterConfig.SOCKS_SHAPES, 
	"shirt": CharacterConfig.SHIRT_SHAPES, 
}
var _fallback_mat: ShaderMaterial = null
var _current: = ""
var _clip_map: = {}
var _skel: Skeleton3D = null
var _bone: = {"l": -1, "r": -1}
var _bone_offset: = {"l": Vector3.ZERO, "r": Vector3.ZERO}
var _scene: Node3D = null
var _base_scale: = 1.0
var _shape_targets: Array = []








const CLOTH_KEYS: = ["shirt_lift", "shirt_flare", "shirt_drop", "shirt_billow_l", "shirt_billow_r"]
var _cloth_targets: Array = []
var _cloth_on: = true
var _pinny_worn: = false

var _cloth: = [0.0, 0.0, 0.0, 0.0, 0.0]
var _cloth_was_air: = false
var _cloth_land: = 0.0
const CLOTH_ATTACK: = 0.05
const CLOTH_RELEASE: = 0.14
var _number_vp: SubViewport = null
var _number_text: Label = null
var _number_mat: ShaderMaterial = null
var _face_root: Node3D = null
var _face_vp: SubViewport = null
var _face_canvas: Control = null
var _face_parts: Array = []
var _face_radius: = 0.65



var playback_scale: = 1.0
var _hair_root: Node3D = null




var _hair_mats: Array = []
var _hair_defaults: Array = []
var _hair_yrange: = Vector2(0.0, 1.0)
var _hair_grad_active: = false
var _hair_style: = -1


var _acc_roots: = {}
var _acc_ids: = {}
var _acc_mats: = {}
var _acc_pivot: = {}
var _tail_skel: Skeleton3D = null



var _tails: Array = []



var _acc_tails: = {}



var _acc_yrange: = {}
var _acc_grad_active: = false
var _prev_head_pos: = Vector3.ZERO
var _prev_head_vel: = Vector3.ZERO
var _head_mount: BoneAttachment3D = null
var _head_bone: = -1








const GAZE_YAW_LIMIT_DEG: = 72.0
const GAZE_PITCH_LIMIT_DEG: = 86.0
const GAZE_DAMP: = 0.55
const GAZE_BLEND: = 7.0





const GAZE_VERTICAL_GUARD_DEG: = 15.0





const GAZE_FADE_PITCH_START: = 58.0
const GAZE_FADE_PITCH_FULL: = 74.0
const GAZE_MIN_DIST: = 0.35






const GAZE_AIM_DIST: = 3.0

const GAZE_SAFE_MARGIN: = 0.08





const GAZE_TURN_RATE: = 7.0
var _gaze_dir: = Vector3.ZERO
var _look: LookAtModifier3D = null
var _gaze: Node3D = null
var _gaze_weight: = 0.0
var _head_rest: = Vector3(0.0, 1.5, 0.0)
var _head_radii: = Vector3(0.65, 0.68, 0.65)

static func model_path() -> String:
	for path in MODEL_PATHS:
		if ResourceLoader.exists(path):
			return path
	return ""

static func available() -> bool:
	return model_path() != ""

var _reflection: = false

func setup(is_reflection: = false) -> bool:



	_reflection = is_reflection
	var packed: PackedScene = load(model_path())
	if packed == null:
		return false
	var scene: = packed.instantiate()
	add_child(scene)
	_anim = _find_anim(scene)
	if _anim != null:



		for want in CLIP_ALIASES:
			for candidate in CLIP_ALIASES[want]:
				if _anim.has_animation(candidate)\
				and _anim.get_animation(candidate).length > 0.02:
					_clip_map[want] = candidate
					break

		_anim.playback_default_blend_time = BLEND



		var loop_clips: = {}
		for want in ["idle", "run"]:
			if _clip_map.has(want):
				loop_clips[_clip_map[want]] = true




		for want in ACTION_LOOP:
			if ACTION_LOOP[want] and _clip_map.has(want):
				loop_clips[_clip_map[want]] = true
		for want in _clip_map:
			var anim: Animation = _anim.get_animation(_clip_map[want])
			if anim != null:
				anim.loop_mode = Animation.LOOP_LINEAR if loop_clips.has(_clip_map[want])\
				else Animation.LOOP_NONE
	var meshes: Array = []
	_collect_meshes(scene, meshes)

	var top: = 0.01
	for m in meshes:
		top = maxf(top, (m as MeshInstance3D).mesh.get_aabb().end.y)
	var k: = TARGET_HEIGHT / top
	_scene = scene
	_base_scale = k
	scene.scale = Vector3.ONE * k
	scene.rotation.y = MODEL_YAW


	for m in meshes:
		var mi: = m as MeshInstance3D
		if not String(mi.name).to_lower().contains("hand"):
			continue
		var box: = mi.mesh.get_aabb()

		hand_radius = box.size.z * 0.5 * k
		hand_rest = Vector3(box.end.x - box.size.z * 0.5, 
			box.get_center().y, box.get_center().z) * k
		mi.visible = false
	_apply_toon_materials(scene)
	_skel = _find_skeleton(scene)
	_cloth_targets = []
	if _reflection:
		_collect_shape_targets(scene)
		return true
	_ink(meshes, OUTLINE_WIDTH / k)


	_collect_shape_targets(scene)
	_calibrate_hands()
	_build_number_patch(meshes)
	_build_face(meshes)
	return true

func anim_state() -> Dictionary:
	if _anim == null:
		return {}
	return {"clip": _current, "pos": _anim.current_animation_position, 
		"speed": _anim.speed_scale}

func seek_normalized(value: float) -> void :
	if _anim == null or _anim.current_animation == "":
		return
	var length: = _anim.current_animation_length
	if length > 0.0001:
		_anim.seek(clampf(value, 0.0, 1.0) * length, true)

func apply_anim_state(s: Dictionary) -> void :

	if _anim == null or s.is_empty() or String(s.clip) == "":
		return
	if _anim.current_animation != s.clip:
		_anim.play(s.clip)
	_anim.speed_scale = s.speed
	_anim.seek(s.pos, true)





func play_clip(name: String, loop: = true) -> String:
	if _anim == null or name == "":
		return ""
	var found: = ""
	if _anim.has_animation(name):
		found = name
	else:
		var want: = name.to_lower()
		for a in _anim.get_animation_list():
			var sl: = String(a).to_lower()
			if sl == want or sl.ends_with("/" + want) or sl.ends_with("|" + want)\
			or sl.ends_with(want) or sl.contains(want):
				found = String(a)
				break
	if found == "":
		return ""
	var anim: = _anim.get_animation(found)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	_anim.play(found)
	_current = found
	return found


func clip_finished() -> bool:
	return _anim == null or not _anim.is_playing()



func clip_names() -> PackedStringArray:
	return _anim.get_animation_list() if _anim != null else PackedStringArray()

func _build_face(meshes: Array) -> void :



	if _skel == null:
		return
	var head_bone: = _skel.find_bone("head")
	if head_bone < 0:
		return
	var head_box: = AABB()
	for m in meshes:
		var mi: = m as MeshInstance3D
		if String(mi.name).to_lower().contains("head"):
			head_box = mi.mesh.get_aabb()
			break
	if head_box.size.y <= 0.0:
		return
	var centre: = head_box.get_center()


	_head_radii = head_box.size * 0.5
	var r: float = _head_radii.x
	var mount: = BoneAttachment3D.new()
	mount.bone_idx = head_bone
	_head_bone = head_bone
	_skel.add_child(mount)
	_face_root = Node3D.new()

	var rest: = _skel.get_bone_global_rest(head_bone)
	_face_root.transform = rest.affine_inverse() * Transform3D(Basis(), centre)
	mount.add_child(_face_root)
	_head_mount = mount
	_face_radius = r
	_setup_gaze(head_bone)



func head_centre_global() -> Vector3:
	if _face_root != null and is_instance_valid(_face_root) and _face_root.is_inside_tree():
		return _face_root.global_position
	return global_position + global_transform.basis.y * 1.45

func _setup_gaze(head_bone: int) -> void :


	_gaze = Node3D.new()
	_gaze.top_level = true
	add_child(_gaze)
	_look = LookAtModifier3D.new()
	_look.bone_name = _skel.get_bone_name(head_bone)
	_look.forward_axis = _gaze_forward_axis(head_bone)
	_look.origin_from = LookAtModifier3D.ORIGIN_FROM_SELF


	_look.use_angle_limitation = true
	_look.symmetry_limitation = true
	_look.primary_limit_angle = deg_to_rad(GAZE_YAW_LIMIT_DEG)
	_look.secondary_limit_angle = deg_to_rad(GAZE_PITCH_LIMIT_DEG)
	_look.primary_damp_threshold = GAZE_DAMP
	_look.secondary_damp_threshold = GAZE_DAMP
	_look.origin_safe_margin = GAZE_SAFE_MARGIN
	_look.influence = 0.0
	_skel.add_child(_look)
	_look.target_node = _look.get_path_to(_gaze)




	_head_rest = _bone_to_local(_skel.get_bone_global_rest(head_bone)).origin

func _gaze_forward_axis(head_bone: int) -> int:




	var basis: = _bone_to_local(_skel.get_bone_global_rest(head_bone)).basis
	var forward: = Vector3(0.0, 0.0, 1.0).rotated(Vector3.UP, MODEL_YAW)
	var axes: = [basis.x, - basis.x, basis.y, - basis.y, basis.z, - basis.z]
	var best: = 4
	var best_dot: = -2.0
	for i in axes.size():
		var d: float = (axes[i] as Vector3).normalized().dot(forward)
		if d > best_dot:
			best_dot = d
			best = i
	return best

func gaze_at(world_pos: Vector3, want: float, delta: float) -> void :


	if _look == null or _gaze == null:
		return
	var head: = global_transform * _head_rest




	var to_ball: = world_pos - head
	var pitch: = absf(atan2(to_ball.y, Vector2(to_ball.x, to_ball.z).length()))
	want *= 1.0 - smoothstep(deg_to_rad(GAZE_FADE_PITCH_START), 
		deg_to_rad(GAZE_FADE_PITCH_FULL), pitch)
	var aim: = _stable_aim(head, world_pos)
	var want_dir: = aim - head
	want_dir = want_dir.normalized()
	if _gaze_dir.length_squared() < 0.5 or _gaze_weight <= 0.001:


		_gaze_dir = want_dir
	else:

		var ang: = _gaze_dir.angle_to(want_dir)
		if ang > 0.0001:
			var step: = minf(1.0, (GAZE_TURN_RATE * delta) / ang)
			var turned: = _gaze_dir.slerp(want_dir, step)


			_gaze_dir = turned.normalized() if turned.length_squared() > 0.001 else want_dir
	_gaze.global_position = head + _gaze_dir * GAZE_AIM_DIST
	_gaze_weight = lerpf(_gaze_weight, clampf(want, 0.0, 1.0), 
		1.0 - exp( - GAZE_BLEND * delta))
	_look.influence = _gaze_weight

	_look.active = _gaze_weight > 0.001

func _stable_aim(head: Vector3, world_pos: Vector3) -> Vector3:


	var to: = world_pos - head
	if to.length() < GAZE_MIN_DIST:
		var away: = to.normalized() if to.length() > 0.001 else global_basis.z
		to = away * GAZE_MIN_DIST
	var flat: = Vector2(to.x, to.z)
	var min_flat: float = absf(to.y) * tan(deg_to_rad(GAZE_VERTICAL_GUARD_DEG))
	if min_flat > 0.001 and flat.length() < min_flat:







		var fwd: = Vector2(global_basis.z.x, global_basis.z.z)
		var anchor: = (fwd.normalized() if fwd.length() > 0.001
			else Vector2(0.0, 1.0)) * min_flat
		var depth: = clampf(flat.length() / min_flat, 0.0, 1.0)
		flat = anchor.lerp(flat, depth)
		to = Vector3(flat.x, to.y, flat.y)
	return head + to

func _surface_point(x: float, y: float) -> Vector3:


	var nx: = x / maxf(_head_radii.x, 0.001)
	var ny: = y / maxf(_head_radii.y, 0.001)
	var inside: = clampf(1.0 - nx * nx - ny * ny, 0.0, 1.0)
	return Vector3(x, y, _head_radii.z * sqrt(inside) * 1.01)







func _surface_lifted(x: float, y: float, lift: float) -> Vector3:
	var p: = _surface_point(x, y)


	var n: = Vector3(
		p.x / maxf(_head_radii.x * _head_radii.x, 0.0001), 
		p.y / maxf(_head_radii.y * _head_radii.y, 0.0001), 
		p.z / maxf(_head_radii.z * _head_radii.z, 0.0001))
	if n.length_squared() < 1e-06:
		return p + Vector3(0.0, 0.0, lift)
	return p + n.normalized() * lift

func _face_mesh(mesh: Mesh, pos: Vector3, rot: Vector3, scale: Vector3, 
		color: Color) -> void :
	var mat: = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mesh.surface_set_material(0, mat) if mesh is ArrayMesh else null
	if mesh is PrimitiveMesh:
		(mesh as PrimitiveMesh).material = mat
	var mi: = MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	mi.scale = scale
	_face_root.add_child(mi)



	Ink.untag([mi])
	_face_parts.append(mi)






const FACE_DIR: = "res://game/character/faces"







static var _face_paths: Dictionary = {}
static var _faces_scanned: = false

static func _scan_faces() -> void :
	_faces_scanned = true
	_face_paths.clear()
	var dir: = DirAccess.open(FACE_DIR)
	if dir == null:
		return
	var re: = RegEx.new()
	re.compile("^face[ _\\-]?([0-9]+)$")
	for entry in dir.get_files():
		var file: = entry


		if file.ends_with(".import"):
			file = file.substr(0, file.length() - 7)
		var m: = re.search(file.get_basename().to_lower())
		if m == null:
			continue
		var kind: = int(m.get_string(1)) - 1
		if kind < 0 or _face_paths.has(kind):
			continue
		_face_paths[kind] = "%s/%s" % [FACE_DIR, file]




static func face_count() -> int:
	if not _faces_scanned:
		_scan_faces()
	var n: = CharacterConfig.FACE_TYPES
	for kind in _face_paths:
		n = maxi(n, int(kind) + 1)
	return n

static func face_texture(kind: int) -> Texture2D:
	if not _faces_scanned:
		_scan_faces()
	if not _face_paths.has(kind):
		return null
	var path: String = _face_paths[kind]
	if not ResourceLoader.exists(path):


		push_warning("face art '%s' not imported yet, reimport the project"
			%path)
		return null
	return load(path) as Texture2D



const FACE_DECAL_EXTENT: = 0.66
const FACE_DECAL_STEPS: = 12




const FACE_DECAL_LIFT: = 0.055

func _build_face_decal(tex: Texture2D) -> void :




	var r: = _face_radius
	var half: = r * FACE_DECAL_EXTENT
	var st: = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iy in range(FACE_DECAL_STEPS + 1):
		for ix in range(FACE_DECAL_STEPS + 1):
			var u: = float(ix) / float(FACE_DECAL_STEPS)
			var v: = float(iy) / float(FACE_DECAL_STEPS)
			st.set_uv(Vector2(u, v))

			st.add_vertex(_surface_lifted(
				lerpf( - half, half, u), lerpf(half, - half, v), 
				r * FACE_DECAL_LIFT))
	for iy in FACE_DECAL_STEPS:
		for ix in FACE_DECAL_STEPS:
			var i0: = iy * (FACE_DECAL_STEPS + 1) + ix
			var i1: = i0 + 1
			var i2: = i0 + FACE_DECAL_STEPS + 1
			var i3: = i2 + 1
			st.add_index(i0)
			st.add_index(i2)
			st.add_index(i1)
			st.add_index(i1)
			st.add_index(i2)
			st.add_index(i3)
	var mat: = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = false
	var mi: = MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	_face_root.add_child(mi)


	Ink.untag([mi])
	_face_parts.append(mi)






const FACE_CANVAS: = 512

func set_face(cfg: CharacterConfig) -> void :
	if _face_root == null:
		return
	for p in _face_parts:
		(p as Node).queue_free()
	_face_parts.clear()
	_ensure_face_vp()
	_rebuild_face_layers(cfg)



	_build_face_decal(_face_vp.get_texture())

func _ensure_face_vp() -> void :
	if _face_vp != null:
		return
	_face_vp = SubViewport.new()
	_face_vp.size = Vector2i(FACE_CANVAS, FACE_CANVAS)
	_face_vp.transparent_bg = true
	_face_vp.disable_3d = true



	_face_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_face_vp)
	_face_canvas = Control.new()

	_face_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_face_vp.add_child(_face_canvas)





func _kick_vp(vp: SubViewport) -> void :
	if vp == null:
		return
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var tree: = get_tree()
	if tree == null:
		return
	var kick: = func() -> void :
		if is_instance_valid(vp):
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	tree.process_frame.connect(kick, CONNECT_ONE_SHOT)

func _rebuild_face_layers(cfg: CharacterConfig) -> void :
	_kick_vp(_face_vp)
	for c in _face_canvas.get_children():
		c.queue_free()

	if cfg.blush:
		_add_blush(cfg)
	_add_brows(cfg)
	_add_eyes(cfg)
	_add_feature("nose", cfg.nose_shape, Color.WHITE, _feat_xform("nose", cfg))
	_add_feature("mouth", cfg.mouth_shape, Color.WHITE, _feat_xform("mouth", cfg))



class _BlushLayer extends Control:
	var tex: Texture2D
	var patches: Array = []
	func _draw() -> void :
		for p in patches:
			var rw: float = p[1]
			var rh: float = p[2]
			draw_texture_rect(tex, Rect2(p[0] - Vector2(rw, rh), 
				Vector2(rw * 2.0, rh * 2.0)), false, p[3])

static var _blush_tex: Texture2D = null
static func _soft_disc() -> Texture2D:
	if _blush_tex != null:
		return _blush_tex


	var n: = 256
	var img: = Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c: = (n - 1) * 0.5
	for y in n:
		for x in n:
			var d: = Vector2((x - c) / c, (y - c) / c).length()
			var a: = 1.0 - smoothstep(0.93, 1.0, d)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_blush_tex = ImageTexture.create_from_image(img)
	return _blush_tex



func _add_blush(cfg: CharacterConfig) -> void :
	var shape: = CharacterConfig.blush_shape_key(cfg.blush_shape)
	if shape != "circle":
		var tex: = _blush_texture(shape)
		if tex != null:
			_add_blush_texture(cfg, tex, shape)
			return
	_add_blush_circle(cfg)

func _add_blush_circle(cfg: CharacterConfig) -> void :
	var k: = FACE_CANVAS / 512.0



	var scale_min: = 18.0 / 61.5
	var scale_max: = 105.0 / 61.5
	var rad: = 52.0 * lerpf(scale_min, scale_max, cfg.blush_size) * k
	var rw: = 52.0 * 1.6 * lerpf(scale_min, scale_max, cfg.blush_width) * k
	var gap: = lerpf(-40.0, 115.0, cfg.blush_spacing) * k


	var cheek_x: = FACE_CANVAS * 0.24 + gap
	var cheek_y: = FACE_CANVAS * 0.7 + (cfg.blush_height - 0.5) * 260.0 * k
	var cen: = FACE_CANVAS * 0.5
	var layer: = _BlushLayer.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.tex = _soft_disc()
	var col: = Color(cfg.blush_color, lerpf(0.12, 0.92, cfg.blush_opacity))
	layer.patches = [
		[Vector2(cen + cheek_x, cheek_y), rw, rad, col], 
		[Vector2(cen - cheek_x, cheek_y), rw, rad, col], 
	]
	_face_canvas.add_child(layer)





func _add_blush_texture(cfg: CharacterConfig, tex: Texture2D, key: String) -> void :
	var k: = FACE_CANVAS / 512.0
	var w: = float(tex.get_width())
	var h: = float(tex.get_height())
	var left: = AtlasTexture.new()
	left.atlas = tex
	left.region = Rect2(0.0, 0.0, w * 0.5, h)
	var right: = AtlasTexture.new()
	right.atlas = tex
	right.region = Rect2(w * 0.5, 0.0, w * 0.5, h)
	var col: = Color(cfg.blush_color, lerpf(0.12, 0.98, cfg.blush_opacity))

	var sz: = Vector2(1.0 + (cfg.blush_width - 0.5) * 0.9, 
		1.0 + (cfg.blush_size - 0.5) * 0.9)
	var gap: = (cfg.blush_spacing - 0.5) * 220.0 * k
	var dy: = (cfg.blush_height - 0.5) * 260.0 * k
	var half: = FACE_CANVAS * 0.5
	var lc: = _blush_half_center(key, false)
	var rc: = _blush_half_center(key, true)
	_face_canvas.add_child(_blush_half(right, 0.5, 1.0, 
		Vector2(rc.x * half, rc.y * FACE_CANVAS), Vector2(gap, dy), sz, col))
	_face_canvas.add_child(_blush_half(left, 0.0, 0.5, 
		Vector2(lc.x * half, lc.y * FACE_CANVAS), Vector2( - gap, dy), sz, col))



func _blush_half(tex: Texture2D, anchor_l: float, anchor_r: float, pivot: Vector2, 
		off: Vector2, sz: Vector2, col: Color) -> Control:
	var wrap: = Control.new()
	wrap.anchor_left = anchor_l
	wrap.anchor_right = anchor_r
	wrap.anchor_top = 0.0
	wrap.anchor_bottom = 1.0
	wrap.offset_left = off.x
	wrap.offset_right = off.x
	wrap.offset_top = off.y
	wrap.offset_bottom = off.y
	wrap.pivot_offset = pivot
	wrap.scale = sz
	wrap.modulate = col
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tr: = TextureRect.new()
	tr.texture = tex
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(tr)
	return wrap

static var _blush_tex_cache: = {}
static func _blush_texture(key: String) -> Texture2D:
	if _blush_tex_cache.has(key):
		return _blush_tex_cache[key]
	var path: = "res://game/character/faces/blush/%s.png" % key
	var t: Texture2D = (load(path) as Texture2D) if ResourceLoader.exists(path) else null
	_blush_tex_cache[key] = t
	return t



static var _blush_center_cache: = {}
static func _blush_half_center(key: String, right: bool) -> Vector2:
	var ck: = "%s:%s" % [key, "r" if right else "l"]
	if _blush_center_cache.has(ck):
		return _blush_center_cache[ck]
	var c: = Vector2(0.5, 0.55)
	var tex: = _blush_texture(key)
	if tex != null:
		var img: = tex.get_image()
		img.convert(Image.FORMAT_RGBA8)
		var hw: = int(img.get_width() * 0.5)
		var x0: = hw if right else 0
		var ww: = img.get_width() - hw if right else hw
		var sub: = img.get_region(Rect2i(x0, 0, ww, img.get_height()))
		var u: = sub.get_used_rect()
		if u.size.x > 0 and u.size.y > 0:
			var ctr: = Vector2(u.position) + Vector2(u.size) * 0.5
			c = Vector2(ctr.x / sub.get_width(), ctr.y / sub.get_height())
	_blush_center_cache[ck] = c
	return c





const EYE_CX: = 0.115
const EYE_CY: = 0.45
func _add_eyes(cfg: CharacterConfig) -> void :
	var n: = FaceParts.count("eyes")
	if n <= 0 or cfg.eye_shape < 0:
		return
	var idx: = clampi(cfg.eye_shape, 0, n - 1)
	var tex: = FaceParts.texture("eyes", idx)
	if tex == null:
		return
	var w: = float(tex.get_width())
	var h: = float(tex.get_height())
	var right: = AtlasTexture.new()
	right.atlas = tex
	right.region = Rect2(w * 0.5, 0.0, w * 0.5, h)
	var sz: = Vector2(lerpf(0.6, 1.6, cfg.eye_width), 
		lerpf(0.6, 1.6, cfg.eye_size_y))
	var gap: = lerpf(-70.0, 120.0, cfg.eye_spacing) * (FACE_CANVAS / 512.0)
	var dy: = (cfg.eye_height - 0.5) * -390.0 * (FACE_CANVAS / 512.0)
	var pair_x: = (cfg.eye_x - 0.5) * 270.0 * (FACE_CANVAS / 512.0)
	var rot: = (cfg.eye_rot - 0.5) * PI


	var half: = FACE_CANVAS * 0.5
	var rc: = FaceParts.right_half_center("eyes", idx)
	var piv_r: = Vector2(rc.x * half, rc.y * FACE_CANVAS)
	var piv_l: = Vector2((1.0 - rc.x) * half, rc.y * FACE_CANVAS)
	var po_r: = Vector2(FACE_CANVAS * EYE_CX, FACE_CANVAS * EYE_CY)
	var po_l: = Vector2(half - FACE_CANVAS * EYE_CX, FACE_CANVAS * EYE_CY)
	var s0: = Vector2(1.1, 1.1)
	var off_r: = Vector2(gap + pair_x, dy) + _pivot_comp(po_r, piv_r, s0)
	var off_l: = Vector2( - gap + pair_x, dy) + _pivot_comp(po_l, piv_l, s0)




	var iris: = FaceParts.tint_texture("eyes", idx)
	if iris != null:
		var iw: = float(iris.get_width())
		var ih: = float(iris.get_height())
		var iris_r: = AtlasTexture.new()
		iris_r.atlas = iris
		iris_r.region = Rect2(iw * 0.5, 0.0, iw * 0.5, ih)
		var t_r: = _eye_half(iris_r, false, piv_r, off_r, sz, rot, 0.5, 1.0)
		t_r.modulate = cfg.eye_color
		_face_canvas.add_child(t_r)
		var t_l: = _eye_half(iris_r, true, piv_l, off_l, sz, - rot, 0.0, 0.5)
		t_l.modulate = cfg.eye_color
		_face_canvas.add_child(t_l)
	_face_canvas.add_child(_eye_half(right, false, piv_r, off_r, sz, rot, 0.5, 1.0))
	_face_canvas.add_child(_eye_half(right, true, piv_l, off_l, sz, - rot, 0.0, 0.5))




const BROW_CX: = 0.13
const BROW_CY: = 0.27
func _add_brows(cfg: CharacterConfig) -> void :
	if cfg.brow_shape < 0:
		return
	var n: = FaceParts.count("brows")
	if n <= 0:
		return
	var tex: = FaceParts.texture("brows", clampi(cfg.brow_shape, 0, n - 1))
	if tex == null:
		return
	var w: = float(tex.get_width())
	var h: = float(tex.get_height())
	var right: = AtlasTexture.new()
	right.atlas = tex
	right.region = Rect2(w * 0.5, 0.0, w * 0.5, h)
	var gap: = lerpf(-55.0, 105.0, cfg.brow_spacing) * (FACE_CANVAS / 512.0)
	var dy: = (cfg.brow_height - 0.5) * -360.0 * (FACE_CANVAS / 512.0)
	var sz: = Vector2(lerpf(0.65, 1.35, cfg.brow_width), 
		lerpf(0.65, 1.35, cfg.brow_size_y))
	var pair_x: = (cfg.brow_x - 0.5) * 270.0 * (FACE_CANVAS / 512.0)
	var rot: = (cfg.brow_rot - 0.5) * PI

	var half: = FACE_CANVAS * 0.5
	var rc: = FaceParts.right_half_center("brows", clampi(cfg.brow_shape, 0, n - 1))
	var piv_r: = Vector2(rc.x * half, rc.y * FACE_CANVAS)
	var piv_l: = Vector2((1.0 - rc.x) * half, rc.y * FACE_CANVAS)
	var po_r: = Vector2(FACE_CANVAS * BROW_CX, FACE_CANVAS * BROW_CY)
	var po_l: = Vector2(half - FACE_CANVAS * BROW_CX, FACE_CANVAS * BROW_CY)
	var s0: = Vector2(1.0, 1.0)
	_face_canvas.add_child(_eye_half(right, false, piv_r, 
		Vector2(gap + pair_x, dy) + _pivot_comp(po_r, piv_r, s0), sz, rot, 0.5, 1.0))
	_face_canvas.add_child(_eye_half(right, true, piv_l, 
		Vector2( - gap + pair_x, dy) + _pivot_comp(po_l, piv_l, s0), sz, - rot, 0.0, 0.5))



func _eye_half(tex: Texture2D, flip: bool, pivot: Vector2, off: Vector2, 
		sz: Vector2, rot: float, anchor_l: float, anchor_r: float) -> Control:
	var wrap: = Control.new()
	wrap.anchor_left = anchor_l
	wrap.anchor_right = anchor_r
	wrap.anchor_top = 0.0
	wrap.anchor_bottom = 1.0
	wrap.offset_left = off.x
	wrap.offset_right = off.x
	wrap.offset_top = off.y
	wrap.offset_bottom = off.y
	wrap.pivot_offset = pivot
	wrap.scale = sz
	wrap.rotation = rot
	var tr: = TextureRect.new()
	tr.texture = tex
	tr.flip_h = flip
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(tr)
	return wrap

func _add_feature(feature: String, idx: int, tint: Color, xf: Dictionary) -> void :

	if idx < 0:
		return


	var n: = FaceParts.count(feature)
	if n <= 0:
		return
	idx = clampi(idx, 0, n - 1)
	var base: = FaceParts.texture(feature, idx)
	if base == null:
		return

	var tint_tex: = FaceParts.tint_texture(feature, idx)
	if tint_tex != null:
		var t: = _face_layer(tint_tex, xf)
		t.modulate = tint
		_face_canvas.add_child(t)
	_face_canvas.add_child(_face_layer(base, xf))

func _face_layer(tex: Texture2D, xf: Dictionary) -> TextureRect:
	var tr: = TextureRect.new()
	tr.texture = tex


	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.pivot_offset = xf["pivot"]
	tr.scale = xf["scale"]
	tr.position = xf["pos"]
	tr.rotation = xf.get("rot", 0.0)
	return tr



func _feat_pivot(feature: String, idx: int) -> Vector2:
	var n: = FaceParts.count(feature)
	if idx < 0 or n <= 0:
		return Vector2(FACE_CANVAS, FACE_CANVAS) * 0.5
	return FaceParts.used_center(feature, clampi(idx, 0, n - 1)) * FACE_CANVAS




func _pivot_comp(p_old: Vector2, p_new: Vector2, s0: Vector2) -> Vector2:
	return (p_old - p_new) * (Vector2.ONE - s0)



func _feat_xform(feature: String, cfg: CharacterConfig) -> Dictionary:
	var k: = float(FACE_CANVAS) / 512.0
	match feature:
		"eyes":
			var sz: = lerpf(0.82, 1.22, cfg.eye_size)
			var spread: = lerpf(0.9, 1.16, cfg.eye_spacing)
			return {"pivot": Vector2(256, 235) * k, 
				"scale": Vector2(sz * spread, sz), 
				"pos": Vector2(0, (cfg.eye_height - 0.5) * -170.0 * k)}
		"brows":
			return {"pivot": Vector2(256, 200) * k, "scale": Vector2.ONE, 
				"pos": Vector2(0, (cfg.brow_height - 0.5) * -150.0 * k), 
				"rot": (cfg.brow_rot - 0.5) * PI}
		"nose":
			var nz: = Vector2(lerpf(0.55, 1.55, cfg.nose_width), 
				lerpf(0.55, 1.55, cfg.nose_size_y))
			if cfg.nose_flip:
				nz.x = - nz.x
			var np_old: = Vector2(256, 290) * k
			var np: = _feat_pivot("nose", cfg.nose_shape)
			return {"pivot": np, "scale": nz, 
				"pos": Vector2((cfg.nose_x - 0.5) * 240.0 * k, 
					(cfg.nose_height - 0.5) * -345.0 * k)
					+ _pivot_comp(np_old, np, Vector2(1.05, 1.05))}
		"mouth":
			var mz: = Vector2(lerpf(0.6, 1.6, cfg.mouth_width), 
				lerpf(0.6, 1.6, cfg.mouth_size_y))
			var mp_old: = Vector2(256, 345) * k
			var mp: = _feat_pivot("mouth", cfg.mouth_shape)
			return {"pivot": mp, "scale": mz, 
				"pos": Vector2((cfg.mouth_x - 0.5) * 270.0 * k, 
					(cfg.mouth_height - 0.5) * -300.0 * k)
					+ _pivot_comp(mp_old, mp, Vector2(1.1, 1.1)), 
				"rot": (cfg.mouth_rot - 0.5) * PI}
	return {"pivot": Vector2(256, 256) * k, "scale": Vector2.ONE, "pos": Vector2.ZERO}





func _build_blush(r: float, color: = BLUSH_COLOR) -> void :
	var cheek_y: = r * -0.27
	var cheek_x: = r * 0.4
	for side in [-1.0, 1.0]:
		var patch: = SphereMesh.new()
		patch.radius = r * 0.19
		patch.height = r * 0.38
		patch.radial_segments = 10
		patch.rings = 6



		var pos: = _surface_point(side * cheek_x, cheek_y)
		pos.z += r * 0.09
		_face_mesh(patch, pos, Vector3.ZERO, 
			Vector3(1.0, 0.62, 0.22), color)

func set_hair(style: int, cfg: CharacterConfig) -> void :





	if _head_mount == null:
		return
	if style != _hair_style:
		_hair_style = style
		_tail_skel = null
		_tails.clear()
		if _hair_root != null:
			_hair_root.queue_free()
			_hair_root = null




			_scrub_shell_maps()
		_hair_mats = []
		_hair_defaults = []
		var name: = ""
		if style > 0 and style < CharacterConfig.hair_meshes().size():
			name = CharacterConfig.hair_meshes()[style]
		if name != "":
			var path: String = HAIR_DIR % name
			if ResourceLoader.exists(path):
				_hair_root = (load(path) as PackedScene).instantiate()
				_head_mount.add_child(_hair_root)





				var groups: = AccessoryItem.build_groups(_hair_root)
				for g in groups:
					var mat: = _hair_material(AccessoryItem._albedo_of(g["src"]))
					for t in g["targets"]:
						var mi: MeshInstance3D = t[0]
						mi.set_surface_override_material(int(t[1]), mat)
					_hair_mats.append(mat)
					_hair_defaults.append(AccessoryItem._albedo_of(g["src"]))


				_hair_yrange = _measure_hair_yrange()
				_find_tail(_hair_root)





				var hair_meshes: Array = []
				_collect_meshes(_hair_root, hair_meshes)
				_ink(hair_meshes, OUTLINE_WIDTH / _base_scale, true)
	_apply_hair_flip(cfg)
	_tint_hair(cfg)







func _apply_hair_flip(cfg: CharacterConfig) -> void :
	if _hair_root == null or not is_instance_valid(_hair_root):
		return
	var rest: = _skel.get_bone_global_rest(_head_bone)
	var xf: = rest.affine_inverse()
	if cfg.hair_flip:
		xf = Transform3D(Basis.from_scale(Vector3(-1.0, 1.0, 1.0)), Vector3.ZERO) * xf
	_hair_root.transform = xf





func _tint_hair(cfg: CharacterConfig) -> void :
	_hair_grad_active = false
	for i in _hair_mats.size():
		var fallback: Color = _hair_defaults[i] if i < _hair_defaults.size() else Color.WHITE
		var mat: = _hair_mats[i] as ShaderMaterial
		var top: Color = cfg.hair_color_at(i, fallback)
		mat.set_shader_parameter("albedo", top)
		var on: = cfg.hair_gradient_on(i)
		mat.set_shader_parameter("grad_on", 1.0 if on else 0.0)
		if on:
			_hair_grad_active = true
			var fade: Vector2 = cfg.hair_gradient_fade(i)
			mat.set_shader_parameter("top_color", top)
			mat.set_shader_parameter("bottom_color", 
				cfg.hair_gradient_bottom(i, top.darkened(0.4)))
			mat.set_shader_parameter("grad_y_min", _hair_yrange.x)
			mat.set_shader_parameter("grad_y_max", _hair_yrange.y)
			mat.set_shader_parameter("grad_fade_start", fade.x)
			mat.set_shader_parameter("grad_fade_end", fade.y)


	if _hair_grad_active:
		_push_hair_anchor()




func _measure_hair_yrange() -> Vector2:
	return _measure_yrange(_hair_root)




func _measure_yrange(root: Node3D) -> Vector2:
	if root == null or not is_instance_valid(root):
		return Vector2(0.0, 1.0)
	var root_inv: = root.global_transform.affine_inverse()
	var lo: = INF
	var hi: = - INF
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var mi: = n as MeshInstance3D
			var rel: = root_inv * mi.global_transform
			var box: = rel * mi.mesh.get_aabb()
			lo = minf(lo, box.position.y)
			hi = maxf(hi, box.position.y + box.size.y)
		for c in n.get_children():
			stack.append(c)
	if not is_finite(lo) or hi <= lo:
		return Vector2(0.0, 1.0)
	return Vector2(lo, hi)




func _push_hair_anchor() -> void :
	if _hair_root == null or not is_instance_valid(_hair_root):
		return
	var inv: = _hair_root.global_transform.affine_inverse()
	for m in _hair_mats:
		(m as ShaderMaterial).set_shader_parameter("grad_root_inv", inv)



func tick_hair_gradient() -> void :
	if _hair_grad_active:
		_push_hair_anchor()

	if _acc_grad_active:
		for slot in _acc_mats:
			_push_acc_anchor(slot)



func hair_slot_count() -> int:
	return _hair_mats.size()

func hair_slot_default(i: int) -> Color:
	return _hair_defaults[i] if i >= 0 and i < _hair_defaults.size() else Color.WHITE

func set_accessories(cfg: CharacterConfig) -> void :



	if _head_mount == null:
		return
	_acc_grad_active = false
	for slot in CharacterConfig.ACC_SLOTS:
		var id: = cfg.acc_id(slot)
		if id != String(_acc_ids.get(slot, "")):
			_mount_accessory(slot, id)
		_pose_accessory(slot, cfg)
		_tint_accessory(slot, cfg)

	var head_item: = AccessoryCatalog.by_id(cfg.acc_id("head"))
	_apply_hair_hat_mode(head_item.hair_mode if head_item != null\
	else AccessoryItem.HAIR_NORMAL)

func _mount_accessory(slot: String, id: String) -> void :
	_acc_ids[slot] = id
	var old = _acc_roots.get(slot, null)
	if old != null and is_instance_valid(old):
		old.queue_free()


		_scrub_shell_maps()
	_acc_roots.erase(slot)
	_acc_mats[slot] = []
	_acc_tails.erase(slot)
	_acc_yrange.erase(slot)
	var item: = AccessoryCatalog.by_id(id)
	if item == null or item.mesh == null:
		return
	var root: = item.mesh.instantiate() as Node3D
	if root == null:
		return
	_head_mount.add_child(root)
	_acc_roots[slot] = root


	var groups: = AccessoryItem.build_groups(root)
	var mats: Array = []
	for i in groups.size():
		var g = groups[i]



		if item.is_color_locked(i):
			mats.append(null)
			continue


		var mat: = _hair_material(AccessoryItem._albedo_of(g["src"]))
		for t in g["targets"]:
			var mi: MeshInstance3D = t[0]
			mi.set_surface_override_material(int(t[1]), mat)
		mats.append(mat)
	_acc_mats[slot] = mats
	_acc_yrange[slot] = _measure_yrange(root)


	var tg: = _scan_tails(root)
	if tg["skel"] != null:


		tg["stiff"] = maxf(item.jiggle_stiffness, 0.05)
		tg["damp"] = maxf(item.jiggle_damping, 0.05)
		tg["swing"] = item.jiggle_swing
		tg["grav"] = item.jiggle_gravity
		_acc_tails[slot] = tg



	_acc_pivot[slot] = _accessory_centre(root)




	var meshes: Array = []
	_collect_meshes(root, meshes)
	if not _reflection:
		if Ink.active():
			_build_acc_proxies(meshes)
		elif not GameConfig.style_is(GameConfig.ArtStyle.WII):
			_queue_highlight(meshes)
			_build_outlines(meshes, OUTLINE_WIDTH / _base_scale)




func _accessory_centre(root: Node3D) -> Vector3:
	var acc: = {"box": AABB(), "has": false}
	_collect_accessory_aabb(root, Transform3D.IDENTITY, acc, true)
	return (acc["box"] as AABB).get_center() if acc["has"] else Vector3.ZERO

func _collect_accessory_aabb(node: Node, parent_xform: Transform3D, 
		acc: Dictionary, is_root: bool) -> void :
	var xform: = parent_xform
	if node is Node3D and not is_root:
		xform = parent_xform * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var b: = xform * (node as MeshInstance3D).mesh.get_aabb()
		acc["box"] = b if not acc["has"] else (acc["box"] as AABB).merge(b)
		acc["has"] = true
	for c in node.get_children():
		_collect_accessory_aabb(c, xform, acc, false)

func _pose_accessory(slot: String, cfg: CharacterConfig) -> void :
	var root = _acc_roots.get(slot, null)
	if root == null or not is_instance_valid(root):
		return
	var item: = AccessoryCatalog.by_id(cfg.acc_id(slot))
	if item == null:
		return


	var rest: = _skel.get_bone_global_rest(_head_bone)
	var base: = rest.affine_inverse()


	var rad: float = _head_radii.x
	var pos: = item.anchor_offset * rad
	pos.x += (cfg.acc_val(slot, "px") - 0.5) * 2.0 * item.pos_range.x * rad
	pos.y += (cfg.acc_val(slot, "py") - 0.5) * 2.0 * item.pos_range.y * rad
	pos.z += (cfg.acc_val(slot, "pz") - 0.5) * 2.0 * item.pos_range.z * rad
	var deg: = Vector3(
		item.anchor_rotation.x + (cfg.acc_val(slot, "rx") - 0.5) * 2.0 * item.rot_range.x, 
		item.anchor_rotation.y + (cfg.acc_val(slot, "ry") - 0.5) * 2.0 * item.rot_range.y, 
		item.anchor_rotation.z + (cfg.acc_val(slot, "rz") - 0.5) * 2.0 * item.rot_range.z)




	var base_scl: = item.anchor_scale * _acc_scale(item, cfg.acc_val(slot, "sc"))
	var scl: = Vector3(
		clampf(base_scl * _acc_axis(cfg.acc_val(slot, "sx")), 0.35, 2.2), 
		clampf(base_scl * _acc_axis(cfg.acc_val(slot, "sy")), 0.35, 2.2), 
		clampf(base_scl * _acc_axis(cfg.acc_val(slot, "sz")), 0.35, 2.2))




	var rs: = Basis.from_euler(deg * (PI / 180.0)) * Basis.from_scale(scl)
	var pivot: Vector3 = _acc_pivot.get(slot, Vector3.ZERO)
	root.transform = base * Transform3D(rs, pos + pivot - rs * pivot)



func _acc_scale(item: AccessoryItem, s: float) -> float:
	if s <= 0.5:
		return lerpf(item.scale_min, 1.0, clampf(s * 2.0, 0.0, 1.0))
	return lerpf(1.0, item.scale_max, clampf((s - 0.5) * 2.0, 0.0, 1.0))




func _acc_axis(s: float) -> float:
	if s <= 0.5:
		return lerpf(0.6, 1.0, clampf(s * 2.0, 0.0, 1.0))
	return lerpf(1.0, 1.6, clampf((s - 0.5) * 2.0, 0.0, 1.0))

func _tint_accessory(slot: String, cfg: CharacterConfig) -> void :
	var mats: Array = _acc_mats.get(slot, [])
	var item: = AccessoryCatalog.by_id(cfg.acc_id(slot))
	var yr: Vector2 = _acc_yrange.get(slot, Vector2(0.0, 1.0))
	for i in mats.size():
		if mats[i] == null:
			continue
		var fallback: Color = item.default_color(i) if item != null else Color.WHITE
		var mat: = mats[i] as ShaderMaterial
		var top: Color = cfg.acc_color(slot, i, fallback)
		mat.set_shader_parameter("albedo", top)


		var on: = cfg.acc_gradient_on(slot, i)
		mat.set_shader_parameter("grad_on", 1.0 if on else 0.0)
		if on:
			_acc_grad_active = true
			var fade: Vector2 = cfg.acc_gradient_fade(slot, i)
			mat.set_shader_parameter("top_color", top)
			mat.set_shader_parameter("bottom_color", 
				cfg.acc_gradient_bottom(slot, i, top.darkened(0.4)))
			mat.set_shader_parameter("grad_y_min", yr.x)
			mat.set_shader_parameter("grad_y_max", yr.y)
			mat.set_shader_parameter("grad_fade_start", fade.x)
			mat.set_shader_parameter("grad_fade_end", fade.y)
	if _acc_grad_active:
		_push_acc_anchor(slot)



func _push_acc_anchor(slot: String) -> void :
	var root = _acc_roots.get(slot, null)
	if root == null or not is_instance_valid(root):
		return
	var inv: = (root as Node3D).global_transform.affine_inverse()
	for m in _acc_mats.get(slot, []):
		if m != null:
			(m as ShaderMaterial).set_shader_parameter("grad_root_inv", inv)

func _apply_hair_hat_mode(mode: String) -> void :





	if _hair_root == null or not is_instance_valid(_hair_root):
		return
	var top: = 1.0 if mode == AccessoryItem.HAIR_TOP else 0.0
	var full: = 1.0 if mode == AccessoryItem.HAIR_FULL else 0.0
	var hidden: = {}
	if mode == AccessoryItem.HAIR_TOP:
		hidden = {"Hair_Top": true, "Hair_Bangs": true}
	elif mode == AccessoryItem.HAIR_FULL:
		hidden = {"Hair_Top": true, "Hair_Bangs": true, 
			"Hair_Sides": true, "Hair_Back": true}
	_drive_hair_hat(_hair_root, top, full, hidden)







func drive_cloth(delta: float, vel_y: float, grounded: bool, air_boost: float, 
		diving: bool, knocked_down: bool, tilt_x: = 0.0) -> void :


	if _cloth_targets.is_empty() or ( not _cloth_on and not _pinny_worn):
		return






	var size: = clampf(lerpf(0.55, 1.2, air_boost), 0.55, 1.4)
	var rising: = clampf(vel_y / 5.0, 0.0, 1.0) if not grounded else 0.0
	var falling: = clampf( - vel_y / 4.0, 0.0, 1.0) if not grounded else 0.0
	var lift: = 0.0
	var flare: = 0.0
	var drop: = 0.0
	if not grounded:
		lift = (1.0 - falling * 0.85) * size
		flare = (0.6 + 0.4 * rising) * size
		drop = falling * 0.35
	if diving:
		drop = maxf(drop, 0.7)
		lift = 0.0
		flare = 0.0
	elif knocked_down:
		lift = maxf(lift, 0.3)

	if grounded and _cloth_was_air:
		_cloth_land = 1.0
	_cloth_was_air = not grounded
	_cloth_land = maxf(_cloth_land - delta / 0.22, 0.0)
	drop = maxf(drop, _cloth_land * 0.9)
	var bl: = clampf(tilt_x, 0.0, 1.0) * 0.6 if not grounded else 0.0
	var br: = clampf( - tilt_x, 0.0, 1.0) * 0.6 if not grounded else 0.0
	var targets: = [minf(lift, 1.35), minf(flare, 1.35), minf(drop, 1.0), bl, br]
	for i in 5:
		var t: float = targets[i]
		var cur: float = _cloth[i]
		var tau: = CLOTH_ATTACK if t > cur else CLOTH_RELEASE
		_cloth[i] = lerpf(cur, t, 1.0 - exp( - delta / maxf(tau, 0.005)))
	_push_cloth()



func _mesh_is_pinny(mi: MeshInstance3D) -> bool:
	if mi == null or mi.mesh == null:
		return false
	for si in mi.mesh.get_surface_count():
		var sm: = mi.mesh.surface_get_material(si)
		if sm != null and sm.resource_name.to_lower().begins_with("practice_jersey"):
			return true
	return false

func _push_cloth() -> void :
	for entry in _cloth_targets:
		var mi: MeshInstance3D = entry[0]
		var idxs: Array = entry[1]


		var is_pinny: bool = entry.size() > 2 and bool(entry[2])
		var active: = _pinny_worn if is_pinny else _cloth_on
		for i in idxs.size():
			if int(idxs[i]) >= 0:
				mi.set_blend_shape_value(int(idxs[i]), _cloth[i] if active else 0.0)

func _drive_hair_hat(node: Node, top: float, full: float, hidden: Dictionary) -> void :
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var mi: = node as MeshInstance3D
		var ti: = mi.find_blend_shape_by_name("Hat_TopCovered")
		if ti >= 0:
			mi.set_blend_shape_value(ti, top)
		var fi: = mi.find_blend_shape_by_name("Hat_FullCovered")
		if fi >= 0:
			mi.set_blend_shape_value(fi, full)



		if String(mi.name).begins_with("Hair_"):
			var vis: = not hidden.has(String(mi.name))
			mi.visible = vis
			for map in [_shells, _hl_shells]:
				if map.has(mi) and is_instance_valid(map[mi]):
					(map[mi] as MeshInstance3D).visible = vis
	for c in node.get_children():
		_drive_hair_hat(c, top, full, hidden)

func _find_tail(n: Node) -> void :

	var g: = _scan_tails(n)
	_tail_skel = g["skel"]
	_tails = g["chains"]




func _scan_tails(n: Node) -> Dictionary:
	var out: = {"skel": null, "chains": []}
	_scan_tails_into(n, out)
	return out

func _scan_tails_into(n: Node, out: Dictionary) -> void :
	if out["skel"] != null:
		return
	if n is Skeleton3D:
		var sk: = n as Skeleton3D
		var chains: Array = []
		var claimed: = {}
		for b in sk.get_bone_count():
			if not _is_tail_bone(sk, b):
				continue
			var parent: = sk.get_bone_parent(b)
			if parent >= 0 and _is_tail_bone(sk, parent):
				continue
			_walk_tail_chain(sk, b, [], claimed, chains)
		if not chains.is_empty():
			out["skel"] = sk
			out["chains"] = chains
			return
	for c in n.get_children():
		_scan_tails_into(c, out)

static func _is_tail_bone(sk: Skeleton3D, b: int) -> bool:
	return sk.get_bone_name(b).to_lower().begins_with(TAIL_PREFIX)

func _walk_tail_chain(sk: Skeleton3D, b: int, chain: Array, claimed: Dictionary, 
		chains: Array) -> void :
	if claimed.has(b):
		return
	claimed[b] = true
	chain.append(b)
	var kids: Array = []
	for c in sk.get_bone_children(b):
		if _is_tail_bone(sk, c):
			kids.append(c)
	if kids.is_empty():
		_bank_tail_chain(sk, chain, chains)
		return



	_walk_tail_chain(sk, kids[0], chain, claimed, chains)
	for i in range(1, kids.size()):
		_walk_tail_chain(sk, kids[i], [], claimed, chains)

func _bank_tail_chain(sk: Skeleton3D, chain: Array, chains: Array) -> void :
	if chain.size() < 2:
		return
	var rest: Array = []
	var angle: Array = []
	var vel: Array = []
	for b in chain:
		rest.append(sk.get_bone_pose_rotation(b))
		angle.append(Vector2.ZERO)
		vel.append(Vector2.ZERO)
	chains.append({"idx": chain, "rest": rest, "angle": angle, "vel": vel})

func tail_tick(delta: float) -> void :



	if _head_mount == null or delta <= 0.0:
		return
	if _tail_skel == null and _acc_tails.is_empty():
		return
	var here: = _head_mount.global_position
	var vel: = Vector3.ZERO
	if _prev_head_pos != Vector3.ZERO:
		vel = (here - _prev_head_pos) / delta
	var head_accel: = (vel - _prev_head_vel) / maxf(delta, 0.0001)
	_prev_head_pos = here
	_prev_head_vel = vel



	var local: = _head_mount.global_basis.inverse() * head_accel



	_tail_step(delta, Vector2(local.z, - local.x) * TAIL_SWING)






func tail_still(back: float, side: float, seconds: = 0.6) -> void :
	if _tail_skel == null and _acc_tails.is_empty():
		return
	var drive: = Vector2( - back, - side) * TAIL_SWING
	var n: = int(ceilf(seconds * 60.0))
	for i in n:
		_tail_step(1.0 / 60.0, drive)

func _tail_step(delta: float, drive: Vector2) -> void :


	_tail_step_on(_tail_skel, _tails, delta, drive, 1.0, 1.0, 1.0)
	for slot in _acc_tails:
		var g: Dictionary = _acc_tails[slot]
		_tail_step_on(g["skel"], g["chains"], delta, drive * float(g["swing"]), 
			float(g["stiff"]), float(g["damp"]), float(g["grav"]))

func _tail_step_on(skel: Skeleton3D, chains: Array, delta: float, drive: Vector2, 
		stiff_mul: float, damp_mul: float, grav_mul: float) -> void :
	if skel == null:
		return
	var grav_v: = GRAV_V * grav_mul
	for chain in chains:
		var idx: Array = chain.idx
		var rest_q: Array = chain.rest
		var angle: Array = chain.angle
		var vel_arr: Array = chain.vel
		var count: = idx.size()
		for i in count:

			var t: = 0.0 if count < 2 else float(i) / float(count - 1)
			var stiff: = lerpf(TAIL_ROOT_STIFF, TAIL_TIP_STIFF, t) * stiff_mul
			var damp: = lerpf(TAIL_ROOT_DAMP, TAIL_TIP_DAMP, t) * damp_mul





			var target: Vector2 = grav_v
			if i > 0:
				var parent_swing: Vector2 = (angle[i - 1] as Vector2) - grav_v
				target = parent_swing * TAIL_FOLLOW + grav_v
			var accel: Vector2 = (target - angle[i]) * stiff - (vel_arr[i] as Vector2) * damp


			var drive_share: = 1.0 - 0.35 * t
			vel_arr[i] = (vel_arr[i] as Vector2) + (accel + drive * drive_share) * delta
			var ang: Vector2 = (angle[i] as Vector2) + (vel_arr[i] as Vector2) * delta
			ang.x = clampf(ang.x, - TAIL_MAX, TAIL_MAX)
			ang.y = clampf(ang.y, - TAIL_MAX, TAIL_MAX)
			angle[i] = ang
			var swing: = Quaternion(Vector3.RIGHT, ang.x) * Quaternion(Vector3.FORWARD, ang.y)
			skel.set_bone_pose_rotation(idx[i], 
				(rest_q[i] as Quaternion) * swing)

func _collect_shape_targets(node: Node) -> void :


	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var mi: = node as MeshInstance3D





		var heavy: = mi.find_blend_shape_by_name(SHAPE_HEAVY)
		var slim: = mi.find_blend_shape_by_name(SHAPE_SLIM)
		if heavy >= 0 or slim >= 0:
			_shape_targets.append([mi, heavy, slim])

		var cloth_idx: Array = []
		var cloth_any: = false
		for key in CLOTH_KEYS:
			var ci: = mi.find_blend_shape_by_name(key)
			cloth_idx.append(ci)
			cloth_any = cloth_any or ci >= 0
		if cloth_any:
			_cloth_targets.append([mi, cloth_idx, _mesh_is_pinny(mi)])

		for group in PICK_GROUPS:
			var options: Array = PICK_GROUPS[group]
			var idxs: Array = []
			var any: = false
			for name in options:
				if String(name) == "":
					idxs.append(-1)
					continue
				var idx: = mi.find_blend_shape_by_name(String(name))
				idxs.append(idx)
				if idx >= 0:
					any = true
			if any:
				if not _pick_targets.has(group):
					_pick_targets[group] = []
				_pick_targets[group].append([mi, idxs])
	for child in node.get_children():
		_collect_shape_targets(child)

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found: = _find_skeleton(child)
		if found != null:
			return found
	return null

func _calibrate_hands() -> void :



	if _skel == null or hand_radius <= 0.0:
		return
	var found: Array = []
	for key in ["l", "r"]:
		for candidate in HAND_BONES[key]:
			var idx: = _skel.find_bone(candidate)
			if idx >= 0:
				found.append(idx)
				break
	if found.size() < 2:
		return


	var first_x: = _bone_to_local(_skel.get_bone_global_rest(found[0])).origin.x
	var second_x: = _bone_to_local(_skel.get_bone_global_rest(found[1])).origin.x
	var right_first: = first_x > second_x
	_bone["r"] = found[0] if right_first else found[1]
	_bone["l"] = found[1] if right_first else found[0]
	for side in ["l", "r"]:
		var rest: = _bone_to_local(_skel.get_bone_global_rest(_bone[side]))
		var want: = Vector3(hand_rest.x * (1.0 if side == "r" else -1.0), 
			hand_rest.y, hand_rest.z)



		_bone_offset[side] = want - rest.origin

func _bone_to_local(bone_xf: Transform3D) -> Transform3D:

	return global_transform.affine_inverse() * (_skel.global_transform * bone_xf)

func hands_animated() -> bool:
	return _skel != null and _bone["l"] >= 0 and _bone["r"] >= 0

func hand_local(right: bool) -> Vector3:

	var side: = "r" if right else "l"
	var pose: = _bone_to_local(_skel.get_bone_global_pose(_bone[side]))
	return pose.origin + _bone_offset[side]

func _collect_meshes(node: Node, out: Array) -> void :
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		out.append(node)
	for child in node.get_children():
		_collect_meshes(child, out)







func force_static_pose() -> void :
	if _look != null:
		_look.active = false
	if _skel != null:
		_skel.force_update_all_bone_transforms()

func _find_anim(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found: = _find_anim(child)
		if found != null:
			return found
	return null

func _ink(meshes: Array, width: float, front_part: = false, want_highlight: = true) -> void :











	if _reflection:
		return






	if want_highlight:
		_queue_highlight(meshes)
	match GameConfig.art_style:
		GameConfig.ArtStyle.WII:


			return
		GameConfig.ArtStyle.CEL_INK:
			if Ink.supported():



				if front_part:
					_build_acc_proxies(meshes)
				else:
					Ink.tag(meshes)
				return



			_build_outlines(meshes, width)
		_:
			_build_outlines(meshes, width)







func _build_acc_proxies(meshes: Array) -> void :
	for m in meshes:
		var mi: = m as MeshInstance3D
		if mi == null or mi.mesh == null or String(mi.name).to_lower().contains("number"):
			continue
		var proxy: = MeshInstance3D.new()
		proxy.mesh = mi.mesh
		proxy.material_override = Ink.acc_proxy_material()
		proxy.layers = Ink.INK_ACC_MASK
		proxy.skin = mi.skin
		proxy.transform = mi.transform
		mi.get_parent().add_child(proxy)
		proxy.skeleton = mi.skeleton

func _build_outlines(meshes: Array, width: float) -> void :


	var mat: = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_FRONT
	mat.albedo_color = OUTLINE_COLOR
	mat.grow = true
	mat.grow_amount = width
	for m in meshes:
		var mi: = m as MeshInstance3D


		if not mi.visible or String(mi.name).to_lower().contains("number"):
			continue
		var shell: = MeshInstance3D.new()
		shell.mesh = mi.mesh
		shell.material_override = mat
		_shells[mi] = shell
		_outline_mat = mat
		shell.skin = mi.skin
		shell.transform = mi.transform
		mi.get_parent().add_child(shell)

		shell.skeleton = mi.skeleton









var _hl_pending: Array = []

func _queue_highlight(meshes: Array) -> void :
	_hl_pending.append_array(meshes)

func _build_highlight(meshes: Array) -> void :
	if _hl_mat == null:
		_hl_mat = StandardMaterial3D.new()
		_hl_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_hl_mat.cull_mode = BaseMaterial3D.CULL_FRONT
		_hl_mat.grow = true
		_hl_mat.grow_amount = OUTLINE_WIDTH * 4.5
		_hl_mat.albedo_color = Color.WHITE
	for m in meshes:





		if _dead(m):
			continue
		var mi: = m as MeshInstance3D

		if mi == null or _hl_shells.has(mi):
			continue
		if not mi.visible or String(mi.name).to_lower().contains("number"):
			continue
		var shell: = MeshInstance3D.new()
		shell.mesh = mi.mesh

		shell.material_override = _hl_mat
		shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shell.visible = false
		shell.skin = mi.skin
		shell.transform = mi.transform
		mi.get_parent().add_child(shell)
		shell.skeleton = mi.skeleton
		_hl_shells[mi] = shell


		for b in mi.get_blend_shape_count():
			shell.set_blend_shape_value(b, mi.get_blend_shape_value(b))
		var cloth_idx: Array = []
		var cloth_any: = false
		for key in CLOTH_KEYS:
			var ci: = shell.find_blend_shape_by_name(key)
			cloth_idx.append(ci)
			cloth_any = cloth_any or ci >= 0
		if cloth_any:
			_cloth_targets.append([shell, cloth_idx, _mesh_is_pinny(mi)])




func _scrub_shell_maps() -> void :


	for map in [_shells, _hl_shells]:
		var stale: = []
		for k in map:
			if _dead(k) or _dead(map[k]):
				stale.append(k)
		for k in stale:
			map.erase(k)
	var stale2: = []
	for k in _surface_slots:
		if _dead(k):
			stale2.append(k)
	for k in stale2:
		_surface_slots.erase(k)

static func _dead(n) -> bool:
	return not is_instance_valid(n)\
	or (n is Node and (n as Node).is_queued_for_deletion())

func set_highlight(color: Color) -> void :
	_scrub_shell_maps()
	var on: = color.a > 0.01
	if on and not _hl_pending.is_empty():

		var pend: = _hl_pending
		_hl_pending = []
		_build_highlight(pend)
	if on and _hl_mat != null:
		_hl_mat.albedo_color = color
	for mi in _hl_shells:
		var shell: MeshInstance3D = _hl_shells[mi]
		shell.visible = on



static func body_shader() -> Shader:
	return WII if GameConfig.style_is(GameConfig.ArtStyle.WII) else TOON





static var _two_sided: = {}
static func jersey_shader() -> Shader:
	var base: = body_shader()
	if not _two_sided.has(base):
		var sh: = Shader.new()
		sh.code = base.code.replace("cull_back", "cull_disabled")
		_two_sided[base] = sh
	return _two_sided[base]

func _toon_material(color: Color) -> ShaderMaterial:
	var mat: = ShaderMaterial.new()
	mat.shader = body_shader()
	mat.set_shader_parameter("albedo", color)
	return mat



func _hair_material(color: Color) -> ShaderMaterial:
	var mat: = ShaderMaterial.new()
	mat.shader = WII if GameConfig.style_is(GameConfig.ArtStyle.WII) else TOON_HAIR
	mat.set_shader_parameter("albedo", color)
	return mat

func _apply_toon_materials(node: Node) -> void :


	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null\
	and (node as MeshInstance3D).visible:
		var mi: = node as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var src: = mi.mesh.surface_get_material(s)
			var raw: = src.resource_name.to_lower() if src != null else ""
			var slot: String = SLOT_ALIASES.get(raw, raw)
			if not _surface_slots.has(mi):
				_surface_slots[mi] = {}
			_surface_slots[mi][s] = slot
			if not _mats.has(slot):
				var mat: = ShaderMaterial.new()
				mat.shader = jersey_shader() if slot == "jersey" else body_shader()
				var fallback: = (src as BaseMaterial3D).albedo_color\
				if src is BaseMaterial3D else Color.WHITE
				mat.set_shader_parameter("albedo", _default_color(slot, fallback))
				_mats[slot] = mat
			mi.set_surface_override_material(s, _mats[slot])


			if _fallback_mat == null and not _mats.has("jersey")\
			and String(mi.name).to_lower().contains("body"):
				_fallback_mat = _mats[slot]
	for child in node.get_children():
		_apply_toon_materials(child)

func _default_color(slot: String, imported: Color) -> Color:
	match slot:
		"skin":
			return Color(1.0, 0.87, 0.73)
		"jersey":
			return Color(0.3, 0.55, 0.95)
		"shorts":
			return Color(0.09, 0.09, 0.11)
		"socks":
			return Color(0.09, 0.09, 0.11)
		"shoes":
			return Color(0.09, 0.09, 0.11)
	return imported

func skin_color() -> Color:
	if _mats.has("skin"):
		return (_mats["skin"] as ShaderMaterial).get_shader_parameter("albedo")
	return Color(1.0, 0.87, 0.73)





func set_slot_hidden(slot: String, hide: bool) -> void :
	_scrub_shell_maps()
	if _mats.has(slot):
		(_mats[slot] as ShaderMaterial).set_shader_parameter(
			"hidden", 1.0 if hide else 0.0)
	for mi in _surface_slots:
		if not is_instance_valid(mi):
			continue
		var slots: Dictionary = _surface_slots[mi]
		var touches: = false
		for si in slots:
			if slots[si] == slot:
				touches = true
		if not touches:
			continue


		var shell: MeshInstance3D = _shells.get(mi)
		if shell != null and is_instance_valid(shell):
			_silence_shell_slot(shell, slots, slot, hide, _outline_mat)
		var aura: MeshInstance3D = _hl_shells.get(mi)
		if aura != null and is_instance_valid(aura):
			_silence_shell_slot(aura, slots, slot, hide, _hl_mat)

func _silence_shell_slot(shell: MeshInstance3D, slots: Dictionary, 
		slot: String, hide: bool, restore: Material) -> void :
	if shell.material_override != null:

		var base: = shell.material_override
		shell.material_override = null
		for si in shell.mesh.get_surface_count():
			shell.set_surface_override_material(si, base)
	for si in slots:
		if slots[si] == slot:
			shell.set_surface_override_material(si, 
				_invisible() if hide else restore)

static func _invisible() -> ShaderMaterial:
	if _invisible_shell == null:
		var sh: = Shader.new()
		sh.code = "shader_type spatial;\nrender_mode unshaded;\nvoid fragment() { discard; }"
		_invisible_shell = ShaderMaterial.new()
		_invisible_shell.shader = sh
	return _invisible_shell



func _set_blend_shape_named(nm: String, value: float) -> void :
	for mi in _surface_slots.keys():
		if not is_instance_valid(mi) or mi.mesh == null:
			continue
		for s in mi.mesh.get_blend_shape_count():
			if String(mi.mesh.get_blend_shape_name(s)) == nm:
				mi.set_blend_shape_value(s, value)

func set_slot_color(slot: String, color: Color) -> void :
	if _mats.has(slot):
		(_mats[slot] as ShaderMaterial).set_shader_parameter("albedo", color)
	elif slot == "jersey" and _fallback_mat != null:
		_fallback_mat.set_shader_parameter("albedo", color)

func set_kit(primary: Color, secondary: Color, accent: Color, 
		pants_accent: = Color.TRANSPARENT) -> void :




	set_slot_color("jersey", primary)
	set_slot_color("shorts", secondary)
	set_slot_color("accent", accent)
	set_slot_color("pants_accent", 
		accent if pants_accent.a == 0.0 else pants_accent)

func apply_config(cfg: CharacterConfig, kit: Array) -> void :


	_left_handed = cfg.left_handed
	set_slot_color("skin", cfg.skin_tone())
	set_slot_color("kneepad", cfg.kneepad)
	set_slot_color("socks", cfg.socks)
	set_slot_color("shoes", cfg.shoe_color)



	set_slot_hidden("kneepad", not cfg.wear_kneepads)
	set_slot_hidden("socks", not cfg.wear_socks)




	set_slot_hidden("shoes", GameConfig.stage_barefoot)
	if GameConfig.stage_barefoot:
		set_slot_hidden("socks", true)
	if kit.size() == 3:

		set_kit(kit[0], kit[1], kit[2], 
			kit[1] if cfg.casual else Color.TRANSPARENT)



	var show_number: = ( not cfg.casual) or cfg.wear_pinny
	set_number(cfg.number if show_number else -1, 
		cfg.pinny_color if cfg.wear_pinny\
		else (kit[0] if kit.size() == 3 else Color.BLACK))




	set_slot_hidden("practice_jersey", not cfg.wear_pinny)
	set_slot_hidden("practice_jersey_accent", not cfg.wear_pinny)
	_pinny_worn = cfg.wear_pinny
	if cfg.wear_pinny:
		set_slot_color("practice_jersey", cfg.pinny_color)
		set_slot_color("practice_jersey_accent", cfg.pinny_accent)



	_set_blend_shape_named("pinnyoffset", 1.0 if cfg.wear_pinny else 0.0)
	set_face(cfg)
	set_hair(cfg.hair, cfg)


	set_accessories(cfg)
	if _scene == null:
		return


	var h: = 1.0 + (cfg.height - 0.5) * 2.0 * HEIGHT_RANGE
	_scene.scale = Vector3.ONE * _base_scale * h
	var heavy: = clampf((cfg.weight - 0.5) * 2.0, 0.0, 1.0)
	var slim: = clampf((0.5 - cfg.weight) * 2.0, 0.0, 1.0)
	for entry in _shape_targets:
		var mi: MeshInstance3D = entry[0]
		if entry[1] >= 0:
			mi.set_blend_shape_value(entry[1], heavy)
		if entry[2] >= 0:
			mi.set_blend_shape_value(entry[2], slim)


	_apply_pick("head", cfg.head_shape, CharacterConfig.HEAD_SHAPES.size())
	_apply_pick("shorts", cfg.shorts_len, CharacterConfig.SHORTS_SHAPES.size())
	_apply_pick("socks", cfg.socks_len, CharacterConfig.SOCKS_SHAPES.size())


	_apply_pick("shirt", cfg.gym_shirt if cfg.casual else 0, 
		CharacterConfig.SHIRT_SHAPES.size())

	_cloth_on = (cfg.gym_shirt if cfg.casual else 0) == 0
	if not _cloth_on:
		_cloth = [0.0, 0.0, 0.0, 0.0, 0.0]
		_push_cloth()

func _apply_pick(group: String, choice: int, count: int) -> void :
	var pick: = clampi(choice, 0, count - 1)
	for entry in _pick_targets.get(group, []):
		var mi: MeshInstance3D = entry[0]
		var idxs: Array = entry[1]
		for i in idxs.size():
			if int(idxs[i]) >= 0:
				mi.set_blend_shape_value(int(idxs[i]), 1.0 if i == pick else 0.0)

func _build_number_patch(meshes: Array) -> void :





	for m in meshes:
		var mi: = m as MeshInstance3D
		if not String(mi.name).to_lower().contains("number"):
			continue
		if _number_mat != null:

			for s2 in mi.mesh.get_surface_count():
				mi.set_surface_override_material(s2, _number_mat)
			continue
		_number_vp = SubViewport.new()
		_number_vp.size = Vector2i(256, 256)
		_number_vp.transparent_bg = true
		_number_vp.disable_3d = true


		_number_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		add_child(_number_vp)
		_number_text = Label.new()
		_number_text.set_anchors_preset(Control.PRESET_FULL_RECT)
		_number_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_number_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


		if ResourceLoader.exists(NUMBER_FONT):
			_number_text.add_theme_font_override("font", load(NUMBER_FONT))
		_number_text.add_theme_font_size_override("font_size", 128)
		_number_text.add_theme_color_override("font_color", Color.WHITE)
		_number_vp.add_child(_number_text)
		_number_mat = ShaderMaterial.new()
		_number_mat.shader = TOON_NUMBER
		_number_mat.set_shader_parameter("number_tex", _number_vp.get_texture())
		for s in mi.mesh.get_surface_count():
			mi.set_surface_override_material(s, _number_mat)

func set_number(number: int, jersey: Color) -> void :
	if _number_text == null or _number_mat == null:
		return


	_number_text.text = "" if number < 0 else str(clampi(number, 0, 99))
	_kick_vp(_number_vp)

	var lum: = jersey.r * 0.299 + jersey.g * 0.587 + jersey.b * 0.114
	_number_mat.set_shader_parameter("ink", 
		Color(0.07, 0.07, 0.09) if lum > 0.5 else Color(0.97, 0.97, 1.0))






const PACED_CLIPS: = ["run", "strafe_left", "strafe_right", "run_back", 
	"strafe_fwd"]
const PACE_REF: = 6.0
const PACE_MIN: = 0.6
const PACE_MAX: = 1.4

func drive(planar_speed: float, grounded: bool, vel_y: float, 
		action: = "", pace_speed: = 0.0, charge_scrub: = -1.0) -> void :



	if _anim == null:
		return
	var want: = "idle"
	if action != "" and _clip_map.has(action):
		want = action
	elif not grounded:
		want = "jump_rise" if vel_y > 0.5 else "jump_fall"
	elif planar_speed > 1.2:
		want = "run"


	if want == "set" and not grounded and _clip_map.has("set_air"):
		want = "set_air"




	if want == "spike" and spike_light:
		want = "spike_light"
	if _left_handed and _clip_map.has(want + "_L"):
		want += "_L"
	var clip: String = _clip_map.get(want, "")
	if clip == "":
		return
	if clip != _current:
		_current = clip







		var base_want: = want.trim_suffix("_L")
		var blend: = 0.0 if playback_scale <= 0.0\
		else (BLEND_SNAP if base_want in SNAP_ACTIONS else BLEND)
		_anim.play(clip, blend)




		if blend <= 0.0 and playback_scale > 0.0:



			if want.begins_with("spike"):
				_anim.seek((SPIKE_STRIKE_FRAME - CLIP_START_FRAME) / ANIM_FPS, true)
			else:
				_anim.advance(0.0)









	if charge_scrub >= 0.0 and want == "approach" and playback_scale > 0.0:
		var a: = _anim.get_animation(clip)
		if a != null:
			_anim.seek(clampf(charge_scrub, 0.0, 1.0) * a.length, true)
			_anim.speed_scale = 0.0
			return
	var pace: = 1.0
	if want in PACED_CLIPS:
		var nominal: = pace_speed if pace_speed > 0.01 else PACE_REF
		pace = clampf(planar_speed / nominal, PACE_MIN, PACE_MAX)


	_anim.speed_scale = 0.0 if hold_frame else playback_scale * pace
