class_name LandingCall
extends RefCounted







const PILL_SHADER: = preload("res://game/fx/landing_pill.gdshader")
const DISC_SHADER: = preload("res://game/fx/landing_disc.gdshader")
const PILL_W: = 1.5
const PILL_H: = 0.66
const TEXT_COL: = Color(0.13, 0.14, 0.18)



static func short(text: String) -> String:
	return text.trim_prefix("ball ").strip_edges()



const PILL_END_PAD: = 0.78
const PILL_MIN_W: = 1.05





static func apply(marker: Node3D, label: Label3D, text: String, accent: Color) -> void :
	if marker == null:
		return
	var short_text: = short(text)
	var disc: = marker.get_node_or_null("Disc") as MeshInstance3D
	if disc != null and disc.material_override is ShaderMaterial:
		(disc.material_override as ShaderMaterial).set_shader_parameter("col", accent)
	if label != null:
		label.text = short_text


	var pill: = marker.get_node_or_null("Pill") as MeshInstance3D
	if pill != null:
		var w: = PILL_W
		if label != null and label.font != null:
			var px: = label.font.get_string_size(short_text, 
				HORIZONTAL_ALIGNMENT_CENTER, -1.0, label.font_size).x
			w = maxf(PILL_MIN_W, px * label.pixel_size + PILL_END_PAD)
		if pill.mesh is QuadMesh:
			(pill.mesh as QuadMesh).size = Vector2(w, PILL_H)
		if pill.material_override is ShaderMaterial:
			var mat: = pill.material_override as ShaderMaterial
			mat.set_shader_parameter("aspect", w / PILL_H)


			mat.set_shader_parameter("border", Color(accent.r, accent.g, accent.b, 0.85))

static func dress(marker: Node3D, label: Label3D, disc_col: = Color(0.95, 0.25, 0.2)) -> void :
	if marker == null:
		return

	var disc: = marker.get_node_or_null("Disc") as MeshInstance3D
	if disc != null:
		var pm: = PlaneMesh.new()
		pm.size = Vector2(1.2, 1.2)
		disc.mesh = pm
		disc.position.y = 0.0
		var dm: = ShaderMaterial.new()
		dm.shader = DISC_SHADER
		dm.set_shader_parameter("col", disc_col)
		disc.material_override = dm


	if marker.get_node_or_null("Pill") == null:
		var pill: = MeshInstance3D.new()
		pill.name = "Pill"
		var q: = QuadMesh.new()
		q.size = Vector2(PILL_W, PILL_H)
		pill.mesh = q
		var mat: = ShaderMaterial.new()
		mat.shader = PILL_SHADER
		mat.set_shader_parameter("aspect", PILL_W / PILL_H)
		mat.render_priority = 1
		pill.material_override = mat
		if label != null:
			pill.position = label.position
		marker.add_child(pill)






	if label != null:
		label.font = UiStyle.font(UiStyle.FONT_BLACK)
		label.modulate = TEXT_COL
		label.outline_modulate = TEXT_COL
		label.outline_size = 4
		label.font_size = 64
		label.no_depth_test = true
		label.render_priority = 3
		label.outline_render_priority = 2
