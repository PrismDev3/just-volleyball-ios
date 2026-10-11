class_name Ball
extends Node3D







static var PHYS: BallPhysics = preload("res://game/ball/ball_physics.tres")


signal bounced
signal struck(pos: Vector3, power: float, kind: int)
signal net_hit
signal wall_hit

var net_half_width: = PHYS.net_half_width
var antenna_half_width: = PHYS.antenna_half_width
var court_half_w: = 4.5
var court_half_l: = 9.0
var court_center_x: = 0.0
var wall_min: = Vector3(-1000000.0, -1000000.0, -1000000.0)
var wall_max: = Vector3(1000000.0, 1000000.0, 1000000.0)
var frozen: = false


var cross_seq: = 0
var cross_outside: = false




var hitstop_left: = 0.0
var _pending_hitstop: = 0.0
var spike_lock: = 0.0
var last_net_impact: = 0.0



var far_lod: = false
var serve_assist: = false





var serve_held: = false
var home_side: = 1.0
var outline_color: = PHYS.outline_home


var strike_source: Player = null
var combo_tier: = 0
var vel: = Vector3.ZERO





var strike_seq: = 0
var curve: = 0.0





var float_serve: = false
var float_seed: = 0
var _float_t: = 0.0
var _float_prev: = Vector3.ZERO
const FLOAT_LAT: = 0.34
const FLOAT_VERT: = 0.16
const FLOAT_FADE_H: = 1.5
var net_puppet: = false



var remote_driven: = false
var last_hit_power: = 0.0
var last_hit_kind: = 0
var _pulse: = 0.0



var _floor_squash: = 0.0
var _spin: = 0.0




var _replay_time_scale: = 1.0

var _magnet_offset: = Vector3.ZERO
var _magnet_target: = Vector3.ZERO
var _magnet_hold: = 0

@onready var mesh: MeshInstance3D = $Mesh
@onready var outline: MeshInstance3D = $Mesh / Outline
@onready var shadow: MeshInstance3D = $Shadow
@onready var landing_ring: MeshInstance3D = $LandingRing
var show_landing_ring: = true




var landing_ring_muted: = false
@onready var trail: BallTrail = $Trail

var _mirror: MeshInstance3D
var _ring_mat: ShaderMaterial = null




var stage_ball: = ""
var _model: Node3D = null

func _ready() -> void :


	mesh.mesh = mesh.mesh.duplicate(true)
	outline.mesh = outline.mesh.duplicate(true)
	landing_ring.mesh = landing_ring.mesh.duplicate(true)



	_ring_mat = landing_ring.get_active_material(0) as ShaderMaterial
	if _ring_mat == null:
		push_warning("landing ring has no floor_ring material")


	_mirror = MeshInstance3D.new()
	_mirror.mesh = mesh.mesh
	_mirror.top_level = true
	_mirror.layers = FloorReflector.REFLECT_MASK





	var _pm: = mesh.mesh as PrimitiveMesh
	if _pm != null and _pm.material is ShaderMaterial:
		_mirror.set_surface_override_material(0, _pm.material.duplicate())
	add_child(_mirror)
	_build_land_predict()
	_build_tether()
	_dress_model()





var _land_predict: MeshInstance3D = null
var _land_shell: MeshInstance3D = null
var _land_arrow: MeshInstance3D = null
var _land_column: MeshInstance3D = null
var _land_column_mat: ShaderMaterial = null
var _land_arrow_mat: ShaderMaterial = null
var _predict_mat: StandardMaterial3D = null
var _predict_spread: = -1.0
var _predict_pos: = Vector3.ZERO
var _predict_ready: = false
var _predict_strike: = -1



var predicted_landing: = Vector3.ZERO
var predicted_landing_valid: = false







const _TETHER_SHADER: = preload("res://game/ball/tether.gdshader")
var _tether: MeshInstance3D = null
var _tether_mat: ShaderMaterial = null
var _tether_shell: MeshInstance3D = null
var _tether_shell_mat: ShaderMaterial = null

func _build_tether() -> void :


	var cyl: = CylinderMesh.new()
	cyl.top_radius = 0.02
	cyl.bottom_radius = 0.02
	cyl.height = 1.0
	cyl.radial_segments = 8
	cyl.rings = 0


	_tether_shell = MeshInstance3D.new()
	_tether_shell.top_level = true
	_tether_shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_tether_shell.mesh = cyl
	_tether_shell_mat = ShaderMaterial.new()
	_tether_shell_mat.shader = _TETHER_SHADER
	_tether_shell_mat.render_priority = 3
	_tether_shell_mat.set_shader_parameter("tint", Color(0.05, 0.07, 0.11, 0.9))
	_tether_shell.material_override = _tether_shell_mat
	_tether_shell.visible = false
	add_child(_tether_shell)

	_tether = MeshInstance3D.new()
	_tether.top_level = true
	_tether.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_tether.mesh = cyl
	_tether_mat = ShaderMaterial.new()
	_tether_mat.shader = _TETHER_SHADER
	_tether_mat.render_priority = 4
	_tether_mat.set_shader_parameter("tint", Color(1.0, 1.0, 1.0, 0.9))
	_tether.material_override = _tether_mat
	_tether.visible = false
	add_child(_tether)

