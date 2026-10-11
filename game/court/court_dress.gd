class_name CourtDress








const FLOOR_SHADER: = preload("res://game/court/floor_sweat.gdshader")



static func unique_net(net: MeshInstance3D, scale_x: float) -> void :
	net.mesh = net.mesh.duplicate(true)
	((net.mesh as PlaneMesh).material as ShaderMaterial)\
	.set_shader_parameter("grid", Vector2(46.0 * scale_x, 7.0))



static func unique_floor(court: Node3D) -> ShaderMaterial:
	var floor_mesh: MeshInstance3D = court.get_node("CourtFloor")
	floor_mesh.mesh = floor_mesh.mesh.duplicate(true)
	var mat: = ShaderMaterial.new()
	mat.shader = FLOOR_SHADER
	(floor_mesh.mesh as BoxMesh).material = mat
	return mat





static func tessellate_floor(court: Node3D, n: int) -> void :
	if n <= 0:
		return
	var floor_mesh: MeshInstance3D = court.get_node("CourtFloor")
	var bm: = floor_mesh.mesh as BoxMesh
	if bm == null:
		return
	bm.subdivide_width = n
	bm.subdivide_depth = n



static func wire_reflection(mat: ShaderMaterial, tex: Texture2D) -> void :
	mat.set_shader_parameter("reflect_tex", tex)
	mat.set_shader_parameter("reflect_on", true)
	mat.set_shader_parameter("reflectivity", 0.42)
