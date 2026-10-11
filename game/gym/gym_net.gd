class_name GymNet
extends Node






















const PLAYER_SCENE: = preload("res://game/player/player.tscn")
const RELEASE_AFTER_SET: = 3.0
const HARD_SNAP_DIST: = 1.2
const BALL_GRACE_MS: = 400.0

var gym: Node3D = null
var is_host: = false


var _peer_bodies: = {}
var _peer_msg: = {}
var _peer_ack: = {}
var _peer_edges: = {}
var _peer_pad: = {}
var _gid_of: = {}
var _by_gid: = {}
var _next_gid: = 1
var _cast_hash: = 0
var _state_grp: = 0
var _state_seq: = 0
var _set_over_t: = {}


var client_court_idx: = -1
var _tag_side: = {}
var _my_gid: = 0
var _puppets: = {}



var _puppet_buf: = NetSync.PuppetBuffer.new()
var _in_chan: = NetSync.InputChannel.new()

var _pred: = NetSync.Predictor.new()




var _ball_grace: = 0.0
var _ball_grace_seq: = -1.0
var _ball_err: = Vector3.ZERO
var _ball_host_strikes: = -1.0
var _pred_touch_seen: = 0
var _strike_mutes: = 0
var _wire_emitting: = false

var net_stat_rows: Array = []
var _stats_req_ms: = 0

func setup(scene: Node3D) -> void :
	gym = scene
	is_host = Net.is_host
	if is_host:
		Net.late_joiner.connect(_on_late_joiner)
		Net.peer_left_match.connect(_on_peer_left)
		Net.input_received.connect(_on_peer_input)






		for i in gym._matches.size():
			_bridge_court(i, gym._matches[i])

		Net.team_of = func(pid: int) -> Variant:
			var body: Player = gym.player if pid == 1 else _peer_bodies.get(pid)
			if body == null:
				return 0
			var court: = _court_of(body)
			if court == null:
				return 0
			return int((court.humans.get(body, {}) as Dictionary).get("side", 0))



		Net.room_of = func(pid: int) -> Variant:
			var body: Player = gym.player if pid == 1 else _peer_bodies.get(pid)
			if body == null:
				return 0
			var court: = _court_of(body)
			return 0 if court == null else gym._matches.find(court) + 2

		for pid in Net.players:
			if pid != 1:
				_spawn_peer(pid)
	else:
		Net.gym_state_received.connect(_on_state)
		Net.event_received.connect(_on_event)
		Net.notify_match_ready()


		Net.send_up("gcast?", {})




		gym.player.sim_authority = false


		Net.session_ended.connect(_on_session_over)







		for ci in gym._matches.size():
			(gym._matches[ci] as GymMatch).ball.struck.connect(
				func(_p: Vector3, _w: float, _k: int):
					if _wire_emitting or ci != client_court_idx:
						return
					_strike_mutes += 1
					_ball_grace = float(Time.get_ticks_msec()) + BALL_GRACE_MS
					_ball_grace_seq = _ball_host_strikes)
	if is_host:
		Net.up_event_received.connect( func(id: int, kind: String, 
			args: Dictionary):
			if kind == "gcast?":
				_broadcast_cast()
			elif kind == "gstats?":

				var rb: Player = _peer_bodies.get(id)
				var rc: GymMatch = _court_of(rb) if rb != null else null
				if rc != null:
					Net.send_event("gst", {"c": gym._matches.find(rc), 
						"l": rc.stat_rows()})
			elif kind == "gco":
				var body: Player = _peer_bodies.get(id)
				if body != null:
					body.show_callout(Net.ev_i(args, "i", 0))
					Net.send_event("gco", 
						{"g": _gid(body), "i": Net.ev_i(args, "i", 0)}))



func remote_bodies() -> Array:
	return _peer_bodies.values() if is_host else _puppets.values()

func _exit_tree() -> void :
	if is_host:
		Net.team_of = Callable()
		Net.room_of = Callable()

