@tool
class_name NationalsCourtside
extends Node3D




const DEFAULT_HALF_W: = 4.5
const DEFAULT_HALF_L: = 9.0
const BENCH_DEPTH: = 0.82
const BENCH_CLEARANCE: = 1.8
const STAND_DEPTH: = 0.85
const STAND_OFFSET: = 0.9

func _ready() -> void :
	if Engine.is_editor_hint() and get_child_count() == 0:
		_build(DEFAULT_HALF_W, DEFAULT_HALF_L)

func configure(half_w: float, half_l: float) -> void :
	for child in get_children():
		child.queue_free()
	_build(half_w, half_l)

func _build(half_w: float, half_l: float) -> void :
	var seat_mat: = GymDressing.prototype_material("grey", Color(0.72, 0.76, 0.82))
	var frame_mat: = GymDressing.prototype_material("black", Color(0.15, 0.17, 0.22))
	var table_mat: = GymDressing.prototype_material("blue", Color(0.28, 0.42, 0.82))



	var bench_x: = half_w + NationalsPerimeter.GAP + BENCH_DEPTH * 0.5\
	+ BENCH_CLEARANCE


	for side in [-1.0, 1.0]:
		_add_box(Vector3(side * bench_x, 0.55, 0.0), 
			Vector3(BENCH_DEPTH, 0.16, maxf(4.0, half_l * 0.56)), seat_mat, true)
		for z in [-1.7, 1.7]:
			_add_box(Vector3(side * bench_x, 0.28, z), 
				Vector3(0.66, 0.42, 0.16), frame_mat, true)

	var table_z: = - (half_l + NationalsPerimeter.GAP + 1.6)
	_add_box(Vector3(0.0, 0.72, table_z), Vector3(4.0, 0.16, 0.82), table_mat)
	_add_box(Vector3(-1.45, 0.35, table_z), Vector3(0.16, 0.7, 0.66), frame_mat)
	_add_box(Vector3(1.45, 0.35, table_z), Vector3(0.16, 0.7, 0.66), frame_mat)
	_add_referee_stand(half_w, frame_mat, seat_mat)
	_add_line_judge_spots(half_w, half_l, seat_mat)

func _add_referee_stand(half_w: float, frame_mat: Material, 
		seat_mat: Material) -> void :




	var stand_x: = - (half_w + STAND_OFFSET)
	_add_box(Vector3(stand_x, 1.72, 0.0), Vector3(0.9, 0.14, 0.85), 
		seat_mat, true)
	for z in [-0.3, 0.3]:
		_add_box(Vector3(stand_x, 0.82, z), Vector3(0.16, 1.65, 0.16), 
			frame_mat, true)


	var ladder_x: = stand_x - 0.42
	for z in [-0.28, 0.0, 0.28]:
		_add_box(Vector3(ladder_x, 0.55 + z * 0.15, 0.0), 
			Vector3(0.08, 0.08, 0.52), frame_mat, true)

func _add_line_judge_spots(half_w: float, half_l: float, 
		seat_mat: Material) -> void :


	var x: = half_w + NationalsPerimeter.GAP + 0.9
	var z: = half_l + NationalsPerimeter.GAP + 0.9
	for side in [-1.0, 1.0]:
		for end in [-1.0, 1.0]:
			_add_box(Vector3(side * x, 0.035, end * z), 
				Vector3(0.55, 0.07, 0.55), seat_mat)

func _add_box(at: Vector3, size: Vector3, material: Material, 
		collide: bool = false) -> void :
	var mesh: = BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var item: = MeshInstance3D.new()
	item.mesh = mesh
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if not collide:
		item.position = at
		add_child(item)
		return
	var body: = StaticBody3D.new()
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 1
	var shape: = CollisionShape3D.new()
	var box: = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	item.position = Vector3.ZERO
	body.add_child(item)
	add_child(body)