func _build_land_predict() -> void :
	_land_predict = MeshInstance3D.new()
	_land_predict.top_level = true
	_land_predict.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_land_predict.mesh = _shard_cluster_mesh(0.22)
	_predict_mat = StandardMaterial3D.new()
	_predict_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_predict_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_predict_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_predict_mat.albedo_color = Color(0.4, 1.0, 1.0, 0.92)



	_predict_mat.render_priority = 2
	_land_predict.material_override = _predict_mat
	_land_predict.visible = false
	add_child(_land_predict)




	_land_shell = MeshInstance3D.new()
	_land_shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_land_shell.mesh = _shard_cluster_mesh(0.0)
	_land_shell.position = Vector3(0.0, -0.007, 0.0)
	var shell_mat: = StandardMaterial3D.new()
	shell_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shell_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shell_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shell_mat.albedo_color = Color(0.05, 0.07, 0.11, 0.95)
	shell_mat.render_priority = 1
	_land_shell.material_override = shell_mat
	_land_predict.add_child(_land_shell)







	_land_column = MeshInstance3D.new()
	var cyl: = CylinderMesh.new()
	cyl.top_radius = LAND_COLUMN_R
	cyl.bottom_radius = LAND_COLUMN_R
	cyl.height = 1.0
	cyl.cap_top = false
	cyl.cap_bottom = false
	cyl.radial_segments = 24
	cyl.rings = 1
	_land_column_mat = ShaderMaterial.new()
	_land_column_mat.shader = load("res://game/fx/land_column.gdshader")
	_land_column_mat.render_priority = 2
	cyl.material = _land_column_mat
	_land_column.mesh = cyl
	_land_column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_land_column.position = Vector3(0.0, 1.0, 0.0)
	_land_column.scale = Vector3(1.0, 2.0, 1.0)
	_land_predict.add_child(_land_column)
	_land_arrow = MeshInstance3D.new()
	var quad: = QuadMesh.new()
	quad.size = Vector2(0.62, 0.9)
	_land_arrow_mat = ShaderMaterial.new()
	_land_arrow_mat.shader = load("res://game/fx/waypoint_arrow.gdshader")
	_land_arrow_mat.render_priority = 3
	quad.material = _land_arrow_mat
	_land_arrow.mesh = quad
	_land_arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_land_arrow.position = Vector3(0.0, LAND_ARROW_H, 0.0)
	_land_predict.add_child(_land_arrow)
	_land_tint(Color(0.4, 1.0, 1.0, 0.92))


func _land_tint(col: Color) -> void :
	_predict_mat.albedo_color = col
	var solid: = Color(col.r, col.g, col.b, 1.0)
	var edge: = Color(col.r, col.g, col.b, 0.94).darkened(0.88)
	if _land_arrow_mat != null:
		_land_arrow_mat.set_shader_parameter("tint", solid)
		_land_arrow_mat.set_shader_parameter("edge", edge)
	if _land_column_mat != null:
		_land_column_mat.set_shader_parameter("tint", Color(col.r, col.g, col.b, LAND_COLUMN_A))






const _SHARDS: = [
	[0.785, 1.0, 0.34, 0.13], 
	[2.356, 1.0, 0.34, 0.13], 
	[3.927, 1.0, 0.34, 0.13], 
	[5.498, 1.0, 0.34, 0.13], 
]
const _SHARD_ROUND: = 0.36
const SPREAD_FAR: = 1.15
const SPREAD_NEAR: = 0.42
const LAND_ARROW_H: = 1.15
const LAND_COLUMN_R: = 0.42
const LAND_COLUMN_A: = 0.26


func _shard_cluster_mesh(inset: = 0.0, spread: = SPREAD_FAR) -> ArrayMesh:
	var verts: = PackedVector3Array()
	for s in _SHARDS:
		var dir: = Vector2(cos(s[0]), sin(s[0]))
		var perp: = Vector2( - dir.y, dir.x)
		var radius: = float(s[1]) * spread
		var tip: = dir * radius
		var base: = dir * (radius + float(s[2]))
		var c0: = tip
		var c1: = base + perp * float(s[3])
		var c2: = base - perp * float(s[3])
		if inset > 0.0:
			var ctr: = (c0 + c1 + c2) / 3.0
			c0 = ctr + (c0 - ctr) * (1.0 - inset)
			c1 = ctr + (c1 - ctr) * (1.0 - inset)
			c2 = ctr + (c2 - ctr) * (1.0 - inset)
		_append_rounded_tri(verts, c0, c1, c2)
	var arr: = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	var am: = ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am



func _append_rounded_tri(verts: PackedVector3Array, a: Vector2, 
		b: Vector2, c: Vector2) -> void :
	var corners: = [a, b, c]
	var ctr: = (a + b + c) / 3.0
	var rim: Array = []
	for i in 3:
		var p: Vector2 = corners[i]
		var prev: Vector2 = corners[(i + 2) % 3]
		var nxt: Vector2 = corners[(i + 1) % 3]
		var r: = minf(p.distance_to(prev), p.distance_to(nxt)) * _SHARD_ROUND
		var t_in: = p + (prev - p).normalized() * r
		var t_out: = p + (nxt - p).normalized() * r
		for k in 4:
			var u: = float(k) / 3.0
			var w: = 1.0 - u
			rim.append(w * w * t_in + 2.0 * w * u * p + u * u * t_out)
	for i in rim.size():
		var p0: Vector2 = rim[i]
		var p1: Vector2 = rim[(i + 1) % rim.size()]
		verts.append(Vector3(ctr.x, 0.0, ctr.y))
		verts.append(Vector3(p0.x, 0.0, p0.y))
		verts.append(Vector3(p1.x, 0.0, p1.y))

