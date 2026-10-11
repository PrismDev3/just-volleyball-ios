class_name Stage
extends RefCounted



















const SUNSET_SKY: = preload("res://game/court/anime_sky_sunset.gdshader")



const SHIELD_BLUE: = Color(0.25, 0.6, 1.0)

const STAGES: = {
	"nationals": {
		"reverb": {"room": 0.9, "damp": 0.5, "wet": 0.19, "predelay": 35.0, "hipass": 0.2}, 
		"title": "Nationals Arena", 





		"venue": "res://game/stage/kits/nationals.tscn", 
		"bloom": true, 

		"pool_strength": 0.85, 
		"floor_vignette": 0.3, 
		"collision_box": Vector3(18, 14, 26), 

		"force_wall": true, 
		"force_wall_color": SHIELD_BLUE, 

		"crowd": false, 

		"fog": true, 
		"fog_color": Color(0.02, 0.03, 0.05), 
		"fog_begin": 40.0, 
		"fog_end": 95.0, 
		"pad": Color(0.2, 0.36, 0.82), 
		"pole": Color(0.78, 0.8, 0.85), 
		"tape": Color(0.97, 0.97, 0.95), 
		"cord": Color(0.0, 0.0, 0.0), 
		"lines": Color(0.95, 0.95, 0.95), 
		"floor_color": Color(0.9, 0.47, 0.17), 
		"barefoot": false, 
		"ball": "res://game/ball/models/national_ball.blend", 
		"ball_tex": "res://game/ball/textures/nationaldif_SD.png", 
	}, 
	"school": {
		"reverb": {"room": 0.72, "damp": 0.58, "wet": 0.15, "predelay": 20.0, "hipass": 0.15}, 
		"title": "School Gym", 
		"beta_hidden": true, 



		"venue": "res://game/stage/kits/school.tscn", 




		"look": "res://game/stage/school_look.tres", 


		"owns_floor": true, 
		"collision_box": Vector3(18, 14, 26), 
		"force_wall": true, 
		"force_wall_color": SHIELD_BLUE, 




		"fog": true, 


		"fog_color": Color(0.62, 0.61, 0.6), 
		"fog_begin": 30.0, 
		"fog_end": 110.0, 
		"fog_height": 14.5, 
		"fog_height_density": 0.4, 

		"crowd": true, 
		"crowd_lift": 0.1, 


		"crowd_tint": Color(1, 1, 1), 
		"crowd_haze": 0.0, 
		"crowd_shade": {"desat": 0.08, "contrast": 1.0, "depth_dim": 0.18, "depth_hi": 24.0}, 
		"accent_pads": true, 


		"mirror_overlay": true, 
		"pool_strength": 0.7, 
		"floor_vignette": 0.3, 
		"pad": Color(0.72, 0.15, 0.14), 
		"pole": Color(0.4, 0.36, 0.38), 
		"tape": Color(0.97, 0.97, 0.95), 
		"cord": Color(0.0, 0.0, 0.0), 
		"lines": Color(0.97, 0.97, 0.95), 
		"floor_color": Color(0.74, 0.54, 0.32), 
		"barefoot": false, 
		"ball": "res://game/ball/models/jv_ball.blend", 
		"ball_tex": "res://game/ball/textures/jvball_diff_SD.png", 
	}, 





	"practice": {
		"base": "school", 
		"variant": true, 



		"quick": true, 
		"title": "School Gym (practice)", 
		"force": {
			"casual": true, 
			"crowd": false, 
			"scrimmage_pinny": true, 
		}, 
	}, 




	"clouds": {
		"title": "Clouds", 
		"bonus": true, 
		"venue": "res://game/stage/kits/clouds.tscn", 
		"owns_floor": true, 
		"mirror_overlay": true, 
		"sky_mirror": true, 
		"collision_box": Vector3(18, 14, 26), 
		"force_wall": true, 
		"force_wall_color": SHIELD_BLUE, 
		"anime_sky": true, 
		"sun": 1.1, 
		"reflect": true, 
		"crowd": false, 
		"casual": false, 
		"barefoot": false, 
		"surface": "court", 
		"water_x": -1000000000.0, 
		"water_side": 1.0, 



		"fog": false, 
		"pool_strength": 0.0, 
		"floor_vignette": 0.0, 
		"pad": Color(0.97, 0.97, 0.99), 
		"pole": Color(0.9, 0.93, 0.98), 
		"tape": Color(0.97, 0.97, 0.95), 
		"cord": Color(0.12, 0.14, 0.2), 
		"lines": Color(1.0, 1.0, 1.0), 
		"floor_color": Color(0.6, 0.75, 0.95), 
		"ball": "res://game/ball/models/outdoorball.blend", 
		"ball_tex": "res://game/ball/textures/outdoor_dif_SD.png", 
	}, 







	"void": {
		"title": "Training Space", 
		"hidden": true, 
		"venue": "res://game/stage/kits/void.tscn", 
		"use_sky_color": true, 
		"sky_color": Color(0.975, 0.975, 0.98), 
		"fog": true, 
		"fog_color": Color(0.975, 0.975, 0.98), 
		"fog_begin": 34.0, 
		"fog_end": 120.0, 
		"reflect": false, 
		"crowd": false, 
		"casual": true, 
		"barefoot": false, 
		"surface": "court", 
		"collision_box": Vector3(22, 14, 30), 
		"force_wall": false, 
		"pool_strength": 0.0, 
		"floor_vignette": 0.0, 
		"floor_color": Color(0.6, 0.61, 0.63), 
		"checker_size": 1.0, 
		"checker_color": Color(0.7, 0.71, 0.73), 
		"lines": Color(1.0, 1.0, 1.0), 
		"pad": Color(0.93, 0.93, 0.94), 
		"pole": Color(0.9, 0.9, 0.92), 
		"tape": Color(0.96, 0.96, 0.96), 
		"cord": Color(0.35, 0.36, 0.4), 
	}, 
	"training": {
		"reverb": {"room": 0.85, "damp": 0.55, "wet": 0.16, "predelay": 30.0, "hipass": 0.15}, 
		"title": "Training Centre", 
		"hidden": true, 
		"venue": "res://game/stage/kits/training.tscn", 
		"crowd": false, 
		"pad": Color(0.12, 0.56, 0.52), 
		"pole": Color(0.86, 0.87, 0.9), 
		"tape": Color(0.97, 0.97, 0.95), 
		"cord": Color(0.05, 0.05, 0.08), 
		"lines": Color(0.97, 0.97, 0.95), 
		"floor_color": Color(0.2, 0.34, 0.6), 
		"ball": "res://game/ball/models/national_ball.blend", 
		"ball_tex": "res://game/ball/textures/nationaldif_SD.png", 
	}, 
	"beach": {
		"title": "Beach", 

		"venue": "res://game/stage/kits/beach.tscn", 
		"owns_floor": true, 
		"collision_box": Vector3(20, 14, 28), 
		"force_wall": true, 
		"force_wall_color": SHIELD_BLUE, 
		"fog": true, 
		"fog_color": Color(0.72, 0.82, 0.92), 
		"fog_begin": 42.0, 
		"fog_end": 120.0, 
		"anime_sky": true, 
		"sky": Color(0.5, 0.74, 0.95), 
		"sun": 1.25, 
		"reflect": false, 
		"surface": "sand", 


		"water_x": 13.0, 





		"sand_grade": true, 
		"sand_grade_near": Color(1.22, 1.02, 0.62), 
		"sand_grade_far": Color(0.58, 0.48, 0.36), 
		"sand_grade_dir": Vector2(1.0, 0.0), 
		"sand_grade_from": -26.0, 
		"sand_grade_to": 14.0, 
		"crowd": false, 
		"barefoot": true, 
		"casual": true, 
		"pad": Color(0.2, 0.4, 0.85), 
		"pole": Color(0.85, 0.85, 0.82), 
		"tape": Color(0.22, 0.42, 0.85), 
		"cord": Color(0.05, 0.05, 0.08), 
		"lines": Color(0.2, 0.4, 0.85), 
		"floor_color": Color(0.92, 0.85, 0.68), 
		"ball": "res://game/ball/models/outdoorball.blend", 
		"ball_tex": "res://game/ball/textures/outdoor_dif_SD.png", 
	}, 
	"grass": {
		"title": "Grass Court", 

		"venue": "res://game/stage/kits/grass.tscn", 
		"owns_floor": true, 
		"collision_box": Vector3(20, 14, 28), 
		"force_wall": true, 
		"force_wall_color": SHIELD_BLUE, 
		"fog": true, 
		"fog_color": Color(0.6, 0.75, 0.9), 
		"fog_begin": 42.0, 
		"fog_end": 120.0, 
		"anime_sky": true, 
		"sky": Color(0.55, 0.76, 0.95), 
		"sun": 1.2, 
		"reflect": false, 
		"surface": "grass", 
		"crowd": false, 
		"barefoot": false, 
		"casual": true, 
		"pad": Color(0.82, 0.16, 0.15), 
		"pole": Color(0.82, 0.16, 0.15), 
		"tape": Color(0.96, 0.96, 0.93), 
		"cord": Color(0.05, 0.05, 0.08), 
		"lines": Color(0.22, 0.42, 0.85), 
		"floor_color": Color(0.3, 0.5, 0.26), 
		"ball": "res://game/ball/models/outdoorball.blend", 
		"ball_tex": "res://game/ball/textures/outdoor_dif_SD.png", 
	}, 



}




