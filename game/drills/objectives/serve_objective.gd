extends DrillObjective






const SERVE_SPOT: = Vector3(0.0, 0.0, 14.8)

enum {HOLD, TOSSED, FLIGHT}

var serve_phase: = HOLD
var crossed: = false
var launch_z: = 0.0

func _begin() -> void :
	required = 3
	player.global_position = SERVE_SPOT
	player.face_net()
	player.reset_physics_interpolation()

func _instruction() -> String:
	return "toss the ball up, then hit it over the net"

func on_go() -> void :
	runner.objective_say(_instruction())
	schedule_feed(0.6)

func _launch() -> void :

	serve_phase = HOLD
	crossed = false
	runner.objective_say(_instruction())

func wants_serve() -> bool:
	return state == LIVE and serve_phase == HOLD

func serve_tossed() -> void :
	serve_phase = TOSSED

func tick(delta: float) -> void :
	super.tick(delta)
	if player.grounded():
		launch_z = absf(player.global_position.z)

func on_touch(kind: int) -> void :
	if state != LIVE or serve_phase != TOSSED:
		return
	serve_phase = FLIGHT
	if Rules.serve_foot_fault(launch_z, ball.court_half_l):
		_fail("remain in the serving area!")
		return
	var why: = _strike_problem(kind)
	if why != "":
		_fail(why)
		return
	state = VERIFYING
	runner.objective_say("over and in")


func _strike_problem(_kind: int) -> String:
	return ""

func on_cross() -> void :
	if state == VERIFYING:
		crossed = true

func on_net() -> void :
	if state == VERIFYING:
		fail_settle("unlucky!")

func on_bounce(pos: Vector3) -> void :
	match state:
		SETTLING:
			schedule_feed(0.9)
		LIVE:
			if serve_phase == TOSSED:
				_fail("hit the ball at the top of the toss")
		VERIFYING:
			if not crossed or pos.z >= 0.0:
				_fail("get it over the net")
			elif not landing_in(pos):
				_fail("out!")
			else:
				score("good!")

func on_wall() -> void :
	if state == VERIFYING or state == LIVE:
		fail_settle("out!")

func _fail(reason: String) -> void :



	runner.objective_say(reason)
	runner.objective_feedback(reason, false)
	schedule_feed(1.2)
