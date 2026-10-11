@tool
class_name AnimeSkyEnv
extends Node3D












@export var active_at_runtime: = false

func _ready() -> void :
	if not Engine.is_editor_hint() and not active_at_runtime:
		queue_free()