func _update_land_predict() -> void :
	if _land_predict == null:
		return



	var airborne: = show_landing_ring and not landing_ring_muted\
	and not frozen and global_position.y > PHYS.radius + 0.3
	_land_predict.visible = airborne
	if not airborne:
		_predict_ready = false
		predicted_landing_valid = false
		return




	var land: = _predict_land_curved()
	predicted_landing = land
	predicted_landing_valid = true
	var target: = Vector3(land.x, maxf(0.045, SandDeform.decal_y), land.z)






	var struck_now: = strike_seq != _predict_strike
	_predict_strike = strike_seq
	if not _predict_ready or struck_now or _predict_pos.distance_to(target) > 1.2:
		_predict_pos = target
		_land_predict.global_position = target
		_land_predict.reset_physics_interpolation()
	else:
		_predict_pos = _predict_pos.lerp(target, 0.35)
		_land_predict.global_position = _predict_pos
	_predict_ready = true

	var closeness: = 0.0
	var disc: = vel.y * vel.y + 2.0 * PHYS.gravity * (global_position.y - PHYS.radius)
	if disc >= 0.0 and vel.y < 0.0:
		var t_floor: = (vel.y + sqrt(disc)) / PHYS.gravity
		closeness = clampf(1.0 - t_floor / 0.9, 0.0, 1.0)


	var col: Color
	if closeness < 0.5:
		col = Color(0.4, 1.0, 1.0).lerp(Color(1.0, 0.75, 0.15), closeness * 2.0)
	else:
		col = Color(1.0, 0.75, 0.15).lerp(Color(1.0, 0.2, 0.12), (closeness - 0.5) * 2.0)
	col.a = lerpf(0.82, 0.98, closeness)
	_land_tint(col)
	if _land_column != null:
		var h: = clampf(global_position.y - PHYS.radius, 0.6, 12.0)
		_land_column.scale = Vector3(1.0, h, 1.0)
		_land_column.position = Vector3(0.0, h * 0.5, 0.0)





	var spread: = lerpf(SPREAD_FAR, SPREAD_NEAR, closeness)
	if absf(spread - _predict_spread) > 0.01:
		_predict_spread = spread
		_land_predict.mesh = _shard_cluster_mesh(0.22, spread)
		_land_shell.mesh = _shard_cluster_mesh(0.0, spread)







func _predict_land_curved() -> Vector3:
	var pos: = global_position
	var v: = vel
	var c: = curve
	for _step in 240:
		var before: = pos
		var state: = step_flight(pos, v, c, 1.0 / 60.0, 
			net_half_width, court_center_x, wall_min, wall_max)
		pos = state[0]
		v = state[1]
		c = float(state[2])


		if before.y > PHYS.radius + 0.001 and pos.y <= PHYS.radius + 0.02:
			break
	return pos





func set_ball_skin(id: String) -> void :
	if id == stage_ball:
		return
	stage_ball = id
	if _model != null:
		_model.queue_free()
		_model = null
	_set_placeholder_hidden(false)
	_dress_model()






func _set_placeholder_hidden(h: bool) -> void :
	var pm: = mesh.mesh as PrimitiveMesh
	if pm != null and pm.material is ShaderMaterial:
		(pm.material as ShaderMaterial).set_shader_parameter("hidden", 1.0 if h else 0.0)

func _dress_model() -> void :
	var stage_id: = stage_ball if stage_ball != "" else GameConfig.stage
	var path: = Stage.ball_model(stage_id)
	if path == "" or not ResourceLoader.exists(path):
		return


	var tex: Texture2D = null
	var tex_path: = Stage.ball_texture(stage_id)
	if tex_path != "" and ResourceLoader.exists(tex_path):
		tex = load(tex_path)



	var tuned: = (mesh.mesh as PrimitiveMesh).material as ShaderMaterial\
	if mesh.mesh is PrimitiveMesh else null
	var scene: = load(path) as PackedScene
	if scene == null:
		return


	_model = Node3D.new()
	mesh.add_child(_model)
	var body: = scene.instantiate() as Node3D
	_model.add_child(body)


	var combined: = AABB()
	var first: = true
	for c in body.find_children("*", "MeshInstance3D", true, false):
		var mi: = c as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF



		for s in mi.mesh.get_surface_count():
			var mat: = mi.get_active_material(s)
			if mat is BaseMaterial3D:
				var src: BaseMaterial3D = mat
				var cel: = ShaderMaterial.new()
				cel.shader = load("res://game/ball/ball_cel.gdshader")
				if tuned != null:
					for p in ["key_dir", "band_edge", "shade", "band_softness"]:
						var v: Variant = tuned.get_shader_parameter(p)
						if v != null:
							cel.set_shader_parameter(p, v)


				var use_tex: = src.albedo_texture
				if use_tex == null:
					use_tex = tex
				if use_tex != null:
					cel.set_shader_parameter("albedo_tex", use_tex)
					cel.set_shader_parameter("albedo_color", Color.WHITE)
				else:
					cel.set_shader_parameter("albedo_color", src.albedo_color)
				mi.set_surface_override_material(s, cel)
		var rel: = _model.global_transform.affine_inverse()\
		* mi.global_transform
		var box: = rel * mi.get_aabb()
		combined = box if first else combined.merge(box)
		first = false
	if not first and combined.get_longest_axis_size() > 0.001:
		var k: = (PHYS.radius * 2.0) / combined.get_longest_axis_size()
		body.scale = Vector3.ONE * k
		body.position = - combined.get_center() * k



	for c in body.find_children("*", "MeshInstance3D", true, false):
		var mi: = c as MeshInstance3D
		var centre: = mi.global_transform.affine_inverse()\
		* _model.global_transform.origin
		for s in mi.mesh.get_surface_count():
			var cel: = mi.get_surface_override_material(s) as ShaderMaterial
			if cel != null:
				cel.set_shader_parameter("local_center", centre)

	_set_placeholder_hidden(true)

