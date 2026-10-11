@tool
class_name GrassChunk
extends MultiMeshInstance3D













func populate(clump: Mesh, material: Material, transforms: Array, 
		customs: Array, bounds: AABB, far: float, fade_margin: float) -> void :
	var mm: = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = clump
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_custom_data(i, customs[i])
	multimesh = mm
	_full = transforms.size()
	_tris_per = _mesh_tris(clump)
	material_override = material



	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


	custom_aabb = bounds


	visibility_range_end = far
	visibility_range_end_margin = fade_margin
	visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF

var _full: = 0
var _tris_per: = 0





func set_visible_fraction(frac: float) -> void :
	if multimesh == null:
		return
	multimesh.visible_instance_count = clampi(int(_full * clampf(frac, 0.0, 1.0)), 0, _full)

func chunk_center() -> Vector3:
	return global_position + custom_aabb.position + custom_aabb.size * 0.5

func instance_count() -> int:
	return _full



func triangle_count() -> int:
	return _tris_per * _full

static func _mesh_tris(m: Mesh) -> int:
	var tris: = 0
	for s in m.get_surface_count():
		var arr: = m.surface_get_arrays(s)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		if idx.size() > 0:
			tris += idx.size() / 3
		else:
			tris += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return tris
