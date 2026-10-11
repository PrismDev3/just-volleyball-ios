extends "res://game/drills/objectives/receive_objective.gd"



func _instruction() -> String:
	return "watch the float in, plant, and bump it to your teammate"

func _serves() -> Array:
	return [SERVE_FLOAT, SERVE_FLOAT, SERVE_FLOAT]
