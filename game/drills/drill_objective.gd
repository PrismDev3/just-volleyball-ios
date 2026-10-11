class_name DrillObjective
extends RefCounted










enum {WAITING, LIVE, VERIFYING, SETTLING}

const PARK: = Vector3(0.0, -4.0, 0.0)


const PLAYER_SCENE: = preload("res://game/player/player.tscn")

const ACTOR_SPEED: = 5.2
const ACTOR_HOP: = 8.6
const ACTOR_HAND_H: = 1.9
const ACTOR_SWING_H: = 2.4

var runner: DrillRunner = null
var player: Player = null
var ball: Ball = null
var done: = 0
var required: = 3
var state: = WAITING
var feed_wait: = 0.0
var actors: Array[Player] = []
var _hops: = {}

func begin(host: DrillRunner) -> void :
	runner = host
	player = host.player
	ball = host.ball
	done = 0
	state = WAITING
	feed_wait = 0.0
	_begin()




func actors_tick(delta: float) -> void :
	for actor in actors:
		if is_instance_valid(actor):
			actor.puppet_tick(delta)

func tick(delta: float) -> void :
	_hops_tick(delta)
	if state == WAITING:
		feed_wait -= delta
		if feed_wait <= 0.0:
			runner.start_clock()
			state = LIVE
			_launch()
		return


	if not ball.frozen and ball.global_position.y < Ball.PHYS.radius + 0.3\
	and absf(ball.vel.y) < 1.0\
	and Vector2(ball.vel.x, ball.vel.z).length() < 1.4:
		on_bounce(ball.global_position)



func _begin() -> void :
	pass

func on_go() -> void :
	schedule_feed(0.8)

func _launch() -> void :
	pass

func on_touch(_kind: int) -> void :
	pass

func on_bounce(_pos: Vector3) -> void :
	pass

func on_cross() -> void :
	pass

func on_net() -> void :
	pass

func on_wall() -> void :
	pass



func wants_serve() -> bool:
	return false

func serve_tossed() -> void :
	pass

func cancel() -> void :
	for actor in actors:
		if is_instance_valid(actor):
			actor.queue_free()
	actors.clear()
	_hops.clear()
	_cancel()

func _cancel() -> void :
	pass



func schedule_feed(delay: float) -> void :
	state = WAITING
	feed_wait = delay
	park_ball()

func park_ball() -> void :


	ball.toss(PARK, 0.0)
	ball.vel = Vector3.ZERO
	ball.frozen = true



func feed_ball(from: Vector3, arrive: Vector3, flight: float) -> void :
	ball.frozen = false
	ball.toss(from, 0.0)
	var delta: = arrive - from
	var vel: = delta / flight
	vel.y = (delta.y + 0.5 * Ball.PHYS.gravity * flight * flight) / flight
	ball.vel = vel
	ball.curve = 0.0

func landing_in(pos: Vector3) -> bool:
	return Rules.ball_in(pos, ball.court_half_w, ball.court_half_l, 
		ball.court_center_x)



func time_to_height(h: float) -> float:
	var g: = Ball.PHYS.gravity
	var vy: = ball.vel.y
	var disc: = vy * vy - 2.0 * g * (h - ball.global_position.y)
	if disc < 0.0:
		return maxf(vy / g, 0.0)
	return maxf((vy + sqrt(disc)) / g, 0.0)



func meet_point(h: float) -> Vector3:
	var probe: = TeamBot.flight_point_at_height(ball, h)
	return probe.point





func spawn_actor(pos: Vector3, side: int, slot: = 0) -> Player:
	var actor: = make_puppet(runner.get_parent(), pos, side, slot)
	actors.append(actor)
	return actor




static var practice_dress: = false



static func make_puppet(parent: Node, pos: Vector3, side: int, slot: = 0) -> Player:
	var actor: Player = PLAYER_SCENE.instantiate()
	actor.team_side = side
	parent.add_child(actor)
	actor.global_position = pos
	actor.net_puppet = true
	actor.sim_authority = false
	actor.collision_layer = 0
	actor.collision_mask = 0
	actor.charge_ui_enabled = false
	actor.indicator_enabled = false
	actor.set_name_visible(false)
	var cfg: = GameConfig.bot_character(side, slot)
	if practice_dress:
		actor.set_character(cfg.gym_look(), cfg.gym_kit())
	else:
		actor.set_character(cfg, 
			GameConfig.opponent_kit() if side < 0 else GameConfig.team_kit(true))
	actor.face_net()
	actor.aim_point = pos + Vector3(0.0, 0.0, -3.0 * side)
	actor.reset_physics_interpolation()


	actor.voiced.connect( func(bank: String, pitch: float):
		var s: Variant = parent.get("sfx")
		if s != null and is_instance_valid(actor):
			s.play(bank, actor.global_position, -3.0, pitch))
	return actor





