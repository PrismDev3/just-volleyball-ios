class_name NetSync

















class InputChannel:
	extends RefCounted
	var seq: = 0










	var gen: = 0
	var _counts: = {"jr": 0, "cr": 0, "sr": 0, "dv": 0, "sv": 0}
	var _sent: Array = []




	func encode(input: PlayerInput) -> Dictionary:
		seq += 1
		if input.jump_released:
			_counts.jr += 1
		if input.contact_released:
			_counts.cr += 1
		if input.set_released:
			_counts.sr += 1
		if input.dive_pressed:
			_counts.dv += 1
		if input.serve_pressed:
			_counts.sv += 1
		var msg: = {"s": seq, "g": gen, "m": input.move, "mr": input.move_raw, "a": input.aim, 
			"jh": input.jump_held, "cp": input.contact_pressed, 
			"st": input.strafe_held, 
			"sh": input.set_pressed, 
			"jr": _counts.jr, "cr": _counts.cr, "sr": _counts.sr, 
			"dv": _counts.dv, "sv": _counts.sv}
		if input.dive_pressed:


			msg["dd"] = input.dive_dir
			msg["ds"] = input.dive_side
		_sent.append(msg)
		while _sent.size() > 3:
			_sent.pop_front()
		var packet: = msg.duplicate()
		if _sent.size() > 1:
			packet["r"] = _sent.slice(0, _sent.size() - 1)
		return packet





static func decode_input_fields(msg: Dictionary, seen: Dictionary) -> PlayerInput:
	var input: = PlayerInput.new()
	if msg.is_empty():
		return input







	var mv: Variant = msg.get("m", Vector2.ZERO)
	if mv is Vector2 and is_finite(mv.x) and is_finite(mv.y):
		input.move = (mv as Vector2).limit_length(1.0)
	else:
		input.move = Vector2.ZERO






	var mvr: Variant = msg.get("mr", Vector2.ZERO)
	if mvr is Vector2 and is_finite(mvr.x) and is_finite(mvr.y):
		input.move_raw = (mvr as Vector2).limit_length(1.0)
	else:
		input.move_raw = Vector2.ZERO
	var am: Variant = msg.get("a", Vector3.ZERO)
	if am is Vector3 and (am as Vector3).is_finite():
		input.aim = am
	else:
		input.aim = Vector3.ZERO
	input.jump_held = msg.get("jh", false)
	input.contact_pressed = msg.get("cp", false)
	input.set_pressed = msg.get("sh", false)
	input.strafe_held = msg.get("st", false)
	input.jump_released = Net.ni(msg.get("jr", 0)) > int(seen.jr)
	input.contact_released = Net.ni(msg.get("cr", 0)) > int(seen.cr)
	input.set_released = Net.ni(msg.get("sr", 0)) > int(seen.get("sr", 0))
	input.dive_pressed = Net.ni(msg.get("dv", 0)) > int(seen.dv)


	var dd: Variant = msg.get("dd", Vector2.ZERO)
	if input.dive_pressed and dd is Vector2 and is_finite(dd.x) and is_finite(dd.y):
		input.dive_dir = (dd as Vector2).limit_length(1.0)
	var ds: = Net.ni(msg.get("ds", -1), -1)
	input.dive_side = ds if ds >= 0 and ds <= 2 else -1
	input.serve_pressed = Net.ni(msg.get("sv", 0)) > int(seen.sv)
	seen.jr = msg.get("jr", 0)
	seen.cr = msg.get("cr", 0)
	seen.sr = msg.get("sr", 0)
	seen.dv = msg.get("dv", 0)
	seen.sv = msg.get("sv", 0)
	return input
















class Predictor:
	extends RefCounted
	var hard_snap: = 1.2
	var err: = Vector3.ZERO
	var _history: = {}
	var _shift: = Vector3.ZERO





	func tick(body: Node3D, seq: int, delta: float) -> void :
		var err_rate: = lerpf(3.0, 12.0, 
			clampf(err.length() / hard_snap, 0.0, 1.0))
		var fix: = err * minf(1.0, delta * err_rate)
		body.global_position += fix
		err -= fix
		_shift += fix
		_history[seq] = body.global_position - _shift
		if _history.size() > 256:
			_history.erase(_history.keys().min())





	func measure(ack: int, host_pos: Vector3) -> Variant:
		var recorded: Variant = _history.get(ack)
		if recorded == null:
			return null
		return host_pos - (recorded + _shift)

	func commit(e: Vector3, ack: int) -> void :
		err = e

		for k in _history.keys():
			if int(k) < ack:
				_history.erase(k)

	func reset() -> void :
		_history.clear()
		_shift = Vector3.ZERO
		err = Vector3.ZERO








