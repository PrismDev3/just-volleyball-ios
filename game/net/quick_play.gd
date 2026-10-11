class_name QuickPlay
extends Node















signal status(text: String)
signal failed(reason: String)
signal locked



var search_max: = 90.0



var soft_fill_after: = 15.0



var form_max: = 90.0
const SEAT_WAIT: = 4.0


const GROWTH_FLOOR: = 8.0
const SCAN_WINDOW: = 0.8
const SCAN_EVERY: = 4.0
const BACKFILL_AFTER: = 6.0

const LAN_PORT_BASE: = 28970
const LAN_PORTS: = 8







const REGION_TIERS: = [
	{"t": 0.0, "ceil": 39, "name": "near"}, 
	{"t": 18.0, "ceil": 70, "name": "medium"}, 
	{"t": 45.0, "ceil": 90, "name": "far"}, 
]

enum State{IDLE, SEARCHING, FORMING, LOCKED}



static var trace: = "--quick-log" in OS.get_cmdline_user_args()

static func qlog(msg: String) -> void :
	if trace:
		print("[quick %d] %s" % [Time.get_ticks_msec(), msg])

var state: = State.IDLE
var modes: Array = []
var fresh_only: = false




var party_block: Array = []



var _seeker_base: = 1


var _pending_fold: = {}
var _fold_delay: = 0.0








const FOLD_GRACE: = 8.0
const FOLD_UNKNOWN_HOLD: = 2.0




const EMPTY_FOLD_GIVEUP: = 10.0




const HOST_LINE_STALE: = 25.0
var _seen_members: = {}
var _fold_seen: = {}

var _t: = 0.0
var _scan_t: = 0.0
var _scan_open: = 0.0
var _sid: = 0
var _best_reply: = {}
var _best_backfill: = {}
var _listener: PacketPeerUDP = null
var _query: PacketPeerUDP = null
var _am_seeker: = false






var _use_steam: = false



var force_lan: = false





var _isect: Array = []
var _lock_t: = 0.0
var _form_t: = 0.0
var _last_humans: = 0
var _peak_humans: = 0
var _pushed: = ""
var _empty_t: = 0.0
var _stale_t: = 0.0

func begin(want_modes: Array, fresh: = false, seeker: = false) -> void :
	if state != State.IDLE or want_modes.is_empty():
		return
	modes = want_modes.duplicate()
	fresh_only = fresh
	_sid = randi()
	_t = 0.0
	Net.quick_queue = true
	_use_steam = Net.steam_transport_available() and not force_lan
	qlog("begin modes=%s seeker=%s steam=%s players=%d sid=%d" % [str(modes), 
		str(seeker), str(_use_steam), Net.players.size(), _sid])
	if not Net.quick_status.is_connected(_on_quick_status):
		Net.quick_status.connect(_on_quick_status)
	if _use_steam and not Net.steam_lobbies.is_connected(_on_steam_rows):
		Net.steam_lobbies.connect(_on_steam_rows)
	if seeker:




		_am_seeker = true
		_isect = modes.duplicate()
		_last_humans = Net.players.size()
		_peak_humans = Net.players.size()
		_seeker_base = Net.players.size()


		var missing: = maxi(0, 2 * best_mode(_last_humans) - _last_humans)
		_lock_t = soft_fill_after + SEAT_WAIT * missing
		if _use_steam:
			Net.steam_quick_meta(_csv(_isect), Net.players.size(), false)




			Net.quick_seek_visible(true)
		else:
			_advertise_start()
			_query = PacketPeerUDP.new()
			_query.set_broadcast_enabled(true)
		_scan_t = SCAN_EVERY
		state = State.SEARCHING
		return
	_scan_t = SCAN_EVERY
	state = State.SEARCHING
	if not _use_steam:
		_query = PacketPeerUDP.new()
		_query.set_broadcast_enabled(true)