func _bridge_court(i: int, mv: Variant) -> void :
	var m: GymMatch = mv
	m.verdict_called.connect( func(pos: Vector3, text: String, winner: int):
		Net.send_event("gv", {"c": i, "p": pos, "t": text, "w": winner}))
	m.whistle_at.connect( func(reason: String, pos: Vector3):
		Net.send_event("gw", {"c": i, "p": pos, "t": reason}))
	m.toss_at.connect( func(pos: Vector3):
		Net.send_event("gt", {"c": i, "p": pos}))
	m.thumped_at.connect( func(pos: Vector3, strength: float):
		Net.send_event("gth", {"c": i, "p": pos, "s": strength}))
	m.launched_at.connect( func(pos: Vector3, charge: float):
		Net.send_event("gl", {"c": i, "p": pos, "s": charge}))
	m.block_broken_at.connect( func(pos: Vector3, who: Player):
		Net.send_event("gb", {"c": i, "p": pos, "g": _gid(who)}))
	m.flair_at.connect( func(kind: String, who: Player):
		Net.send_event("gf", {"c": i, "k": kind, "g": _gid(who)}))
	m.voice_called.connect( func(bank: String, pos: Vector3, pitch: float):
		Net.send_event("gvo", {"c": i, "b": bank, "p": pos, "h": pitch}))
	m.rally_ended.connect( func(winner_side: int):


		Net.send_event("gre", {"c": i, "w": winner_side, 
			"r": m.last_end_reason, "k": m.kill_power(winner_side)}))
	m.ball.struck.connect( func(pos: Vector3, power: float, kind: int):



		Net.send_event("gs", {"c": i, "p": pos, "s": power, "k": kind, 

			"hs": m.ball.hitstop_left, 
			"g": _gid(m.ball.strike_source)}))

func _on_session_over(reason: String) -> void :


	if reason == "left" or reason == "restart":
		return
	GameConfig.lobby_notice = "the park closed: %s" % reason
	GameConfig.goto_scene("res://game/ui/menu.tscn")


func relay_callout(idx: int) -> void :
	if is_host:
		gym.player.show_callout(idx)
		Net.send_event("gco", {"g": _gid(gym.player), "i": idx})
	else:
		Net.send_up("gco", {"i": idx})



func _on_late_joiner(id: int) -> void :
	Net.send_join_gym(id)
	_spawn_peer(id)

func _spawn_peer(id: int) -> void :
	if _peer_bodies.has(id):
		return
	var body: Player = PLAYER_SCENE.instantiate()
	gym.add_child(body)



	body.global_position = gym.door_spawn(_peer_bodies.size() + 1)
	body.team_side = 1
	var cfg_d: Dictionary = (Net.players.get(id, {}) as Dictionary).get("cfg", {})
	var look: = CharacterConfig.from_dict(cfg_d) if not cfg_d.is_empty()\
	else GameConfig.bot_character(1, id % 6)
	body.set_character(look.gym_look(), look.gym_kit())
	body.set_display_name(String((Net.players.get(id, {}) as Dictionary)\
	.get("name", "guest")))
	body.set_dev_tag(DevBadge.peer_tier(id))
	body.charge_ui_enabled = false
	body.indicator_enabled = false
	_peer_bodies[id] = body
	_peer_edges[id] = {"jr": 0, "cr": 0, "sr": 0, "dv": 0, "sv": 0}
	_broadcast_cast()

func _on_peer_left(id: int) -> void :
	var body: Player = _peer_bodies.get(id)
	if body == null:
		return
	for m in gym._matches:
		if (m as GymMatch).humans.has(body):
			(m as GymMatch).release_member(body)
	_peer_bodies.erase(id)
	_peer_msg.erase(id)
	_peer_ack.erase(id)
	_peer_edges.erase(id)
	_peer_pad.erase(id)
	var gid: int = _gid_of.get(body, 0)
	_gid_of.erase(body)
	_by_gid.erase(gid)
	body.queue_free()
	_broadcast_cast()

func _on_peer_input(peer_id: int, data: Dictionary) -> void :
	_peer_msg[peer_id] = data

func _decode(peer_id: int) -> PlayerInput:
	return NetSync.decode_input_fields(_peer_msg.get(peer_id, {}), 
		_peer_edges[peer_id])

func host_tick(delta: float) -> void :
	for pid in _peer_bodies:
		var body: Player = _peer_bodies[pid]
		var input: = _decode(pid)



		_peer_ack[pid] = int((_peer_msg.get(pid, {}) as Dictionary).get("s", 0))
		var court: = _court_of(body)
		if court != null:
			court.set_member_input(body, input)
		else:
			_peer_pad_logic(pid, body)
		body.simulate(input, delta)




		if court != null:
			gym.contain_in_court(body, court)
		else:
			gym.keep_off_courts(body)
	_release_finished_sets(delta)
	_stream_state()

