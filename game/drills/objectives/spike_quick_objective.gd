extends "res://game/drills/objectives/spike_objective.gd"




const QUICK_WINDOW: = 0.85
const QUICK_START: = Vector3(-1.4, 0.0, 2.2)

func _begin() -> void :
	super._begin()
	player.global_position = QUICK_START
	player.reset_physics_interpolation()

func _build_zone() -> void :
	zone = null

func _instruction() -> String:
	return "be in the air as the set comes, then swing right away"

func _set_quick() -> bool:
	return true

func _set_power() -> float:
	return 1.0

func _swing_problem(kind: int) -> String:
	if kind != Player.TouchKind.SPIKE:
		return "jump before you touch"
	if runner.elapsed - set_time > QUICK_WINDOW:
		return "too slow for a quick, swing right after the set"
	return ""

func _landed_ok(_pos: Vector3) -> bool:
	return true
