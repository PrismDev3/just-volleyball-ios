extends "res://game/drills/objectives/receive_objective.gd"





const PLAYER_START: = Vector3(0.0, 0.0, 8.0)

enum {WAIT_BUMP, BUMPED, SET_UP, ATTACK}

var rally_phase: = WAIT_BUMP
var crossed: = false
var spiked: = false

func _begin() -> void :
	super._begin()
	player.global_position = PLAYER_START
	player.reset_physics_interpolation()

func _instruction() -> String:
	return "bump the serve to your teammate"

func _launch() -> void :
	super._launch()
	rally_phase = WAIT_BUMP
	crossed = false
	spiked = false
	player.global_position = PLAYER_START
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()

func tick(delta: float) -> void :
	super.tick(delta)
	if state != LIVE or serve_phase != FLIGHT or ball.frozen:
		return
	if rally_phase == BUMPED and teammate.ball_position_in_reach(ball.global_position):


		var x: = clampf(player.global_position.x, -3.5, 3.5)
		var z: = clampf(player.global_position.z - 1.4, 1.4, 3.2)
		cpu_set(teammate, Vector3(x, 0.0, z))
		_combo(teammate, 2)
		rally_phase = SET_UP
		runner.objective_say("jump and spike it over!")

func on_touch(kind: int) -> void :
	if serve_phase != FLIGHT or state != LIVE:
		return
	match rally_phase:
		WAIT_BUMP:
			if _qualifying(kind):
				rally_phase = BUMPED
				_combo(player, 1)
				runner.objective_say("begin your approach!")
			else:
				fail_settle("get underneath the ball")
		SET_UP:
			rally_phase = ATTACK
			spiked = kind == Player.TouchKind.SPIKE
			crossed = false
			state = VERIFYING
			if spiked:
				_combo(player, 3)
			runner.objective_say("over and in" if spiked else "jump before you touch")
		_:
			pass

func on_cross() -> void :
	if state == VERIFYING:
		crossed = true
	elif state == LIVE and rally_phase == BUMPED:
		fail_settle("keep the bump on your side")

func on_bounce(pos: Vector3) -> void :
	match state:
		SETTLING:
			if refeed_wait <= 0.0:
				schedule_feed(0.9)
		LIVE:
			if serve_phase != FLIGHT:
				return
			var msg: = ""
			match rally_phase:
				WAIT_BUMP:
					msg = "get to the serve before it lands"
				BUMPED:
					msg = "your teammate could not reach that"
				SET_UP:
					msg = "swing before the ball drops"
			if msg != "":
				runner.objective_say(msg)
				runner.objective_feedback(msg, false)
			schedule_feed(1.3)
		VERIFYING:
			if not spiked:
				_fail("jump before you touch")
			elif not crossed or pos.z >= 0.0:
				_fail("put it over the net")
			elif not landing_in(pos):
				_fail("out!")
			else:
				score("again!")

func on_wall() -> void :
	if state == VERIFYING:
		fail_settle("out!")
	elif state == LIVE and serve_phase == FLIGHT:
		fail_settle("keep it in play")

func _fail(reason: String) -> void :



	runner.objective_say(reason)
	runner.objective_feedback(reason, false)
	schedule_feed(1.3)




func _combo(who: Player, n: int) -> void :
	if who != null and is_instance_valid(who):
		who.show_combo(n)
	if runner.sfx != null:
		runner.sfx.play_2d("combo_home_%d" % n, -6.0)
