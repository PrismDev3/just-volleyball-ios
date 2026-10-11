@tool
class_name GrassField3D
extends Node3D

const DEBUG_BUILD: = false

















const GRASS_SHADER: = preload("res://game/court/grass.gdshader")
const FLOOR_SHADER: = preload("res://game/court/grass_floor.gdshader")
const MAX_INTERACT: = 12


@export_group("Field")


@export var field_half: = Vector2(30.0, 34.0)
@export_range(4.0, 24.0) var chunk_size: = 10.0

@export var field_seed: = 20260813

@export var regenerate: = false: set = _set_regenerate

@export_group("Density (clumps per m^2)")
@export_range(0.0, 60.0) var interior_density: = 16.0
@export_range(0.0, 120.0) var mid_density: = 28.0
@export_range(0.0, 200.0) var outer_density: = 44.0
@export_range(0.0, 30.0) var ring_width: = 6.0


@export var max_instances: = 220000


@export_range(0.0, 4.0) var court_clear: = 0.0


@export_range(0.0, 0.6) var line_clear: = 0.22

@export_group("Card / tuft")

@export_range(0.05, 1.5) var card_height: = 0.4
@export_range(0.1, 1.0) var interior_height: = 0.55
@export_range(0.05, 0.8) var card_width: = 0.32
@export_range(1, 6) var tuft_blades: = 3
@export_range(0.05, 0.95) var blade_thickness: = 0.62
@export_range(0.0, 1.0) var tip_narrow: = 0.6
@export_range(0.0, 0.5) var height_jitter: = 0.36


@export_range(0.0, 1.5) var indicator_clearance: = 1.0


@export_range(0.0, 1.0) var indicator_feet: = 0.35

@export_group("Wind")
@export var wind_direction: = Vector2(1.0, 0.35)
@export_range(0.0, 1.0) var wind_strength: = 0.32
@export_range(0.0, 4.0) var wind_speed: = 1.1
@export_range(1.0, 60.0) var large_wave_scale: = 22.0
@export_range(0.5, 20.0) var small_wave_scale: = 6.0
@export_range(0.0, 0.5) var flutter_strength: = 0.06
@export_range(1.0, 4.0) var bend_curve: = 1.6


@export_range(0.0, 1.0) var wind_shade: = 0.32


@export_range(0.0, 1.0) var topdown_flatten: = 0.75

@export_group("Interaction")
@export_range(0.0, 3.0) var walk_radius: = 0.7
@export_range(0.0, 3.0) var run_radius: = 1.1
@export_range(0.0, 4.0) var dive_radius: = 1.8
@export_range(0.0, 2.0) var walk_strength: = 0.35
@export_range(0.0, 3.0) var run_strength: = 0.7
@export_range(0.0, 4.0) var dive_strength: = 2.2
@export_range(1.0, 12.0) var run_speed: = 5.0
@export var interact_ball: = true


@export var wake_recovery: = true
@export_range(0.0, 1.0) var wake_flatten: = 0.8
@export_range(0.0, 1.0) var wake_bend: = 0.5

@export_group("LOD & shadows")
@export_range(1.0, 200.0) var lod_near: = 15.0
@export_range(1.0, 400.0) var lod_far: = 55.0
@export_range(0.0, 60.0) var lod_fade: = 10.0


@export_range(0.0, 60.0) var shadow_distance: = 0.0

@export_group("Color")


@export var ground_texture: Texture2D = preload("res://game/assets/textures/grasstielablecartoon.jpg")
@export_range(0.02, 1.0) var ground_tex_scale: = 0.14
@export var base_tint: = Color(1, 1, 1)
@export_range(0.0, 3.0) var brightness: = 1.0



@export var reskin_floor: = true
@export_range(0.05, 4.0) var floor_tex_scale: = 1.0


@export_range(0.0, 1.5) var root_shade: = 1.0
@export var tip_color: = Color(0.6, 0.74, 0.42)
@export_range(0.0, 1.0) var tip_amount: = 0.5
@export_range(0.0, 1.0) var color_variation: = 0.26

@export var patch_color: = Color(0.46, 0.62, 0.34)
@export_range(1.0, 40.0) var patch_scale: = 8.0
@export_range(0.0, 1.0) var patch_strength: = 0.25

@export var grad_bottom: = Color(1.0, 1.02, 0.92)
@export var grad_top: = Color(0.82, 0.93, 0.86)
@export_range(0.0, 1.0) var grad_strength: = 0.12

@export_group("Debug")
@export var debug_disable: = false: set = _set_disable
@export var debug_freeze_wind: = false



var _court_half: = Vector2(9.0, 9.0)
var _bodies_provider: = Callable()
var _ball_provider: = Callable()

