class_name SandDeform
extends Node


















static var decal_y: = 0.0



static var decal_y_feet: = 0.0



static func feet_y() -> float:
	return decal_y_feet if decal_y_feet > 0.0 else decal_y



const SIZE: = 1024





const STEP_MIN_MOVE: = 0.36





const FOOT_RADIUS: = 0.14
const FOOT_DEPTH: = 0.28
const DIVE_RADIUS: = 0.55
const DIVE_DEPTH: = 0.7
const BALL_RADIUS: = 0.42
const BALL_DEPTH: = 0.9

var area: = 24.0
var center: = Vector2.ZERO



var bodies_provider: = Callable()
var ball_provider: = Callable()



const BALL_CONTACT_H: = 0.28

var _vp: SubViewport
var _canvas: Node2D
var _brush: Texture2D
var _pending: Array = []
var _last_pos: = {}
var _clear_frames: = 0
var _prev_ball_y: = 1000000000.0

func setup(court_area: float, world_center: = Vector2.ZERO) -> void :
	area = maxf(court_area, 1.0)
	center = world_center
	_brush = _make_brush()
	_vp = SubViewport.new()
	_vp.size = Vector2i(SIZE, SIZE)
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.msaa_2d = Viewport.MSAA_DISABLED
	add_child(_vp)


	_canvas = Node2D.new()
	var cm: = CanvasItemMaterial.new()
	cm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_canvas.material = cm
	_canvas.draw.connect(_draw_canvas)
	_vp.add_child(_canvas)
	reset()

func texture() -> Texture2D:
	return _vp.get_texture()









