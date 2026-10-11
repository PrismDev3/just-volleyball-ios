extends "res://game/drills/objectives/serve_objective.gd"




func _instruction() -> String:
	return "jump, tilt back, and hit it over"

func _strike_problem(kind: int) -> String:
	if kind != Player.TouchKind.SPIKE:
		return "jump and hit the ball in the air"
	if not ball.float_serve:
		return "tilt back as you hit to float it"
	return ""