static func interp_world(buf: Array, render_at: float, bodies: Array, 
		stride: int, skip: Callable, extrapolate_max: float, 
		hard: bool) -> void :
	if buf.is_empty():
		return
	var older: Dictionary = buf[0]
	var newer: Dictionary = buf[buf.size() - 1]
	for i in buf.size():
		if float(buf[i].hm) <= render_at:
			older = buf[i]
			newer = buf[mini(i + 1, buf.size() - 1)]
	var span: = float(newer.hm) - float(older.hm)
	var alpha: = clampf((render_at - float(older.hm)) / span, 0.0, 1.0)\
	if span > 0.0 else 1.0
	var over: = clampf((render_at - float(newer.hm)) / 1000.0, 0.0, 
		extrapolate_max)
	var a: Dictionary = older.d
	var b: Dictionary = newer.d
	if hard:
		alpha = 1.0
		over = 0.0
	for i in bodies.size():
		var body: Player = bodies[i]
		if skip.call(body):
			continue
		var sb: = _slice(b.p, i, stride)
		if sb.is_empty():
			continue
		var sa: = _slice(a.p, i, stride)
		if sa.is_empty():
			sa = sb
		var pos: = Vector3(sa[0], sa[1], sa[2]).lerp(
			Vector3(sb[0], sb[1], sb[2]), alpha)




		var charging_still: = sb.size() > 17 and (int(sb[11]) & 4) != 0 and sb[17] > 0.02
		if over > 0.0 and not charging_still:
			pos += Vector3(sb[3], sb[4], sb[5]) * over
		body.net_apply(sb, pos)
		if hard:
			body.reset_physics_interpolation()

static func _slice(flat: PackedFloat32Array, idx: int, 
		stride: int) -> PackedFloat32Array:
	var base: = idx * stride
	if idx < 0 or base + stride > flat.size():
		return PackedFloat32Array()
	return flat.slice(base, base + stride)


class PuppetBuffer:
	extends RefCounted





	var render_delay_ms: = 160.0
	var snap_dist: = 3.0
	var _max: = 12
	var _samples: = {}

	func add(id: int, st: PackedFloat32Array, now_ms: float) -> void :
		if st.size() < Player.NET_FLOATS:
			return
		var ring: Array = _samples.get(id, [])
		ring.append({"t": now_ms, "st": st})
		while ring.size() > _max:
			ring.pop_front()
		_samples[id] = ring

	func forget(id: int) -> void :
		_samples.erase(id)





	func drive(id: int, body: Player, now_ms: float, delta: float) -> void :
		var ring: Array = _samples.get(id, [])
		if ring.is_empty():
			return
		var render_at: = now_ms - render_delay_ms
		var a: Dictionary = ring[0]
		var b: Dictionary = ring[ring.size() - 1]
		for i in ring.size():
			if float(ring[i].t) <= render_at:
				a = ring[i]
				b = ring[mini(i + 1, ring.size() - 1)]
		var st: PackedFloat32Array = b.st
		var pos: = Vector3(st[0], st[1], st[2])
		var span: = float(b.t) - float(a.t)
		if span > 1.0:
			var alpha: = clampf((render_at - float(a.t)) / span, 0.0, 1.0)
			var ast: PackedFloat32Array = a.st
			pos = Vector3(ast[0], ast[1], ast[2]).lerp(pos, alpha)


		if body.global_position.distance_to(pos) > snap_dist:
			body.reset_physics_interpolation()
		body.net_apply(st, pos)
		body.puppet_tick(delta)








class BallBuffer:
	extends RefCounted
	const GRAVITY: = 11.0
	var render_delay_ms: = 110.0
	var snap_dist: = 3.0
	var _max: = 12
	var _samples: = {}

	func add(id: int, st: PackedFloat32Array, now_ms: float) -> void :
		if st.size() < 7:
			return
		var ring: Array = _samples.get(id, [])
		ring.append({"t": now_ms, "st": st})
		while ring.size() > _max:
			ring.pop_front()
		_samples[id] = ring

	func forget(id: int) -> void :
		_samples.erase(id)

	func drive(id: int, ball: Ball, now_ms: float, _delta: float) -> void :
		var ring: Array = _samples.get(id, [])
		if ring.is_empty():
			return
		var render_at: = now_ms - render_delay_ms
		var a: Dictionary = ring[0]
		var b: Dictionary = ring[ring.size() - 1]
		for i in ring.size():
			if float(ring[i].t) <= render_at:
				a = ring[i]
				b = ring[mini(i + 1, ring.size() - 1)]
		var newest: PackedFloat32Array = b.st
		var pos: Vector3
		var span: = float(b.t) - float(a.t)
		if span > 1.0:



			var alpha: = clampf((render_at - float(a.t)) / span, 0.0, 1.0)
			var ta: = (render_at - float(a.t)) / 1000.0
			var tb: = (render_at - float(b.t)) / 1000.0
			pos = _reckon(a.st, ta).lerp(_reckon(newest, tb), alpha)
		else:

			pos = _reckon(newest, (render_at - float(b.t)) / 1000.0)
		ball.net_apply(newest)
		if ball.global_position.distance_to(pos) > snap_dist:
			ball.reset_physics_interpolation()
		ball.global_position = pos



	func _reckon(st: PackedFloat32Array, dt: float) -> Vector3:
		var p: = Vector3(st[0], st[1], st[2])
		if st.size() >= 7 and st[6] > 0.5:
			return p
		var v: = Vector3(st[3], st[4], st[5])
		return p + v * dt + Vector3(0.0, -0.5 * GRAVITY * dt * dt, 0.0)
