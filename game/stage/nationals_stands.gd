@tool
class_name NationalsStands
extends Node3D


















const WALL_X: = 22.0
const WALL_Z: = 28.0
const WALL_GAP: = 0.6




const SIDE_INNER_MIN: = 16.5
const END_INNER_MIN: = 21.5
const APRON: = 3.0

const TIER_DEPTH: = 1.05
const TIER_RISE: = 1.2
const FRONT_HEIGHT: = 1.0
const MAX_TIERS: = 12

const DEFAULT_HALF_W: = 4.5
const DEFAULT_HALF_L: = 9.0

const BLOCKOUT: = "Blockout"

func _ready() -> void :


	if Engine.is_editor_hint():
		_build(DEFAULT_HALF_W, DEFAULT_HALF_L)

func configure(half_w: float, half_l: float) -> void :
	_build(half_w, half_l)

func _build(half_w: float, half_l: float) -> void :
	var inner_x: = maxf(SIDE_INNER_MIN, half_w + APRON)
	var inner_z: = maxf(END_INNER_MIN, half_l + APRON)





	var deck: = GymDressing.prototype_material("grey", Color(0.5, 0.54, 0.62))
	var seat: = GymDressing.prototype_material("blue", Color(0.22, 0.33, 0.66))
	seat.emission_enabled = true
	seat.emission = Color(0.12, 0.2, 0.45)
	seat.emission_energy_multiplier = 0.55
	deck.emission_enabled = true
	deck.emission = Color(0.16, 0.18, 0.22)
	deck.emission_energy_multiplier = 0.4


	_bank("StandNorth", "z", -1.0, inner_z, 2.0 * WALL_X, deck, seat)
	_bank("StandSouth", "z", 1.0, inner_z, 2.0 * WALL_X, deck, seat)
	_bank("StandEast", "x", 1.0, inner_x, 2.0 * inner_z, deck, seat)
	_bank("StandWest", "x", -1.0, inner_x, 2.0 * inner_z, deck, seat)






func _bank(bank_name: String, axis: String, sign: float, inner: float, 
		cross: float, deck: Material, seat: Material) -> void :


	var anchor: = get_node_or_null(NodePath(bank_name)) as Node3D
	if anchor == null:
		anchor = Node3D.new()
		anchor.name = bank_name
		add_child(anchor)
	anchor.position = Vector3(sign * inner, 0.0, 0.0) if axis == "x"\
	else Vector3(0.0, 0.0, sign * inner)

	var old: = anchor.get_node_or_null(BLOCKOUT)
	if old != null:
		anchor.remove_child(old)
		old.queue_free()
	for c in anchor.get_children():
		if c.name != BLOCKOUT:
			return
	var blockout: = Node3D.new()
	blockout.name = BLOCKOUT
	anchor.add_child(blockout)
	var body: = StaticBody3D.new()
	body.name = "StandCollision"
	body.collision_layer = 1
	body.collision_mask = 1
	blockout.add_child(body)
	var outer: = (WALL_Z if axis == "z" else WALL_X) - WALL_GAP
	var run: = outer - inner
	for i in MAX_TIERS:
		var front: = float(i) * TIER_DEPTH
		var depth: = run - front
		if depth <= 0.2:
			break
		var height: = FRONT_HEIGHT + float(i) * TIER_RISE

		var along: = sign * (front + depth * 0.5)
		var pos: Vector3
		var size: Vector3
		if axis == "z":
			pos = Vector3(0.0, height * 0.5, along)
			size = Vector3(cross, height, depth)
		else:
			pos = Vector3(along, height * 0.5, 0.0)
			size = Vector3(depth, height, cross)
		var mat: = deck if i % 2 == 0 else seat
		_add_tier(blockout, body, pos, size, mat)

func _add_tier(blockout: Node3D, body: StaticBody3D, at: Vector3, size: Vector3, 
		mat: Material) -> void :
	var mesh: = BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	var tier: = MeshInstance3D.new()
	tier.name = "Tier"
	tier.mesh = mesh
	tier.position = at
	tier.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	blockout.add_child(tier)
	var shape: = CollisionShape3D.new()
	var box: = BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	body.add_child(shape)