var _mat: ShaderMaterial
var _gfloor_mat: ShaderMaterial
var _wake: GrassWake = null
var _chunks: Array[GrassChunk] = []
var _built: = false
var _total: = 0
var _interact: = PackedVector4Array()


var _configured: = false
var _grass_shown: = true

func _ready() -> void :
	_interact.resize(MAX_INTERACT)
	set_process(true)





	if Engine.is_editor_hint():
		_rebuild()



func configure(half_w: float, half_l: float) -> void :
	_court_half = Vector2(half_w, half_l)
	_configured = true
	_rebuild()


func set_feeds(bodies_provider: Callable, ball_provider: Callable) -> void :
	_bodies_provider = bodies_provider
	_ball_provider = ball_provider
	_ensure_wake()




func _ensure_wake() -> void :
	if _wake != null or _mat == null:
		return
	if not wake_recovery:
		return
	_wake = GrassWake.new()
	_wake.name = "GrassWake"
	add_child(_wake)
	var span: = 2.0 * maxf(_court_half.x, _court_half.y) + 8.0
	_wake.setup(span, Vector2(global_position.x, global_position.z))
	_wake.bodies_provider = _bodies_provider
	_bind_wake()



func _bind_wake() -> void :
	if _wake == null or _mat == null:
		return
	_mat.set_shader_parameter("wake_tex", _wake.texture())
	_mat.set_shader_parameter("wake_center", _wake.wake_center_xz())
	_mat.set_shader_parameter("wake_area", _wake.wake_area())
	_mat.set_shader_parameter("wake_on", true)





func indicator_clearance_y() -> float:
	return card_height * (1.0 + height_jitter) * indicator_clearance


func indicator_feet_y() -> float:
	return card_height * (1.0 + height_jitter) * indicator_feet




func _rebuild() -> void :
	if not is_inside_tree():
		return
	_clear()
	if debug_disable:
		_built = false
		return
	var t0: = Time.get_ticks_usec()
	_mat = _make_material()
	var clump: = _build_clump_mesh()

	var cs: = maxf(chunk_size, 2.0)
	var nx: = int(ceil(field_half.x * 2.0 / cs))
	var nz: = int(ceil(field_half.y * 2.0 / cs))
	var origin: = Vector2( - field_half.x, - field_half.y)

	var rng: = RandomNumberGenerator.new()
	rng.seed = field_seed



	var peak: = maxf(maxf(interior_density, mid_density), outer_density)
	if peak <= 0.0:
		_built = true
		return

	var scale: = 1.0
	var est: = _estimate_total(cs, nx, nz, origin)
	if max_instances > 0 and est > max_instances:
		scale = float(max_instances) / float(est)
		push_warning("GrassField3D: estimated %d clumps over max %d; density scaled to %.2f"
			%[est, max_instances, scale])

	_total = 0
	var max_bh: = card_height * (1.0 + height_jitter)
	for cz in nz:
		for cx in nx:
			var cmin: = origin + Vector2(cx, cz) * cs
			var cmax: = Vector2(minf(cmin.x + cs, field_half.x), 
				minf(cmin.y + cs, field_half.y))
			var area: = (cmax.x - cmin.x) * (cmax.y - cmin.y)
			if area <= 0.0:
				continue
			var candidates: = int(ceil(peak * area * scale))
			var transforms: Array = []
			var customs: Array = []
			for _c in candidates:
				var px: = rng.randf_range(cmin.x, cmax.x)
				var pz: = rng.randf_range(cmin.y, cmax.y)
				var reg: = _region(px, pz)
				if reg[0] <= 0.0:
					continue

				if rng.randf() > (reg[0] * scale) / peak:
					continue
				var hs: float = reg[1] * (1.0 + rng.randf_range( - height_jitter, height_jitter))
				var wv: = 1.0 + rng.randf_range(-0.15, 0.15)


				var basis: = Basis.IDENTITY.scaled(
					Vector3(card_width * wv, card_height * hs, card_width * wv))
				transforms.append(Transform3D(basis, Vector3(px, 0.0, pz)))

				customs.append(Color(rng.randf(), rng.randf(), 0.0, rng.randf()))
			if transforms.is_empty():
				continue
			var chunk: = GrassChunk.new()
			chunk.name = "GrassChunk_%d_%d" % [cx, cz]
			add_child(chunk)

			if Engine.is_editor_hint() and get_tree() != null:
				chunk.owner = null
			var pad: = maxf(max_bh, dive_radius) + 1.0
			var bounds: = AABB(
				Vector3(cmin.x - pad, - pad, cmin.y - pad), 
				Vector3((cmax.x - cmin.x) + pad * 2.0, max_bh + pad * 2.0, 
					(cmax.y - cmin.y) + pad * 2.0))
			chunk.populate(clump, _mat, transforms, customs, bounds, lod_far, lod_fade)
			_chunks.append(chunk)
			_total += transforms.size()
	_reskin_floor()
	_bind_wake()
	_built = true
	if DEBUG_BUILD:
		var ms: = (Time.get_ticks_usec() - t0) / 1000.0
		print("GrassField3D: %d clumps in %d chunks, ~%.0f k tris, built in %.1f ms"
			%[_total, _chunks.size(), _total * _clump_tris(clump) / 1000.0, ms])




