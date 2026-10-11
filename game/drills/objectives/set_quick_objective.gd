extends "res://game/drills/objectives/set_objective.gd"




const QUICK_MIN_H: = 1.9

func _instruction() -> String:
	return "hold set all the way and quick set your hitter"

func _set_problem() -> String:
	if not player.last_touch_quick:
		return "hold the set button fully for a quick"
	var apex: = TeamBot.flight_apex(ball)
	if apex.y < QUICK_MIN_H or absf(apex.z) > TeamBot.SECOND_BALL_DEPTH:
		return "aim the quick at your hitter by the net"
	return ""