func cancel() -> void :
	qlog("cancel state=%d party=%d" % [state, party_block.size()])


	if state == State.LOCKED:
		return
	if not party_block.is_empty():



		_stop_advertise()
		Net.quick_seek_visible(false)
		Net.quick_status_push("")



		Net.drop_folds("search cancelled")
		party_block = []
		Net.quick_queue = false
		_am_seeker = false
		state = State.IDLE
		status.emit("")
		return
	if Net.active:
		Net.leave()
	_cleanup()
	state = State.IDLE
	status.emit("")

func _exit_tree() -> void :
	_cleanup()

func _cleanup() -> void :
	if _listener != null:
		_listener.close()
		_listener = null
	if _query != null:
		_query.close()
		_query = null
	if Net.steam_lobbies.is_connected(_on_steam_rows):
		Net.steam_lobbies.disconnect(_on_steam_rows)
	if Net.quick_status.is_connected(_on_quick_status):
		Net.quick_status.disconnect(_on_quick_status)
	_pushed = ""
	_lock_t = 0.0
	_form_t = 0.0
	_last_humans = 0
	_peak_humans = 0
	if not Net.in_match:
		Net.quick_queue = false
	_am_seeker = false
	_isect = []
	_best_reply = {}
	_pending_fold = {}
	_seen_members = {}
	_fold_seen = {}
	_fold_delay = 0.0
	_seeker_base = 1

func _process(delta: float) -> void :


	if _fold_delay > 0.0:
		_fold_delay -= delta
		if _fold_delay <= 0.0:
			_leader_join_fold()
		return


	if state != State.IDLE and not Net.in_match:
		Net.quick_queue = true
	match state:
		State.SEARCHING:
			_tick_search(delta)
		State.FORMING:
			_tick_forming(delta)
		_:
			pass

func modes_label() -> String:
	if modes.size() >= 6:
		return "any mode"
	var parts: = []
	var sorted: = modes.duplicate()
	sorted.sort()
	for m in sorted:
		parts.append("%dv%d" % [m, m])
	return ", ".join(parts)



func _tick_search(delta: float) -> void :
	_t += delta
	var region: = ("   " + _region_label()) if _use_steam else ""
	status.emit("searching%s   %s%s   %d:%02d"\
	%[" (lan)" if force_lan else "", modes_label(), region, 
		int(_t) / 60, int(_t) % 60])
	if _t >= search_max:
		var r: = "no matches found, try again or host a custom lobby"
		cancel()
		failed.emit(r)
		return




	if _am_seeker:
		_advertise_tick()

		if Net.players.size() > _seeker_base:
			qlog("joiner arrived (%d > base %d): FORMING" % [Net.players.size(), _seeker_base])
			state = State.FORMING
			return





		if not party_block.is_empty():
			_lock_t -= delta



			var line: = "searching   %s%s   %d:%02d"\
			%[modes_label(), ("   " + _region_label()) if _use_steam else "", 
				int(_t) / 60, int(_t) % 60]
			if line != _pushed:
				_pushed = line
				Net.quick_status_push(line)
			if _lock_t <= 0.0:
				state = State.FORMING
				return
	_scan_t += delta
	if _scan_open > 0.0:
		_collect_replies()
		_scan_open -= delta
		if _scan_open <= 0.0:
			_scan_done()
	elif _scan_t >= SCAN_EVERY:
		_scan_t = 0.0

		_scan_open = 2.0 if _use_steam else SCAN_WINDOW
		_best_reply = {}
		_best_backfill = {}
		_scan_send()

func _scan_send() -> void :
	if _use_steam:


		Net.steam_request_lobbies()
		return


	for i in LAN_PORTS:
		for ip in ["255.255.255.255", "127.0.0.1"]:
			_query.set_dest_address(ip, LAN_PORT_BASE + i)
			_query.put_packet(("QUICK?").to_utf8_buffer())
	qlog("probed udp %d..%d" % [LAN_PORT_BASE, LAN_PORT_BASE + LAN_PORTS - 1])