func _reskin_floor() -> void :
	if not reskin_floor:
		return
	var floor: = _find_env_floor()
	if floor == null:
		return
	if _gfloor_mat == null:
		_gfloor_mat = ShaderMaterial.new()
		_gfloor_mat.shader = FLOOR_SHADER
	_gfloor_mat.set_shader_parameter("tex", ground_texture)
	_gfloor_mat.set_shader_parameter("world_scale", floor_tex_scale)
	_push_floor_look()
	floor.material_override = _gfloor_mat

func _find_env_floor() -> MeshInstance3D:
	var p: = get_parent()
	if p == null:
		return null
	for m in p.find_children("EnvFloor", "MeshInstance3D", true, false):
		return m as MeshInstance3D
	return null

func _push_floor_look() -> void :
	if _gfloor_mat == null:
		return
	_gfloor_mat.set_shader_parameter("tint", base_tint)
	_gfloor_mat.set_shader_parameter("brightness", brightness)
	_gfloor_mat.set_shader_parameter("patch_color", patch_color)
	_gfloor_mat.set_shader_parameter("patch_scale", patch_scale)
	_gfloor_mat.set_shader_parameter("patch_strength", patch_strength)



func _estimate_total(cs: float, nx: int, nz: int, origin: Vector2) -> int:
	var sum: = 0.0
	for cz in nz:
		for cx in nx:
			var c: = origin + (Vector2(cx, cz) + Vector2(0.5, 0.5)) * cs
			sum += _region(c.x, c.y)[0] * cs * cs
	return int(sum)



func _region(x: float, z: float) -> Array:
	var cw: float = _court_half.x + court_clear
	var cl: float = _court_half.y + court_clear



	if line_clear > 0.0 and absf(x) <= _court_half.x + line_clear + 0.5\
	and absf(z) <= _court_half.y + line_clear + 0.5:
		if absf(absf(x) - _court_half.x) < line_clear\
		or absf(absf(z) - _court_half.y) < line_clear\
		or absf(z) < line_clear:
			return [0.0, 0.0]


	var edge: = minf(field_half.x, field_half.y)
	var taper: = 1.0 - smoothstep(edge * 0.7, edge, maxf(absf(x), absf(z)))
	if court_clear > 0.0 and absf(x) < cw and absf(z) < cl:
		return [0.0, 0.0]
	var dx: = maxf(absf(x) - cw, 0.0)
	var dz: = maxf(absf(z) - cl, 0.0)
	if dx <= 0.0 and dz <= 0.0:
		return [interior_density, interior_height]
	var d: = sqrt(dx * dx + dz * dz)
	if d <= ring_width:
		var k: = d / maxf(ring_width, 0.001)
		return [lerpf(mid_density, outer_density, k) * taper, 
			lerpf(interior_height + (1.0 - interior_height) * 0.5, 1.0, k)]
	return [outer_density * taper, 1.0]






