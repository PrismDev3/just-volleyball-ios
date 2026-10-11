@tool
extends Node3D



















@export var stage_id: = "school"
@export var venue_path: NodePath = ^"../Gym"
@export var painted: = true: set = _set_painted
@export var refresh: = false: set = _set_refresh
@export_range(0, 3) var accent: = 2: set = _set_accent

var _ghost: Node3D = null
var _real: Node3D = null

func _set_gleams(on: bool) -> void :
	var root: = get_parent()
	if root == null:
		return
	for n in root.find_children("FloorGleam", "", true, false):
		(n as Node3D).visible = on

func _enter_tree() -> void :
	if not Engine.is_editor_hint():


		queue_free()

func _ready() -> void :
	if Engine.is_editor_hint():
		_rebuild.call_deferred()

func _notification(what: int) -> void :
	if not Engine.is_editor_hint():
		return

	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		_set_gleams(true)
		if _real != null and _ghost != null:
			_real.visible = true
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_set_gleams(painted)
		if _real != null and _ghost != null:
			_real.visible = false

func _set_painted(v: bool) -> void :
	painted = v
	if is_inside_tree() and Engine.is_editor_hint():
		_rebuild()

func _set_refresh(_v: bool) -> void :
	refresh = false
	if is_inside_tree() and Engine.is_editor_hint():
		_rebuild()

func _set_accent(v: int) -> void :
	accent = v
	if is_inside_tree() and Engine.is_editor_hint():
		_rebuild()

func _clear() -> void :
	if _ghost != null and is_instance_valid(_ghost):
		_ghost.free()
	_ghost = null
	if _real != null and is_instance_valid(_real):
		_real.visible = true
	_real = null
	_set_gleams(true)

func _rebuild() -> void :
	_clear()




	_set_gleams(painted)
	if not painted:
		return
	var real: = get_node_or_null(venue_path) as Node3D
	if real == null:
		push_warning("painted preview: no node at %s" % venue_path)
		return


	var stage_script: Variant = load("res://game/stage/stage.gd")
	var paint_script: Variant = load("res://game/court/env_paint.gd")
	if stage_script == null or paint_script == null:
		return
	var ghost: = real.duplicate(0) as Node3D
	if ghost == null:
		return
	ghost.name = "PaintedGhost"
	add_child(ghost)
	ghost.global_transform = real.global_transform
	for n in ghost.find_children("*", "MeshInstance3D", true, false):
		if String(n.name).to_lower().contains("cutter"):
			(n as Node3D).visible = false
	var painted_mats: Dictionary = paint_script.apply(ghost, 
		stage_script.val(stage_id, "emissive_mats", {}))
	var look: Variant = stage_script.config(stage_id, true)
	if look != null and look.has_method("apply"):
		look.apply(painted_mats)
	var accents: Array = stage_script.val(stage_id, "accents", [])
	if not accents.is_empty():
		stage_script.apply_school_accent(painted_mats, null, stage_id, 
			accents[accent % accents.size()], null, {})
	if ghost.find_children("*", "MeshInstance3D", true, false).is_empty():
		push_warning("painted preview: ghost has no meshes, leaving the real model visible")
		ghost.free()
		return
	_real = real
	_real.visible = false
	_ghost = ghost
	print("painted preview: ghost built, %d materials painted (real model hidden while painted=true)" % painted_mats.size())
