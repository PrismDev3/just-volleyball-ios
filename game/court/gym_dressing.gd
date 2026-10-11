class_name GymDressing
extends Node3D




static func prototype_material(tex_name: String, tint: = Color.WHITE) -> StandardMaterial3D:



	var mat: = StandardMaterial3D.new()
	mat.albedo_texture = load(
		"res://addons/prototype_textures/textures/%s_texture.png" % tex_name)
	mat.albedo_color = tint
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3(0.25, 0.25, 0.25)
	return mat











@export var enabled: = true

func _ready() -> void :
	if not enabled:
		return
	_build_doors()
	_build_trim_and_scoreboard()
	_build_orientation_markers()



func _build_orientation_markers() -> void :
	for spec in [
		{"tex": "orange", "z": -27.0, "size": Vector3(3.0, 3.0, 3.0)}, 
		{"tex": "purple", "z": 27.0, "size": Vector3(3.0, 1.6, 3.0)}, 
	]:
		var block: = MeshInstance3D.new()
		var mesh: = BoxMesh.new()
		mesh.size = spec.size
		mesh.material = prototype_material(spec.tex)
		block.mesh = mesh
		block.position = Vector3(0.0, spec.size.y * 0.5, spec.z)
		add_child(block)

func _build_doors() -> void :
	var door_mat: = StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.42, 0.44, 0.5)
	var bar_mat: = StandardMaterial3D.new()
	bar_mat.albedo_color = Color(0.75, 0.76, 0.8)
	for z_side in [-1.0, 1.0]:
		for x_off in [-1.15, 1.15]:
			var door: = MeshInstance3D.new()
			var mesh: = BoxMesh.new()
			mesh.size = Vector3(1.1, 2.3, 0.14)
			mesh.material = door_mat
			door.mesh = mesh
			door.position = Vector3(x_off + 6.0 * z_side, 1.15, z_side * 27.8)
			add_child(door)
			var bar: = MeshInstance3D.new()
			var bar_mesh: = BoxMesh.new()
			bar_mesh.size = Vector3(0.8, 0.07, 0.06)
			bar_mesh.material = bar_mat
			bar.mesh = bar_mesh
			bar.position = door.position + Vector3(0, -0.1, - z_side * 0.09)
			add_child(bar)

func _build_trim_and_scoreboard() -> void :


	var board: = MeshInstance3D.new()
	var board_mesh: = BoxMesh.new()
	board_mesh.size = Vector3(4.5, 2.2, 0.25)
	var board_mat: = StandardMaterial3D.new()
	board_mat.albedo_color = Color(0.08, 0.09, 0.12)
	board_mesh.material = board_mat
	board.mesh = board_mesh
	board.position = Vector3(0, 5.8, -27.7)
	add_child(board)
	var glow: = MeshInstance3D.new()
	var glow_mesh: = BoxMesh.new()
	glow_mesh.size = Vector3(4.1, 0.35, 0.05)
	var glow_mat: = StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.albedo_color = Color(0.95, 0.55, 0.25)
	glow_mesh.material = glow_mat
	glow.mesh = glow_mesh
	glow.position = Vector3(0, 6.3, -27.56)
	add_child(glow)
