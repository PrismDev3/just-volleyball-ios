extends "res://game/drills/objectives/set_objective.gd"



func _instruction() -> String:
	return "set your hitter any way you like"

func _set_problem() -> String:
	if TeamBot.set_attackable(ball, 1.0):
		return ""
	var apex: = TeamBot.flight_apex(ball)
	if player.last_touch_quick and apex.y >= 1.9\
	and absf(apex.z) <= TeamBot.SECOND_BALL_DEPTH:
		return ""
	if not TeamBot.attack_apex_ok(ball):
		return "set it higher"
	return "set it closer to the net"
