extends DrillObjective







const MEET_H: = TeamBot.SECOND_BALL_MEET_H
const HIT_HOP: = 10.2
const HOP_LEAD: = HIT_HOP / 22.0
const LOAD_TIME: = 0.4
const HIT_REACH: = 1.35

enum {H_IDLE, H_RUN, H_LOAD, H_SWING, H_DONE}

var hitter_state: = H_IDLE
var hitter: Player = null
var hitter_target: = Vector3.ZERO
var hitter_spot: = Vector3.ZERO
var hitter_power: = 0.55
var load_t: = 0.0


var hop_early: = 0.0


func hitter_arm(body: Player, target: Vector3, power: = 0.55) -> void :
	hitter = body
	hitter_target = target
	hitter_power = power
	var meet: = meet_point(MEET_H)


	hitter_spot = Vector3(meet.x, 0.0, meet.z + 0.35 * float(body.team_side))
	hitter_state = H_RUN

func hitter_reset() -> void :
	hitter_state = H_IDLE
	if hitter != null and is_instance_valid(hitter):
		actor_stop(hitter)
		hitter._jump_charge = 0.0


func hitter_tick(delta: float) -> bool:
	if hitter == null or not is_instance_valid(hitter):
		return false
	match hitter_state:
		H_RUN:
			var there: = actor_move(hitter, hitter_spot, delta, ACTOR_SPEED * 1.25)
			if ball.frozen:
				hitter_reset()
				return false
			var t: = time_to_height(MEET_H)
			var close: = Vector2(hitter.global_position.x - hitter_spot.x, 
				hitter.global_position.z - hitter_spot.z).length() <= 1.2
			if there or (close and t <= HOP_LEAD + LOAD_TIME):


				actor_stop(hitter)
				actor_face(hitter, hitter_target)
				load_t = 0.0
				hitter_state = H_LOAD
			elif t <= HOP_LEAD:

				actor_stop(hitter)
				actor_face(hitter, hitter_target)
				actor_jump(hitter, HIT_HOP)
				hitter_state = H_SWING
			if ball.global_position.y < 0.8 and ball.vel.y < 0.0:
				hitter_state = H_DONE
		H_LOAD:
			if ball.frozen:
				hitter_reset()
				return false
			load_t += delta

			hitter._jump_charge = load_t
			if time_to_height(MEET_H) <= HOP_LEAD + hop_early:
				hitter._jump_charge = 0.0
				actor_jump(hitter, HIT_HOP)
				hitter_state = H_SWING
			elif ball.global_position.y < 0.8 and ball.vel.y < 0.0:
				hitter._jump_charge = 0.0
				hitter_state = H_DONE
		H_SWING:
			if ball.frozen:
				hitter_state = H_DONE
				return false


			var hanging: = hop_early > 0.0 and float(_hops.get(hitter, 0.0)) > 0.5
			if ball_near(hitter, HIT_REACH) and ball.vel.y < 2.0 and not hanging:
				actor_strike(hitter, Player.TouchKind.SPIKE, hitter_target, 
					hitter_power, false)
				hitter_state = H_DONE
				return true
			if not actor_airborne(hitter):
				hitter_state = H_DONE
	return false





func contact_when_near(body: Player, kind: int, target: Vector3, power: = 0.3, 
		finesse: = false, quick: = false) -> bool:
	if ball.frozen or ball.vel.y > 0.5:
		return false
	var hands: = actor_hands(body)
	var flat: = Vector2(ball.global_position.x - hands.x, 
		ball.global_position.z - hands.z).length()
	var dy: = ball.global_position.y - hands.y
	if flat > 1.5 or dy > 0.6 or dy < -0.9:
		return false
	if kind == Player.TouchKind.SET:
		cpu_set(body, target, quick)
	else:
		actor_strike(body, kind, target, power, finesse, quick)
	return true




func pass_target(body: Player, from: Vector3) -> Vector3:
	var dir: = Vector3(body.global_position.x - from.x, 0.0, 
		body.global_position.z - from.z)
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD
	return Vector3(body.global_position.x, 0.0, body.global_position.z) + dir * 0.9