static func ids(with_variants: = true) -> Array:
	var out: = []
	var beta: = LaunchGate.public_beta()
	for id in STAGES:
		if bool(STAGES[id].get("hidden", false)):
			continue
		if beta and bool(STAGES[id].get("beta_hidden", false)):
			continue
		if with_variants or not bool(STAGES[id].get("variant", false)):
			out.append(id)
	return out

static func info(id: String) -> Dictionary:
	var d: Dictionary = STAGES.get(id, STAGES["nationals"])
	if d.has("base") and STAGES.has(d["base"]):

		var merged: Dictionary = STAGES[d["base"]].duplicate()
		merged.merge(d, true)
		return merged
	return d

static func title(id: String) -> String:
	return String(info(id).get("title", id))











const REVERB_BUSES: = {"sfx": 1.0, "voice": 0.9, "crowd": 0.55}

static func apply_reverb(id: String) -> void :
	var rv: Dictionary = val(id, "reverb", {})
	for bus_name in REVERB_BUSES:
		var bi: = AudioServer.get_bus_index(bus_name)
		if bi == -1:
			continue
		var fx: AudioEffectReverb = null
		var at: = -1
		for i in AudioServer.get_bus_effect_count(bi):
			var e: = AudioServer.get_bus_effect(bi, i)
			if e is AudioEffectReverb:
				fx = e
				at = i
				break
		if rv.is_empty():
			if fx != null:
				AudioServer.set_bus_effect_enabled(bi, at, false)
			continue
		if fx == null:
			fx = AudioEffectReverb.new()
			AudioServer.add_bus_effect(bi, fx)
			at = AudioServer.get_bus_effect_count(bi) - 1
		var scale: float = REVERB_BUSES[bus_name]
		fx.room_size = float(rv.get("room", 0.8))
		fx.damping = float(rv.get("damp", 0.5))
		fx.wet = float(rv.get("wet", 0.2)) * scale
		fx.dry = 1.0
		fx.predelay_msec = float(rv.get("predelay", 25.0))
		fx.predelay_feedback = 0.3
		fx.hipass = float(rv.get("hipass", 0.15))
		fx.spread = 1.0
		AudioServer.set_bus_effect_enabled(bi, at, true)