var mirror_off: = false

func _update_mirror() -> void :
	if _mirror == null:
		return
	var idle: = far_lod or mirror_off or not GameConfig.reflections_live()
	if _mirror.visible != not idle:
		_mirror.visible = not idle
	if idle:
		return
	_mirror.global_position = Vector3(global_position.x, 
		- global_position.y, global_position.z)

func _physics_process(delta: float) -> void :
	if far_lod:





		predicted_landing_valid = false
		landing_ring.visible = false
	else:
		_update_outline()
		_update_landing_ring()
		_update_land_predict()
	_update_mirror()
	_update_magnet_lean(delta)
	if net_puppet or remote_driven:




		if hitstop_left > 0.0:
			hitstop_left = maxf(hitstop_left - delta, 0.0)
		_update_shadow()
		_update_stretch(delta)
		trail.set_active( not far_lod and (serve_held\
		or ( not frozen and vel.length() > PHYS.trail_min_speed)))
		return
	if frozen:
		_update_shadow()

		trail.set_active( not far_lod and serve_held)


		mesh.scale = mesh.scale.lerp(Vector3.ONE, 1.0 - exp(-14.0 * delta))




		var q: = mesh.transform.basis.get_rotation_quaternion()\
		.slerp(Quaternion.IDENTITY, 1.0 - exp(-14.0 * delta))
		mesh.transform.basis = Basis(q).scaled(mesh.scale)
		return
	if hitstop_left > 0.0:

		hitstop_left -= delta
		_update_shadow()
		return
	var prev: = global_position
	spike_lock = maxf(spike_lock - delta, 0.0)
	vel.y -= PHYS.gravity * delta
	if curve != 0.0:




		var flat: = Vector3(vel.x, 0.0, vel.z)
		var sp: = flat.length()
		if sp > 1.0:
			vel += Vector3.UP.cross(flat / sp) * curve * (sp / PHYS.curve_ref_speed) * delta
		curve *= exp( - delta / PHYS.curve_decay_time)
	global_position += vel * delta
	if float_serve:
		_float_t += delta
		var off: = float_offset(float_seed, _float_t, vel)\
		* clampf((global_position.y - PHYS.radius) / FLOAT_FADE_H, 0.0, 1.0)
		global_position += off - _float_prev
		_float_prev = off
	_bounce_floor(delta)
	_hit_net(prev)
	_bounce_walls()



	if signf(prev.z) != signf(global_position.z)\
	and prev.z != 0.0 and global_position.z != 0.0:
		var t: = prev.z / (prev.z - global_position.z)
		var cx: = lerpf(prev.x, global_position.x, t)
		cross_outside = absf(cx - court_center_x) > antenna_half_width
		cross_seq += 1
	_update_shadow()
	_update_stretch(delta)
	trail.set_active( not far_lod and vel.length() > PHYS.trail_min_speed)













static func solve_launch(from: Vector3, target: Vector3, kind: int, power: float, 
		finesse: bool, influence: = Vector2.ZERO, clearance: = false, 
		quick: = false, serve: = false) -> Vector3:





	const MIN_CLEAR_LANDING_DEPTH: = 0.85
	if clearance and from.z * target.z < 0.0\
	and absf(target.z) < MIN_CLEAR_LANDING_DEPTH:
		target.z = - signf(from.z) * MIN_CLEAR_LANDING_DEPTH




	if kind == Player.TouchKind.SET:
		target.y = PHYS.quick_arrive_h if quick else PHYS.set_arrive_h
	else:
		target.y = 0.0
	var flight: = _flight_time(kind, power, finesse, quick)



	if kind == Player.TouchKind.SET and not quick and not finesse:
		var set_flat: = Vector2(target.x - from.x, target.z - from.z).length()
		if set_flat < PHYS.set_far_dist:
			var tall: = lerpf(1.45, PHYS.set_near_full_time, power)
			var blend: = clampf((set_flat - PHYS.set_near_dist)
				/ (PHYS.set_far_dist - PHYS.set_near_dist), 0.0, 1.0)
			flight = lerpf(tall, flight, blend)
	flight *= lerpf(PHYS.float_time_factor, PHYS.drive_time_factor, (influence.y + 1.0) * 0.5)




	if kind == Player.TouchKind.SPIKE:
		var spike_flat: = Vector2(target.x - from.x, target.z - from.z).length()
		var speed: float
		var min_flight: float
		if finesse:



			speed = PHYS.spike_speed_slow * 0.9
			min_flight = 1.0
		else:
			speed = lerpf(PHYS.spike_speed_slow, PHYS.spike_speed_fast, clampf(power, 0.0, 1.0))


			min_flight = lerpf(PHYS.spike_min_flight_slow, PHYS.spike_min_flight, clampf(power, 0.0, 1.0))
		speed /= lerpf(PHYS.float_time_factor, PHYS.drive_time_factor, (influence.y + 1.0) * 0.5)
		flight = clampf(spike_flat / maxf(speed, 1.0), min_flight, 3.0)
	var to_target: = target - from
	var out: = Vector3(to_target.x, 0.0, to_target.z) / flight
	out.y = (to_target.y + 0.5 * PHYS.gravity * flight * flight) / flight




	var lo: = 0.0
	var hi: = INF
	match kind:
		Player.TouchKind.SPIKE: lo = PHYS.spike_min_speed
		Player.TouchKind.DUMP: lo = PHYS.dump_min_speed
		Player.TouchKind.BUMP: hi = PHYS.pass_max_speed
		Player.TouchKind.SET: hi = PHYS.quick_set_max_speed if quick else PHYS.pass_max_speed
	var flat_speed: = Vector2(out.x, out.z).length()
	var flat_dist: = Vector2(to_target.x, to_target.z).length()
	if flat_dist > 0.05 and flat_speed > 0.01\
	and (flat_speed < lo or flat_speed > hi):




		flight = minf(flat_dist / clampf(flat_speed, lo, hi), 3.0)
		out = Vector3(to_target.x, 0.0, to_target.z) / flight
		out.y = (to_target.y + 0.5 * PHYS.gravity * flight * flight) / flight
	if clearance:








		if signf(to_target.z) == signf( - from.z) and to_target.z != 0.0:
			var f: = absf(from.z) / absf(to_target.z)
			if f < 1.0:



				var margin: = PHYS.pass_clear_margin


				if not serve and (kind == Player.TouchKind.SPIKE or kind == Player.TouchKind.DUMP):
					margin = lerpf(PHYS.attack_clear_soft, 
						PHYS.attack_clear_tight, clampf(power, 0.0, 1.0))
				var clear: = PHYS.net_height + margin + PHYS.radius
				var coef: = 0.5 * PHYS.gravity * f * (1.0 - f)
				var need: = clear - from.y * (1.0 - f)
				if coef > 0.0 and need > 0.0 and need / coef > flight * flight:
					flight = sqrt(need / coef)
					out = Vector3(to_target.x, 0.0, to_target.z) / flight
					out.y = (to_target.y + 0.5 * PHYS.gravity * flight * flight) / flight
	return out

