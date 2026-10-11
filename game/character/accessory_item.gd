class_name AccessoryItem
extends Resource













const CATEGORIES: = ["head", "face", "extra"]




const HAIR_NORMAL: = "normal"
const HAIR_TOP: = "top_covered"
const HAIR_FULL: = "full_covered"

@export var id: = ""
@export var display_name: = ""
@export var mesh: PackedScene
@export_enum("head", "face", "extra") var category: = "face"





@export var price: = 0






@export var anchor_offset: = Vector3.ZERO
@export var anchor_rotation: = Vector3.ZERO
@export var anchor_scale: = 1.0


@export var pos_range: = Vector3(0.5, 0.5, 0.5)
@export var rot_range: = Vector3(45.0, 45.0, 45.0)


@export var scale_min: = 0.8
@export var scale_max: = 1.3








@export var start_colors: PackedColorArray = PackedColorArray()








@export var locked_colors: PackedInt32Array = PackedInt32Array()







@export var jiggle_stiffness: = 1.0
@export var jiggle_damping: = 1.0
@export var jiggle_swing: = 1.0
@export var jiggle_gravity: = 1.0

@export_enum("normal", "top_covered", "full_covered") var hair_mode: = "normal"




@export_enum("head", "upper", "extra", "full") var portrait: = "head"

var _groups_scanned: = false
var _color_count: = 0
var _default_colors: Array = []

func name_or_id() -> String:
	return display_name if display_name != "" else id


func color_count() -> int:
	_scan_groups()
	return _color_count






func default_colors() -> Array:
	_scan_groups()
	var out: Array = []
	for i in _color_count:
		out.append(default_color(i))
	return out

func default_color(i: int) -> Color:
	if i >= 0 and i < start_colors.size():
		return start_colors[i]
	_scan_groups()
	return _default_colors[i] if i >= 0 and i < _default_colors.size() else Color.WHITE


func is_color_locked(i: int) -> bool:
	return i in locked_colors

func _scan_groups() -> void :
	if _groups_scanned:
		return
	_groups_scanned = true
	if mesh == null:
		return
	var root: = mesh.instantiate()
	var groups: = build_groups(root)
	_color_count = groups.size()
	for g in groups:
		_default_colors.append(_albedo_of(g["src"]))
	root.free()






static func build_groups(root: Node) -> Array:
	var order: Array = []
	var groups: Array = []
	_walk_groups(root, order, groups)
	return groups

static func _walk_groups(node: Node, order: Array, groups: Array) -> void :
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var mi: = node as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var src: = mi.mesh.surface_get_material(s)
			var slot: = _slot_of(order, src)
			if slot == groups.size():
				groups.append({"src": src, "targets": []})
			groups[slot]["targets"].append([mi, s])
	for c in node.get_children():
		_walk_groups(c, order, groups)

static func _slot_of(order: Array, src: Material) -> int:
	for i in order.size():
		if order[i] == src:
			return i
	order.append(src)
	return order.size() - 1

static func _albedo_of(src: Material) -> Color:
	if src is BaseMaterial3D:
		return (src as BaseMaterial3D).albedo_color
	if src is ShaderMaterial:
		var v = (src as ShaderMaterial).get_shader_parameter("albedo")
		if v is Color:
			return v
	return Color.WHITE