func _on_steam_rows(rows: Array) -> void :


	if state != State.SEARCHING or not _use_steam:
		return
	for row in rows:
		if String(row.get("kind", "")) != "quick":
			continue
		if not bool(row.get("compatible", false)):
			continue
		if int(row.get("lobby_id", 0)) == Net.steam_lobby_id:
			continue
		var their_modes: Array = []
		for part in String(row.get("modes", "")).split(",", false):
			their_modes.append(int(part))
		var d: = {
			"sid": int(row.get("lobby_id", 0)), 
			"modes": their_modes, 
			"members": maxi(int(row.get("qmembers", 0)), 1), 
			"steam": true, 
			"host_id": int(row.get("host_id", 0)), 
			"ping": int(row.get("ping", -1)), 
		}
		_seen_members[int(d["sid"])] = int(d["members"])
		if not _mode_overlap(their_modes):
			continue
		if not _ping_admissible(int(d["ping"])):
			continue


		if String(row.get("in_progress", "")) == "1":
			if not fresh_only and int(row.get("open", 0)) > 0:
				_best_backfill = d
			continue
		if _better_reply(d):
			_best_reply = d




static func _ni(v: Variant, def: = 0) -> int:
	return int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_BOOL]\
	else def

func _collect_replies() -> void :
	while _query != null and _query.get_available_packet_count() > 0:
		var pkt: = _query.get_packet()
		var ip: = _query.get_packet_ip()
		var d: Variant = JSON.parse_string(pkt.get_string_from_utf8())
		qlog("reply from %s: %s" % [ip, pkt.get_string_from_utf8()])
		if d == null or typeof(d) != TYPE_DICTIONARY:
			continue
		if _ni(d.get("proto", 0)) != Net.PROTO:
			continue
		if bool(d.get("gym", false)):
			continue
		if _ni(d.get("sid", 0)) == _sid:
			continue
		_seen_members[_ni(d.get("sid", 0))] = _ni(d.get("members", 0))
		if not _mode_overlap(d.get("modes", [])):
			continue
		if bool(d.get("in_progress", false)):


			if not fresh_only and _ni(d.get("open", 0)) > 0:
				d["ip"] = ip
				_best_backfill = d
			continue
		if _better_reply(d):
			d["ip"] = ip
			_best_reply = d

func _better_reply(d: Dictionary) -> bool:
	if _best_reply.is_empty():
		return true
	var a: = _ni(d.get("members", 0))
	var b: = _ni(_best_reply.get("members", 0))
	if a != b:
		return a > b


	var ba: = _ping_bucket(_ni(d.get("ping", -1), -1))
	var bb: = _ping_bucket(_ni(_best_reply.get("ping", -1), -1))
	if ba != bb:
		return ba < bb
	return _ni(d.get("sid", 0)) < _ni(_best_reply.get("sid", 0))



func _mode_overlap(theirs: Variant) -> bool:
	if not (theirs is Array):
		return false
	var their_ints: Array = (theirs as Array).map( func(x): return _ni(x, -999))
	for m in modes:
		if int(m) in their_ints:
			return true
	return false


func _current_tier() -> Dictionary:
	var tier: Dictionary = REGION_TIERS[0]
	for t in REGION_TIERS:
		if _t >= float(t["t"]):
			tier = t
	return tier

func _region_label() -> String:
	return String(_current_tier()["name"])



func _ping_admissible(ping: int) -> bool:
	return ping < 0 or ping <= int(_current_tier()["ceil"])




func _ping_bucket(ping: int) -> int:
	if ping < 0:
		return 1
	if ping <= 39:
		return 0
	if ping <= 70:
		return 1
	if ping <= 90:
		return 2
	return 3




func _my_sid() -> int:
	if _use_steam:
		return Net.steam_lobby_id if Net.steam_lobby_id != 0\
		else 9223372036854775807
	return _sid

