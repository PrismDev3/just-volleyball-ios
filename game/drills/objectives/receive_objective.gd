extends DrillObjective













const SERVE_BASIC: = {"kind": Player.TouchKind.BUMP, "power": 0.0, "finesse": true, 
	"toss": 6.0, "strike_below": 0.5, "jump": false, "float": false}
const SERVE_JUMP: = {"kind": Player.TouchKind.SPIKE, "power": 0.0, "finesse": false, 
	"toss": 8.5, "strike_below": -0.5, "jump": true, "float": false}
const SERVE_FLOAT: = {"kind": Player.TouchKind.SPIKE, "power": 0.5, "finesse": false, 
	"toss": 8.5, "strike_below": -0.5, "jump": true, "float": true}
const SPOTS: = [
	Vector3(0.0, 0.0, -14.2), 
	Vector3(5.0, 0.0, -14.2), 
	Vector3(-5.0, 0.0, -14.2), 
]
const HOP_AT: = 2.5
const ARRIVES: = [
	Vector3(0.0, 0.0, 6.2), 
	Vector3(-2.2, 0.0, 6.8), 
	Vector3(2.2, 0.0, 6.8), 
]
const TEAMMATE_SPOT: = Vector3(1.8, 0.0, 2.4)

enum {HOLD, TOSSED, FLIGHT}

var server: Player = null
var teammate: Player = null
var serve_phase: = FLIGHT
var hold_time: = 0.0
var refeed_wait: = 0.0

func _begin() -> void :
	required = 3

	server = spawn_actor(Vector3(SPOTS[0]), -1, randi() % 4096)
	teammate = spawn_actor(TEAMMATE_SPOT, 1, randi() % 4096)

	actor_face(teammate, TEAMMATE_SPOT + Vector3(-0.5, 0.0, -3.0))


func _serves() -> Array:
	return [SERVE_BASIC, SERVE_BASIC, SERVE_BASIC]

func _recipe() -> Dictionary:
	var list: = _serves()
	return list[done % list.size()]



func _instruction() -> String:
	return "bump the ball to your teammate"

func on_go() -> void :
	runner.objective_say(_instruction())
	schedule_feed(0.9)

func _launch() -> void :
	serve_phase = HOLD
	hold_time = 0.7
	actor_land(server)

	server.global_position = Vector3(SPOTS[done % SPOTS.size()])
	server.reset_physics_interpolation()
	actor_face(server, ARRIVES[done % ARRIVES.size()])
	ball.frozen = true
	ball.vel = Vector3.ZERO
	runner.objective_say(_instruction())

func tick(delta: float) -> void :
	super.tick(delta)
	if state == WAITING:
		return
	if state == SETTLING and refeed_wait > 0.0:


		refeed_wait -= delta
		if refeed_wait <= 0.0:
			schedule_feed(0.4)
		return
	if serve_phase == FLIGHT and state == VERIFYING and not ball.frozen\
	and teammate.ball_position_in_reach(ball.global_position):


		actor_strike(teammate, Player.TouchKind.SET, 
			teammate.global_position + Vector3(-1.5, 0.0, -1.0), 0.0)
		score("nice!")
		refeed_wait = 1.4
		return
	var recipe: = _recipe()
	match serve_phase:
		HOLD:


			server.serve_charge_ui = true
			ball.global_position = server.serve_cradle_point()
			hold_time -= delta
			if hold_time <= 0.0:
				serve_phase = TOSSED
				server.serve_charge_ui = false
				ball.frozen = false
				ball.toss(server.serve_cradle_point(), float(recipe.toss))
				server.present_serve_toss(true)
		TOSSED:
			if bool(recipe.jump) and not actor_airborne(server)\
			and ball.vel.y <= HOP_AT:

				actor_jump(server, 8.0)
			if ball.vel.y <= float(recipe.strike_below):
				serve_phase = FLIGHT



				ball.serve_assist = true
				var seed: = (randi() % 999983 + 1) if bool(recipe.float) else 0
				actor_strike(server, int(recipe.kind), ARRIVES[done % ARRIVES.size()], 
					float(recipe.power), bool(recipe.finesse), false, seed)

func _qualifying(kind: int) -> bool:
	return kind == Player.TouchKind.BUMP\
	or (kind == Player.TouchKind.SET and player.grounded())

func on_touch(kind: int) -> void :



	if state == SETTLING and not ball.frozen:
		schedule_feed(0.5)
		return
	if serve_phase != FLIGHT or state != LIVE:
		return
	if _qualifying(kind):

		state = VERIFYING
	else:
		fail_settle("get underneath the ball")

func on_cross() -> void :
	if state == VERIFYING:
		fail_settle("keep it on your side")

func on_bounce(_pos: Vector3) -> void :
	match state:
		SETTLING:


			if refeed_wait <= 0.0:
				schedule_feed(0.7)
		LIVE:
			if serve_phase == FLIGHT:
				runner.objective_say("get to the ball before it lands")
				schedule_feed(1.1)
		VERIFYING:
			runner.objective_say("your teammate could not reach that")
			schedule_feed(1.3)

func on_wall() -> void :
	if state == VERIFYING:
		fail_settle("your teammate could not reach that")
	elif state != WAITING:
		fail_settle(_instruction())