func hit(target: Vector3, kind: int, power: float, finesse: bool, 
		influence: = Vector2.ZERO, clearance_assist: = false, quick: = false, 
		float_seed_in: = 0) -> void :
	vel = solve_launch(global_position, target, kind, power, finesse, influence, 
		serve_assist or clearance_assist, quick, serve_assist)
	if float_seed_in != 0:

		vel = solve_float(global_position, target, power)
	serve_assist = false
	curve = - influence.x * PHYS.curve_strength


	stop_float()
	if float_seed_in != 0:
		start_float(float_seed_in)
	last_hit_power = power
	last_hit_kind = kind


	if kind == Player.TouchKind.SPIKE:
		spike_lock = clampf((vel.length() - PHYS.spike_lock_free) * PHYS.spike_lock_gain, 
			0.0, PHYS.spike_lock_max)
	else:
		spike_lock = 0.0






	hitstop_left = _pending_hitstop
	_pending_hitstop = 0.0
	_mark_strike()
	struck.emit(global_position, power, kind)

var recorder = null




func _mark_strike() -> void :
	_pulse = 1.0
	strike_seq += 1

func pulse() -> void :
	if recorder != null:
		recorder.cue("pulse", {})

	_mark_strike()




func floor_squash(impact: float) -> void :
	if recorder != null:
		recorder.cue("fsquash", {"s": impact})
	_floor_squash = maxf(_floor_squash, clampf((impact - 5.0) / 13.0, 0.0, 1.0))



static func solve_float(from: Vector3, target: Vector3, power: float) -> Vector3:
	var t: = lerpf(PHYS.float_serve_time_slow, PHYS.float_serve_time_fast, clampf(power, 0.0, 1.0))
	var to_target: = target - from
	var out: = Vector3(to_target.x, 0.0, to_target.z) / t
	out.y = (to_target.y + 0.5 * PHYS.gravity * t * t) / t
	return out

func start_float(seed: int) -> void :
	float_serve = true
	float_seed = seed
	_float_t = 0.0
	_float_prev = Vector3.ZERO
	curve = 0.0

func stop_float() -> void :
	float_serve = false
	_float_prev = Vector3.ZERO




static func _fhash(seed: int, i: int) -> float:


	var x: = (absi(seed) * 374761393 + (i + 1) * 668265263) & 2147483647
	x = ((x ^ (x >> 13)) * 1274126177) & 2147483647
	x = (x ^ (x >> 16)) & 2147483647
	return float(x) / float(2147483647)






static func float_offset(seed: int, t: float, v: Vector3) -> Vector3:
	var f1: = 0.7 + 0.5 * _fhash(seed, 0)
	var f2: = 2.4 + 1.7 * _fhash(seed, 1)
	var f3: = 1.3 + 1.2 * _fhash(seed, 2)
	var pa: = _fhash(seed, 3) * TAU
	var pb: = _fhash(seed, 4) * TAU
	var pc: = _fhash(seed, 5) * TAU
	var dir: = 1.0 if _fhash(seed, 6) < 0.5 else -1.0
	var lean_amp: = 0.7 + 0.7 * _fhash(seed, 7)
	var jit_amp: = 0.22 + 0.4 * _fhash(seed, 8)
	var skew: = 0.65 + 0.9 * _fhash(seed, 9)
	var mag: = 0.85 + 0.35 * _fhash(seed, 10)
	var env: = smoothstep(0.0, 0.25, t)
	var flat: = Vector3(v.x, 0.0, v.z)
	var side: = Vector3.RIGHT if flat.length() < 0.5 else Vector3.UP.cross(flat.normalized())


	var s: = sin(TAU * f1 * t + pa)
	var swept: = signf(s) * pow(absf(s), skew) * lean_amp * dir
	var jitter: = sin(TAU * f2 * t + pb) * jit_amp
	var lat: = clampf((swept + jitter) * mag, -1.9, 1.9) * FLOAT_LAT
	var vert: = sin(TAU * f3 * t + pc) * FLOAT_VERT
	return (side * lat + Vector3.UP * vert) * env

