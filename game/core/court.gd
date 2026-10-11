class_name Court
extends RefCounted











var center_x: = 0.0
var half_w: = 4.5
var half_l: = 9.0

func configure(cx: float, hw: float, hl: float) -> Court:
	center_x = cx
	half_w = hw
	half_l = hl
	return self





func formation_spot(slot: int, n: int, side: int) -> Vector3:
	if n <= 1:
		return Vector3(center_x, 0.0, side * half_l * 0.45)
	var front_count: = maxi(1, int(n / 2.0))
	var front: = slot < front_count
	var group: = front_count if front else n - front_count
	var idx: = slot if front else slot - front_count
	var frac: = (float(idx) + 0.5) / float(group)
	var x: = center_x + lerpf( - half_w + 1.6, half_w - 1.6, frac) * side
	var z: = 1.8 if front else half_l * 0.65
	return Vector3(x, 0.0, side * z)




func out_of_play(ball_pos: Vector3) -> bool:
	return absf(ball_pos.x - center_x) > half_w + 7.0\
	or absf(ball_pos.z) > half_l + 9.0 or ball_pos.y < -2.0



func line_fault_offender(players: Array) -> Player:
	for p in players:
		var member: Player = p
		if member == null or not member.is_on_floor() or member.knocked():
			continue
		if member.global_position.z * float(member.team_side) < -0.3\
		and absf(member.global_position.x - center_x) < half_w:
			return member
	return null






func allies_of(players: Array, p: Player) -> Array:
	return players.filter( func(o): return o != p and o.team_side == p.team_side)

func opponents_of(players: Array, p: Player) -> Array:
	return players.filter( func(o): return o.team_side != p.team_side)





func quick_set_ready(players: Array, aim: Vector3, hitter: Player) -> bool:
	for p in players:
		var member: Player = p
		if member == hitter or member.team_side != hitter.team_side:
			continue
		if TeamBot.DEBUG_SET:
			print("  [QSR] %s grounded=%s vy=%.2f y=%.2f z=%.2f d=%.2f" % [
				member.name, str(member.grounded()), member.velocity.y, 
				member.global_position.y, member.global_position.z, 
				Vector2(member.global_position.x - aim.x, member.global_position.z - aim.z).length()])
		if member.grounded():
			continue






		if member.velocity.y < -2.5 or member.global_position.y < 0.7\
		or absf(member.global_position.z) > 4.0:
			continue
		if Vector2(member.global_position.x - aim.x, 
			member.global_position.z - aim.z).length() < 2.8:
			return true
	return false