func _scan_done() -> void :
	if not _best_reply.is_empty():





		var their_members: = clampi(_ni(_best_reply.get("members", 1), 1), 0, Net.MAX_PLAYERS)
		var ours: = Net.players.size() if _am_seeker else 0
		var fold: = their_members > ours\
		or (their_members == ours\
		and int(_best_reply.get("sid", 0)) < _my_sid())
		qlog("scan: best=%s theirs=%d ours=%d fold=%s" % [str(_best_reply), 
			their_members, ours, str(fold)])
		if fold:
			if not party_block.is_empty():

				_fold_party_block()
				return
			if _am_seeker:
				Net.leave()
				_stop_advertise()
			var joined: bool
			if bool(_best_reply.get("steam", false)):
				joined = Net.join_game_steam(int(_best_reply.host_id), 
					Net.my_name) == OK
			else:
				joined = Net.join_game(String(_best_reply.ip), Net.my_name) == OK
			qlog("fold join ok=%s" % str(joined))
			if joined:


				Net.quick_join_modes = modes.duplicate()
				state = State.FORMING
				_am_seeker = false
				return


	if _best_reply.is_empty() and not _best_backfill.is_empty()\
	and _t >= BACKFILL_AFTER and party_block.is_empty():
		if _am_seeker:
			Net.leave()
			_stop_advertise()
			_am_seeker = false
		var bf_ok: bool
		if bool(_best_backfill.get("steam", false)):
			bf_ok = Net.join_game_steam(int(_best_backfill.host_id), 
				Net.my_name) == OK
		else:
			bf_ok = Net.join_game(String(_best_backfill.ip), Net.my_name) == OK
		if bf_ok:
			Net.quick_join_modes = modes.duplicate()
			state = State.FORMING
			status.emit("joining a match in progress...")
			return
	if not _am_seeker:

		if _use_steam:
			if Net.host_game_steam(Net.my_name) == OK:
				_am_seeker = true
				_isect = modes.duplicate()


			return





		var probe: = PacketPeerUDP.new()
		var port_free: = probe.bind(Net.PORT) == OK
		probe.close()
		qlog("no lobby found; port_free=%s -> hosting" % str(port_free))
		if port_free and Net.host_game(Net.my_name) == OK:
			_am_seeker = true
			_isect = modes.duplicate()
			_advertise_start()






func _fold_party_block() -> void :
	qlog("party FOLDS into %s" % str(_best_reply))
	_stop_advertise()
	var steam: = bool(_best_reply.get("steam", false))
	var host_id: = int(_best_reply.get("host_id", 0)) if steam else 0
	var host_ip: = String(_best_reply.get("ip", "")) if not steam else ""
	var token: = _my_sid()
	Net.rehome_party(host_id, host_ip, modes, token)


	Net.home_party = {"is_leader": true, "token": token}
	_pending_fold = {"host_id": host_id, "ip": host_ip, "token": token}
	_fold_delay = 0.35

func _leader_join_fold() -> void :
	var pf: = _pending_fold
	_pending_fold = {}
	Net.quick_join_modes = modes.duplicate()
	Net.quick_party_token = int(pf.get("token", 0))
	var ok: = false
	if int(pf.get("host_id", 0)) != 0:
		ok = Net.join_game_steam(int(pf.host_id), Net.my_name) == OK
	elif String(pf.get("ip", "")) != "":
		ok = Net.join_game(String(pf.ip), Net.my_name) == OK
	qlog("leader fold join ok=%s" % str(ok))
	if ok:

		party_block = []
		_am_seeker = false
		state = State.FORMING
	else:
		Net.home_party = {}
		cancel()
		failed.emit("couldn't join the match, try again")




func absorb_filter(theirs: Array) -> void :
	if not _am_seeker:
		return
	var t: = theirs.map( func(x): return int(x))
	_isect = _isect.filter( func(m): return int(m) in t)
	if _isect.is_empty():
		_isect = [Net.team_size]