func shank() -> void :



	_pending_hitstop = 0.0
	hitstop_left = 0.0
	stop_float()
	var ang: = randf() * TAU
	vel = Vector3(cos(ang), 0.0, sin(ang)) * randf_range(5.0, 9.0)
	vel.y = randf_range(2.0, 4.5)
	curve = randf_range(-0.5, 0.5) * PHYS.curve_strength
	_mark_strike()
	struck.emit(global_position, 0.2, Player.TouchKind.BUMP)



func net_capture() -> PackedFloat32Array:
	return PackedFloat32Array([global_position.x, global_position.y, 
		global_position.z, vel.x, vel.y, vel.z, 1.0 if frozen else 0.0])

func net_apply(a: PackedFloat32Array) -> void :
	if a.size() < 7:
		return
	global_position = Vector3(a[0], a[1], a[2])
	vel = Vector3(a[3], a[4], a[5])
	frozen = a[6] > 0.5





func set_replay_time_scale(scale: float) -> void :
	_replay_time_scale = scale
	if trail != null:
		trail.speed_scale = maxf(scale, 0.0)

func toss(pos: Vector3, up_speed: = 7.5) -> void :
	global_position = pos
	vel = Vector3(0.0, up_speed, 0.0)
	curve = 0.0
	stop_float()

	_magnet_offset = Vector3.ZERO
	_magnet_target = Vector3.ZERO
	_magnet_hold = 0
	mesh.position = Vector3.ZERO
	reset_visuals()
	trail.restart()
	reset_physics_interpolation()
	shadow.reset_physics_interpolation()
	landing_ring.reset_physics_interpolation()







func reset_visuals() -> void :
	_pulse = 0.0
	_floor_squash = 0.0
	hitstop_left = 0.0
	_spin = 0.0
	mesh.scale = Vector3.ONE
	mesh.transform.basis = Basis()
	((mesh.mesh as SphereMesh).material as ShaderMaterial).set_shader_parameter("spin", 0.0)
	if _model != null:
		_model.rotation = Vector3.ZERO

static func _flight_time(kind: int, power: float, finesse: bool, quick: = false) -> float:








	match kind:
		Player.TouchKind.BUMP:






			return lerpf(1.05, 1.85, power)
		Player.TouchKind.SET:


			if quick:
				return 0.45
			return 1.65 if finesse else lerpf(1.45, 0.58, power)
		Player.TouchKind.SPIKE:









			return 1.0 if finesse else lerpf(0.9, 0.52, power)
		Player.TouchKind.DUMP:

			return 0.85 if finesse else lerpf(0.7, 0.5, power)
	return 1.5

func power_through() -> void :


	vel.x *= 0.82
	vel.z *= 0.82
	vel.y = minf(vel.y, 0.0) - 1.2
	_mark_strike()
	struck.emit(global_position, last_hit_power, Player.TouchKind.SPIKE)

func spike_locked() -> bool:
	return spike_lock > 0.0

func block_deflect(center: Vector3, aim: Vector3) -> void :
	spike_lock = 0.0




	var off: = global_position - center


	var tooled: = absf(off.x) > 0.7 or off.y > 0.55
	if tooled:











		var flat_in: = Vector2(vel.x, vel.z)
		var speed_in: = flat_in.length()
		var keep: = clampf(PHYS.tool_keep - speed_in * PHYS.tool_bleed, 
			PHYS.tool_keep_min, PHYS.tool_keep)
		var dir: = flat_in.normalized() if speed_in > 0.01 else Vector2(0.0, signf(vel.z))


		var out: = dir * (speed_in * keep) + Vector2(off.x * PHYS.tool_smear, 0.0)

		if out.length() > PHYS.tool_max_speed:
			out = out.normalized() * PHYS.tool_max_speed
		vel = Vector3(out.x, 
			absf(vel.y) * 0.35 + PHYS.tool_lift + speed_in * PHYS.tool_lift_gain, 
			out.y)
	else:

		var speed: = maxf(vel.length() * 0.75, 5.0)
		aim.y = 0.0
		var to_aim: = aim - global_position
		var flat: = Vector3(to_aim.x, 0.0, to_aim.z)
		var t: = clampf(flat.length() / speed, 0.25, 1.1)
		vel = flat / t
		vel.y = ( - global_position.y + 0.5 * PHYS.gravity * t * t) / t
		vel.x += off.x * 2.0
	curve = 0.0
	stop_float()
	_mark_strike()
	struck.emit(global_position, 0.8, Player.TouchKind.BLOCK)

func _bounce_walls() -> void :


	var touched_wall: = false
	if global_position.x < wall_min.x + PHYS.radius:
		global_position.x = wall_min.x + PHYS.radius
		vel.x = absf(vel.x) * 0.5
		touched_wall = true
	elif global_position.x > wall_max.x - PHYS.radius:
		global_position.x = wall_max.x - PHYS.radius
		vel.x = - absf(vel.x) * 0.5
		touched_wall = true
	if global_position.z < wall_min.z + PHYS.radius:
		global_position.z = wall_min.z + PHYS.radius
		vel.z = absf(vel.z) * 0.5
		touched_wall = true
	elif global_position.z > wall_max.z - PHYS.radius:
		global_position.z = wall_max.z - PHYS.radius
		vel.z = - absf(vel.z) * 0.5
		touched_wall = true
	if global_position.y > wall_max.y - PHYS.radius:
		global_position.y = wall_max.y - PHYS.radius
		vel.y = - absf(vel.y) * 0.5
		touched_wall = true
	if touched_wall:


		wall_hit.emit()








