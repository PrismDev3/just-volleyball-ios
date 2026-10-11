class_name StageMorph






const MORPH_SHADER: = preload("res://game/court/stage_morph.gdshader")
const BAND: = 6.0



static func play(host: Node, old_roots: Array, new_roots: Array, 
		dir: Vector3, dur: = 1.0) -> void :
	dir = dir.normalized()
	var mats: Array[ShaderMaterial] = []
	var restore: = []
	var lo: = INF
	var hi: = - INF
	for root in old_roots:
		for mi in _meshes(root):
			var m: = _apply(mi, _base_color(mi), 1.0, dir)
			mats.append(m)
			var e: = _extent(mi, dir)
			lo = minf(lo, e.x);hi = maxf(hi, e.y)
	for root in new_roots:
		for mi in _meshes(root):
			restore.append([mi, mi.material_override])
			var m: = _apply(mi, _base_color(mi), -1.0, dir)
			mats.append(m)
			var e: = _extent(mi, dir)
			lo = minf(lo, e.x);hi = maxf(hi, e.y)
	if mats.is_empty():
		return
	var start: = lo - BAND
	var stop: = hi + BAND
	for m in mats:
		m.set_shader_parameter("wave", start)
	var tw: = host.create_tween()
	tw.tween_method( func(w: float):
		for m in mats:
			m.set_shader_parameter("wave", w), start, stop, dur)
	await tw.finished
	for root in old_roots:
		if is_instance_valid(root):
			root.queue_free()
	for pair in restore:
		var mi: MeshInstance3D = pair[0]
		if is_instance_valid(mi):
			mi.material_override = pair[1]

static func _apply(mi: MeshInstance3D, base: Color, mode: float, 
		dir: Vector3) -> ShaderMaterial:
	var m: = ShaderMaterial.new()
	m.shader = MORPH_SHADER
	m.set_shader_parameter("base_color", base)
	m.set_shader_parameter("mode", mode)
	m.set_shader_parameter("dir", dir)
	m.set_shader_parameter("band", BAND)
	mi.material_override = m
	return m

static func _meshes(root: Node) -> Array:
	var out: = []
	if root is MeshInstance3D:
		out.append(root)
	for n in root.find_children("*", "MeshInstance3D", true, false):
		out.append(n)
	return out



static func _base_color(mi: MeshInstance3D) -> Color:
	var m: = mi.get_active_material(0)
	if m is StandardMaterial3D:
		return (m as StandardMaterial3D).albedo_color
	if m is ShaderMaterial:
		for key in ["albedo", "base_color", "tint"]:
			var v: Variant = (m as ShaderMaterial).get_shader_parameter(key)
			if v is Color:
				return v
	return Color(0.4, 0.72, 1.0)


static func _extent(mi: MeshInstance3D, dir: Vector3) -> Vector2:
	if mi.mesh == null:
		return Vector2(INF, - INF)
	var aabb: = mi.global_transform * mi.mesh.get_aabb()
	var lo: = INF
	var hi: = - INF
	for i in 8:
		var c: = aabb.get_endpoint(i)
		var d: = c.dot(dir)
		lo = minf(lo, d);hi = maxf(hi, d)
	return Vector2(lo, hi)
