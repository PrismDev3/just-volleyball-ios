extends "res://game/drills/objectives/receive_objective.gd"



func _instruction() -> String:
	return "plant your feet and bump it to your teammate"

func _serves() -> Array:
	return [SERVE_JUMP, SERVE_JUMP, SERVE_JUMP]