static func step_flight(pos: Vector3, vel: Vector3, curve_in: float, dt: float, 
		net_half_w: float, court_cx: float, wmin: Vector3, wmax: Vector3) -> Array:
	var prev: = pos
	vel.y -= PHYS.gravity * dt
	if curve_in != 0.0:


		var flat: = Vector3(vel.x, 0.0, vel.z)
		var sp: = flat.length()
		if sp > 1.0:
			vel += Vector3.UP.cross(flat / sp) * curve_in * (sp / PHYS.curve_ref_speed) * dt
		curve_in *= exp( - dt / PHYS.curve_decay_time)
	pos += vel * dt

	if pos.y <= PHYS.radius and vel.y < 0.0:
		pos.y = PHYS.radius
		vel.y = - vel.y * PHYS.floor_bounce
		vel.x *= PHYS.floor_friction
		vel.z *= PHYS.floor_friction
		curve_in = 0.0
		if vel.y < 1.2:
			vel.y = 0.0
	if pos.y <= PHYS.radius + 0.001 and vel.y == 0.0:
		vel.x = move_toward(vel.x, 0.0, PHYS.roll_drag * dt)
		vel.z = move_toward(vel.z, 0.0, PHYS.roll_drag * dt)

	if signf(prev.z) != signf(pos.z):
		var dip: = PHYS.net_height - (pos.y - PHYS.radius)
		if dip > 0.0 and absf(pos.x - court_cx) < net_half_w:
			var to_side: = - signf(prev.z)
			if dip <= PHYS.tape_band:

				pos.z = to_side * (PHYS.radius + 0.03)
				var pop: = clampf(PHYS.tape_pop_base + vel.length() * PHYS.tape_pop_gain, 
					PHYS.tape_pop_min, PHYS.tape_pop_max)
				vel.z = to_side * PHYS.tape_drift
				vel.x *= PHYS.tape_side_damp
				vel.y = pop
			else:
				pos.z = signf(prev.z) * (PHYS.radius + 0.03)
				vel.z = - vel.z * 0.25
				vel.x *= 0.7
				vel.y = minf(vel.y * 0.5, 2.0)

	if pos.x < wmin.x + PHYS.radius:
		pos.x = wmin.x + PHYS.radius
		vel.x = absf(vel.x) * 0.5
	elif pos.x > wmax.x - PHYS.radius:
		pos.x = wmax.x - PHYS.radius
		vel.x = - absf(vel.x) * 0.5
	if pos.z < wmin.z + PHYS.radius:
		pos.z = wmin.z + PHYS.radius
		vel.z = absf(vel.z) * 0.5
	elif pos.z > wmax.z - PHYS.radius:
		pos.z = wmax.z - PHYS.radius
		vel.z = - absf(vel.z) * 0.5
	if pos.y > wmax.y - PHYS.radius:
		pos.y = wmax.y - PHYS.radius
		vel.y = - absf(vel.y) * 0.5
	return [pos, vel, curve_in]

func _bounce_floor(delta: float) -> void :
	if global_position.y <= PHYS.radius and vel.y < 0.0:
		global_position.y = PHYS.radius
		if - vel.y > 0.8:
			_pulse = 0.8
			floor_squash(vel.length())
			bounced.emit()
		vel.y = - vel.y * PHYS.floor_bounce
		vel.x *= PHYS.floor_friction
		vel.z *= PHYS.floor_friction
		curve = 0.0
		stop_float()
		if vel.y < 1.2:
			vel.y = 0.0
	if global_position.y <= PHYS.radius + 0.001 and vel.y == 0.0:

		vel.x = move_toward(vel.x, 0.0, PHYS.roll_drag * delta)
		vel.z = move_toward(vel.z, 0.0, PHYS.roll_drag * delta)

func _hit_net(prev: Vector3) -> void :


	if signf(prev.z) == signf(global_position.z):
		return

	var dip: = PHYS.net_height - (global_position.y - PHYS.radius)
	var inside_posts: = absf(global_position.x - court_center_x) < net_half_width
	if dip <= 0.0 or not inside_posts:
		return




	last_net_impact = vel.length()
	var to_side: = - signf(prev.z)
	if dip <= PHYS.tape_band:




		global_position.z = to_side * (PHYS.radius + 0.03)
		var pop: = clampf(PHYS.tape_pop_base + last_net_impact * PHYS.tape_pop_gain, 
			PHYS.tape_pop_min, PHYS.tape_pop_max)
		vel.z = to_side * PHYS.tape_drift
		vel.x *= PHYS.tape_side_damp
		vel.y = pop
		net_hit.emit()
		return

	global_position.z = signf(prev.z) * (PHYS.radius + 0.03)
	vel.z = - vel.z * 0.25
	vel.x *= 0.7
	vel.y = minf(vel.y * 0.5, 2.0)
	net_hit.emit()



func magnet_lean(toward: Vector3, strength: float) -> void :
	var pull: = toward - global_position
	var dist: = pull.length()
	if dist > 0.001:


		_magnet_target = pull / dist\
		* minf(dist * 0.35, PHYS.magnet_lean_max) * clampf(strength, 0.0, 1.0)
	_magnet_hold = 2

func _update_magnet_lean(delta: float) -> void :
	var goal: = _magnet_target if _magnet_hold > 0 else Vector3.ZERO
	_magnet_hold = maxi(_magnet_hold - 1, 0)


	var k: = 18.0 if goal.length() > _magnet_offset.length() else 10.0
	_magnet_offset = _magnet_offset.lerp(goal, 1.0 - exp( - k * delta))
	mesh.position = _magnet_offset

