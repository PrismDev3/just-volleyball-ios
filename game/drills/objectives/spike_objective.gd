extends "res://game/drills/objectives/cpu_play_objective.gd"





const SETTER_SPOT: = Vector3(1.2, 0.0, 1.5)
const FEED_FROM: = Vector3(0.0, 2.0, -5.5)
const HITTER_START: = Vector3(-2.2, 0.0, 5.2)
const ZONES: = [
	Vector3(-3.6, 0.0, -7.0), 
	Vector3(3.6, 0.0, -7.0), 
	Vector3(0.0, 0.0, -10.5), 
]
const ZONE_R: = 2.0

enum {FEED, SET, ATTACK}

var setter: Player = null
var play: = FEED
var crossed: = false
var spiked: = false
var set_time: = 0.0
var zone: Node3D = null

func _begin() -> void :
	required = 3
	setter = spawn_actor(SETTER_SPOT, 1, randi() % 4096)
	player.global_position = HITTER_START
	player.face_net()
	player.reset_physics_interpolation()
	_build_zone()

func _build_zone() -> void :
	zone = runner.add_column_marker(ZONES[0], ZONE_R, Color("ffd33d"))
	zone.visible = false

func _zone() -> Vector3:
	return ZONES[done % ZONES.size()]

func _instruction() -> String:
	return "run in, jump and spike into the marked zone"

func on_go() -> void :
	if zone != null:
		zone.visible = true
	runner.objective_say(_instruction())
	schedule_feed(0.9)




func _set_target() -> Vector3:
	var x: = clampf(player.global_position.x, -3.5, 3.5)
	var z: = clampf(player.global_position.z - 1.4, 1.4, 3.2)
	return Vector3(x, 0.0, z)

func _set_quick() -> bool:
	return false

func _set_power() -> float:
	return 0.0

func _launch() -> void :
	play = FEED
	crossed = false
	spiked = false
	actor_face(setter, FEED_FROM)
	feed_ball(FEED_FROM, actor_hands(setter), 1.5)
	runner.objective_say(_instruction())

func tick(delta: float) -> void :
	super.tick(delta)
	if state != LIVE or play != FEED:
		return
	if contact_when_near(setter, Player.TouchKind.SET, _set_target(), 
			_set_power(), false, _set_quick()):
		play = SET
		set_time = runner.elapsed

func on_touch(kind: int) -> void :
	if state != LIVE or play != SET:
		return
	play = ATTACK
	spiked = kind == Player.TouchKind.SPIKE
	var why: = _swing_problem(kind)
	if why != "":
		state = VERIFYING
		spiked = false
		runner.objective_say(why)
		return
	state = VERIFYING
	runner.objective_say("over and in")

func _swing_problem(kind: int) -> String:
	if kind != Player.TouchKind.SPIKE:
		return "jump before you touch"
	return ""

func on_cross() -> void :
	if state == VERIFYING:
		crossed = true

func on_net() -> void :
	if state == VERIFYING and spiked:
		fail_settle("unlucky!")


func _landed_ok(pos: Vector3) -> bool:
	var z: = _zone()
	return Vector2(pos.x - z.x, pos.z - z.z).length() <= ZONE_R + Ball.PHYS.radius

func _land_fail() -> String:
	return "spike into the marked zone"

func on_bounce(pos: Vector3) -> void :
	match state:
		SETTLING:
			schedule_feed(0.7)
		LIVE:
			_fail("swing before the ball drops")
		VERIFYING:
			if not spiked:
				_fail("jump before you touch")
			elif not crossed or pos.z >= 0.0:
				_fail("put it over the net")
			elif not landing_in(pos):
				_fail("out!")
			elif not _landed_ok(pos):
				_fail(_land_fail())
			else:
				score("nice!")
				if zone != null and done < required:
					zone.global_position = _zone() + Vector3.UP * 0.02

func on_wall() -> void :
	if state == VERIFYING:
		fail_settle("out!")
	elif state == LIVE:
		fail_settle("swing before the ball drops")

func _fail(reason: String) -> void :
	runner.objective_say(reason)
	schedule_feed(1.3)
