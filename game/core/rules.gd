class_name Rules
extends RefCounted










const TOUCHES_PER_SIDE: = 3






enum Bar{NONE, DEAD, CONSECUTIVE, THREE_TOUCH, SERVE, TEAM_LOCK}




const HOME_COLOR: = Color(0.35, 1.0, 0.55)
const AWAY_COLOR: = Color(1.0, 0.25, 0.72)

static func side_color(side: int) -> Color:
	return HOME_COLOR if side > 0 else AWAY_COLOR






static var set_swapped: = false



static func half_identity(point_z: float) -> int:
	var court_side: = 1 if point_z >= 0.0 else -1
	return - court_side if set_swapped else court_side


static func half_color(point_z: float) -> Color:
	return side_color(half_identity(point_z))

static func side_name(side: int) -> String:
	return "home" if side > 0 else "away"

static func bar_reason(member: Player, last_toucher: Player, team_size: int, 
		touch_count: int, owner_side: float, phase_dead: bool, 
		serve_crossed: bool, serve_side: int, server: Player, 
		team_lock_side: = 0) -> int:

	if phase_dead:
		return Bar.DEAD


	if member == last_toucher and team_size > 1:
		return Bar.CONSECUTIVE






	if touch_count >= TOUCHES_PER_SIDE and float(member.team_side) == owner_side:
		return Bar.THREE_TOUCH







	if not serve_crossed and member.team_side == serve_side\
	and (member != server or touch_count >= 1):
		return Bar.SERVE


	if team_lock_side != 0 and member.team_side == team_lock_side:
		return Bar.TEAM_LOCK
	return Bar.NONE

static func touch_barred(member: Player, last_toucher: Player, team_size: int, 
		touch_count: int, owner_side: float, phase_dead: bool, 
		serve_crossed: bool, serve_side: int, server: Player, 
		team_lock_side: = 0) -> bool:
	return bar_reason(member, last_toucher, team_size, touch_count, owner_side, 
		phase_dead, serve_crossed, serve_side, server, team_lock_side) != Bar.NONE






static func bar_shows_marker(reason: int) -> bool:
	return reason == Bar.CONSECUTIVE or reason == Bar.THREE_TOUCH



const SERVE_LINE_TOL: = 0.05

static func serve_foot_fault(launch_z: float, half_l: float) -> bool:




	return launch_z < half_l - SERVE_LINE_TOL



const BASE_HALF_W: = 4.5
const BASE_HALF_L: = 9.0
const LINE_HALF_WIDTH: = 0.025

static func ball_in(pos: Vector3, half_w: float, half_l: float, 
		center_x: = 0.0) -> bool:



	var edge_x: = half_w + LINE_HALF_WIDTH * (half_w / BASE_HALF_W) + Ball.PHYS.radius
	var edge_z: = half_l + LINE_HALF_WIDTH * (half_l / BASE_HALF_L) + Ball.PHYS.radius
	return absf(pos.x - center_x) <= edge_x and absf(pos.z) <= edge_z








static func touch_clears_net(kind: int) -> bool:
	return kind == Player.TouchKind.BUMP or kind == Player.TouchKind.SET

static func contact_strength(kind: int, power: float) -> float:
	match kind:
		Player.TouchKind.SPIKE:
			return 0.6 + 0.4 * power
		Player.TouchKind.DUMP:
			return 0.5
		Player.TouchKind.BLOCK:
			return 0.8





		Player.TouchKind.BUMP:
			return 0.25 + 0.5 * power
		Player.TouchKind.SET:
			return 0.25 + 0.45 * power
	return 0.25



static func contact_sound(kind: int, power: float, quiet: = 0.0) -> Dictionary:
	match kind:
		Player.TouchKind.SPIKE:
			return {"n": "spike", "db": lerpf(-6.0, 0.0, power) + quiet, "pt": 1.0}
		Player.TouchKind.DUMP:
			return {"n": "hit_medium", "db": -3.0 + quiet, "pt": 1.0}
		Player.TouchKind.BLOCK:
			return {"n": "block_hard" if power > 0.6 else "block_medium", 
				"db": quiet, "pt": 1.0}





		Player.TouchKind.BUMP:
			return {"n": "hit_soft", "db": lerpf(-5.0, 0.5, power) + quiet, 
				"pt": lerpf(1.06, 0.94, power)}
		Player.TouchKind.SET:
			return {"n": "hit_soft", "db": lerpf(-7.0, -1.0, power) + quiet, 
				"pt": lerpf(1.16, 1.0, power)}
	return {"n": "hit_soft", "db": -4.0 + quiet, "pt": 1.0}