func _update_stretch(delta: float) -> void :

	var speed: = vel.length()








	if not float_serve and hitstop_left <= 0.0:
		_spin = fmod(_spin + speed * delta * 1.4 * _replay_time_scale, TAU)
	((mesh.mesh as SphereMesh).material as ShaderMaterial)\
	.set_shader_parameter("spin", _spin)



	if _model != null:
		_model.rotation = Vector3(_spin, 0.0, 0.0)
	if _floor_squash > 0.02:



		var f: = _floor_squash
		mesh.global_transform.basis = Basis.IDENTITY
		mesh.scale = Vector3(1.0 + 0.7 * f, 1.0 - 0.62 * f, 1.0 + 0.7 * f)
		mesh.position = _magnet_offset + Vector3(0.0, - PHYS.radius * 0.62 * f, 0.0)
		_floor_squash = move_toward(_floor_squash, 0.0, delta * 5.0)
		_pulse = move_toward(_pulse, 0.0, delta * 5.0)
		return
	if speed > 6.0:
		var dir: = vel / speed
		var up: = Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
		mesh.global_transform.basis = Basis.looking_at(dir, up)
		var s: = clampf((speed - 6.0) * 0.05, 0.0, 0.75)
		mesh.scale = Vector3(
			1.0 - s * 0.35 + _pulse * 0.5, 
			1.0 - s * 0.35 + _pulse * 0.5, 
			1.0 + s - _pulse * 0.45)
	else:
		var squashed: = Vector3(1.0 + _pulse * 0.35, 1.0 - _pulse * 0.4, 1.0 + _pulse * 0.35)
		mesh.scale = mesh.scale.lerp(squashed, 1.0 - exp(-14.0 * delta))
	_pulse = move_toward(_pulse, 0.0, delta * 5.0)

func _update_outline() -> void :

	var mat: StandardMaterial3D = (outline.mesh as SphereMesh).material












	var on_home: = Rules.half_identity(global_position.z) > 0
	outline_color = PHYS.outline_home if on_home else PHYS.outline_away
	mat.albedo_color = outline_color





	trail.color = PHYS.trail_fast if vel.length() > PHYS.trail_fast_speed\
	else outline_color






func predict_point(height: float) -> Vector3:
	var dy: = global_position.y - height
	var disc: = vel.y * vel.y + 2.0 * PHYS.gravity * dy
	if disc <= 0.0:
		return Vector3(global_position.x, height, global_position.z)
	var t: = (vel.y + sqrt(disc)) / PHYS.gravity
	if t <= 0.0:
		return Vector3(global_position.x, height, global_position.z)
	return Vector3(global_position.x + vel.x * t, height, 
		global_position.z + vel.z * t)

func _update_landing_ring() -> void :





	var airborne: = show_landing_ring and not landing_ring_muted and global_position.y > PHYS.radius + 0.3
	landing_ring.visible = airborne
	if _tether != null:
		_tether.visible = airborne
		_tether_shell.visible = airborne
	if not airborne:
		return



	landing_ring.global_position = Vector3(global_position.x, maxf(0.055, SandDeform.decal_y), global_position.z)
	var s: = clampf(1.0 + global_position.y * 0.1, 1.0, 1.8)


	var closeness: = 0.0
	var disc: = vel.y * vel.y + 2.0 * PHYS.gravity * (global_position.y - PHYS.radius)
	if disc >= 0.0 and vel.y < 0.0:
		var t_floor: = (vel.y + sqrt(disc)) / PHYS.gravity
		closeness = clampf(1.0 - t_floor / 0.9, 0.0, 1.0)
	var ring_col: Color
	if closeness < 0.5:
		ring_col = Color(0.3, 0.9, 0.35).lerp(Color(1.0, 0.6, 0.1), closeness * 2.0)
	else:
		ring_col = Color(1.0, 0.6, 0.1).lerp(Color(1.0, 0.15, 0.1), (closeness - 0.5) * 2.0)
	ring_col.a = lerpf(0.7, 0.95, closeness)
	if _ring_mat != null:
		_ring_mat.set_shader_parameter("tint", ring_col)


		_ring_mat.set_shader_parameter("edge", 
			Color(ring_col.r, ring_col.g, ring_col.b, 0.94).darkened(0.88))
	s *= 1.0 + 0.15 * closeness
	landing_ring.scale = Vector3(s, 1.0, s)




	if _tether != null:
		var h: = maxf(global_position.y - PHYS.radius, 0.02)
		var base: = Vector3(global_position.x, PHYS.radius + h * 0.5, global_position.z)
		_tether.global_position = base
		_tether.scale = Vector3(1.0, h, 1.0)
		_tether_shell.global_position = base
		_tether_shell.scale = Vector3(1.4, h, 1.4)
		_tether_mat.set_shader_parameter("length_m", h)
		_tether_shell_mat.set_shader_parameter("length_m", h)
		var tcol: = ring_col
		tcol.a = 0.95
		_tether_mat.set_shader_parameter("tint", tcol)

func _update_shadow() -> void :


	shadow.visible = global_position.y > -0.5
	if not shadow.visible:
		return

	shadow.global_position = Vector3(global_position.x, maxf(0.02, SandDeform.decal_y), global_position.z)
	var s: = clampf(1.0 - global_position.y * 0.06, 0.4, 1.0)
	shadow.scale = Vector3(s, 1.0, s)