static func has_crowd(id: String) -> bool:
	return bool(val(id, "crowd", true))






static func config(id: String, fresh: = false) -> Resource:
	var path: = String(info(id).get("look", ""))
	if path == "" or not ResourceLoader.exists(path):
		return null
	if fresh:
		return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
	return load(path)







static func val(id: String, key: String, default: Variant) -> Variant:


	var forced: Dictionary = info(id).get("force", {})
	if forced.has(key):
		return forced[key]
	var c: = config(id)
	if c != null:
		var v: Variant = c.get(key)
		if v != null:
			return v
	return info(id).get(key, default)






const THUMB_DIR: = "res://game/stages/thumbs"

static func thumb_path(id: String) -> String:
	return String(val(id, "thumb", "%s/%s.png" % [THUMB_DIR, id]))

static func thumb(id: String) -> Texture2D:
	var path: = thumb_path(id)
	if path == "" or not ResourceLoader.exists(path):
		return null
	var res: = load(path)
	return res if res is Texture2D else null



static func kind(id: String) -> String:
	var k: = String(val(id, "kind", ""))
	if k != "":
		return k
	if bool(val(id, "anime_sky", false)) or val(id, "sun", null) != null:
		return "outdoor"
	return "indoor"

static func random_id() -> String:



	var pool: = ids(false)
	var beta: = LaunchGate.public_beta()
	for id in STAGES:
		if id in pool or not bool(STAGES[id].get("quick", false)):
			continue
		if bool(STAGES[id].get("hidden", false)):
			continue
		if beta and bool(STAGES[id].get("beta_hidden", false)):
			continue
		pool.append(id)
	return pool[randi() % pool.size()]



static func ball_model(id: String) -> String:
	return String(info(id).get("ball", ""))





static func ball_texture(id: String) -> String:
	return String(info(id).get("ball_tex", ""))







static func tint_court_lines(court: Node3D, color: Color) -> void :
	_tint(court, ["SideLineWest", "SideLineEast", "EndLineNorth", 
		"EndLineSouth", "CenterLine"], color)











static func apply_school_accent(painted: Dictionary, court: Node3D, id: String, 
		accent: Color, tape: Variant = null, wall_base: = {}) -> void :
	for mname in val(id, "accent_mats", []):
		for mat in painted.get(mname, []):
			(mat as ShaderMaterial).set_shader_parameter("albedo", accent)
	if tape != null:
		tint_court_lines(court, tape)



	if court != null and bool(val(id, "accent_pads", false)):
		_tint_gradient(court, ["PostWestPad", "PostEastPad"], accent)
	var wash: float = val(id, "wall_wash", 0.11)
	for mname in val(id, "wall_mats", []):
		for mat in painted.get(mname, []):
			var sm: = mat as ShaderMaterial
			if not wall_base.has(sm):
				wall_base[sm] = sm.get_shader_parameter("albedo")
			sm.set_shader_parameter("albedo", 
				(wall_base[sm] as Color).lerp(accent, wash))