func _court_of(body: Player) -> GymMatch:
	for m in gym._matches:
		if (m as GymMatch).humans.has(body):
			return m
	return null



func _court_of_any(body: Player) -> GymMatch:
	for m in gym._matches:
		if (m as GymMatch)._all_players.has(body):
			return m
	return null

func _peer_pad_logic(pid: int, body: Player) -> void :

	var standing = null
	for pad in gym._pads:
		var flat: = Vector2(body.global_position.x - pad.pos.x, 
			body.global_position.z - pad.pos.z)
		if flat.length() < 1.2:
			standing = pad
			break
	var queued = _peer_pad.get(pid)
	if standing != null:
		if queued != null and queued != standing:
			queued.match .cancel_join(body)
		_peer_pad[pid] = standing
		var look_d: Dictionary = (Net.players.get(pid, {}) as Dictionary)\
		.get("cfg", {})
		standing.match .request_join(body, standing.side, standing.slot, 
			String((Net.players.get(pid, {}) as Dictionary).get("name", "guest")), 
			CharacterConfig.from_dict(look_d) if not look_d.is_empty() else null)
	elif queued != null:
		queued.match .cancel_join(body)
		_peer_pad.erase(pid)

func _release_finished_sets(delta: float) -> void :


	for m in gym._matches:
		var court: GymMatch = m
		if not court.set_over:
			_set_over_t.erase(court)
			continue
		_set_over_t[court] = float(_set_over_t.get(court, 0.0)) + delta
		if float(_set_over_t[court]) < RELEASE_AFTER_SET:
			continue
		for body in court.humans.keys():
			if body != gym.player:
				court.release_member(body)



func _all_bodies() -> Array:
	var out: Array = [gym.player]
	for pid in _peer_bodies:
		out.append(_peer_bodies[pid])
	for m in gym._matches:
		for p in (m as GymMatch)._all_players:
			if not out.has(p):
				out.append(p)
	return out

func _gid(body: Player) -> int:
	if not _gid_of.has(body):
		_gid_of[body] = _next_gid
		_by_gid[_next_gid] = body
		_next_gid += 1
	return _gid_of[body]

func _broadcast_cast() -> void :
	var cast: Array = []
	for body in _all_bodies():
		if not is_instance_valid(body):
			continue
		var pid: = 0
		for id in _peer_bodies:
			if _peer_bodies[id] == body:
				pid = id
		if body == gym.player:
			pid = 1
		cast.append({"g": _gid(body), "n": body.display_name(), 
			"p": pid, "c": _look_of(body, pid)})
	Net.send_event("gcast", {"l": cast})

func _look_of(body: Player, pid: int) -> Dictionary:
	if pid == 1:
		return GameConfig.character.to_dict() if GameConfig.character != null else {}
	if pid > 0:
		return (Net.players.get(pid, {}) as Dictionary).get("cfg", {})


	var court: = _court_of_any(body)
	var salt: int = court.court_salt if court != null else 0
	return GameConfig.bot_character(body.team_side, 
		int(court._slots.get(body, 0)) if court != null else 0, salt).to_dict()

func _stream_state() -> void :
	_state_seq += 1
	_state_grp = 1 - _state_grp
	var bodies: Array = []
	var live: = _all_bodies()
	var member_hash: = 0
	for body in live:
		if not is_instance_valid(body):
			continue
		var g: = _gid(body)
		member_hash ^= hash(g * 2654435761)
		if g % 2 == _state_grp:
			bodies.append([g, body.net_capture()])




	if member_hash != _cast_hash:
		_cast_hash = member_hash
		_prune_gids(live)
		_broadcast_cast()
	var balls: Array = []
	for i in gym._matches.size():
		var b: Ball = (gym._matches[i] as GymMatch).ball
		if b != null:
			balls.append([i, PackedFloat32Array([b.global_position.x, 
				b.global_position.y, b.global_position.z, 
				b.vel.x, b.vel.y, b.vel.z, 
				1.0 if b.frozen else 0.0, b.curve, 
				float(b.strike_seq)])])
	var courts: Array = []
	for i in gym._matches.size():
		var m: GymMatch = gym._matches[i]
		var members: Array = []
		for body in m.humans:
			members.append([_gid(body), int(m.humans[body].side)])
		var srv: Player = m._rally.server
		var lt: Player = m._last_toucher
		courts.append([i, int(m.scores.get(1, 0)), int(m.scores.get(-1, 0)), 
			int(m._phase), members, 
			_gid(srv) if srv != null and is_instance_valid(srv) else 0, 
			int(clampf(m._rally.serve_clock, 0.0, 250.0)), 
			m.current_sweat, 
			mini(m._touch_count, 255), 
			(1 if m._serve_done else 0) | ((1 if m._serve_crossed else 0) << 1), 
			_gid(lt) if lt != null and is_instance_valid(lt) else 0])

	var pads: Array = []
	for i in gym._pads.size():
		var pad = gym._pads[i]
		var claimed: bool = gym._queued == pad or (pad.match as GymMatch).human_on(pad.side, pad.slot)
		for pp in _peer_pad.values():
			if pp == pad:
				claimed = true
		if claimed:
			pads.append(i)
	Net.send_gym_state({"sq": _state_seq, "grp": _state_grp, 
		"bodies": bodies, "balls": balls, "courts": courts, "pads": pads, 
		"ack": _peer_ack.duplicate()})

