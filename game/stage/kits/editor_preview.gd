@tool
extends Node3D











func _enter_tree() -> void :
	if not Engine.is_editor_hint():


		queue_free()