func actor_face(actor: Player, toward: Vector3) -> void :
	var d: = toward - actor.global_position
	if Vector2(d.x, d.z).length() > 0.05:
		actor.visual.rotation.y = atan2(d.x, d.z)
	actor.aim_point = toward


func actor_move(actor: Player, target: Vector3, delta: float, 
		speed: = ACTOR_SPEED) -> bool:
	var to: = Vector3(target.x - actor.global_position.x, 0.0, 
		target.z - actor.global_position.z)
	var dist: = to.length()
	if dist <= 0.12:
		actor_stop(actor)
		return true
	var step: = minf(speed * delta, dist)
	var dir: = to / dist
	actor.global_position += dir * step
	actor.velocity.x = dir.x * speed
	actor.velocity.z = dir.z * speed


	actor._move_intent = Vector2(dir.x, dir.z)
	actor.visual.rotation.y = atan2(dir.x, dir.z)
	return dist - step <= 0.12

func actor_stop(actor: Player) -> void :
	actor.velocity.x = 0.0
	actor.velocity.z = 0.0
	actor._move_intent = Vector2.ZERO

func actor_jump(actor: Player, impulse: = ACTOR_HOP) -> void :
	if _hops.has(actor):
		return
	_hops[actor] = impulse
	actor._puppet_grounded = false



	actor.velocity.y = impulse

	var boost: = clampf((impulse - actor.FEEL.jump_min_velocity)
		/ maxf(actor.FEEL.jump_max_velocity - actor.FEEL.jump_min_velocity, 0.01), 0.0, 1.4)
	actor._launch_pulse = actor.FEEL.launch_stretch * (1.0 + boost * actor.FEEL.launch_charge_gain)
	actor._launch_vel = 0.0
	actor_voice(actor, "v_jump")


func actor_voice(actor: Player, bank: String) -> void :
	if actor.character == null:
		return
	actor.voiced.emit(bank, actor.character.voice_pitch() * randf_range(0.96, 1.04))

func actor_airborne(actor: Player) -> bool:
	return _hops.has(actor)

func actor_land(actor: Player, fall_speed: = 0.0) -> void :
	_hops.erase(actor)
	actor.global_position.y = 0.0
	actor.velocity.y = 0.0
	actor._puppet_grounded = true
	if fall_speed > 0.0:

		actor._land_pulse = clampf(fall_speed * 0.08, 0.25, 1.0)
		actor._launch_pulse = - actor.FEEL.land_pop * clampf(fall_speed / actor.FEEL.jump_max_velocity, 0.35, 1.0)
		actor._launch_vel = 0.0

func _hops_tick(delta: float) -> void :
	for actor in _hops.keys():
		if not is_instance_valid(actor):
			_hops.erase(actor)
			continue
		var v: float = _hops[actor]
		actor.velocity.y = v
		actor.global_position.y += v * delta
		v -= actor.FEEL.gravity * delta
		_hops[actor] = v
		if v < 0.0 and actor.global_position.y <= 0.0:
			actor_land(actor, - v)



func actor_hands(actor: Player) -> Vector3:
	var h: = ACTOR_SWING_H if actor_airborne(actor) else ACTOR_HAND_H
	return actor.global_position + Vector3(0.0, h, 0.0)

func ball_near(actor: Player, radius: float) -> bool:
	return not ball.frozen\
	and ball.global_position.distance_to(actor_hands(actor)) <= radius





func actor_strike(actor: Player, kind: int, target: Vector3, power: = 0.5, 
		finesse: = false, quick: = false, float_seed: = 0) -> void :
	actor_face(actor, target)
	ball.hit(target, kind, power, finesse, Vector2.ZERO, true, quick, float_seed)
	actor.present_authoritative_touch(kind)
	if kind == Player.TouchKind.BUMP:
		actor_voice(actor, "v_receive")







const SET_ARRIVE_H: = TeamBot.SECOND_BALL_MEET_H
const SET_FLIGHT: = 1.3
const QUICK_FLIGHT: = 0.8

func cpu_set(body: Player, target: Vector3, quick: = false) -> void :
	actor_face(body, target)
	var from: = actor_hands(body)
	from.y = minf(from.y, ball.global_position.y)
	var arrive: = Vector3(target.x, SET_ARRIVE_H + (0.2 if quick else 0.0), target.z)
	feed_ball(from, arrive, QUICK_FLIGHT if quick else SET_FLIGHT)
	ball.pulse()
	ball.struck.emit(ball.global_position, 0.0 if not quick else 0.8, Player.TouchKind.SET)
	body.present_authoritative_touch(Player.TouchKind.SET)



func fail_settle(reason: String) -> void :
	runner.objective_say(reason)
	runner.objective_feedback(reason, false)
	state = SETTLING

func score(next_feedback: String) -> void :
	done += 1
	runner.objective_progress(done, required)
	runner.objective_feedback("nice!", true)
	if done >= required:
		runner.objective_complete()
	else:
		runner.objective_say(next_feedback)
		state = SETTLING