func _prune_gids(live: Array) -> void :
	for body in _gid_of.keys():
		if not is_instance_valid(body) or not live.has(body):
			_by_gid.erase(_gid_of[body])
			_gid_of.erase(body)




func request_stats() -> void :
	var now: = Time.get_ticks_msec()
	if now - _stats_req_ms < 500:
		return
	_stats_req_ms = now
	Net.send_up("gstats?", {})

func client_tick(input: PlayerInput, delta: float) -> void :

	Net.send_input(_in_chan.encode(input))




	_pred.hard_snap = HARD_SNAP_DIST
	_pred.tick(gym.player, _in_chan.seq, delta)



func _body_of_gid(g: int) -> Player:
	if g == _my_gid:
		return gym.player
	return _puppets.get(g)

func _on_event(kind: String, args: Dictionary) -> void :


	if kind == "regroup":


		Net.end_match()
		GameConfig.goto_scene("res://game/ui/menu.tscn")
		return
	match kind:
		"gv", "gw", "gt", "gth", "gl", "gb", "gf", "gvo", "gre", "gs":
			var m: GymMatch = null
			var c: = Net.ev_i(args, "c", -1)
			if c >= 0 and c < gym._matches.size():
				m = gym._matches[c]
			if m == null:
				return
			match kind:
				"gv":
					m.verdict_called.emit(Net.ev_v3(args, "p"), Net.ev_s(args, "t", "", 64), 
						Net.ev_i(args, "w", 0))
				"gw":
					m.whistle_at.emit(Net.ev_s(args, "t", "", 64), Net.ev_v3(args, "p"))
				"gt":
					m.toss_at.emit(Net.ev_v3(args, "p"))
				"gth":
					m.thumped_at.emit(Net.ev_v3(args, "p"), Net.ev_f(args, "s"))
				"gl":
					m.launched_at.emit(Net.ev_v3(args, "p"), Net.ev_f(args, "s"))
				"gb":
					var wb: = _body_of_gid(Net.ev_i(args, "g", 0))
					if wb != null:
						m.block_broken_at.emit(Net.ev_v3(args, "p"), wb)
				"gf":
					var wf: = _body_of_gid(Net.ev_i(args, "g", 0))
					if wf != null:
						m.flair_at.emit(Net.ev_s(args, "k", "", 32), wf)
				"gvo":
					m.voice_called.emit(Net.ev_s(args, "b", "", 32), Net.ev_v3(args, "p"), Net.ev_f(args, "h"))
				"gre":


					m.last_end_reason = Net.ev_s(args, "r", "", 64)
					m._last_kill_power = Net.ev_f(args, "k", 0.0)
					m.rally_ended.emit(clampi(Net.ev_i(args, "w"), -1, 1))
					if c == client_court_idx:


						_ball_grace = 0.0
						_strike_mutes = 0
				"gs":
					var accepted_gid: = Net.ev_i(args, "g", 0)
					if c == client_court_idx and accepted_gid != 0:
						var own_confirmed: = accepted_gid == _my_gid



						if m.ball != null and m.ball.net_puppet:
							m.ball.hitstop_left = maxf(m.ball.hitstop_left, 
								Net.ev_f(args, "hs", 0.0))
						if own_confirmed and m.ball.net_puppet:
							gym.player.touch_seq += 1
						elif not own_confirmed and gym.reach_marker != null:
							gym.reach_marker.authoritative_touch(false)
						if own_confirmed:



							gym.player.present_authoritative_touch(
								Net.ev_i(args, "k", 0) as Player.TouchKind, 
								Net.ev_f(args, "hs", 0.0))
							if Net.ev_i(args, "k", 0) == Player.TouchKind.SPIKE\
							and Net.ev_f(args, "hs", 0.0) > 0.0:
								gym.camera_rig.shake(minf(0.12
									+ Net.ev_f(args, "hs", 0.0) * 2.0, 0.4))
					if c == client_court_idx and _strike_mutes > 0\
					and accepted_gid == _my_gid:





						_strike_mutes -= 1
						_ball_grace = 0.0
					else:
						_wire_emitting = true
						m.ball.struck.emit(Net.ev_v3(args, "p"), float(Net.ev_f(args, "s")), 
							int(Net.ev_s(args, "k")))
						_wire_emitting = false
						m.ball.pulse()
			return
		"gco":
			var body: = _body_of_gid(Net.ev_i(args, "g", 0))
			if body != null and body != gym.player:
				body.show_callout(Net.ev_i(args, "i", 0), false)
			return
		"gst":


			if Net.ev_i(args, "c", -1) == client_court_idx:
				net_stat_rows = Net.ev_arr(args, "l", 32)
			return
	if kind != "gcast":
		return
	var seen: = {}
	for entry in Net.ev_arr(args, "l", Net.MAX_PLAYERS * 2):
		if not (entry is Dictionary):
			continue
		var g: = Net.ev_i(entry, "g")
		seen[g] = true
		if Net.ev_i(entry, "p") == multiplayer.get_unique_id():
			_my_gid = g
			continue
		if _puppets.has(g):
			continue
		var body: Player = PLAYER_SCENE.instantiate()
		body.net_puppet = true
		gym.add_child(body)
		body.charge_ui_enabled = false
		body.indicator_enabled = false
		var cfg_v: Variant = entry.get("c", {})
		var cfg_d: Dictionary = cfg_v if cfg_v is Dictionary else {}
		if not cfg_d.is_empty():
			var look: = CharacterConfig.from_dict(cfg_d)
			body.set_character(look.gym_look(), look.gym_kit())
		body.set_display_name(String(entry.get("n", "")))
		body.set_dev_tag(DevBadge.peer_tier(int(entry.get("p", 0))))
		_puppets[g] = body
	for g in _puppets.keys():
		if not seen.has(g):
			(_puppets[g] as Player).queue_free()
			_puppets.erase(g)
			_puppet_buf.forget(g)