static func build(parent: Node, id: String, shell: Node, court: Node, half_w: float, half_l: float, 
		bodies_provider: Callable, ball_provider: Callable) -> Dictionary:
	if String(Stage.val(id, "surface", "court")) != "sand":
		return {}



	var env_floor: MeshInstance3D = null
	if shell != null:
		for m in shell.find_children("*", "MeshInstance3D", true, false):
			if String(m.name) == "EnvFloor":
				env_floor = m
				break
	if env_floor == null:
		return {}
	var deform: = SandDeform.new()
	parent.add_child(deform)

	var span: = 2.0 * maxf(half_w, half_l) + 6.0
	var deck_center: = Vector2(env_floor.global_position.x, env_floor.global_position.z)
	deform.setup(span, deck_center)
	deform.bodies_provider = bodies_provider
	deform.ball_provider = ball_provider


	var tess: = int(clampi(int(Stage.val(id, "sand_tess", 200)), 8, 400))
	var pm: = PlaneMesh.new()
	pm.size = Vector2(span, span)
	pm.subdivide_width = tess
	pm.subdivide_depth = tess
	var deck: = MeshInstance3D.new()
	deck.name = "SandDeck"
	deck.mesh = pm
	deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF






	var src: = env_floor.material_override
	var sand_texture: Texture2D = null
	var sand_uv_scale: = 0.22
	if src is StandardMaterial3D and (src as StandardMaterial3D).albedo_texture != null:
		sand_texture = (src as StandardMaterial3D).albedo_texture
		sand_uv_scale = (src as StandardMaterial3D).uv1_scale.x
	elif src is ShaderMaterial:
		var t = (src as ShaderMaterial).get_shader_parameter("albedo_tex")
		if t != null:
			sand_texture = t
		var sc = (src as ShaderMaterial).get_shader_parameter("sand_albedo_scale")
		if sc != null:
			sand_uv_scale = float(sc)


	var env_top: = env_floor.global_position.y
	var env_bm: = env_floor.mesh as BoxMesh
	if env_bm != null:
		env_top += env_bm.size.y * 0.5
	deck.position = Vector3(deck_center.x, env_top + 0.003, deck_center.y)

	var sm: = ShaderMaterial.new()
	sm.shader = CourtDress.FLOOR_SHADER
	if sand_texture != null:
		sm.set_shader_parameter("use_albedo_tex", true)
		sm.set_shader_parameter("albedo_tex", sand_texture)
		sm.set_shader_parameter("sand_albedo_scale", sand_uv_scale)
	sm.set_shader_parameter("reflect_on", false)
	sm.set_shader_parameter("sand_on", true)
	sm.set_shader_parameter("sand_cutout", false)
	sm.set_shader_parameter("sand_tex", deform.texture())
	sm.set_shader_parameter("sand_center", deform.sand_center_xz())
	sm.set_shader_parameter("sand_area", deform.sand_area())
	deck.material_override = sm
	parent.add_child(deck)



	var sme: = ShaderMaterial.new()
	sme.shader = CourtDress.FLOOR_SHADER
	if sand_texture != null:
		sme.set_shader_parameter("use_albedo_tex", true)
		sme.set_shader_parameter("albedo_tex", sand_texture)
		sme.set_shader_parameter("sand_albedo_scale", sand_uv_scale)
	sme.set_shader_parameter("reflect_on", false)
	sme.set_shader_parameter("sand_on", true)
	sme.set_shader_parameter("sand_cutout", true)
	sme.set_shader_parameter("sand_dune_amp", 0.0)
	sme.set_shader_parameter("sand_lift", 0.0)
	sme.set_shader_parameter("sand_tex", deform.texture())
	sme.set_shader_parameter("sand_center", deform.sand_center_xz())
	sme.set_shader_parameter("sand_area", deform.sand_area())
	env_floor.material_override = sme
	paint_look(sm, id)




	if src is ShaderMaterial and bool((src as ShaderMaterial).get_shader_parameter("sand_grade")):
		_copy_grade(src as ShaderMaterial, sm)
		_copy_grade(src as ShaderMaterial, sme)
	else:
		paint_grade(sm, id)
		paint_grade(sme, id)


	decal_y = (env_top + 0.003) + float(Stage.val(id, "sand_lift", 0.05))\
	+ float(Stage.val(id, "sand_dune_amp", 0.035)) + 0.01



	if court != null:
		var line_y: = float(Stage.val(id, "sand_lift", 0.05)) + 0.008
		for lname in ["SideLineWest", "SideLineEast", "EndLineNorth", "EndLineSouth", "CenterLine"]:
			var ln: = court.get_node_or_null(NodePath(lname)) as Node3D
			if ln != null:
				ln.position.y = line_y


		var ns: = court.get_node_or_null(^"NetShadow") as Node3D
		if ns != null:
			ns.position.y = decal_y + 0.006




	return {"deform": deform, "deck": deck, "mat": sm, "surround": sme}



static func paint_look(mat: ShaderMaterial, id: String) -> void :
	if mat == null:
		return
	mat.set_shader_parameter("sand_depth", float(Stage.val(id, "sand_depth", 0.05)))
	mat.set_shader_parameter("sand_relief", float(Stage.val(id, "sand_relief", 1.15)))
	mat.set_shader_parameter("sand_bump", float(Stage.val(id, "sand_bump", 2.0)))

	mat.set_shader_parameter("sand_lift", float(Stage.val(id, "sand_lift", 0.05)))
	mat.set_shader_parameter("sand_dune_amp", float(Stage.val(id, "sand_dune_amp", 0.035)))
	mat.set_shader_parameter("sand_dune_scale", float(Stage.val(id, "sand_dune_scale", 0.5)))




static func paint_grade(mat: ShaderMaterial, id: String) -> void :
	if mat == null:
		return
	mat.set_shader_parameter("sand_grade", bool(Stage.val(id, "sand_grade", false)))
	mat.set_shader_parameter("sand_grade_near", Stage.val(id, "sand_grade_near", Color(1, 1, 1)))
	mat.set_shader_parameter("sand_grade_far", Stage.val(id, "sand_grade_far", Color(1, 1, 1)))
	mat.set_shader_parameter("sand_grade_dir", Stage.val(id, "sand_grade_dir", Vector2(1, 0)))
	mat.set_shader_parameter("sand_grade_from", float(Stage.val(id, "sand_grade_from", -20.0)))
	mat.set_shader_parameter("sand_grade_to", float(Stage.val(id, "sand_grade_to", 20.0)))




