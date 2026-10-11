extends "res://game/drills/objectives/cpu_play_objective.gd"





const JUMP_GOOD_H: = 2.7
const JUMP_GOOD_RISE: = 2.0
const SETTER_SPOT: = Vector3(1.2, 0.0, 1.5)
const FEED_FROM: = Vector3(0.0, 2.0, -5.5)
const PLAYER_START: = Vector3(-1.4, 0.0, 2.2)
const SET_TARGET: = Vector3(-1.5, 0.0, 1.3)

var setter: Player = null
var set_up: = false
var was_grounded: = true

func _begin() -> void :
	required = 3
	setter = spawn_actor(SETTER_SPOT, 1, randi() % 4096)
	player.global_position = PLAYER_START
	player.face_net()
	player.reset_physics_interpolation()

func on_go() -> void :
	runner.objective_say("jump as the set goes up")
	schedule_feed(0.9)

func _launch() -> void :
	set_up = false
	was_grounded = true
	actor_face(setter, FEED_FROM)
	feed_ball(FEED_FROM, actor_hands(setter), 1.5)
	runner.objective_say("jump as the set goes up")

func tick(delta: float) -> void :
	super.tick(delta)
	if state != LIVE:
		return
	if not set_up:
		if contact_when_near(setter, Player.TouchKind.SET, SET_TARGET, 0.0):
			set_up = true
		return




	var grounded: = player.grounded()
	if was_grounded and not grounded:
		var y: = ball.global_position.y
		var vy: = ball.vel.y
		if y > JUMP_GOOD_H and vy < JUMP_GOOD_RISE:
			score("nice!")
		elif vy > 0.5:
			fail_settle("too early! let the set rise, then jump")
		else:
			fail_settle("too late! jump as the set starts to drop")
	was_grounded = grounded

func on_bounce(_pos: Vector3) -> void :
	match state:
		SETTLING:
			schedule_feed(0.7)
		LIVE:
			if set_up:
				runner.objective_say("jump while the ball is in the air")
			schedule_feed(1.2)
		VERIFYING:
			schedule_feed(1.0)

func on_wall() -> void :
	if state != WAITING:
		schedule_feed(1.0)
