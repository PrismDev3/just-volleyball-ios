extends "res://game/drills/objectives/block_objective.gd"



func _instruction() -> String:
	return "watch the set, get in front of the hitter, and block"

func _lanes_used() -> Array:
	return [0, 1, 2]

func _pick_lane() -> int:
	return randi() % 3