func _on_state(d: Dictionary) -> void :
	var now: = float(Time.get_ticks_msec())
	for pair in d.get("bodies", []):
		var g: = int(pair[0])
		var st: PackedFloat32Array = pair[1]
		if g == _my_gid:
			_reconcile(st, d.get("ack", {}))
			continue
		_puppet_buf.add(g, st, now)
	for pair in d.get("balls", []):
		var idx: = int(pair[0])
		if idx >= gym._matches.size():
			continue
		var b: Ball = (gym._matches[idx] as GymMatch).ball
		if b == null:
			continue
		var s: PackedFloat32Array = pair[1]
		if idx == client_court_idx:




			_reconcile_ball(b, s)
			continue





		b.frozen = s[6] > 0.5
		b.vel = Vector3(s[3], s[4], s[5])
		var target: = Vector3(s[0], s[1], s[2])
		if b.frozen or b.global_position.distance_to(target) > 2.0:
			b.global_position = target
			b.reset_physics_interpolation()
		else:
			b.global_position = b.global_position.lerp(target, 0.35)
	var was_court: = client_court_idx
	client_court_idx = -1
	var on_court: = {}
	var court_sweat: = {}
	for row in d.get("courts", []):
		var idx: = int(row[0])
		if idx >= gym._matches.size():
			continue
		var m: GymMatch = gym._matches[idx]
		m.scores = {1: int(row[1]), -1: int(row[2])}
		m.net_phase = int(row[3])
		if row.size() > 6:
			m.net_srv_gid = int(row[5])
			m.net_serve_clock = int(row[6])
			m.net_srv_is_me = m.net_srv_gid != 0 and m.net_srv_gid == _my_gid
			var sb: = _body_of_gid(m.net_srv_gid)
			m.net_srv_name = sb.display_name() if sb != null and is_instance_valid(sb) else "someone"








		if row.size() > 6:
			m._phase = int(row[3]) as GymMatch.Phase
			m._rally.live = int(row[3]) == GymMatch.Phase.LIVE
			m._rally.serve_clock = float(m.net_serve_clock)
			m._server = _body_of_gid(m.net_srv_gid)
		if row.size() > 10:
			m._rally.touch_count = int(row[8])
			m._rally.serve_done = (int(row[9]) & 1) == 1
			m._rally.serve_crossed = ((int(row[9]) >> 1) & 1) == 1
			m._last_toucher = _body_of_gid(int(row[10]))



		var sweat: = float(row[7]) if row.size() > 7 else 0.0
		m.net_apply_sweat(sweat)
		court_sweat[idx] = sweat


		for pair in (row[4] if row.size() > 4 else []):
			var g: = int(pair[0])
			var side: = int(pair[1])
			on_court[g] = true
			if g == _my_gid:
				client_court_idx = idx
				gym.player.team_side = side
				gym.player.set_tag_color(Rules.side_color(side))
				gym.player.sweat = sweat
			else:
				var mb: = _body_of_gid(g)
				if mb != null:
					mb.sweat = sweat


					mb.team_side = side
					if _tag_side.get(g, 99) != side:
						_tag_side[g] = side
						mb.set_tag_color(Rules.side_color(side))

	for g in _tag_side.keys():
		if not on_court.has(g):
			_tag_side.erase(g)
			var mb2: = _body_of_gid(g)
			if mb2 != null:
				mb2.set_tag_color(Rules.side_color(1))
	gym.net_claimed_pads = d.get("pads", [])



	for g in _puppets:
		var pb: Player = _puppets[g]
		if not is_instance_valid(pb) or on_court.has(int(g)):
			continue
		for idx in court_sweat:
			var cm: GymMatch = gym._matches[idx]
			if absf(pb.global_position.x - cm.cx) < cm.half_w + 3.0\
			and absf(pb.global_position.z) < cm.half_l + 3.0:
				pb.sweat = float(court_sweat[idx])
				break
	if client_court_idx != was_court:


		_ball_grace = 0.0
		_ball_err = Vector3.ZERO
		_ball_host_strikes = -1.0
		_strike_mutes = 0




