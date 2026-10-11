extends "res://game/drills/objectives/spike_objective.gd"




const CHARGE_MIN: = 0.35

func _build_zone() -> void :
	zone = null

func _instruction() -> String:
	return "approach and spike it over"

func on_touch(kind: int) -> void :



	if done == 0 and state == LIVE and kind == Player.TouchKind.SPIKE\
	and player.last_touch_power < CHARGE_MIN:
		fail_settle("hold {contact} to charge your spike!")
		return
	super.on_touch(kind)

func _landed_ok(_pos: Vector3) -> bool:
	return true
