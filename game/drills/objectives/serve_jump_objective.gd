extends "res://game/drills/objectives/serve_objective.gd"




func _instruction() -> String:
	return "toss it high, jump, and spike it over"

func _strike_problem(kind: int) -> String:
	if kind != Player.TouchKind.SPIKE:
		return "jump and swing at the top of the toss"
	if ball.float_serve:
		return "keep your tilt forward, that was a float"
	return ""