func client_frame(delta: float) -> void :


	var now: = float(Time.get_ticks_msec())
	for g in _puppets:
		var body: Player = _puppets[g]
		if is_instance_valid(body):
			_puppet_buf.drive(g, body, now, delta)

func _reconcile_ball(b: Ball, s: PackedFloat32Array) -> void :







	var was_frozen: = b.frozen
	b.frozen = s[6] > 0.5
	var host_strikes: = s[8] if s.size() > 8 else -1.0
	b.curve = s[7]
	var host_pos: = Vector3(s[0], s[1], s[2])
	if b.frozen:

		_ball_grace = 0.0
		_ball_host_strikes = host_strikes
		b.global_position = host_pos
		b.vel = Vector3.ZERO
		return
	if _ball_grace > 0.0:
		if host_strikes >= 0.0 and _ball_grace_seq >= 0.0\
		and host_strikes != _ball_grace_seq:
			_ball_grace = 0.0
		elif float(Time.get_ticks_msec()) > _ball_grace:
			_ball_grace = 0.0
			_strike_mutes = 0
		else:
			_ball_host_strikes = host_strikes
			return
	_ball_host_strikes = host_strikes
	b.vel = Vector3(s[3], s[4], s[5])
	if was_frozen or b.global_position.distance_to(host_pos) > 1.5:
		b.global_position = host_pos
		b.reset_physics_interpolation()
	else:
		b.global_position = b.global_position.lerp(host_pos, 0.35)
	_ball_err = Vector3.ZERO

func _reconcile(st: PackedFloat32Array, acks: Dictionary) -> void :







	if client_court_idx >= 0:
		gym.player.touch_barred = ((int(st[11]) >> 10) & 1) == 1
		gym.player.touch_barred_self = ((int(st[11]) >> 14) & 1) == 1
	var ack: = int(acks.get(multiplayer.get_unique_id(), 0))
	var host_pos: = Vector3(st[0], st[1], st[2])
	var err_v: Variant = _pred.measure(ack, host_pos)
	if err_v == null:
		return
	var err: Vector3 = err_v
	var host_knocked: bool = st[13] > 0.0
	if err.length() > HARD_SNAP_DIST\
	or (host_knocked and not gym.player.knocked()):
		gym.player.net_force_state(st)
		gym.player.reset_physics_interpolation()
		_pred.reset()
	else:
		_pred.commit(err, ack)