static func _copy_grade(src: ShaderMaterial, dst: ShaderMaterial) -> void :
	if src == null or dst == null:
		return
	for p in ["sand_grade", "sand_grade_near", "sand_grade_far", "sand_grade_dir", 
			"sand_grade_from", "sand_grade_to"]:
		dst.set_shader_parameter(p, src.get_shader_parameter(p))


func sand_center_xz() -> Vector2:
	return center

func sand_area() -> float:
	return area



func reset() -> void :



	_clear_frames = 2
	_pending.clear()
	_last_pos.clear()



func _collect_bodies(bodies: Array) -> void :
	for b in bodies:
		if b == null or not is_instance_valid(b):
			continue
		if not (b.has_method("grounded") and b.grounded()):
			continue
		var here: = Vector2(b.global_position.x, b.global_position.z)
		var id: int = b.get_instance_id()





		if not _last_pos.has(id):
			_last_pos[id] = here
			continue
		var last: Vector2 = _last_pos[id]
		var diving: bool = b.has_method("diving") and b.diving()

		if diving:
			_add_stamp(here, DIVE_RADIUS, DIVE_DEPTH)
			_last_pos[id] = here
		elif here.distance_to(last) >= STEP_MIN_MOVE:
			_add_stamp(here, FOOT_RADIUS, FOOT_DEPTH)
			_last_pos[id] = here




func stamp_ball(world_pos: Vector3, strength: = 1.0) -> void :
	var s: = clampf(strength, 0.4, 2.0)
	_add_stamp(Vector2(world_pos.x, world_pos.z), BALL_RADIUS * s, BALL_DEPTH)


func _process(_delta: float) -> void :


	if _clear_frames > 0:
		_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
		_clear_frames -= 1
	elif _vp.render_target_clear_mode != SubViewport.CLEAR_MODE_NEVER:
		_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER

	if bodies_provider.is_valid():
		_collect_bodies(bodies_provider.call())

	if ball_provider.is_valid():
		var b = ball_provider.call()
		if b != null and is_instance_valid(b):
			var by: float = b.global_position.y
			if by <= BALL_CONTACT_H and _prev_ball_y > BALL_CONTACT_H:

				var s: = clampf((_prev_ball_y - by) * 3.0, 0.6, 2.0)
				_add_stamp(Vector2(b.global_position.x, b.global_position.z), BALL_RADIUS * s, BALL_DEPTH)
			_prev_ball_y = by





	if _canvas != null:
		_canvas.queue_redraw()

func _add_stamp(world_xz: Vector2, radius_m: float, depth: float) -> void :
	var px_per_m: = float(SIZE) / area
	var p: = (world_xz - center) * px_per_m + Vector2(SIZE, SIZE) * 0.5
	if p.x < -50.0 or p.y < -50.0 or p.x > SIZE + 50 or p.y > SIZE + 50:
		return
	_pending.append({"p": p, "r": radius_m * px_per_m, "a": depth})

func _draw_canvas() -> void :


	for st in _pending:
		var r: float = st["r"]
		var rect: = Rect2(st["p"] - Vector2(r, r), Vector2(r, r) * 2.0)
		_canvas.draw_texture_rect(_brush, rect, false, Color(1, 1, 1, st["a"]))
	_pending.clear()


func _make_brush() -> Texture2D:
	var g: = Gradient.new()
	g.set_offset(0, 0.0)
	g.set_color(0, Color(1, 1, 1, 1))
	g.add_point(0.55, Color(1, 1, 1, 0.75))
	g.set_offset(g.get_point_count() - 1, 1.0)
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	var t: = GradientTexture2D.new()
	t.gradient = g
	t.width = 96
	t.height = 96
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t
