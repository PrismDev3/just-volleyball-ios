extends "res://game/drills/objectives/spike_objective.gd"




const SETS: = [
	{"quick": true, "power": 1.0}, 
	{"quick": false, "power": 0.0}, 
	{"quick": false, "power": 0.5}, 
]

func _build_zone() -> void :
	zone = null

func _instruction() -> String:
	return "time each set and spike it over"

func _set_quick() -> bool:
	return bool(SETS[done % SETS.size()].quick)

func _set_power() -> float:
	return float(SETS[done % SETS.size()].power)

func _landed_ok(_pos: Vector3) -> bool:
	return true
