extends Node3D














const LOOK: = "res://game/stage/school_look.tres"
const WOOD: = "res://game/stage/school/materials/Wood_Floor.tres"

@export_group("Hall")

@export var hall_center_x: = 21.0
@export var hall_half_w: = 88.0
@export var hall_half_l: = 36.0
@export var wood_repeat: = 3.6
@export var wood_tint: = Color(0.98, 0.95, 0.86)

@export_group("Walls")
@export var wall_upper: = Color(0.97, 0.95, 0.9)
@export var wall_lower: = Color(0.36, 0.45, 0.56)
@export var wall_trim: = Color(0.24, 0.58, 0.62)

@export_group("Flags")
@export var flags: = true
@export var flag_lines_x: Array[float] = [21.0]
@export var flag_y: = 11.5
@export var flag_span: = 66.0
@export var flag_height: = 1.7
@export var flag_count: = 28
@export var flag_seed: = 7




const WALL_KEEP: = ["Gym walls", "Gym doors", "Pillars", "Pillars (side)"]

func _ready() -> void :
	_build_floor()
	_dress_model()
	if flags:
		_hang_flags()



func _build_floor() -> void :
	var floor_root: = Node3D.new()
	floor_root.name = "Floor"
	add_child(floor_root)

	var w: = hall_half_w * 2.0
	var l: = hall_half_l * 2.0
	var st: = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ru: = w / wood_repeat
	var rv: = l / wood_repeat
	var corners: = [Vector3( - hall_half_w, 0, - hall_half_l), Vector3(hall_half_w, 0, - hall_half_l), 
		Vector3(hall_half_w, 0, hall_half_l), Vector3( - hall_half_w, 0, hall_half_l)]
	var uvs: = [Vector2(0, 0), Vector2(ru, 0), Vector2(ru, rv), Vector2(0, rv)]


	for i in [0, 1, 2, 0, 2, 3]:
		st.set_normal(Vector3.UP)
		st.set_uv(uvs[i])
		st.add_vertex(corners[i])
	var wood_mat: Material = load(WOOD)
	if wood_mat is StandardMaterial3D:
		wood_mat = (wood_mat as StandardMaterial3D).duplicate()
		(wood_mat as StandardMaterial3D).albedo_color = wood_tint
	st.set_material(wood_mat)
	var wood: = MeshInstance3D.new()
	wood.name = "Wood"
	wood.mesh = st.commit()

	wood.position = Vector3(hall_center_x, -0.03, 0.0)
	wood.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	floor_root.add_child(wood)
	_paint(floor_root, {})

func _dress_model() -> void :
	for gym in get_children():
		var is_roof: = String(gym.name).begins_with("Roof")
		var is_walls: = String(gym.name) == "Walls"
		if not (is_roof or is_walls):
			continue
		for c in gym.get_children():
			if not (c is Node3D):
				continue
			if is_roof:
				(c as Node3D).visible = String(c.name).begins_with("GymExtraParts")
			else:
				(c as Node3D).visible = false
				if String(c.name).begins_with("Gymnasium"):
					(c as Node3D).visible = true
					for part in c.get_children():
						if part is Node3D:
							(part as Node3D).visible = String(part.name).strip_edges() in WALL_KEEP
		_paint(gym, {"White": wall_upper, "Gray": wall_lower, 
			"Hallway floor": wall_lower, "Blue": wall_trim} if is_walls else {})
		if is_walls:
			_drop_floor_slab(gym)




func _drop_floor_slab(gym: Node) -> void :
	var walls: = gym.find_child("Gym walls", true, false) as MeshInstance3D
	if walls == null:
		return
	for s in walls.mesh.get_surface_count():
		var m: = walls.mesh.surface_get_material(s)
		if m != null and m.resource_name == "Hallway floor":
			var hide: = ShaderMaterial.new()
			var sh: = Shader.new()
			sh.code = "shader_type spatial; render_mode unshaded; void fragment() { discard; }"
			hide.shader = sh
			walls.set_surface_override_material(s, hide)



func _paint(root: Node, colours: Dictionary) -> Dictionary:
	var paint: Variant = load("res://game/court/env_paint.gd")
	var stage: Variant = load("res://game/stage/stage.gd")
	var look: Variant = load(LOOK)
	if paint == null:
		return {}
	var painted: Dictionary = paint.apply(root, 
		stage.val("school", "emissive_mats", {}) if stage != null else {})
	if look != null and look.has_method("apply"):
		look.apply(painted)
	for mname in painted:
		for m in painted[mname]:
			var sm: = m as ShaderMaterial
			if sm == null:
				continue

			sm.set_shader_parameter("focus_dim", 0.0)
			sm.set_shader_parameter("haze_amt", 0.0)
			sm.set_shader_parameter("pool_strength", 0.0)
			sm.set_shader_parameter("floor_vignette", 0.0)


			sm.set_shader_parameter("ambient", 1.0)
			sm.set_shader_parameter("key", 0.35)
			sm.set_shader_parameter("shade_cool", 0.08)
			sm.set_shader_parameter("height_shade", 0.18)
			sm.set_shader_parameter("floor_warm_amt", 0.08)
			sm.set_shader_parameter("saturation", 0.98)
			if colours.has(mname):
				sm.set_shader_parameter("albedo", colours[mname])
	return painted



func _hang_flags() -> void :
	var rng: = RandomNumberGenerator.new()
	rng.seed = flag_seed
	var palette: = [Color(0.85, 0.15, 0.15), Color(0.95, 0.95, 0.95), Color(0.1, 0.3, 0.7), 
		Color(0.95, 0.8, 0.1), Color(0.1, 0.55, 0.3), Color(0.05, 0.05, 0.08), 
		Color(0.95, 0.5, 0.1), Color(0.35, 0.7, 0.95)]
	var w: = 64 * flag_count
	var h: = 64
	var img: = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for f in flag_count:
		var x0: = f * 64 + 6
		var fw: = 52
		var stripes: = 2 + rng.randi_range(0, 1)
		var horizontal: = rng.randf() < 0.5
		var cols: = []
		for s in stripes:
			cols.append(palette[rng.randi_range(0, palette.size() - 1)])
		for y in range(4, h - 4):
			for x in range(x0, x0 + fw):
				var t: = float(x - x0) / float(fw) if not horizontal else float(y - 4) / float(h - 8)
				var idx: = mini(int(t * stripes), stripes - 1)
				img.set_pixel(x, y, cols[idx])
	var tex: = ImageTexture.create_from_image(img)
	var mat: = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.albedo_texture = tex
	var lines: = Node3D.new()
	lines.name = "Flags"
	add_child(lines)
	for x in flag_lines_x:
		var q: = MeshInstance3D.new()
		var mesh: = QuadMesh.new()
		mesh.size = Vector2(flag_span, flag_height)
		q.mesh = mesh
		q.material_override = mat
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		q.rotation.y = PI * 0.5
		q.position = Vector3(x, flag_y, 0.0)
		lines.add_child(q)