func _build_clump_mesh() -> ArrayMesh:
	var verts: = PackedVector3Array([
		Vector3(-0.5, 0.0, 0.0), Vector3(0.5, 0.0, 0.0), 
		Vector3(-0.5, 1.0, 0.0), Vector3(0.5, 1.0, 0.0)])
	var uvs: = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(1.0, 0.0), 
		Vector2(0.0, 1.0), Vector2(1.0, 1.0)])
	var norms: = PackedVector3Array([
		Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	var idx: = PackedInt32Array([0, 1, 2, 1, 3, 2])
	var arr: = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_INDEX] = idx
	var m: = ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m

func _clump_tris(m: Mesh) -> int:
	return (m.surface_get_arrays(0)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3

func _make_material() -> ShaderMaterial:
	var mat: = ShaderMaterial.new()
	mat.shader = GRASS_SHADER
	_push_look(mat)
	mat.set_shader_parameter("interact_count", 0)
	return mat




func _process(_dt: float) -> void :
	if not _built or _mat == null:
		return
	if Engine.is_editor_hint():
		_push_look(_mat)
		_push_floor_look()
	else:


		var on: bool = GameConfig.grass
		if on != _grass_shown:
			_grass_shown = on
			for c in _chunks:
				c.visible = on
		if not on:
			return
	_update_chunks()
	_update_interaction()

func _update_interaction() -> void :
	var n: = 0
	if _bodies_provider.is_valid():
		var bodies: Array = _bodies_provider.call()


		for b in bodies:
			if n >= MAX_INTERACT:
				break
			if b == null or not is_instance_valid(b):
				continue
			if not (b.has_method("grounded") and b.grounded()):
				continue
			var p: Vector3 = b.global_position
			var strength: = walk_strength
			var radius: = walk_radius
			if b.has_method("diving") and b.diving():
				strength = dive_strength
				radius = dive_radius
			else:
				var v: Vector3 = b.velocity
				if Vector2(v.x, v.z).length() >= run_speed:
					strength = run_strength
					radius = run_radius
			_interact[n] = Vector4(p.x, p.z, strength, radius)
			n += 1
	if interact_ball and n < MAX_INTERACT and _ball_provider.is_valid():
		var ball = _ball_provider.call()
		if ball != null and is_instance_valid(ball):
			var bp: Vector3 = ball.global_position
			if bp.y < card_height * 1.5:
				_interact[n] = Vector4(bp.x, bp.z, run_strength, run_radius)
				n += 1

	for i in range(n, MAX_INTERACT):
		_interact[i] = Vector4.ZERO
	_mat.set_shader_parameter("interact_points", _interact)
	_mat.set_shader_parameter("interact_count", n)







func _update_chunks() -> void :
	var cam: = get_viewport().get_camera_3d()
	if cam == null:
		return
	var cp: = cam.global_position
	var cp_flat: = Vector3(cp.x, 0.0, cp.z)
	var near2: = lod_near * lod_near
	var span: = maxf(lod_far - lod_near, 0.001)
	var shad: = shadow_distance > 0.0
	var sd2: = shadow_distance * shadow_distance
	for c in _chunks:
		var mid: = c.chunk_center()
		var d2: = Vector3(mid.x, 0.0, mid.z).distance_squared_to(cp_flat)

		var frac: = 1.0
		if d2 > near2:
			frac = clampf(1.0 - (sqrt(d2) - lod_near) / span, 0.0, 1.0)
		c.set_visible_fraction(frac)
		if shad:
			var mode: = (GeometryInstance3D.SHADOW_CASTING_SETTING_ON if d2 <= sd2
				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
			if c.cast_shadow != mode:
				c.cast_shadow = mode


func _clear() -> void :
	for c in _chunks:
		if is_instance_valid(c):
			c.queue_free()
	_chunks.clear()
	_total = 0


func stats() -> Dictionary:
	var tris: = 0
	for c in _chunks:
		tris += c.triangle_count()
	return {
		"chunks": _chunks.size(), 
		"instances": _total, 
		"triangles": tris, 
		"draw_calls": _chunks.size(), 
	}



func _push_look(mat: ShaderMaterial) -> void :
	mat.set_shader_parameter("wind_direction", wind_direction)
	mat.set_shader_parameter("wind_strength", wind_strength)
	mat.set_shader_parameter("wind_speed", wind_speed)
	mat.set_shader_parameter("large_wave_scale", large_wave_scale)
	mat.set_shader_parameter("small_wave_scale", small_wave_scale)
	mat.set_shader_parameter("flutter_strength", flutter_strength)
	mat.set_shader_parameter("bend_curve", bend_curve)
	mat.set_shader_parameter("wind_shade", wind_shade)
	mat.set_shader_parameter("topdown_flatten", topdown_flatten)
	mat.set_shader_parameter("wake_flatten", wake_flatten)
	mat.set_shader_parameter("wake_bend", wake_bend)
	mat.set_shader_parameter("freeze_wind", 1.0 if debug_freeze_wind else 0.0)
	mat.set_shader_parameter("tuft_blades", tuft_blades)
	mat.set_shader_parameter("blade_thickness", blade_thickness)
	mat.set_shader_parameter("tip_narrow", tip_narrow)
	mat.set_shader_parameter("grass_tex", ground_texture)
	mat.set_shader_parameter("use_tex", ground_texture != null)
	mat.set_shader_parameter("tex_scale", ground_tex_scale)
	mat.set_shader_parameter("base_tint", base_tint)
	mat.set_shader_parameter("brightness", brightness)
	mat.set_shader_parameter("root_shade", root_shade)
	mat.set_shader_parameter("tip_color", tip_color)
	mat.set_shader_parameter("tip_amount", tip_amount)
	mat.set_shader_parameter("color_variation", color_variation)
	mat.set_shader_parameter("patch_color", patch_color)
	mat.set_shader_parameter("patch_scale", patch_scale)
	mat.set_shader_parameter("patch_strength", patch_strength)
	mat.set_shader_parameter("grad_bottom", grad_bottom)
	mat.set_shader_parameter("grad_top", grad_top)
	mat.set_shader_parameter("grad_strength", grad_strength)



func _set_regenerate(_v: bool) -> void :
	regenerate = false
	if is_inside_tree():
		_rebuild()

func _set_disable(v: bool) -> void :
	debug_disable = v
	if is_inside_tree():
		_rebuild()
