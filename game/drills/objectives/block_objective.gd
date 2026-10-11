extends "res://game/drills/objectives/cpu_play_objective.gd"






const FEED_FROM: = Vector3(0.0, 1.5, 6.0)
const RECEIVER_SPOT: = Vector3(0.0, 0.0, -9.0)
const SETTER_SPOT: = Vector3(0.8, 0.0, -1.8)

const LANES: = [
	{"home": Vector3(-3.2, 0.0, -4.0), "set": Vector3(-2.6, 0.0, -1.3)}, 
	{"home": Vector3(0.4, 0.0, -4.6), "set": Vector3(0.0, 0.0, -1.3)}, 
	{"home": Vector3(3.4, 0.0, -4.0), "set": Vector3(2.8, 0.0, -1.3)}, 
]
const TEAMMATES: = [Vector3(-2.8, 0.0, 7.6), Vector3(2.8, 0.0, 7.6)]
const PLAYER_START: = Vector3(0.0, 0.0, 2.4)

enum {FEED, PASS, SET, ATTACK}

var receiver: Player = null
var setter: Player = null
var hitters: Array[Player] = []
var play: = FEED
var lane: = 1
var blocked: = false

func _begin() -> void :
	required = 3
	hop_early = 0.3
	receiver = spawn_actor(RECEIVER_SPOT, -1, randi() % 4096)
	setter = spawn_actor(SETTER_SPOT, -1, randi() % 4096)
	for i in _lanes_used():
		hitters.append(spawn_actor(LANES[i].home, -1, randi() % 4096))
	for spot in TEAMMATES:
		spawn_actor(spot, 1, randi() % 4096)
	player.global_position = PLAYER_START
	player.face_net()
	player.reset_physics_interpolation()


func _lanes_used() -> Array:
	return [1]

func _pick_lane() -> int:
	return _lanes_used()[done % _lanes_used().size()]

func _instruction() -> String:
	return "jump and block the spike"

func on_go() -> void :
	runner.objective_say(_instruction())
	schedule_feed(0.9)

func _launch() -> void :
	play = FEED
	blocked = false
	hitter_reset()
	lane = _pick_lane()
	for i in hitters.size():
		var h: = hitters[i]
		h.global_position = LANES[_lanes_used()[i]].home
		actor_face(h, h.global_position + Vector3(0.0, 0.0, 3.0))
	actor_face(receiver, FEED_FROM)
	feed_ball(FEED_FROM, actor_hands(receiver), 1.6)
	runner.objective_say(_instruction())

func _hitter_for_lane() -> Player:
	return hitters[_lanes_used().find(lane)]

func tick(delta: float) -> void :
	super.tick(delta)
	if state != LIVE and state != VERIFYING:
		return
	match play:
		FEED:
			if contact_when_near(receiver, Player.TouchKind.BUMP, 
					pass_target(setter, receiver.global_position), 0.2, true):
				play = PASS
		PASS:
			if contact_when_near(setter, Player.TouchKind.SET, LANES[lane].set, 0.0):
				play = SET

				var h: = _hitter_for_lane()
				var aim: = Vector3(clampf(LANES[lane].set.x * 0.7, -3.0, 3.0), 0.0, 7.5)
				hitter_arm(h, aim, 0.55)
		SET:
			if hitter_tick(delta):
				play = ATTACK
		ATTACK:
			hitter_tick(delta)

func on_touch(kind: int) -> void :
	if state != LIVE or play != ATTACK:
		return
	if kind == Player.TouchKind.BLOCK:
		blocked = true
		_on_block()
	else:

		fail_settle("jump and block it at the net")

func _on_block() -> void :
	score("good!")

func on_bounce(pos: Vector3) -> void :
	match state:
		SETTLING:
			schedule_feed(0.8)
		LIVE:
			if play == ATTACK:
				if pos.z > 0.0:
					_fail("get in front of the attacker and jump")
				else:
					schedule_feed(1.0)
			elif play != FEED:
				schedule_feed(1.0)
		VERIFYING:
			_verify_landing(pos)

func _verify_landing(_pos: Vector3) -> void :
	schedule_feed(1.0)

func on_wall() -> void :
	if state == VERIFYING:
		_verify_landing(ball.global_position)
	elif state == LIVE and play == ATTACK:
		schedule_feed(1.0)

func _fail(reason: String) -> void :
	runner.objective_say(reason)
	schedule_feed(1.3)
