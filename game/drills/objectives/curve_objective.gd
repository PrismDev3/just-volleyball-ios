extends "res://game/drills/objectives/spike_objective.gd"








const CURVE_MIN: = 3.0
var _hit_curve: = 0.0

func _build_zone() -> void :
	pass


func _want_dir() -> int:
	match done:
		0: return 1
		1: return -1
		_: return 0

func _instruction() -> String:
	match _want_dir():
		1: return "in the air, hold left to curve it left"
		-1: return "in the air, hold right to curve it right"
		_: return "curve it whichever way you like"

func _launch() -> void :
	_hit_curve = 0.0
	super._launch()

func on_touch(kind: int) -> void :
	super.on_touch(kind)
	if kind == Player.TouchKind.SPIKE:
		_hit_curve = ball.curve



func _landed_ok(_pos: Vector3) -> bool:
	if absf(_hit_curve) < CURVE_MIN:
		return false
	var dir: = _want_dir()
	return dir == 0 or int(sign(_hit_curve)) == dir

func _land_fail() -> String:
	if absf(_hit_curve) < CURVE_MIN:
		return "hold left or right in the air to bend it"
	return "curve it the other way"