static func contact_fx(fx: Fx, pos: Vector3, strength: float, dir: Vector3, 
		wet: = 0.0, full: = true, kind: = -1, combo_tier: = 0) -> void :



	var heavy: = kind == Player.TouchKind.SPIKE or kind == Player.TouchKind.BLOCK





	var control: = kind == Player.TouchKind.BUMP or kind == Player.TouchKind.SET


	var rim: = Player.combo_color(combo_tier)\
	if combo_tier >= 1 and kind == Player.TouchKind.SPIKE else Color(0, 0, 0, 0)

	if kind == Player.TouchKind.SPIKE and combo_tier >= 3:
		strength *= 1.3
	if full:
		if not control:
			fx.impact(pos, strength, dir, heavy, rim)
	elif not control:

		fx.ring(pos, dir, strength * 0.5, rim)
	fx.burst(pos, strength, dir, wet)
	sweat_spray(fx, pos, strength, wet)





	if full and (kind == Player.TouchKind.SPIKE or control):
		var burst_tier: = combo_tier
		if control and burst_tier < 1:
			burst_tier = 1
		if burst_tier >= 1:
			fx.combo_burst(pos, dir, burst_tier)

static func sweat_spray(fx: Fx, pos: Vector3, strength: float, wet: float) -> void :


	if wet <= 0.05:
		return
	var count: = int(round(wet * (2.0 + strength * 5.0)))
	for i in count:
		fx.sweat(pos + Vector3(randf_range(-0.22, 0.22), 
			randf_range(-0.15, 0.25), randf_range(-0.22, 0.22)))














static func rotation_ring(n: int) -> Array:
	if n <= 1:
		return [0]
	var front_count: = maxi(1, int(n / 2.0))
	var ring: Array = [front_count - 1]
	for i in range(n - 1, front_count - 1, -1):
		ring.append(i)
	for i in range(0, front_count - 1):
		ring.append(i)
	return ring

static func rotated_slot(base_slot: int, n: int, steps: int) -> int:

	if n <= 1 or steps == 0:
		return base_slot
	var ring: = rotation_ring(n)
	var idx: = ring.find(base_slot)
	if idx < 0:
		return base_slot
	return int(ring[(idx + steps) % ring.size()])

static func server_slot(n: int) -> int:


	return 0 if n <= 1 else n - 1



















static func air_bumps(players: Array) -> Array:
	var hits: Array = []
	for i in players.size():
		var a: Player = players[i]
		if a == null or a.knocked():
			continue
		for j in range(i + 1, players.size()):
			var b: Player = players[j]
			if b == null or b.knocked():
				continue
			var a_dive: = a.diving()
			var b_dive: = b.diving()

			var reach: = 1.05 if (a_dive or b_dive) else 0.85
			if a.global_position.distance_to(b.global_position) > reach:
				continue
			if not a_dive and not b_dive\
			and (a.is_on_floor() or b.is_on_floor()):
				continue
			var dir: = a.global_position - b.global_position
			dir.y = 0.0
			dir = dir.normalized() if dir.length() > 0.01 else Vector3.RIGHT


			var a_momentum: = Vector3(b.velocity.x, 0.0, b.velocity.z)
			var b_momentum: = Vector3(a.velocity.x, 0.0, a.velocity.z)
			if a_dive and not b_dive:
				b.knock(b_momentum * 0.8 - dir * 2.0 + Vector3(0, 2.0, 0))
			elif b_dive and not a_dive:
				a.knock(a_momentum * 0.8 + dir * 2.0 + Vector3(0, 2.0, 0))
			else:
				a.knock(a_momentum * 0.8 + dir * 2.0 + Vector3(0, 2.0, 0))
				b.knock(b_momentum * 0.8 - dir * 2.0 + Vector3(0, 2.0, 0))
			hits.append({
				"pos": (a.global_position + b.global_position) * 0.5, 
				"dir": dir, 
			})
	return hits






const NET_GRAZE: = 0.5





static func net_crossing(ball_z: float, prev_side: float) -> Dictionary:
	if absf(ball_z) < NET_GRAZE:
		return {"side": prev_side, "crossed": false}
	var side: = signf(ball_z)
	return {
		"side": side, 
		"crossed": side != 0.0 and prev_side != 0.0 and side != prev_side, 
	}
