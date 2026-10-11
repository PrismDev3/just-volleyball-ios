extends "res://game/drills/objectives/receive_objective.gd"






const WIDE_ARRIVES: = [
	Vector3(-4.6, 0.0, 7.4), 
	Vector3(4.6, 0.0, 7.4), 
	Vector3(-4.2, 0.0, 9.6), 
]
const PLAYER_START: = Vector3(0.0, 0.0, 7.6)

func _begin() -> void :
	super._begin()
	player.global_position = PLAYER_START
	player.reset_physics_interpolation()

func _instruction() -> String:
	return "dive for the ball and get it to your teammate"

func _serves() -> Array:
	return [SERVE_JUMP, SERVE_JUMP, SERVE_JUMP]

func _launch() -> void :
	super._launch()



	player.global_position = PLAYER_START
	player.velocity = Vector3.ZERO
	player.dive_cooldown = 0.0
	player.reset_physics_interpolation()

func tick(delta: float) -> void :


	var before: = serve_phase
	super.tick(delta)
	if before == TOSSED and serve_phase == FLIGHT and not ball.frozen:
		var from: = ball.global_position
		var arrive: Vector3 = WIDE_ARRIVES[done % WIDE_ARRIVES.size()]

		var flight: = 1.05
		var delta_p: = arrive - from
		var vel: = delta_p / flight
		vel.y = (delta_p.y + 0.5 * Ball.PHYS.gravity * flight * flight) / flight
		ball.vel = vel

func on_touch(kind: int) -> void :




	if state == SETTLING and not ball.frozen:
		schedule_feed(0.5)
		return
	if serve_phase != FLIGHT or state != LIVE:
		return
	if not player.diving():
		fail_settle("press {dive} on the ground to dive for it!")
		return
	if _qualifying(kind):
		state = VERIFYING
	else:
		fail_settle("get under the ball first")
