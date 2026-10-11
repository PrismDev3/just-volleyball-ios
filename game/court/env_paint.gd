class_name EnvPaint









const SHADER: = preload("res://game/court/env_paint.gdshader")

const WALL_WARM: = Color(1.0, 0.94, 0.82)

static func apply(root: Node, emissive_mats: Dictionary = {}) -> Dictionary:
	var by_name: = {}
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi: = node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var src: = mi.get_active_material(s)





			if not (src is StandardMaterial3D):
				var own: = mi.mesh.surface_get_material(s)
				if own != null:
					src = own
			var std: = src as StandardMaterial3D
			var sname: = src.resource_name if src != null else ""
			var sl: = sname.to_lower()



			if emissive_mats.has(sname):
				var em: = StandardMaterial3D.new()
				em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				var ec: Color = emissive_mats[sname]
				em.albedo_color = ec
				em.emission_enabled = true
				em.emission = ec
				em.emission_energy_multiplier = 2.6
				mi.set_surface_override_material(s, em)
				continue





			if sl.begins_with("window"):
				var win: = ShaderMaterial.new()
				win.shader = load("res://game/court/window_glow.gdshader")
				if std != null and std.albedo_texture != null:
					win.set_shader_parameter("win_tex", std.albedo_texture)
					win.set_shader_parameter("use_tex", true)
				else:
					win.set_shader_parameter("use_tex", false)
				mi.set_surface_override_material(s, win)
				continue




			if sl == "glass":
				var gm: = StandardMaterial3D.new()
				gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				gm.albedo_color = Color(0.9, 0.95, 1.0, 0.12)
				mi.set_surface_override_material(s, gm)
				continue



			if sl == "light" or sl == "lamp":
				var lm: = StandardMaterial3D.new()
				lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				lm.albedo_color = Color(1.0, 0.98, 0.9)
				lm.emission_enabled = true
				lm.emission = Color(1.0, 0.97, 0.86)
				lm.emission_energy_multiplier = 2.2
				mi.set_surface_override_material(s, lm)
				continue
			var mat: = ShaderMaterial.new()
			mat.shader = SHADER
			if std != null and std.albedo_texture != null:


				mat.set_shader_parameter("use_tex", true)
				mat.set_shader_parameter("albedo_tex", std.albedo_texture)
				mat.set_shader_parameter("albedo", std.albedo_color)
			else:
				var col: = std.albedo_color if std != null else Color(0.8, 0.8, 0.8)




				col = col * WALL_WARM
				mat.set_shader_parameter("albedo", col)
			mi.set_surface_override_material(s, mat)
			var key: = src.resource_name if src != null else ""
			if key != "":
				by_name.get_or_add(key, []).append(mat)
	return by_name