func best_mode(humans: int) -> int:
	var sorted: = _isect.map( func(x): return int(x))
	sorted.sort()
	for m in sorted:
		if int(m) * 2 >= humans:
			return int(m)
	return int(sorted.back()) if not sorted.is_empty() else Net.team_size

func _on_quick_status(text: String) -> void :

	if not _am_seeker and state == State.FORMING:
		if text != _pushed:
			_stale_t = 0.0
		_pushed = text



func _tick_forming(delta: float) -> void :
	_t += delta
	if not Net.active:


		state = State.SEARCHING
		_am_seeker = false
		return
	var humans: = Net.players.size()





	if not _am_seeker and humans == 0:
		_empty_t += delta
		if _empty_t >= EMPTY_FOLD_GIVEUP:
			qlog("fold never landed (%.0fs with no roster): back to searching"
				%_empty_t)
			_empty_t = 0.0
			_pushed = ""
			Net.leave()
			state = State.SEARCHING
			_am_seeker = false
			return
	else:
		_empty_t = 0.0




	if not _am_seeker and _pushed != "":
		_stale_t += delta
		if _stale_t >= HOST_LINE_STALE:
			qlog("host line frozen %.0fs (%s): leaving" % [_stale_t, _pushed])
			_stale_t = 0.0
			_pushed = ""
			Net.leave()
			state = State.SEARCHING
			_am_seeker = false
			return
	if not _am_seeker:



		status.emit(_pushed if _pushed != ""\
		else "players found %d, waiting%s"\
		%[humans, ".".repeat(1 + int(_t * 2.0) % 3)])
		return
	_advertise_tick()
	if humans > _last_humans:













		if humans > _peak_humans:
			_lock_t = maxf(_lock_t, GROWTH_FLOOR)
	_peak_humans = maxi(_peak_humans, humans)
	_last_humans = humans
	var line: String
	if humans >= 2:
		_lock_t -= delta
		_form_t += delta


		var left: = minf(_lock_t, form_max - _form_t)
		line = "players found %d, starting in %d"\
		%[humans, maxi(1, ceili(maxf(left, 0.0)))]
	else:
		line = "players found %d, waiting%s"\
		%[humans, ".".repeat(1 + int(_t * 2.0) % 3)]
	status.emit(line)
	if line != _pushed:
		_pushed = line
		Net.quick_status_push(line)
	var full: = humans >= 2 * int(best_mode(999))
	if _fold_incomplete():


		_lock_t = maxf(_lock_t, 2.0)
		return
	if full or (humans >= 2 and (_lock_t <= 0.0 or _form_t >= form_max)):



		_lock()
	elif _t >= search_max and humans < 2:
		var r: = "no matches found, try again or host a custom lobby"
		cancel()
		failed.emit(r)





func _fold_incomplete() -> bool:
	var have: = {}
	for pid in Net.players:
		var tok: = int((Net.players[pid] as Dictionary).get("ptoken", 0))
		if tok != 0:
			have[tok] = int(have.get(tok, 0)) + 1
	for tok in have:
		if not _fold_seen.has(tok):
			_fold_seen[tok] = _t
		var since: float = _t - float(_fold_seen[tok])
		if since >= FOLD_GRACE:
			continue
		var want: = int(_seen_members.get(tok, 0))
		if want > 0:
			if int(have[tok]) < want:
				return true
		elif since < FOLD_UNKNOWN_HOLD:
			return true
	return false

func _lock() -> void :
	qlog("LOCK players=%s" % str(Net.players))
	state = State.LOCKED
	_stop_advertise()

	Net.set_team_size(best_mode(Net.players.size()))
	Net.quick_status_push("match found!")
	status.emit("match found!")
	locked.emit()



	GameConfig.set_points = 7
	GameConfig.sets_to_win = 2
	GameConfig.win_by_two = true
	Net.set_rules(7, 2, true, false, 1.0)
	Net.stage = Stage.random_id()
	_balance_sides()
	quick_start.emit()


signal quick_start




