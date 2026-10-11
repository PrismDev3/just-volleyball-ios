extends "res://game/drills/objectives/cpu_play_objective.gd"









const FEED_FROM: = Vector3(0.0, 1.6, 7.2)
const ARRIVES: = [
	Vector3(0.4, 1.9, 2.5), 
	Vector3(-0.4, 1.9, 2.3), 
	Vector3(0.5, 1.9, 2.6), 
]
const FLIGHT: = 1.4


const HITTER_HOMES: = [
	Vector3(-3.5, 0.0, 2.2), 
	Vector3(3.5, 0.0, 2.2), 
	Vector3(1.0, 0.0, 2.8), 
]
const SETTER_HOME: = Vector3(0.0, 0.0, 2.4)
const BACK_HOME: = Vector3(0.0, 0.0, 7.2)
const FAR_TARGET: = Vector3(1.5, 0.0, -7.5)

var body: Player = null
var back: Player = null
var crossed: = false

func _begin() -> void :
	required = 3
	body = spawn_actor(HITTER_HOMES[0], 1, randi() % 4096)

	back = spawn_actor(BACK_HOME, 1, randi() % 4096)
	actor_face(back, SETTER_HOME)
	player.global_position = SETTER_HOME
	actor_face(player, BACK_HOME)
	player.reset_physics_interpolation()





	player.quick_check = Callable()

func _quick_ready(aim: Vector3, _me: Player) -> bool:
	return is_instance_valid(body)\
	and Vector2(aim.x - body.global_position.x, 
		aim.z - body.global_position.z).length() <= 2.6

func _cancel() -> void :
	if player.quick_check == Callable(_quick_ready):
		player.quick_check = Callable()

func _instruction() -> String:
	return "set the ball to your teammate"

func on_go() -> void :
	runner.objective_say(_instruction())
	schedule_feed(0.9)

func _launch() -> void :
	crossed = false
	hitter_reset()
	var home: Vector3 = HITTER_HOMES[done % HITTER_HOMES.size()]
	body.global_position = home
	body.reset_physics_interpolation()
	actor_face(body, home + Vector3(0.0, 0.0, -3.0))


	var arrive: Vector3 = ARRIVES[done % ARRIVES.size()]
	feed_ball(actor_hands(back), arrive, FLIGHT)
	actor_face(back, arrive)
	back.present_authoritative_touch(Player.TouchKind.BUMP)
	runner.objective_say(_instruction())

func tick(delta: float) -> void :
	super.tick(delta)
	if state == VERIFYING:
		hitter_tick(delta)


func _set_problem() -> String:
	if not TeamBot.set_attackable(ball, 1.0):
		if not TeamBot.attack_apex_ok(ball):
			return "set it higher"
		return "set it closer to the net"
	return ""

func on_touch(kind: int) -> void :
	if state != LIVE:
		return
	if kind != Player.TouchKind.SET:
		fail_settle("set it, don't bump it")
		return
	var why: = _set_problem()
	if why != "":
		fail_settle(why)
		return

	state = VERIFYING
	hitter_arm(body, FAR_TARGET)
	runner.objective_say("good!")

func on_cross() -> void :
	if state == VERIFYING and hitter_state == H_DONE:
		crossed = true

func on_bounce(pos: Vector3) -> void :
	match state:
		SETTLING:
			schedule_feed(0.7)
		LIVE:
			_fail("touch the ball before it lands")
		VERIFYING:
			if hitter_state == H_DONE and crossed and pos.z < 0.0\
			and landing_in(pos):
				score("nice!")
			elif hitter_state == H_IDLE:
				schedule_feed(1.3)
			else:
				_fail("too far")

func on_wall() -> void :
	if state != WAITING:
		schedule_feed(1.3)

func _fail(reason: String) -> void :


	runner.objective_say(reason)
	runner.objective_feedback(reason, false)
	schedule_feed(1.3)
