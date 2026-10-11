extends "res://game/drills/objectives/receive_objective.gd"



func _instruction() -> String:
	return "read the toss, then bump it to your teammate"

func _serves() -> Array:
	return [SERVE_BASIC, SERVE_JUMP, SERVE_FLOAT]
