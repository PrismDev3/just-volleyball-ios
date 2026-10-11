extends "res://game/drills/objectives/block_objective.gd"




func _instruction() -> String:
	return "jump right after the hitter and stuff it back"

func _on_block() -> void :
	state = VERIFYING
	runner.objective_say("stuff it")

func _verify_landing(pos: Vector3) -> void :
	if pos.z < 0.0:
		score("stuffed, next play")
	else:
		runner.objective_say("late block, jump right after the hitter")
		schedule_feed(1.3)
