extends "res://game/drills/objectives/set_objective.gd"







func _instruction() -> String:
	return "press {set} to set the ball up to the net"

func _set_problem() -> String:
	if not TeamBot.attack_apex_ok(ball):
		return "set it a little higher"
	return ""