func _balance_sides() -> void :
	if not party_block.is_empty():
		_balance_party()
		return





	var blocks: = {}
	var lone: = 0
	for id in Net.players.keys():
		var tok: = int((Net.players[id] as Dictionary).get("ptoken", 0))
		if tok == 0:
			lone -= 1
			tok = lone
		if not blocks.has(tok):
			blocks[tok] = []
		(blocks[tok] as Array).append(id)
	var groups: Array = blocks.values()


	groups.sort_custom( func(a, b): return (a as Array).size() > (b as Array).size())
	var count: = {1: 0, -1: 0}
	for grp in groups:
		var side: = 1 if int(count[1]) <= int(count[-1]) else -1
		for id in grp:
			Net.players[id].side = side
		count[side] = int(count[side]) + (grp as Array).size()




func _balance_party() -> void :
	var team: = int(Net.team_size)
	var others: = Net.players.keys().filter( func(id): return not party_block.has(id))

	var blocks: = {}
	var loners: Array = []
	for id in others:
		var tok: = int((Net.players[id] as Dictionary).get("ptoken", 0))
		if tok != 0:
			if not blocks.has(tok):
				blocks[tok] = []
			blocks[tok].append(id)
		else:
			loners.append(id)
	loners.sort_custom( func(a, b):
		return float(Net.players[a].get("wr", 0.5))\
		> float(Net.players[b].get("wr", 0.5)))
	var home: = 0
	for id in party_block:
		if Net.players.has(id):
			Net.players[id].side = 1
			home += 1

	var block_list: Array = blocks.values()
	block_list.sort_custom( func(a, b): return a.size() > b.size())
	for grp in block_list:
		for id in grp:
			Net.players[id].side = -1

	for id in loners:
		if home < team:
			Net.players[id].side = 1
			home += 1
		else:
			Net.players[id].side = -1



func _advertise_tick() -> void :
	if _use_steam:


		Net.steam_quick_meta(_csv(_isect), Net.players.size(), false)
	else:
		_answer_probes()

func _csv(a: Array) -> String:
	return ",".join(a.map( func(x): return str(int(x))))

func _advertise_start() -> void :
	_listener = PacketPeerUDP.new()
	for i in LAN_PORTS:
		if _listener.bind(LAN_PORT_BASE + i) == OK:
			qlog("advertising on udp %d" % (LAN_PORT_BASE + i))
			return
	_listener = null

func _stop_advertise() -> void :
	if _use_steam and _am_seeker:

		Net.steam_quick_meta(_csv(_isect), Net.players.size(), true)
	if _listener != null:
		_listener.close()
		_listener = null

var _probe_reply_t: = {}
var _probe_global_t: Array = []

func _answer_probes() -> void :
	while _listener != null and _listener.get_available_packet_count() > 0:
		var pkt: = _listener.get_packet()
		if pkt.get_string_from_utf8() != "QUICK?":
			continue


		var src: = _listener.get_packet_ip()
		var now: = Time.get_ticks_msec()
		if now - int(_probe_reply_t.get(src, -100000)) < 250:
			continue
		_probe_reply_t[src] = now
		if _probe_reply_t.size() > 256:
			_probe_reply_t.clear()
		while not _probe_global_t.is_empty() and now - int(_probe_global_t[0]) > 1000:
			_probe_global_t.pop_front()
		if _probe_global_t.size() >= 40:
			continue
		_probe_global_t.append(now)


		if Net.players.size() >= 2 * int(best_mode(999)):
			continue
		var reply: = {
			"sid": _sid, 
			"proto": Net.PROTO, 

			"modes": _isect, 
			"members": Net.players.size(), 
			"in_progress": false, 
			"open": 2 * int(best_mode(999)) - Net.players.size(), 
		}
		_listener.set_dest_address(_listener.get_packet_ip(), 
			_listener.get_packet_port())
		_listener.put_packet(JSON.stringify(reply).to_utf8_buffer())
		qlog("answered probe from %s:%d with %s" % [src, _listener.get_packet_port(), str(reply)])