static func dress_court(court: Node3D, id: String) -> void :
	var s: = info(id)


	for n in court.find_children("*Ink", "MeshInstance3D", true, false):


		var nm: = String(n.name)
		var parent_nm: = String(n.get_parent().name) if n.get_parent() != null else ""
		(n as MeshInstance3D).visible = nm == "NetBandInk" or nm == "NetBandBottomInk" or (nm == "Ink" and parent_nm.begins_with("Antenna"))



	var old_marks: = court.get_node_or_null("NationalsMarkings")
	if old_marks != null:
		court.remove_child(old_marks)
		old_marks.queue_free()
	if id == "nationals":
		_add_nationals_markings(court, val(id, "lines", s.lines))


	_tint_gradient(court, ["PostWest", "PostEast"], val(id, "pole", s.pole), 0.18)
	_tint_gradient(court, ["PostWestPad", "PostEastPad"], val(id, "pad", s.pad), 0.04)




	_tint(court, ["SideLineWest", "SideLineEast", "EndLineNorth", 
		"EndLineSouth", "CenterLine"], val(id, "lines", s.lines))
	var tape_col: Color = val(id, "tape", s.tape)
	_tint(court, ["NetBand", "NetBandBottom"], tape_col)

	_tint(court, ["CordTopWest", "CordBottomWest", "CordTopEast", "CordBottomEast"], 
		val(id, "cord", s.cord))
	var net: = court.get_node_or_null("Net") as MeshInstance3D
	if net != null:



		net.mesh = net.mesh.duplicate(true)
		var mat: = (net.mesh as PlaneMesh).material as ShaderMaterial
		mat.set_shader_parameter("tape_color", tape_col)
		mat.set_shader_parameter("cord_color", val(id, "cord", s.cord))

static func _add_nationals_markings(court: Node3D, color: Color) -> void :



	var mat: = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.75


	const mark_y: = 0.006
	const mark_thickness: = 0.012
	var st: = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)


	for z: float in [-3.0, 3.0]:
		_mark_box(st, Vector3(0.0, mark_y, z), 
			Vector3(9.0, mark_thickness, 0.055))


		for side_x: float in [-1.0, 1.0]:
			for dash in 4:
				var x: float = side_x * (4.72 + float(dash) * 0.38)
				_mark_box(st, Vector3(x, mark_y, z), 
					Vector3(0.22, mark_thickness, 0.055))

	for end_z: float in [-1.0, 1.0]:
		for side_x: float in [-1.0, 1.0]:
			for dash in 4:
				var z: float = end_z * (9.22 + float(dash) * 0.38)
				_mark_box(st, Vector3(side_x * 4.5, mark_y, z), 
					Vector3(0.055, mark_thickness, 0.22))
	var mesh: = st.commit()
	mesh.surface_set_material(0, mat)
	var marks: = MeshInstance3D.new()
	marks.name = "NationalsMarkings"
	marks.mesh = mesh
	marks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	court.add_child(marks)

static func _mark_box(st: SurfaceTool, at: Vector3, size: Vector3) -> void :
	var box: = BoxMesh.new()
	box.size = size
	st.append_from(box, 0, Transform3D(Basis.IDENTITY, at))

const NET_GRADIENT: = preload("res://game/court/net_gradient.gdshader")






static func _tint_gradient(court: Node3D, names: Array, color: Color, shine: = 0.6) -> void :
	for n in names:
		var mi: = court.get_node_or_null(n) as MeshInstance3D
		if mi == null:
			continue
		var m: = ShaderMaterial.new()
		m.shader = NET_GRADIENT
		m.set_shader_parameter("base_color", color)
		m.set_shader_parameter("shine", shine)
		m.set_shader_parameter("rim_dark", 0.35 if shine > 0.3 else 0.22)
		mi.material_override = m

static func _tint(court: Node3D, names: Array, color: Color) -> void :



	var dups: = {}
	for n in names:
		var mi: = court.get_node_or_null(n) as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		if not dups.has(mi.mesh):
			var d: Mesh = mi.mesh.duplicate(true)
			var m: Material = (d as PrimitiveMesh).material\
			if d is PrimitiveMesh else d.surface_get_material(0)
			if m is StandardMaterial3D:
				(m as StandardMaterial3D).albedo_color = color
			dups[mi.mesh] = d
		mi.mesh = dups[mi.mesh]
