@tool
extends Node3D







@export var grade: ShaderMaterial

func _ready() -> void :
	_apply()

func _apply() -> void :
	if grade == null:
		return
	for child in get_children():
		if not String(child.name).begins_with("Bld"):
			continue
		for m in child.find_children("*", "MeshInstance3D", true, false):
			(m as MeshInstance3D).material_overlay = grade
