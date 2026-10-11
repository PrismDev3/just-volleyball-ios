@tool
class_name NationalsPerimeter
extends Node3D






const DEFAULT_HALF_W: = 4.5
const DEFAULT_HALF_L: = 9.0



const GAP: = 6.0
const PAD_THICKNESS: = 0.48
const PAD_HEIGHT: = 0.78

func _ready() -> void :
	if get_child_count() > 0:
		return


	if Engine.is_editor_hint():
		_build(DEFAULT_HALF_W, DEFAULT_HALF_L)

func configure(half_w: float, half_l: float) -> void :
	for child in get_children():
		child.queue_free()
	_build(half_w, half_l)

func _build(half_w: float, half_l: float) -> void :
	var mat: = GymDressing.prototype_material("blue", Color(0.42, 0.62, 0.98))
	var collision: = StaticBody3D.new()
	collision.name = "PerimeterCollision"
	collision.collision_layer = 3
	collision.collision_mask = 3
	add_child(collision)


	_add_pad(Vector3( - (half_w + GAP), PAD_HEIGHT * 0.5, 0.0), 
		Vector3(PAD_THICKNESS, PAD_HEIGHT, 
			(half_l + GAP) * 2.0 + PAD_THICKNESS), mat, collision)
	_add_pad(Vector3(half_w + GAP, PAD_HEIGHT * 0.5, 0.0), 
		Vector3(PAD_THICKNESS, PAD_HEIGHT, 
			(half_l + GAP) * 2.0 + PAD_THICKNESS), mat, collision)
	_add_pad(Vector3(0.0, PAD_HEIGHT * 0.5, - (half_l + GAP)), 
		Vector3((half_w + GAP) * 2.0 + PAD_THICKNESS, PAD_HEIGHT, 
			PAD_THICKNESS), mat, collision)
	_add_pad(Vector3(0.0, PAD_HEIGHT * 0.5, half_l + GAP), 
		Vector3((half_w + GAP) * 2.0 + PAD_THICKNESS, PAD_HEIGHT, 
			PAD_THICKNESS), mat, collision)

func _add_pad(at: Vector3, size: Vector3, mat: Material, 
		collision: StaticBody3D) -> void :
	var mesh: = BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	var pad: = MeshInstance3D.new()
	pad.name = "Pad"
	pad.mesh = mesh
	pad.position = at
	pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(pad)
	var shape: = BoxShape3D.new()
	shape.size = size
	var collider: = CollisionShape3D.new()
	collider.name = "PadShape"
	collider.shape = shape
	collider.position = at
	collision.add_child(collider)
