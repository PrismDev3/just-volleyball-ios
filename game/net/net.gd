extends Node








signal lobby_changed
signal steam_lobbies(rows: Array)
signal session_ended(reason: String)
signal match_started(roster: Array)
signal input_received(peer_id: int, data: Dictionary)
signal snapshot_received(data: Dictionary)
signal event_received(kind: String, args: Dictionary)
signal up_event_received(peer_id: int, kind: String, args: Dictionary)
signal peer_left_match(peer_id: int)
signal peer_match_ready(peer_id: int)

const PORT: = 28960
const MAX_PLAYERS: = 12









const PROTO: = 16

static func proto_ok(v: int) -> bool:
	return v == PROTO

var active: = false
var is_host: = false
var in_match: = false





var custom_lobby: = false



var party_lan: = false
var my_name: = "player"
var team_size: = 2





var max_humans: = 0
var stage: = "nationals"
var cpu_difficulty: = 1



var cpu_slots: Dictionary = {}



var rule_points: = 7
var rule_sets: = 2
var rule_wbt: = true
var rule_sweat: = false
var rule_rate: = 1.0

const RULE_DEFAULTS: = {"pts": 7, "sets": 2, "wbt": true, "sweat": false, "rate": 1.0}

func set_rules(pts: int, sets: int, wbt: bool, sweat: bool, rate: float) -> void :
	if not is_host:
		return
	rule_points = clampi(pts, 3, 25)
	rule_sets = clampi(sets, 1, 3)
	rule_wbt = wbt
	rule_sweat = sweat
	rule_rate = rate
	_broadcast_lobby()
	lobby_changed.emit()



func init_rules_from_config() -> void :
	rule_points = GameConfig.set_points
	rule_sets = GameConfig.sets_to_win
	rule_wbt = GameConfig.win_by_two
	rule_sweat = GameConfig.sweat_enabled
	rule_rate = GameConfig.sweat_rate



func apply_rules_to_config() -> void :
	GameConfig.set_points = rule_points
	GameConfig.sets_to_win = rule_sets
	GameConfig.win_by_two = rule_wbt
	GameConfig.sweat_enabled = rule_sweat
	GameConfig.sweat_rate = rule_rate


var players: = {}



var session_token: = 0



var last_players: = {}



var last_chat: Array = []

func restore_chat() -> void :
	if chat_log.is_empty() and not last_chat.is_empty():
		chat_log = last_chat.duplicate(true)
		last_chat = []
		for entry in chat_log:
			chat.emit(entry)
var fake_latency_ms: = 0
var fake_jitter_ms: = 0









var fake_loss_pct: = 0







const PING_EVERY_MS: = 200
var _rtt_ms: = 0.0
var _ping_next: = 0


var _peer_rtt: = {}

var _out_queue: Array = []
var _in_queue: Array = []













signal chat(entry: Dictionary)

const CHAT_MAX_LEN: = 100
const CHAT_LOG_MAX: = 500
const CHAT_MIN_INTERVAL_MS: = 350
const CHAT_BURST: = 4
const CHAT_BURST_WINDOW_MS: = 5000

var chat_log: Array = []
var _chat_burst: = {}



var chat_filter: = Callable()





signal typing_changed(names: Array)

const TYPING_TTL_MS: = 4000

var _typing_until: = {}
var _typing_names: Array = []
var _typing_sent: = false

func set_typing(on: bool) -> void :
	if not active:
		return
	if is_host:
		_host_typing(1, on)
	elif on != _typing_sent or on:
		_c_typing.rpc_id(1, on)
	_typing_sent = on

@rpc("any_peer", "call_remote", "reliable")
func _c_typing(on: bool) -> void :
	var id: = multiplayer.get_remote_sender_id()
	_recv( func(): _host_typing(id, on))

var _typing_flip_t: = {}

func _host_typing(peer: int, on: bool) -> void :
	if not is_host:
		return
	if not _rate_ok(_typing_flip_t, peer, 4, 1000):
		return
	if on:
		_typing_until[peer] = Time.get_ticks_msec() + TYPING_TTL_MS
	else:
		_typing_until.erase(peer)
	_typing_broadcast()

func _typing_sweep() -> void :
	if _typing_until.is_empty():
		return
	var now: = Time.get_ticks_msec()
	var expired: = []
	for pid in _typing_until:
		if int(_typing_until[pid]) <= now:
			expired.append(pid)
	if expired.is_empty():
		return
	for pid in expired:
		_typing_until.erase(pid)
	_typing_broadcast()

func _typing_broadcast() -> void :
	var names: = []
	for pid in _typing_until:
		names.append(String((players.get(pid, {}) as Dictionary)\
		.get("name", "player")))
	names.sort()
	if names == _typing_names:
		return
	_typing_names = names

	typing_changed.emit(names)
	_s_typing.rpc(names)

@rpc("authority", "call_remote", "reliable")
func _s_typing(names: Array) -> void :
	_recv( func():
		_typing_names = names
		typing_changed.emit(names))



var team_of: = Callable()




var room_of: = Callable()
var _chat_last_ms: = {}



static func _chat_identity(court_side: int) -> int:
	return - court_side if Rules.set_swapped else court_side

func side_of(peer_id: int) -> int:
	if team_of.is_valid():
		var s: Variant = team_of.call(peer_id)
		if s != null:
			return int(s)
	return int((players.get(peer_id, {}) as Dictionary).get("side", 0))

func _room(peer_id: int) -> int:
	if room_of.is_valid():
		var r: Variant = room_of.call(peer_id)
		if r != null:
			return int(r)
	return side_of(peer_id)








func ev_v3(a: Dictionary, k: String, d: = Vector3.ZERO) -> Vector3:
	var v: Variant = a.get(k)
	return v if v is Vector3 and is_finite(v.x) and is_finite(v.y) and is_finite(v.z) else d

func ev_f(a: Dictionary, k: String, d: = 0.0) -> float:
	var v: Variant = a.get(k)
	if v is float or v is int:
		var f: = float(v)
		return f if is_finite(f) else d
	return d

func ev_i(a: Dictionary, k: String, d: = 0) -> int:
	var v: Variant = a.get(k)
	if v is int:
		return v
	if v is float and is_finite(v):
		return int(v)
	return d

func ev_s(a: Dictionary, k: String, d: = "", max_len: = 256) -> String:
	var v: Variant = a.get(k)
	return (v as String).substr(0, max_len) if v is String else d

func ev_b(a: Dictionary, k: String, d: = false) -> bool:
	var v: Variant = a.get(k)
	return v if v is bool else d

func ev_arr(a: Dictionary, k: String, max_size: = 64) -> Array:
	var v: Variant = a.get(k)
	return (v as Array).slice(0, max_size) if v is Array else []



static func ni(v: Variant, def: = 0) -> int:
	return int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_BOOL]\
	else def

static func sanitize_chat(text: String) -> String:
	var t: = text.replace("[", "(").replace("]", ")").strip_edges()
	return t.substr(0, CHAT_MAX_LEN)






const NAME_MAX_LEN: = 24

func sanitize_name(text: String) -> String:
	var t: = text.replace("[", "(").replace("]", ")")\
	.replace("\n", " ").replace("\r", " ").strip_edges()
	if t == "":
		t = "player"
	return t.substr(0, NAME_MAX_LEN)

func send_chat(channel: String, text: String) -> void :
	var t: = sanitize_chat(text)
	if t == "" or not active:
		return
	if is_host:
		_host_route_chat(1, channel, t)
	else:
		_c_chat.rpc_id(1, channel, t)

@rpc("any_peer", "call_remote", "reliable")
func _c_chat(channel: String, text: String) -> void :
	var id: = multiplayer.get_remote_sender_id()
	_recv( func(): _host_route_chat(id, channel, text))

func _host_route_chat(from_peer: int, channel: String, text: String) -> void :
	if not is_host:
		return
	var t: = sanitize_chat(text)
	if t == "":
		return
	var now: = Time.get_ticks_msec()
	if now - int(_chat_last_ms.get(from_peer, - CHAT_MIN_INTERVAL_MS))\
	< CHAT_MIN_INTERVAL_MS:
		return

	var burst: Array = _chat_burst.get(from_peer, [])
	burst = burst.filter( func(t): return now - int(t) < CHAT_BURST_WINDOW_MS)
	if burst.size() >= CHAT_BURST:
		return
	burst.append(now)
	_chat_burst[from_peer] = burst
	_chat_last_ms[from_peer] = now
	if chat_filter.is_valid():
		t = String(chat_filter.call(t))
		if t == "":
			return
	var ch: = "team" if channel == "team" else "all"
	var entry: = {
		"t": Time.get_unix_time_from_system(), 
		"p": from_peer, 
		"n": String((players.get(from_peer, {}) as Dictionary)\
		.get("name", "player")), 




		"s": _chat_identity(side_of(from_peer)), 
		"ch": ch, 
		"m": t, 



		"d": DevBadge.tier_of(int((players.get(from_peer, {}) as Dictionary).get("sid", 0))), 
	}
	if ch == "team":
		var room: = _room(from_peer)
		for pid in players:
			if pid != 1 and _room(int(pid)) == room:
				_s_chat.rpc_id(int(pid), entry)
		if _room(1) == room:
			_take_chat(entry)
	else:
		_s_chat.rpc(entry)
		_take_chat(entry)

@rpc("authority", "call_remote", "reliable")
func _s_chat(entry: Dictionary) -> void :
	_recv( func(): _take_chat(entry))

func _take_chat(raw: Dictionary) -> void :




	var entry: = {
		"n": sanitize_name(ev_s(raw, "n", "player", 64)), 
		"m": sanitize_chat(ev_s(raw, "m", "", CHAT_MAX_LEN * 2)), 
		"s": clampi(ev_i(raw, "s", 0), -1, 1), 
		"ch": "team" if ev_s(raw, "ch", "all") == "team" else "all", 
	}
	for k in raw:
		if not entry.has(k) and k is String and (raw[k] is int or raw[k] is float or raw[k] is bool):
			entry[k] = raw[k]
	if entry.m == "":
		return




	chat_log.append(entry)
	while chat_log.size() > CHAT_LOG_MAX:
		chat_log.pop_front()
	chat.emit(entry)










const STEAM_APP_ID_MAIN: = 5037200
const STEAM_APP_ID_PLAYTEST: = 5037230




const STEAM_APP_ID_SPACEWAR: = 480

static func steam_app_id() -> int:







	if not OS.has_feature("spacewar"):
		var launched: = OS.get_environment("SteamAppId")
		if launched.is_valid_int() and int(launched) != 0:
			return int(launched)

	if OS.has_feature("spacewar"):
		return STEAM_APP_ID_SPACEWAR
	return STEAM_APP_ID_PLAYTEST if OS.has_feature("playtest") else STEAM_APP_ID_MAIN
const STEAM_GAME_KEY: = "volleyball-arcade"
var steam_lobby_id: = 0
var _ploc_published: = false
var _ploc_next: = 0
var _steam: Object = null
var _steam_tried: = false



var _steam_peer: MultiplayerPeer = null
var _steam_hosting: = false
var _web_peer: Variant = null
var _web_connections: Dictionary = {}
var _web_remote_ids: Dictionary = {}
var _web_peer_profiles: Dictionary = {}
var _web_pending_ice: Dictionary = {}
var _web_room := ""
var _web_lobby_row: Dictionary = {}
var _web_host_user := ""
var _web_client_name := ""
var _web_join_lookup := false
var _web_session := false
var _web_offer_pending := false
var _web_room_join_pending := false
var _web_lobby_created := false


func _ready() -> void :


	process_mode = Node.PROCESS_MODE_ALWAYS



	multiplayer.server_relay = true
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect( func(): _teardown("connection failed"))
	multiplayer.server_disconnected.connect( func(): _teardown("host left"))
	SupabaseClient.room_message.connect(_on_web_room_message)
	SupabaseClient.room_joined.connect(_on_web_room_joined)
	SupabaseClient.lobby_created.connect(_on_web_lobby_created)
	SupabaseClient.lobby_resolved.connect(_on_web_lobby_resolved)
	SupabaseClient.lobby_error.connect(_on_web_lobby_error)







var quick_ad_open: = 0
var _quick_udp: PacketPeerUDP = null

func quick_backfill_ad(open: int) -> void :
	if not is_host:
		return
	quick_ad_open = maxi(open, 0)
	if _steam != null and steam_lobby_id != 0:







		var resting: = not in_match
		var rest_kind: = "locked" if GameConfig.quick_match else _lobby_kind
		_steam.setLobbyData(steam_lobby_id, "kind", rest_kind if resting
			else ("quick" if quick_ad_open > 0 else "locked"))
		_steam.setLobbyData(steam_lobby_id, "in_progress", "0" if resting else "1")
		_steam.setLobbyData(steam_lobby_id, "modes", str(team_size))
		_steam.setLobbyData(steam_lobby_id, "members", str(players.size()))
		_steam.setLobbyData(steam_lobby_id, "open", str(quick_ad_open))
	_ensure_quick_udp(_want_quick_udp())




var migrate_open: = false

func migrate_advertise(on: bool) -> void :
	migrate_open = on
	_ensure_quick_udp(_want_quick_udp())

func _want_quick_udp() -> bool:


	return quick_ad_open > 0 or migrate_open or (gym_session and is_host)

func _ensure_quick_udp(want: bool) -> void :
	if want and _quick_udp == null:
		_quick_udp = PacketPeerUDP.new()
		var bound: = false
		for i in QuickPlay.LAN_PORTS:
			if _quick_udp.bind(QuickPlay.LAN_PORT_BASE + i) == OK:
				bound = true
				break
		if not bound:
			_quick_udp = null
	elif not want and _quick_udp != null:
		_quick_udp.close()
		_quick_udp = null

var _ad_reply_t: = {}
var _ad_global_t: = {}

func _quick_ad_answer() -> void :
	while _quick_udp != null and _quick_udp.get_available_packet_count() > 0:
		var pkt: = _quick_udp.get_packet()
		if pkt.get_string_from_utf8() != "QUICK?":
			continue
		var src: = _quick_udp.get_packet_ip()
		var now: = Time.get_ticks_msec()
		if now - int(_ad_reply_t.get(src, -100000)) < 250:
			continue
		if not _rate_ok(_ad_global_t, 0, 40, 1000):
			continue
		_ad_reply_t[src] = now
		if _ad_reply_t.size() > 256:
			_ad_reply_t.clear()
		var reply: = {
			"sid": steam_lobby_id if steam_lobby_id != 0 else 1, 
			"proto": PROTO, 
			"modes": [team_size], 
			"members": players.size(), 
			"in_progress": true, 
			"open": quick_ad_open, 
			"migrate": session_token if migrate_open else 0, 


			"steam_host": my_steam_id() if _steam_hosting else 0, 


			"gym": gym_session, 

			"priv": privacy, 
		}
		_quick_udp.set_dest_address(_quick_udp.get_packet_ip(), 
			_quick_udp.get_packet_port())
		_quick_udp.put_packet(JSON.stringify(reply).to_utf8_buffer())

func _process(_delta: float) -> void :
	if is_host:
		_typing_sweep()
		if (in_match and quick_ad_open > 0) or migrate_open\
		or gym_session:
			_quick_ad_answer()
	if _steam != null:
		_steam.run_callbacks()
	var now: = Time.get_ticks_msec()
	if _web_session and is_host and _web_offer_pending and SupabaseClient.realtime_ready():
		_web_offer_pending = false
		SupabaseClient.publish_lobby(_web_room, "%s's court" % my_name, stage,
			"%dv%d" % [team_size, team_size], max_humans if max_humans > 0 else MAX_PLAYERS,
			"public" if privacy == Priv.PUBLIC else ("friends" if privacy == Priv.FRIENDS else "private"))



	if is_host and steam_lobby_id != 0 and not _ploc_published and now >= _ploc_next:
		_ploc_next = now + 1500
		_ploc_published = _publish_ping_location(steam_lobby_id)

	if active and not is_host and now >= _ping_next:
		_ping_next = now + PING_EVERY_MS
		ping_host()







	if not _out_queue.is_empty():
		var still_out: Array = []
		for out in _out_queue:
			if int(out.at) <= now and _can_send():
				(out.fn as Callable).call()
			elif int(out.at) > now:
				still_out.append(out)
		_out_queue = still_out
	if not _in_queue.is_empty():
		var still_in: Array = []
		for inp in _in_queue:
			if int(inp.at) <= now:
				(inp.fn as Callable).call()
			else:
				still_in.append(inp)
		_in_queue = still_in





signal steam_ready



var _steam_last_status: = 0
var _steam_last_verbal: = ""



func steam_status_text() -> String:
	if _steam != null:
		return "steam authenticated"
	match _steam_last_status:
		2:
			return "steam isn't running, start steam and then restart the game (code 2)"
		3:
			return "steam is out of date, restart steam to update it, then the game (code 3)"
		0:
			return "steam isn't running"
		_:
			return "couldn't reach steam, restart steam and the game (code %d)" % _steam_last_status

func steam_init() -> bool:
	if _steam != null:
		return true






	if _steam_tried:
		return false
	_steam_tried = true
	if not Engine.has_singleton("Steam"):
		return false
	var s: Object = Engine.get_singleton("Steam")
	var app_id: = steam_app_id()
	OS.set_environment("SteamAppId", str(app_id))
	OS.set_environment("SteamGameId", str(app_id))
	var res: Variant = s.steamInitEx(app_id, true)
	if typeof(res) == TYPE_DICTIONARY and int(res.get("status", 1)) != 0:
		_steam_last_status = int(res.get("status", 1))
		_steam_last_verbal = String(res.get("verbal", ""))

		print("[steam] init failed: status %d (%s) app %d"\
		%[_steam_last_status, _steam_last_verbal, app_id])
		return false
	_steam_last_status = 0
	_steam = s




	if _steam.has_method("initRelayNetworkAccess"):
		_steam.initRelayNetworkAccess()
	_steam.lobby_created.connect(_on_steam_lobby_created)
	_steam.lobby_match_list.connect(_on_steam_lobby_list)



	if _steam.has_signal("join_requested"):
		_steam.join_requested.connect(_on_steam_join_requested)
	if _steam.has_signal("lobby_joined"):
		_steam.lobby_joined.connect(_on_steam_lobby_joined)


	_check_launch_invite.call_deferred()
	return true






func steam_achievements_available() -> bool:
	if not steam_init():
		return false
	return _steam.has_method("setAchievement") and _steam.has_method("getAchievement") and _steam.has_method("storeStats")

func steam_set_achievement(api_name: String) -> bool:
	if api_name == "" or not steam_achievements_available():
		return false
	_steam.setAchievement(api_name)
	_steam.storeStats()
	return true

func steam_has_achievement(api_name: String) -> bool:
	if api_name == "" or not steam_achievements_available():
		return false
	var st: Variant = _steam.getAchievement(api_name)
	if st is Dictionary:
		return bool(st.get("achieved", false))
	return false




signal invite_join_failed(reason: String)

func steam_invite_overlay() -> void :

	if _steam != null and steam_lobby_id != 0\
	and _steam.has_method("activateGameOverlayInviteDialog"):
		_steam.activateGameOverlayInviteDialog(steam_lobby_id)

func _on_steam_join_requested(lobby_id: int, _friend_id: int) -> void :


	if _steam != null and lobby_id != 0:
		_pending_invite_lobby = lobby_id
		_steam.joinLobby(lobby_id)

var _pending_invite_lobby: = 0






const CODE_KEY_CHARS: = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const CODE_KEY_LEN: = 4
var code_key: = ""

static func _roll_code_key() -> String:
	var out: = ""
	for i in CODE_KEY_LEN:
		out += CODE_KEY_CHARS[randi() % CODE_KEY_CHARS.length()]
	return out

func _on_steam_lobby_joined(lobby_id: int, _perm: int, _locked: bool, 
		response: = 1) -> void :



	if lobby_id != _pending_invite_lobby:
		return
	_pending_invite_lobby = 0
	if response != 1:
		invite_join_failed.emit("couldn't join that lobby")
		return
	var host_id: = int(String(_steam.getLobbyData(lobby_id, "host_id")))
	_steam.leaveLobby(lobby_id)
	if host_id != 0 and host_id != my_steam_id():



		var hid: = host_id




		var lc: = str(lobby_id)
		var do_join: = func():



			if party and is_host and players.size() > 1:
				party_travel_to.emit(hid, lc)
				return
			join_game_steam(hid, local_display_name())
			remote_lobby_code = lc
		if OnlineTerms.require(do_join):
			do_join.call()

func _check_launch_invite() -> void :
	var args: = OS.get_cmdline_args()
	var i: = args.find("+connect_lobby")
	if i != -1 and i + 1 < args.size() and String(args[i + 1]).is_valid_int()\
	and _steam != null:
		_pending_invite_lobby = int(args[i + 1])
		_steam.joinLobby(_pending_invite_lobby)



func steam_friends() -> Array:
	var out: Array = []
	if _steam == null or not _steam.has_method("getFriendCount"):
		return out
	var flag: = 4
	var count: = int(_steam.getFriendCount(flag))
	for i in count:
		var fid: = int(_steam.getFriendByIndex(i, flag))


		var st: = int(_steam.getFriendPersonaState(fid))\
		if _steam.has_method("getFriendPersonaState") else 1
		if st == 0:
			continue
		var same_game: = false
		var lobby: = 0
		if _steam.has_method("getFriendGamePlayed"):
			var g: Variant = _steam.getFriendGamePlayed(fid)
			if typeof(g) == TYPE_DICTIONARY:
				same_game = int(g.get("id", 0)) == steam_app_id()
				lobby = int(g.get("lobby", 0))
		var status: = ""
		if same_game and _steam.has_method("getFriendRichPresence"):
			status = String(_steam.getFriendRichPresence(fid, "status"))
		out.append({"id": fid, "name": String(_steam.getFriendPersonaName(fid)), 
			"in_game": same_game, "status": status, "lobby": lobby})

	out.sort_custom( func(a, b):
		if bool(a.in_game) != bool(b.in_game):
			return bool(a.in_game)
		return String(a.name).naturalnocasecmp_to(String(b.name)) < 0)
	return out

func steam_invite_friend(friend_id: int) -> void :
	if _steam != null and steam_lobby_id != 0\
	and _steam.has_method("inviteUserToLobby"):
		_steam.inviteUserToLobby(steam_lobby_id, friend_id)
		party_invited[friend_id] = true


func steam_join_friend_lobby(lobby_id: int) -> void :
	if _steam != null and lobby_id != 0:



		_pending_invite_lobby = lobby_id
		_steam.joinLobby(lobby_id)





signal presence_changed(text: String)
var presence_text: = "In the menu"

func set_presence(text: String, group: = "", group_size: = 0, 
		group_max: = 6) -> void :
	if text == presence_text and group == _presence_group:
		return
	presence_text = text
	_presence_group = group
	if _steam != null and _steam.has_method("setRichPresence"):
		_steam.setRichPresence("status", text)

		_steam.setRichPresence("steam_player_group", group)
		if group != "" and group_size > 0:
			_steam.setRichPresence("steam_player_group_size", str(group_size))
	presence_changed.emit(text)

var _presence_group: = ""

func steam_persona() -> String:
	return String(_steam.getPersonaName()) if _steam != null else ""

func steam_transport_available() -> bool:
	return steam_init() and ClassDB.class_exists("SteamMultiplayerPeer")





var remote_lobby_code: = ""
func online_session() -> bool:
	# True when this session is a WebRTC/Supabase online room, as opposed to a
	# LAN or Steam one. The room panel uses it to decide between copying an
	# invite link and opening the Steam invite overlay.
	return _web_session

func lobby_code() -> String:




	if steam_lobby_id != 0:
		return "" if GameConfig.quick_match or code_key == ""\
		else "%d-%s" % [steam_lobby_id, code_key]
	if _web_session and privacy != Priv.PUBLIC:
		return ""
	return remote_lobby_code






func shared_lobby_code() -> String:
	return lobby_code() if privacy == Priv.PUBLIC else ""







func join_by_code(code_text: String) -> bool:



	var parts: = code_text.strip_edges().to_upper().split("-", false)
	if parts.is_empty() or not String(parts[0]).is_valid_int():
		return false
	var lobby: = int(parts[0])
	if lobby == 0 or not steam_init():
		return false
	join_password = String(parts[1]) if parts.size() > 1 else ""
	_pending_invite_lobby = lobby
	_steam.joinLobby(lobby)
	return true

func host_game_steam(player_name: String) -> Error:


	if not steam_transport_available():
		return ERR_UNAVAILABLE
	if active:
		_teardown("restart")
	_steam_hosting = true
	active = true
	is_host = true
	my_name = player_name
	players = {1: {"name": player_name, "cfg": local_character_dict(), 
		"wr": Career.winrate(), "sid": my_steam_id(), "side": 1}}
	session_token = randi()
	code_key = _roll_code_key()
	_steam.createLobby(2, MAX_PLAYERS)
	lobby_changed.emit()
	return OK

func join_game_steam(host_steam_id: int, player_name: String) -> Error:


	if not steam_transport_available() or host_steam_id == 0:
		return ERR_UNAVAILABLE
	if active:
		_teardown("restart")
	var peer: MultiplayerPeer = ClassDB.instantiate("SteamMultiplayerPeer")
	if peer == null:
		return ERR_UNAVAILABLE
	peer.call("create_client", host_steam_id, 0)
	multiplayer.multiplayer_peer = peer
	_steam_peer = peer
	active = true
	is_host = false
	my_name = player_name
	players = {}
	return OK

func local_display_name() -> String:
	if steam_init() and steam_persona() != "":
		return steam_persona()
	var profile: SavedProfile = ProfileStore.active()
	if profile != null and not profile.name.begins_with("Profile "):
		return sanitize_name(profile.name)
	return "player"








func display_name_for_slot(slot: int) -> String:
	var base: = local_display_name()
	if slot <= 0:
		return base
	return "%s%d" % [base, slot + 1]

func _lan_ip() -> String:

	for addr in IP.get_local_addresses():
		var a: = String(addr)
		if a.begins_with("192.168.") or a.begins_with("10."):
			return a
		if a.begins_with("172."):
			var second: = int(a.split(".")[1])
			if second >= 16 and second <= 31:
				return a
	return "127.0.0.1"

func _steam_open_lobby() -> void :
	if _steam == null or steam_lobby_id != 0:
		return

	_steam.createLobby(2, MAX_PLAYERS)

func _on_steam_lobby_created(result: int, lobby_id: int) -> void :
	if result != 1 or not active or not is_host:
		return
	steam_lobby_id = lobby_id
	_steam.setLobbyData(lobby_id, "game", STEAM_GAME_KEY)
	_steam.setLobbyData(lobby_id, "name", "%s's court" % my_name)
	_steam.setLobbyData(lobby_id, "proto", str(PROTO))
	_steam.setLobbyData(lobby_id, "humans", str(players.size()))


	_steam.setLobbyData(lobby_id, "cap", 
		str(max_humans if max_humans > 0 else MAX_PLAYERS))





	_ploc_published = _publish_ping_location(lobby_id)



	_steam.setLobbyData(lobby_id, "kind", _lobby_kind)


	_steam.setLobbyData(lobby_id, "locked", 
		"1" if privacy == Priv.PASSWORD else "0")
	_steam.setLobbyData(lobby_id, "priv", 
		["public", "friends", "password"][privacy])

	if party:
		_apply_party_lobby_type()
	if _steam_hosting:


		var peer: MultiplayerPeer = ClassDB.instantiate("SteamMultiplayerPeer")
		peer.call("create_host", 0)
		multiplayer.multiplayer_peer = peer
		_steam_peer = peer
		_steam.setLobbyData(lobby_id, "steam", "1")
		_steam.setLobbyData(lobby_id, "host_id", str(_steam.getSteamID()))
	elif OS.is_debug_build() and not LaunchGate.public_beta():





		_steam.setLobbyData(lobby_id, "ip", _lan_ip())




	lobby_changed.emit()




func steam_quick_meta(modes_csv: String, members: int, locked: bool) -> void :
	if _steam == null or steam_lobby_id == 0:
		return
	_steam.setLobbyData(steam_lobby_id, "kind", "locked" if locked else "quick")
	_steam.setLobbyData(steam_lobby_id, "modes", modes_csv)
	_steam.setLobbyData(steam_lobby_id, "members", str(members))

func _steam_close_lobby() -> void :
	if _steam != null and steam_lobby_id != 0:
		_steam.leaveLobby(steam_lobby_id)
	steam_lobby_id = 0
	_ploc_published = false




func _publish_ping_location(lobby_id: int) -> bool:
	if lobby_id == 0 or _steam == null or not _steam.has_method("getLocalPingLocation"):
		return false
	var loc: Variant = _steam.getLocalPingLocation()



	var bytes: = PackedByteArray()
	if typeof(loc) == TYPE_DICTIONARY:
		var v: Variant = (loc as Dictionary).get("location", null)
		if typeof(v) == TYPE_PACKED_BYTE_ARRAY:
			bytes = v
	elif typeof(loc) == TYPE_PACKED_BYTE_ARRAY:
		bytes = loc
	if bytes.size() > 0:
		_steam.setLobbyData(lobby_id, "ploc", Marshalls.raw_to_base64(bytes))
		return true
	return false


func _estimate_ping(ploc: String) -> int:
	if ploc == "" or _steam == null\
	or not _steam.has_method("estimatePingTimeFromLocalHost"):
		return -1

	var bytes: = Marshalls.base64_to_raw(ploc)
	if bytes.size() == 0:
		return -1
	var est: Variant = _steam.estimatePingTimeFromLocalHost(bytes)
	return int(est) if typeof(est) in [TYPE_INT, TYPE_FLOAT] and int(est) >= 0\
	else -1

func steam_request_lobbies() -> void :
	if _steam == null:
		return

	_steam.addRequestLobbyListStringFilter("game", STEAM_GAME_KEY, 0)




	_steam.addRequestLobbyListDistanceFilter(3)




	_steam.addRequestLobbyListResultCountFilter(250)
	_steam.requestLobbyList()

func _on_steam_lobby_list(lobbies: Array) -> void :


	var rows: Array = []
	for lobby_id in lobbies:
		var ip: = String(_steam.getLobbyData(lobby_id, "ip"))
		var via_steam: = String(_steam.getLobbyData(lobby_id, "steam")) == "1"
		var host_id: = int(String(_steam.getLobbyData(lobby_id, "host_id")))
		if ip == "" and not (via_steam and host_id != 0):
			continue



		var lobby_kind: = String(_steam.getLobbyData(lobby_id, "kind"))
		rows.append({
			"name": String(_steam.getLobbyData(lobby_id, "name")), 
			"ip": ip, 
			"steam": via_steam, 
			"host_id": host_id, 
			"lobby_id": int(lobby_id), 
			"players": int(_steam.getNumLobbyMembers(lobby_id)), 
			"kind": lobby_kind, 
			"modes": String(_steam.getLobbyData(lobby_id, "modes")), 
			"qmembers": int(String(_steam.getLobbyData(lobby_id, "members"))), 
			"in_progress": String(_steam.getLobbyData(lobby_id, "in_progress")), 
			"open": int(String(_steam.getLobbyData(lobby_id, "open"))), 
			"state": String(_steam.getLobbyData(lobby_id, "state")), 
			"mode": String(_steam.getLobbyData(lobby_id, "mode")), 
			"map": String(_steam.getLobbyData(lobby_id, "map")), 
			"stage": String(_steam.getLobbyData(lobby_id, "stage")), 
			"humans": int(String(_steam.getLobbyData(lobby_id, "humans"))), 
			"cap": String(_steam.getLobbyData(lobby_id, "cap")), 
			"ping": _estimate_ping(String(_steam.getLobbyData(lobby_id, "ploc"))), 
			"locked": String(_steam.getLobbyData(lobby_id, "locked")) == "1", 
			"priv": String(_steam.getLobbyData(lobby_id, "priv")), 



			"compatible": int(String(_steam.getLobbyData(lobby_id, "proto")))\
			== PROTO, 
		})
	if GameConfig.debug_net_log:
		print("[net] lobby list: %d from steam, %d listed" % [lobbies.size(), rows.size()])
	steam_lobbies.emit(rows)



func online_hosting_available() -> bool:
	# WebRTCMultiplayerPeer + WebRTCPeerConnection are registered in native
	# desktop builds too (verified against 4.7.2-stable win64), so online
	# hosting is not a browser-only feature. The only real requirement is the
	# Supabase signaling backend being reachable.
	return SupabaseClient.is_ready and ClassDB.class_exists("WebRTCMultiplayerPeer") \
			and ClassDB.class_exists("WebRTCPeerConnection")

func host_game_web(player_name: String) -> Error:
	if not online_hosting_available():
		return ERR_UNAVAILABLE
	if active:
		_teardown("restart")
	var peer: Variant = ClassDB.instantiate("WebRTCMultiplayerPeer")
	if peer == null:
		return ERR_UNAVAILABLE
	var err: int = peer.create_server()
	if err != OK:
		return err
	multiplayer.server_relay = true
	multiplayer.multiplayer_peer = peer
	_web_peer = peer
	_web_session = true
	var crypto := Crypto.new()
	_web_room = "court-" + crypto.generate_random_bytes(24).hex_encode()
	_web_host_user = SupabaseClient.user_id
	_web_connections.clear()
	_web_remote_ids.clear()
	_web_peer_profiles.clear()
	_web_pending_ice.clear()
	_web_lobby_created = false
	_web_room_join_pending = false
	remote_lobby_code = _web_room
	active = true
	is_host = true
	my_name = player_name
	players = {1: {"name": player_name, "cfg": local_character_dict(), "wr": Career.winrate(), "sid": 0, "side": 1}}
	session_token = randi()
	SupabaseClient.join_room(_web_room)
	_web_offer_pending = true
	lobby_changed.emit()
	return OK

func join_game_web(room: String, host_user: String, player_name: String) -> Error:
	if not online_hosting_available() or room == "":
		return ERR_UNAVAILABLE
	if active:
		_teardown("restart")
	multiplayer.server_relay = true
	_web_room = room
	_web_host_user = host_user
	_web_join_lookup = host_user == ""
	_web_client_name = player_name
	_web_session = true
	_web_room_join_pending = true
	_web_peer = null
	_web_connections.clear()
	_web_remote_ids.clear()
	_web_peer_profiles.clear()
	_web_pending_ice.clear()
	active = true
	is_host = false
	my_name = player_name
	players = {}
	SupabaseClient.join_room(room)
	if _web_join_lookup:
		SupabaseClient.resolve_lobby(room)
	return OK

func _on_web_lobby_created(row: Dictionary) -> void:
	if not _web_session or not is_host:
		return
	_web_lobby_row = row
	_web_lobby_created = true
	lobby_changed.emit()

func _on_web_lobby_error(reason: String) -> void:
	if _web_session and is_host and not _web_lobby_created:
		_teardown("online lobby unavailable: " + reason)

func web_lobby_row() -> Dictionary:
	return _web_lobby_row.duplicate(true)

func _on_web_lobby_resolved(row: Dictionary) -> void:
	if not _web_session or is_host or not _web_join_lookup:
		return
	_web_host_user = String(row.get("owner", ""))
	_web_join_lookup = false
	if _web_host_user == "":
		_teardown("online court not found or expired")
		return
	if SupabaseClient.realtime_ready():
		_on_web_room_joined()

func _on_web_room_joined() -> void:
	if not _web_session or is_host or _web_join_lookup or _web_host_user == "":
		return
	if not SupabaseClient.realtime_ready() or not _web_room_join_pending:
		return
	_web_room_join_pending = false
	SupabaseClient.send_room_message("join_request", {
		"to": _web_host_user,
		"from": SupabaseClient.user_id,
		"name": my_name,
		"cfg": local_character_dict(),
		"wr": Career.winrate(),
		"proto": PROTO,
	})

func _on_web_room_message(kind: String, payload: Dictionary) -> void:
	if kind == "signaling_closed":
		if _web_session:
			_teardown("online signaling connection lost")
		return
	if not _web_session:
		return
	if is_host:
		if String(payload.get("to", "")) != SupabaseClient.user_id:
			return
		if kind == "join_request":
			_web_accept_request(payload)
		elif kind == "webrtc_answer":
			var client_id := String(payload.get("from", ""))
			if int(_web_remote_ids.get(client_id, 0)) == int(payload.get("peer_id", 0)):
				_web_apply_description(payload, "answer")
		elif kind == "webrtc_candidate":
			var client_id := String(payload.get("from", ""))
			if int(_web_remote_ids.get(client_id, 0)) == int(payload.get("peer_id", 0)):
				_web_apply_candidate(payload)
		return
	if String(payload.get("to", "")) != SupabaseClient.user_id:
		return
	var sender := String(payload.get("from", ""))
	if _web_host_user != "" and sender != _web_host_user:
		return
	match kind:
		"webrtc_offer":
			_web_accept_offer(payload)
		"webrtc_candidate":
			_web_apply_candidate(payload)
		"host_id":
			_web_host_user = String(payload.get("from", ""))

func _web_accept_request(payload: Dictionary) -> void:
	var from := String(payload.get("from", ""))
	if from == "" or from == SupabaseClient.user_id or int(payload.get("proto", -1)) != PROTO or _web_remote_ids.has(from):
		return
	var pending_admissions := 0
	for reserved_peer in _web_remote_ids.values():
		if not players.has(int(reserved_peer)):
			pending_admissions += 1
	var capacity := mini(max_humans if max_humans > 0 else MAX_PLAYERS, MAX_PLAYERS)
	if players.size() + pending_admissions >= capacity:
		return
	var peer_id := randi_range(2, 2000000000)
	while _web_connections.has(peer_id) or peer_id == 1:
		peer_id = randi_range(2, 2000000000)
	var pc: Variant = ClassDB.instantiate("WebRTCPeerConnection")
	if pc == null:
		return
	if pc.initialize({"iceServers": [{"urls": ["stun:stun.l.google.com:19302"]}]}) != OK:
		return
	pc.session_description_created.connect(_on_web_session_description.bind(peer_id))
	pc.ice_candidate_created.connect(_on_web_ice_candidate.bind(peer_id))
	if _web_peer.add_peer(pc, peer_id) != OK:
		pc.close()
		return
	_web_connections[peer_id] = pc
	_web_remote_ids[from] = peer_id
	_web_peer_profiles[peer_id] = {
		"name": String(payload.get("name", "player")).left(10),
		"cfg": CharacterConfig.sanitize_dict(payload.get("cfg", {})),
		"wr": clampf(float(payload.get("wr", 0.5)), 0.0, 1.0),
	}
	pc.create_offer()
	_broadcast_lobby()
	lobby_changed.emit()

func _on_web_session_description(type: String, sdp: String, peer_id: int) -> void:
	var remote_id := ""
	for uid in _web_remote_ids:
		if int(_web_remote_ids[uid]) == peer_id:
			remote_id = String(uid)
			break
	if remote_id == "":
		return
	var pc: Variant = _web_connections.get(peer_id)
	if pc == null:
		return
	if pc.set_local_description(type, sdp) != OK:
		return
	var event := "webrtc_offer" if type == "offer" else "webrtc_answer"

	SupabaseClient.send_room_message(event, {
		"to": remote_id,
		"from": SupabaseClient.user_id,
		"peer_id": peer_id,
		"type": type,
		"sdp": sdp,
	})

func _on_web_ice_candidate(media: String, index: int, candidate: String, peer_id: int) -> void:
	var remote_id := ""
	for uid in _web_remote_ids:
		if int(_web_remote_ids[uid]) == peer_id:
			remote_id = String(uid)
			break
	if remote_id != "":
		SupabaseClient.send_room_message("webrtc_candidate", {
			"to": remote_id,
			"from": SupabaseClient.user_id,
			"peer_id": peer_id,
			"media": media,
			"index": index,
			"candidate": candidate,
		})

func _web_accept_offer(payload: Dictionary) -> void:
	var peer_id := int(payload.get("peer_id", 0))
	var host_user := String(payload.get("from", ""))
	if peer_id < 2 or host_user == "":
		return
	_web_host_user = host_user
	var peer: Variant = ClassDB.instantiate("WebRTCMultiplayerPeer")
	var pc: Variant = ClassDB.instantiate("WebRTCPeerConnection")
	if peer == null or pc == null or peer.create_client(peer_id) != OK:
		return
	if pc.initialize({"iceServers": [{"urls": ["stun:stun.l.google.com:19302"]}]}) != OK:
		return
	pc.session_description_created.connect(_on_web_client_description.bind(host_user, peer_id))
	pc.ice_candidate_created.connect(_on_web_client_candidate.bind(host_user, peer_id))
	if peer.add_peer(pc, 1) != OK:
		pc.close()
		return
	_web_peer = peer
	multiplayer.multiplayer_peer = peer
	_web_connections[1] = pc
	var err: int = pc.set_remote_description("offer", String(payload.get("sdp", "")))
	if err != OK:
		_teardown("couldn't establish secure online connection")
		return
	_web_flush_ice(1)

func _on_web_client_description(type: String, sdp: String, host_user: String, peer_id: int) -> void:
	var pc: Variant = _web_connections.get(1)
	if pc == null:
		return
	pc.set_local_description(type, sdp)
	SupabaseClient.send_room_message("webrtc_answer", {
		"to": host_user,
		"from": SupabaseClient.user_id,
		"peer_id": peer_id,
		"type": type,
		"sdp": sdp,
	})

func _on_web_client_candidate(media: String, index: int, candidate: String, host_user: String, peer_id: int) -> void:
	SupabaseClient.send_room_message("webrtc_candidate", {
		"to": host_user,
		"from": SupabaseClient.user_id,
		"peer_id": peer_id,
		"media": media,
		"index": index,
		"candidate": candidate,
	})

func _web_apply_description(payload: Dictionary, expected: String) -> void:
	var peer_id := int(payload.get("peer_id", 0))
	var pc: Variant = _web_connections.get(peer_id)
	if pc != null and String(payload.get("type", expected)) == expected:
		var err: int = pc.set_remote_description(expected, String(payload.get("sdp", "")))
		if err == OK:
			_web_flush_ice(peer_id)

func _web_flush_ice(peer_id: int) -> void:
	var pc: Variant = _web_connections.get(peer_id)
	if pc == null:
		return
	var pending: Array = _web_pending_ice.get(peer_id, [])
	_web_pending_ice.erase(peer_id)
	for candidate in pending:
		pc.add_ice_candidate(String(candidate.media), int(candidate.index), String(candidate.candidate))

func _web_apply_candidate(payload: Dictionary) -> void:
	var from := String(payload.get("from", ""))
	var peer_id := int(payload.get("peer_id", 0))
	if is_host and int(_web_remote_ids.get(from, 0)) != peer_id:
		return
	if not is_host and from != _web_host_user:
		return
	var local_peer_id := peer_id if is_host else 1
	var pc: Variant = _web_connections.get(local_peer_id)
	var candidate := {"media": String(payload.get("media", "")), "index": int(payload.get("index", 0)), "candidate": String(payload.get("candidate", ""))}
	if pc == null:
		var pending_without_peer: Array = _web_pending_ice.get(local_peer_id, [])
		pending_without_peer.append(candidate)
		_web_pending_ice[local_peer_id] = pending_without_peer
		return
	var remote_sdp_ready: bool = pc.get_signaling_state() == WebRTCPeerConnection.SIGNALING_STATE_HAVE_REMOTE_OFFER or (not is_host and pc.get_signaling_state() == WebRTCPeerConnection.SIGNALING_STATE_STABLE)
	if not remote_sdp_ready:
		var pending: Array = _web_pending_ice.get(local_peer_id, [])
		pending.append(candidate)
		_web_pending_ice[local_peer_id] = pending
	else:
		pc.add_ice_candidate(candidate.media, candidate.index, candidate.candidate)

func host_game(player_name: String) -> Error:
	multiplayer.server_relay = false
	if active:

		_teardown("restart")
	var peer: = ENetMultiplayerPeer.new()
	var err: = peer.create_server(host_port(), MAX_PLAYERS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	active = true
	is_host = true
	my_name = player_name
	players = {1: {"name": player_name, "cfg": local_character_dict(), 
		"wr": Career.winrate(), "sid": my_steam_id(), "side": 1}}
	session_token = randi()
	_steam_open_lobby()
	lobby_changed.emit()
	return OK




func split_address(addr: String) -> Array:
	var s: = addr.strip_edges()
	var cut: = s.rfind(":")
	if cut > 0 and not s.ends_with("]") and s.substr(cut + 1).is_valid_int():
		var head: = s.substr(0, cut)
		if head.count(":") == 0 or head.ends_with("]"):
			return [head, int(s.substr(cut + 1))]
	return [s, PORT]




func host_port() -> int:
	var a: = OS.get_cmdline_user_args()
	var i: = a.find("--net-port")
	if i != -1 and i + 1 < a.size() and String(a[i + 1]).is_valid_int():
		return int(a[i + 1])
	return PORT

func join_game(ip: String, player_name: String) -> Error:
	multiplayer.server_relay = false
	if active:
		_teardown("restart")
	var peer: = ENetMultiplayerPeer.new()
	var hp: = split_address(ip)
	var err: = peer.create_client(String(hp[0]), int(hp[1]))
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	active = true
	is_host = false
	my_name = player_name
	players = {}
	_last_join_ip = ip
	return OK

func _notification(what: int) -> void :






	if what == NOTIFICATION_WM_CLOSE_REQUEST and active:
		leave()

func leave() -> void :
	if _web_session:
		if is_host:
			SupabaseClient.close_lobby()
		else:
			SupabaseClient.leave_room()
		_web_session = false
		multiplayer.server_relay = false
	if is_host and active and _has_live_peer():
		_s_session_closing.rpc()
	elif active and not is_host and _has_live_peer()\
	and multiplayer.multiplayer_peer.get_connection_status()\
	== MultiplayerPeer.CONNECTION_CONNECTED:
		_c_bye.rpc_id(1)

		multiplayer.poll()
	_teardown("left")

@rpc("authority", "call_remote", "reliable")
func _s_session_closing() -> void :
	if not is_host:
		_teardown("host left")

func _teardown(reason: String) -> void :
	if not active:
		return
	QuickPlay.qlog("teardown: %s (host=%s players=%d)" % [reason, str(is_host), players.size()])
	_steam_close_lobby()
	if _web_session:
		if is_host:
			SupabaseClient.close_lobby()
		else:
			SupabaseClient.leave_room()
		multiplayer.server_relay = false
	_web_session = false
	_web_join_lookup = false
	_web_offer_pending = false
	_web_room_join_pending = false
	_web_lobby_created = false
	_web_room = ""
	_web_host_user = ""
	remote_lobby_code = ""
	_web_connections.clear()
	_web_remote_ids.clear()
	_web_peer_profiles.clear()
	_web_pending_ice.clear()
	_web_peer = null
	_steam_peer = null
	_steam_hosting = false
	custom_lobby = false
	cpu_slots = {}
	party_lan = false
	last_players = players.duplicate(true)
	last_chat = chat_log.duplicate(true)
	active = false
	is_host = false
	_rtt_ms = 0.0
	_ping_next = 0
	_peer_rtt.clear()
	_peer_heard_ms.clear()
	in_match = false
	gym_session = false
	party = false
	quick_queue = false
	quick_ad_open = 0
	migrate_open = false
	remote_lobby_code = ""
	code_key = ""
	_lobby_kind = "custom"



	privacy = Priv.PUBLIC
	password = ""
	max_humans = 0
	if _quick_udp != null:
		_quick_udp.close()
		_quick_udp = null
	players = {}

	chat_log.clear()
	_chat_last_ms.clear()
	_chat_burst.clear()
	_typing_until.clear()
	_typing_names = []
	_typing_sent = false
	team_of = Callable()
	room_of = Callable()
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	session_ended.emit(reason)

func peer_rtt_ms(peer_id: int) -> float:

	if _steam_peer != null:




		if is_host:
			return float(_peer_rtt.get(peer_id, fake_latency_ms))
		return _rtt_ms if _rtt_ms > 0.0 else float(fake_latency_ms)
	var enet: = multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if enet == null:
		return float(fake_latency_ms)





	if not multiplayer.get_peers().has(peer_id):
		return float(fake_latency_ms)
	var p: = enet.get_peer(peer_id)
	if p == null:
		return float(fake_latency_ms)
	return p.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)\
	+ float(fake_latency_ms)



func _on_peer_connected(id: int) -> void :







	if _web_session and is_host and _web_peer_profiles.has(id):
		var profile: Dictionary = _web_peer_profiles[id]
		_web_peer_profiles.erase(id)
		_hello_admit(id, String(profile.get("name", "player")),
			profile.get("cfg", {}), PROTO, float(profile.get("wr", 0.5)), [], 0, "", 0)
		return
	if not is_host:
		return
	if players.has(id):
		players.erase(id)
		_broadcast_lobby()
		lobby_changed.emit()
	_hello_peer_t.erase(id)






enum Priv{PUBLIC, FRIENDS, PASSWORD}
var privacy: int = Priv.PUBLIC
var password: = ""
var join_password: = ""




func _is_friend(sid: int) -> bool:
	if _steam == null or sid == 0:
		return false
	if not _steam.has_method("getFriendRelationship"):
		return true

	return int(_steam.getFriendRelationship(sid)) == 3

func local_character_dict() -> Dictionary:
	var cfg: CharacterConfig = GameConfig.character
	return cfg.to_dict() if cfg != null else {}

func _on_connected() -> void :
	_c_hello.rpc_id(1, my_name, local_character_dict(), PROTO, 
		Career.winrate(), quick_join_modes, my_steam_id(), join_password, 
		quick_party_token)
	quick_join_modes = []
	quick_party_token = 0
	join_password = ""




func my_steam_id() -> int:
	return int(_steam.getSteamID()) if _steam != null else 0

func _on_peer_disconnected(id: int) -> void :
	QuickPlay.qlog("peer %d disconnected (host=%s)" % [id, str(is_host)])
	if not is_host:
		if _web_session:
			_teardown("host left")
		return
	players.erase(id)
	_peer_heard_ms.erase(id)
	if _web_session:
		var user_to_remove := ""
		for uid in _web_remote_ids:
			if int(_web_remote_ids[uid]) == id:
				user_to_remove = String(uid)
				break
		if user_to_remove != "":
			_web_remote_ids.erase(user_to_remove)
			_web_connections.erase(id)
			_web_peer_profiles.erase(id)
			SupabaseClient.update_lobby({"humans": players.size(), "updated_at": Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system()), true) + "+00:00"})
	if in_match:
		peer_left_match.emit(id)




	_broadcast_lobby()
	lobby_changed.emit()





signal quick_modes_requested(modes: Array)



signal quick_status(text: String)

func quick_status_push(text: String) -> void :
	if is_host and active:
		_s_quick_status.rpc(text)

@rpc("authority", "call_remote", "reliable")
func _s_quick_status(text: String) -> void :
	_recv( func(): quick_status.emit(text))
var quick_join_modes: Array = []



var quick_party_token: = 0






var home_party: = {}
var _last_join_ip: = ""



var quick_queue: = false

@rpc("any_peer", "call_remote", "reliable")
func _c_hello(player_name: String, cfg: Dictionary, proto: = 0, 
	wr: = 0.5, quick_modes: Array = [], steam_id: = 0, pw: = "", 
	ptoken: = 0) -> void :
	if not is_host:
		return
	var id: = multiplayer.get_remote_sender_id()



	if players.has(id):
		return
	if not _rate_ok(_hello_peer_t, id, 2, 10000):
		return
	_hello_admit(id, player_name, cfg, proto, wr, quick_modes, steam_id, pw, ptoken)




func _hello_admit(id: int, player_name: String, cfg: Dictionary, proto: int, 
		wr: float, quick_modes: Array, steam_id: int, pw: String, ptoken: int, 
		dup_settled: = false) -> void :
	if not is_host or players.has(id):
		return
	if dup_settled and not multiplayer.get_peers().has(id):
		return


	if players.size() >= MAX_PLAYERS:
		refuse_peer(id, "lobby is full")
		return


	player_name = sanitize_name(player_name)




	if _steam_peer != null and _steam_peer.has_method("get_steam_id_for_peer_id"):
		steam_id = int(_steam_peer.call("get_steam_id_for_peer_id", id))

















	if steam_id != 0 and _steam_peer != null:
		var old: = _same_sid_peer(steam_id, id)
		if old != 0:
			var old_alive: bool = Time.get_ticks_msec()\
			- int(_peer_heard_ms.get(old, 0)) < DUP_LIVE_MS
			if old_alive and not dup_settled:
				var tree: = Engine.get_main_loop() as SceneTree
				if tree != null:
					tree.create_timer(DUP_SETTLE_S).timeout.connect(
						_hello_admit.bind(id, player_name, cfg, proto, wr, 
							quick_modes, steam_id, pw, ptoken, true))
					return
			if old_alive:
				refuse_peer(id, "you're already in this lobby from another copy of the game")
				return
			_evict_ghost(steam_id, id)



	if not quick_modes.is_empty() and not (quick_queue or quick_ad_open > 0 or migrate_open):
		quick_modes = []

	cfg = CharacterConfig.sanitize_dict(cfg)
	wr = clampf(wr, 0.0, 1.0) if is_finite(wr) else 0.5


	if not _rate_ok(_hello_t, 0, HELLO_BURST, 10000):
		refuse_peer(id, "busy, try again in a moment")
		return



	if not proto_ok(proto):
		refuse_peer(id, "version mismatch, update the game")
		return





	var keyed: = privacy == Priv.PASSWORD and code_key != "" and pw == code_key
	if privacy == Priv.PASSWORD and pw != password and not keyed:
		_rate_ok(_pw_fail_t, 0, PW_TRIES, PW_WINDOW_MS)
		refuse_peer(id, "wrong password")
		return
	if privacy == Priv.PASSWORD and not keyed\
	and not _rate_ok(_pw_fail_t, 0, PW_TRIES, PW_WINDOW_MS, false):
		refuse_peer(id, "too many wrong passwords, wait a minute")
		return
	if privacy == Priv.FRIENDS and _steam != null\
	and not _is_friend(steam_id):
		refuse_peer(id, "friends only")
		return




	if party and quick_modes.is_empty() and _steam != null and not party_lan:
		var invited: bool = party_invited.has(steam_id)
		if party_privacy == PartyPriv.PRIVATE and not invited:
			refuse_peer(id, "this party is invite-only")
			return
		if party_privacy == PartyPriv.FRIENDS\
		and not (invited or _is_friend(steam_id)):
			refuse_peer(id, "this party is friends-only")
			return

	if party and players.size() >= PARTY_MAX:
		refuse_peer(id, "party is full")
		return




	if not party and not gym_session and quick_modes.is_empty()\
	and max_humans > 0 and players.size() >= max_humans:
		refuse_peer(id, "lobby is full")
		return


	var side_1: = 0
	for p in players.values():
		if p.side == 1:
			side_1 += 1
	players[id] = {		"name": player_name, "cfg": cfg, "wr": wr, 
		"sid": steam_id,  










		"qjoin": not quick_modes.is_empty() or quick_queue or GameConfig.quick_match, 


		"ptoken": ptoken, 
		"side": 0 if gym_session\
		else (1 if side_1 * 2 < players.size() + 1 else -1)}



	if party and quick_modes.is_empty() and steam_id != 0 and not quick_queue:
		party_invited[steam_id] = true
	QuickPlay.qlog("hello ACCEPT peer %d '%s' modes=%s ptoken=%d qjoin=%s party=%s quick_queue=%s quick_match=%s"
		%[id, player_name, str(quick_modes), ptoken, str(players[id].qjoin), 
		str(party), str(quick_queue), str(GameConfig.quick_match)])
	if not quick_modes.is_empty():
		quick_modes_requested.emit(quick_modes)
















	if party and quick_modes.is_empty() and not quick_queue and not GameConfig.quick_match:
		send_join_party(id)
	_broadcast_lobby()
	if _web_session:
		SupabaseClient.update_lobby({"humans": players.size(), "updated_at": Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system()), true) + "+00:00"})
	lobby_changed.emit()
	if in_match:


		late_joiner.emit(id)




@rpc("authority", "call_remote", "reliable")
func _s_refused(reason: String) -> void :
	_teardown(reason)







const HELLO_BURST: = 32
const PW_TRIES: = 3
const PW_WINDOW_MS: = 60000
var _hello_t: = {}
var _hello_peer_t: = {}
var _pw_fail_t: = {}
var _rpc_t: = {}



func _rpc_ok(peer: int, kind: String, limit: int, window_ms: = 1000) -> bool:
	return _rate_ok(_rpc_t, "%d:%s" % [peer, kind], limit, window_ms)

func _rate_ok(bucket: Dictionary, key: Variant, limit: int, window_ms: int, record: = true) -> bool:
	var now: = Time.get_ticks_msec()
	var arr: Array = bucket.get(key, [])
	while not arr.is_empty() and now - int(arr[0]) > window_ms:
		arr.pop_front()
	if arr.size() >= limit:
		bucket[key] = arr
		return false
	if record:
		arr.append(now)
	bucket[key] = arr
	return true

func refuse_peer(id: int, reason: String) -> void :
	if not is_host:
		return
	QuickPlay.qlog("REFUSE peer %d: %s" % [id, reason])
	_s_refused.rpc_id(id, reason)
	players.erase(id)
	_broadcast_lobby()
	lobby_changed.emit()
	var tree: = Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.create_timer(0.5).timeout.connect( func(): _kick_peer(id))
	else:
		_kick_peer(id)



var _peer_heard_ms: = {}
const DUP_LIVE_MS: = 1500
const DUP_SETTLE_S: = 1.6


func _same_sid_peer(sid: int, not_id: int) -> int:
	for pid in players:
		if pid != not_id and pid != 1 and int(players[pid].get("sid", 0)) == sid:
			return int(pid)
	return 0





func _evict_ghost(sid: int, keep_id: int) -> void :
	for old in players.keys():
		if old == keep_id or old == 1 or int(players[old].get("sid", 0)) != sid:
			continue
		players.erase(old)
		_hello_peer_t.erase(old)
		if in_match:
			peer_left_match.emit(old)
		_kick_peer(old)





@rpc("any_peer", "call_remote", "reliable")
func _c_bye() -> void :
	if not is_host:
		return
	var id: = multiplayer.get_remote_sender_id()
	if players.has(id):
		_on_peer_disconnected(id)

func _kick_peer(id: int) -> void :
	var peer: = multiplayer.multiplayer_peer
	if peer == null or not peer.has_method("disconnect_peer"):
		return


	if not multiplayer.get_peers().has(id):
		return
	peer.disconnect_peer(id)

@rpc("any_peer", "call_remote", "reliable")
func _c_pick_side(side: int) -> void :
	if not is_host:
		return
	var id: = multiplayer.get_remote_sender_id()
	if not _rpc_ok(id, "side", 2):
		return


	if players.has(id) and (side == 1 or side == -1 or side == 0):
		players[id].side = side
		_broadcast_lobby()
		lobby_changed.emit()

func pick_side(side: int) -> void :
	if is_host:
		players[1].side = side
		_broadcast_lobby()
		lobby_changed.emit()
	else:
		_c_pick_side.rpc_id(1, side)








func shuffle_sides() -> void :
	if not is_host:
		return
	var ids: = players.keys()
	var before: = {}
	for id in ids:
		before[id] = int(players[id].side)
	var dealt: = {}
	for _attempt in 12:
		ids.shuffle()
		dealt = {}
		var count: = {1: 0, -1: 0}
		for id in ids:
			var open: Array = []
			if count[1] < team_size:
				open.append(1)
			if count[-1] < team_size:
				open.append(-1)
			var side: int = 0 if open.is_empty() else int(open[randi() % open.size()])
			dealt[id] = side
			if side != 0:
				count[side] += 1
		if dealt != before:
			break
	for id in ids:
		players[id].side = dealt[id]
	_broadcast_lobby()
	lobby_changed.emit()

func set_team_size(size: int) -> void :
	if is_host:
		team_size = size
		if _web_session:
			SupabaseClient.update_lobby({"mode": "%dv%d" % [team_size, team_size], "updated_at": Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system()), true) + "+00:00"})
		_broadcast_lobby()
		lobby_changed.emit()






func build_roster(ids: Array, players: Dictionary, team_size: int, 
		kits: Dictionary, cpus: Dictionary = {}) -> Array:
	var roster: Array = []
	var counts: = {1: 0, -1: 0}
	var watching: Array = []
	for id in ids:
		var side: int = players[id].side



		if side == 0:


			watching.append({"peer": id, "name": players[id].name, 
				"side": 0, "slot": -1, "spec": true, 
				"cfg": players[id].get("cfg", {}), "kit": kits[1]})
			continue
		if counts[side] >= team_size:
			watching.append({"peer": id, "name": players[id].name, 
				"side": side, "slot": -1, "spec": true, 
				"cfg": players[id].get("cfg", {}), "kit": kits[side]})
			continue
		roster.append({"peer": id, "name": players[id].name, 
			"side": side, "slot": counts[side], 
			"cfg": players[id].get("cfg", {}), "kit": kits[side]})
		counts[side] += 1
	for side in [1, -1]:
		for i in range(counts[side], team_size):
			var e: = {"peer": 0, "name": "cpu %d" % (i + 1), 
				"side": side, "slot": i, "cfg": {}, "kit": kits[side]}




			var cpu: = CpuSlots.lookup(cpus, side, i - counts[side])
			if not cpu.is_empty():
				e["cfg"] = cpu.cfg
				e["cname"] = cpu.name
				e["diff"] = cpu.diff
			roster.append(e)



	roster.append_array(watching)
	return roster





func captain_kits(players: Dictionary) -> Dictionary:
	var dressed: = players.keys().filter( func(id):
		return not (players[id].get("cfg", {}) as Dictionary).is_empty())
	if dressed.is_empty():
		return {1: GameConfig.team_kit(true).map( func(c): return (c as Color).to_html(false)), 
			-1: GameConfig.team_kit(false).map( func(c): return (c as Color).to_html(false))}
	var captain: Dictionary = players[dressed[randi() % dressed.size()]]
	var cfg: = CharacterConfig.from_dict(captain.cfg)
	return {1: cfg.kit_home.map( func(c): return (c as Color).to_html(false)), 
		-1: cfg.kit_away.map( func(c): return (c as Color).to_html(false))}

func set_cpu_difficulty(level: int) -> void :
	if is_host:
		cpu_difficulty = clampi(level, 0, 2)

		CpuSlots.set_all_diff(cpu_slots, cpu_difficulty)
		_broadcast_lobby()
		lobby_changed.emit()


func set_cpu_slots(slots: Dictionary) -> void :
	if is_host:
		cpu_slots = slots
		_broadcast_lobby()
		lobby_changed.emit()




func sync_lobby() -> void :
	if is_host:
		_broadcast_lobby()
		lobby_changed.emit()

func set_stage(id: String) -> void :
	if is_host:
		stage = id
		if _web_session:
			SupabaseClient.update_lobby({"stage": stage, "updated_at": Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system()), true) + "+00:00"})
		_broadcast_lobby()
		lobby_changed.emit()




func _has_live_peer() -> bool:
	var p: = multiplayer.multiplayer_peer
	return p != null and not (p is OfflineMultiplayerPeer)

func _broadcast_lobby() -> void :
	if not _has_live_peer():
		return



	var shared: = {}
	for pid in players:
		var row: Dictionary = (players[pid] as Dictionary).duplicate()
		row.erase("wr")
		row.erase("ptoken")
		shared[pid] = row



	_s_lobby.rpc(shared, team_size, cpu_difficulty, stage, session_token, 
		{"pts": rule_points, "sets": rule_sets, "wbt": rule_wbt, 
		"sweat": rule_sweat, "rate": rule_rate, "code": shared_lobby_code()}, cpu_slots)



	if _steam != null and steam_lobby_id != 0:
		_steam.setLobbyData(steam_lobby_id, "humans", str(players.size()))
		_steam.setLobbyData(steam_lobby_id, "cap", 
			str(max_humans if max_humans > 0 else MAX_PLAYERS))

@rpc("authority", "call_remote", "reliable")
func _s_lobby(lobby_players: Dictionary, size: int, cpu_diff: int, 
		stage_id: = "nationals", token: = 0, rules: = {}, cpus: = {}) -> void :


	if lobby_players.size() > MAX_PLAYERS * 2:
		return
	for k in lobby_players:
		if not (k is int) or not (lobby_players[k] is Dictionary):
			return
	if size < 1 or size > 6:
		return
	players = lobby_players
	team_size = size
	cpu_difficulty = cpu_diff
	stage = stage_id
	if token != 0:
		session_token = token
	if not rules.is_empty():
		rule_points = int(rules.get("pts", rule_points))
		rule_sets = int(rules.get("sets", rule_sets))
		rule_wbt = bool(rules.get("wbt", rule_wbt))
		rule_sweat = bool(rules.get("sweat", rule_sweat))
		rule_rate = float(rules.get("rate", rule_rate))






		if rules.has("code"):
			remote_lobby_code = String(rules.get("code", ""))
	cpu_slots = CpuSlots.sanitize(cpus)
	lobby_changed.emit()



var match_ready_peers: = {}

func start_match(roster: Array, seed: int) -> void :



	in_match = true
	if _web_session and is_host:
		SupabaseClient.update_lobby({"state": "game", "humans": players.size(), "updated_at": Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system()), true) + "+00:00"})
	quick_queue = false
	match_ready_peers = {}
	GameConfig.match_seed = seed


	if _steam != null and steam_lobby_id != 0:
		_steam.setLobbyData(steam_lobby_id, "state", "game")
		_steam.setLobbyData(steam_lobby_id, "mode", 
			"%dv%d" % [team_size, team_size])
		_steam.setLobbyData(steam_lobby_id, "map", Stage.title(stage))
		_steam.setLobbyData(steam_lobby_id, "stage", stage)





	if _has_live_peer():
		_s_start.rpc(roster, seed, stage, GameConfig.quick_match)
	match_started.emit(roster)

func notify_match_ready() -> void :

	_c_match_ready.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _c_match_ready() -> void :
	if not is_host:
		return
	var id: = multiplayer.get_remote_sender_id()
	if match_ready_peers.get(id, false) or not _rpc_ok(id, "ready", 2):
		return
	match_ready_peers[id] = true
	peer_match_ready.emit(id)

@rpc("authority", "call_remote", "reliable")
func _s_start(roster: Array, seed: int, stage_id: = "", quick: = false) -> void :
	if not roster_ok(roster):
		return
	in_match = true
	quick_queue = false
	GameConfig.match_seed = seed
	if stage_id != "":
		stage = stage_id







	GameConfig.quick_match = quick
	match_started.emit(roster)

func end_match() -> void :
	in_match = false
	if _web_session and is_host:
		SupabaseClient.update_lobby({"state": "lobby", "updated_at": Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system()), true) + "+00:00"})
	gym_session = false
	quick_backfill_ad(0)
	if is_host:






		if party:
			for pid in players.keys():

				if pid != 1 and bool(players[pid].get("qjoin", false)):
					refuse_peer(pid, "the host left the match")

		_broadcast_lobby()





	quick_seek_visible(false)
	if _steam != null and steam_lobby_id != 0:
		_steam.setLobbyData(steam_lobby_id, "state", "lobby")






signal gym_joined
signal gym_state_received(data: Dictionary)

var gym_session: = false

func host_gym(player_name: String, force_lan: = false) -> Error:
	var err: = host_game_steam(player_name)\
	if steam_transport_available() and not force_lan\
	else host_game(player_name)
	if err == OK:
		gym_session = true
		in_match = true
		_lobby_kind = "gym"



		_ensure_quick_udp(true)
	return err


var _lobby_kind: = "custom"





func mark_lobby_hidden() -> void :
	_lobby_kind = "locked"

func send_join_gym(id: int) -> void :
	if is_host:
		_s_join_gym.rpc_id(id)




func gym_from_party() -> void :
	if not is_host or not party:
		return
	gym_session = true
	in_match = true
	_lobby_kind = "gym"
	_ensure_quick_udp(true)
	for pid in players:
		if pid != 1:
			send_join_gym(pid)
	gym_joined.emit()

@rpc("authority", "call_remote", "reliable")
func _s_join_gym() -> void :
	in_match = true
	gym_session = true
	quick_queue = false
	gym_joined.emit()

func send_gym_state(data: Dictionary) -> void :
	if fake_loss_pct > 0 and randi() % 100 < fake_loss_pct:
		return
	var bytes: = StateCodec.encode_gym(data)
	_send( func(): _s_gym_state.rpc(bytes))

@rpc("authority", "call_remote", "unreliable_ordered")
func _s_gym_state(bytes: PackedByteArray) -> void :
	var data: = StateCodec.decode_gym(bytes)
	if data.is_empty():
		return
	_recv( func(): gym_state_received.emit(data))









signal party_joined

var party: = false
const PARTY_MAX: = 6



enum PartyPriv{PRIVATE, FRIENDS, FOF}
const PARTY_PRIV_NAMES: = ["private", "friends only", "friends of friends"]
var party_privacy: = PartyPriv.PRIVATE



var party_invited: = {}

func set_party_privacy(level: int) -> void :
	party_privacy = clampi(level, 0, 2)
	_apply_party_lobby_type()
	lobby_changed.emit()



func _apply_party_lobby_type() -> void :
	if not party or _steam == null or steam_lobby_id == 0:
		return
	if _steam.has_method("setLobbyType"):
		_steam.setLobbyType(steam_lobby_id, [0, 1, 2][party_privacy])








func quick_seek_visible(on: bool) -> void :
	if not party or _steam == null or steam_lobby_id == 0:
		return
	if on:
		if _steam.has_method("setLobbyType"):
			_steam.setLobbyType(steam_lobby_id, 2)
	else:
		_apply_party_lobby_type()


		_steam.setLobbyData(steam_lobby_id, "kind", _lobby_kind)

func host_party(player_name: String, force_lan: = false) -> Error:
	var err: = host_game_steam(player_name)\
	if steam_transport_available() and not force_lan\
	else host_game(player_name)
	if err == OK:
		party = true





		privacy = Priv.PUBLIC
		password = ""
		party_privacy = PartyPriv.PRIVATE
		party_invited = {}
		_lobby_kind = "party"
		party_lan = force_lan
	return err








func i_am_fold() -> bool:
	if not active or is_host:
		return false
	var me: Dictionary = players.get(multiplayer.get_unique_id(), {})
	return bool(me.get("qjoin", false))




func drop_folds(reason: String) -> void :
	if not is_host or not party:
		return
	for pid in players.keys():
		if pid != 1 and bool(players[pid].get("qjoin", false)):
			refuse_peer(pid, reason)

func party_members() -> Array:
	if not party:
		return []
	var out: Array = []
	for pid in players:
		if not bool(players[pid].get("qjoin", false)):
			out.append(pid)
	return out

func send_join_party(id: int) -> void :
	if is_host:
		_s_join_party.rpc_id(id)



func kick_from_party(id: int) -> void :
	if is_host and id != 1 and players.has(id):
		refuse_peer(id, "removed from the party")










signal party_travel_to(host_id: int, code: String)

signal party_home_called(leader_sid: int)





func send_party_home() -> void :
	if not active:
		return
	var sid: = my_steam_id()
	if is_host:
		_s_party_home.rpc(sid)
	else:
		_c_party_home.rpc_id(1, sid)



	multiplayer.poll()

@rpc("any_peer", "call_remote", "reliable")
func _c_party_home(leader_sid: int) -> void :
	if not is_host:
		return
	_s_party_home.rpc(leader_sid)

@rpc("authority", "call_remote", "reliable")
func _s_party_home(leader_sid: int) -> void :
	party_home_called.emit(leader_sid)

func rehome_party(host_id: int, host_ip: String, modes: Array, token: int) -> void :
	if is_host:
		_s_rehome.rpc(host_id, host_ip, modes, token)

@rpc("authority", "call_remote", "reliable")
func _s_rehome(host_id: int, host_ip: String, modes: Array, token: int) -> void :
	_recv( func(): _do_rehome(host_id, host_ip, modes, token))

func _do_rehome(host_id: int, host_ip: String, modes: Array, token: int) -> void :




	home_party = {
		"is_leader": false, 
		"leader_sid": int((players.get(1, {}) as Dictionary).get("sid", 0)), 
		"leader_ip": _last_join_ip, 
		"token": token, 



		"room": modes.is_empty() and token == 0, 
	}


	quick_join_modes = modes.duplicate()
	quick_party_token = token
	var ok: = false
	if host_id != 0:
		ok = join_game_steam(host_id, my_name) == OK
	elif host_ip != "":
		ok = join_game(host_ip, my_name) == OK
	QuickPlay.qlog("rehome -> %s/%d token=%d ok=%s" % [host_ip, host_id, token, str(ok)])
	if not ok:


		home_party = {}
		_teardown("couldn't join the match")

@rpc("authority", "call_remote", "reliable")
func _s_join_party() -> void :

	party = true
	custom_lobby = false
	quick_queue = false
	party_joined.emit()






signal freeplay_pose(peer_id: int, st: PackedFloat32Array)

func send_freeplay_pose(st: PackedFloat32Array) -> void :



	if not active or not party or multiplayer.multiplayer_peer == null:
		return
	if is_host:
		_s_freeplay_pose.rpc(1, st)
	else:
		_c_freeplay_pose.rpc_id(1, st)





@rpc("any_peer", "call_remote", "unreliable")
func _c_freeplay_pose(st: PackedFloat32Array) -> void :
	if not is_host:
		return
	var sid: = multiplayer.get_remote_sender_id()
	if not party or not players.has(sid) or not _rpc_ok(sid, "pose", 100)\
	or bool(players[sid].get("qjoin", false)):
		return
	if not pose_ok(st, Player.NET_FLOATS):
		return
	freeplay_pose.emit(sid, st)
	_s_freeplay_pose.rpc(sid, st)

@rpc("authority", "call_remote", "unreliable")
func _s_freeplay_pose(peer_id: int, st: PackedFloat32Array) -> void :
	if pose_ok(st, Player.NET_FLOATS):
		freeplay_pose.emit(peer_id, st)


static func pose_ok(st: PackedFloat32Array, need: int) -> bool:
	if st.size() < need or st.size() > 96:
		return false
	for v in st:
		if not is_finite(v):
			return false
	return true






signal ball_pose(peer_id: int, st: PackedFloat32Array, bid: int)

func send_ball_pose(st: PackedFloat32Array, bid: int) -> void :
	if not active or not party or multiplayer.multiplayer_peer == null:
		return
	if is_host:
		_s_ball_pose.rpc(1, st, bid)
	else:
		_c_ball_pose.rpc_id(1, st, bid)

@rpc("any_peer", "call_remote", "unreliable")
func _c_ball_pose(st: PackedFloat32Array, bid: int) -> void :
	if not is_host:
		return
	var sid: = multiplayer.get_remote_sender_id()
	if not party or not players.has(sid) or not _rpc_ok(sid, "bpose", 100)\
	or bool(players[sid].get("qjoin", false)):
		return
	if not pose_ok(st, 7) or not players.has(bid):
		return
	ball_pose.emit(sid, st, bid)
	_s_ball_pose.rpc(sid, st, bid)

@rpc("authority", "call_remote", "unreliable")
func _s_ball_pose(peer_id: int, st: PackedFloat32Array, bid: int) -> void :
	if pose_ok(st, 7) and players.has(bid):
		ball_pose.emit(peer_id, st, bid)



signal freeplay_fx(peer_id: int, kind: int, pos: Vector3, power: float, vel: Vector3)

func send_freeplay_fx(kind: int, pos: Vector3, power: float, vel: Vector3) -> void :
	if not active or not party:
		return
	if is_host:
		_s_freeplay_fx.rpc(1, kind, pos, power, vel)
	else:
		_c_freeplay_fx.rpc_id(1, kind, pos, power, vel)

@rpc("any_peer", "call_remote", "reliable")
func _c_freeplay_fx(kind: int, pos: Vector3, power: float, vel: Vector3) -> void :
	if not is_host:
		return
	var sid: = multiplayer.get_remote_sender_id()


	if not party or not players.has(sid) or not _rpc_ok(sid, "fx", 10)\
	or bool(players[sid].get("qjoin", false)):
		return
	if not (pos.is_finite() and vel.is_finite() and is_finite(power)):
		return
	freeplay_fx.emit(sid, kind, clampf(power, 0.0, 2.0), pos, vel)
	_s_freeplay_fx.rpc(sid, kind, pos, clampf(power, 0.0, 2.0), vel)

@rpc("authority", "call_remote", "reliable")
func _s_freeplay_fx(peer_id: int, kind: int, pos: Vector3, power: float, 
		vel: Vector3) -> void :
	freeplay_fx.emit(peer_id, kind, pos, power, vel)



signal party_look(peer_id: int, outfit: String)

func send_party_look(outfit: String) -> void :




	if not active:
		return



	var cfg: = local_character_dict()
	if is_host:
		if players.has(1):
			players[1]["cfg"] = cfg






		if multiplayer.has_multiplayer_peer():
			_s_party_look.rpc(1, outfit, cfg)
	elif multiplayer.has_multiplayer_peer():
		_c_party_look.rpc_id(1, outfit, cfg)

@rpc("any_peer", "call_remote", "reliable")
func _c_party_look(outfit: String, cfg: Dictionary) -> void :
	if not is_host:
		return
	var sid: = multiplayer.get_remote_sender_id()
	cfg = CharacterConfig.sanitize_dict(cfg)
	if not _rate_ok(_look_t, sid, 4, 2000):
		return
	if players.has(sid):
		players[sid]["cfg"] = cfg
	party_look.emit(sid, outfit)
	_s_party_look.rpc(sid, outfit, cfg)

@rpc("authority", "call_remote", "reliable")
func _s_party_look(peer_id: int, outfit: String, cfg: Dictionary) -> void :
	if players.has(peer_id):
		players[peer_id]["cfg"] = cfg
	party_look.emit(peer_id, outfit)




signal party_ball(peer_id: int, skin: String)

func send_party_ball(skin: String) -> void :


	if not active or not party or not multiplayer.has_multiplayer_peer():
		return
	if is_host:
		_s_party_ball.rpc(1, skin)
	else:
		_c_party_ball.rpc_id(1, skin)

@rpc("any_peer", "call_remote", "reliable")
func _c_party_ball(skin: String) -> void :
	if not is_host:
		return
	var sid: = multiplayer.get_remote_sender_id()
	if not party or not players.has(sid) or not _rpc_ok(sid, "ball", 2, 2000):
		return
	if skin.length() > 32 or not Stage.STAGES.has(skin):
		return
	party_ball.emit(sid, skin)
	_s_party_ball.rpc(sid, skin)

@rpc("authority", "call_remote", "reliable")
func _s_party_ball(peer_id: int, skin: String) -> void :
	party_ball.emit(peer_id, skin)




signal party_stage(stage_id: String)

func send_party_stage(stage_id: String) -> void :
	if not active or not party:
		return
	if is_host:
		_s_party_stage.rpc(stage_id)
	else:
		_c_party_stage.rpc_id(1, stage_id)

@rpc("any_peer", "call_remote", "reliable")
func _c_party_stage(stage_id: String) -> void :
	if not is_host:
		return
	var sid: = multiplayer.get_remote_sender_id()


	if not party or not players.has(sid) or not _rpc_ok(sid, "stage", 1, 2000):
		return
	if not Stage.STAGES.has(stage_id) or bool(Stage.info(stage_id).get("hidden", false)):
		return
	party_stage.emit(stage_id)
	_s_party_stage.rpc(stage_id)

@rpc("authority", "call_remote", "reliable")
func _s_party_stage(stage_id: String) -> void :
	party_stage.emit(stage_id)







signal late_joiner(id: int)

func send_late_join(id: int, roster: Array, auto_side: int) -> void :
	if is_host:
		_s_join_match.rpc_id(id, roster, stage, team_size, auto_side, 
			GameConfig.match_seed)

@rpc("authority", "call_remote", "reliable")
func _s_join_match(roster: Array, stage_id: String, size: int, 
	auto_side: = 0, seed: = 0) -> void :
	if not roster_ok(roster) or size < 1 or size > 6:
		return
	in_match = true
	quick_queue = false
	team_size = size
	if stage_id != "":
		stage = stage_id


	if seed != 0:
		GameConfig.match_seed = seed
	GameConfig.quick_backfill_side = auto_side
	match_started.emit(roster)



const ROSTER_MAX: = MAX_PLAYERS * 2
static func roster_ok(roster: Array) -> bool:
	if roster.size() > ROSTER_MAX:
		return false
	for e in roster:
		if not (e is Dictionary):
			return false
		if not ((e as Dictionary).get("peer", 0) is int) or not ((e as Dictionary).get("side", 0) is int):
			return false
	return true



func _delay_half() -> int:
	return int(fake_latency_ms / 2.0)




func _delay_one() -> int:
	var d: = int(fake_latency_ms / 2.0)
	if fake_jitter_ms > 0:
		d += randi() % (fake_jitter_ms + 1)
	return d

func _send(fn: Callable) -> void :





	if not _can_send():
		return
	if fake_latency_ms <= 0 and fake_jitter_ms <= 0:
		fn.call()
	else:
		_out_queue.append({"at": Time.get_ticks_msec() + _delay_one(), "fn": fn})

func _can_send() -> bool:
	return active and multiplayer.multiplayer_peer != null\
	and multiplayer.multiplayer_peer.get_connection_status()\
	== MultiplayerPeer.CONNECTION_CONNECTED

func _recv(fn: Callable) -> void :
	if fake_latency_ms <= 0 and fake_jitter_ms <= 0:
		fn.call()
	else:
		_in_queue.append({"at": Time.get_ticks_msec() + _delay_one(), "fn": fn})





func ping_host() -> void :
	if is_host or not active:
		return
	_send( func(): _c_ping.rpc_id(1, Time.get_ticks_msec()))

@rpc("any_peer", "call_remote", "unreliable")
func _c_ping(t: int) -> void :
	if not is_host:
		return
	var who: = multiplayer.get_remote_sender_id()
	if not _rpc_ok(who, "ping", 8):
		return
	_peer_heard_ms[who] = Time.get_ticks_msec()
	_recv( func(): _send( func(): _s_pong.rpc_id(who, t)))

@rpc("authority", "call_remote", "unreliable")
func _s_pong(t: int) -> void :
	_recv( func():
		var sample: = float(Time.get_ticks_msec() - t)

		_rtt_ms = sample if _rtt_ms <= 0.0 else lerpf(_rtt_ms, sample, 0.2)


		_send( func(): _c_rtt.rpc_id(1, _rtt_ms)))

@rpc("any_peer", "call_remote", "unreliable")
func _c_rtt(ms: float) -> void :
	var who: = multiplayer.get_remote_sender_id()

	var safe: = clampf(ms, 0.0, 600.0) if is_finite(ms) else 0.0
	_recv( func(): _peer_rtt[who] = safe)

func send_input(data: Dictionary) -> void :



	if is_host or not active:
		return
	if fake_loss_pct > 0 and randi() % 100 < fake_loss_pct:
		return
	_send( func(): _c_input.rpc_id(1, data))

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _c_input(data: Dictionary) -> void :
	if not is_host:
		return
	var id: = multiplayer.get_remote_sender_id()
	if not _rpc_ok(id, "input", 100):
		return
	_recv( func(): input_received.emit(id, data))

func send_snapshot(data: Dictionary) -> void :
	if fake_loss_pct > 0 and randi() % 100 < fake_loss_pct:
		return


	var bytes: = StateCodec.encode_snapshot(data)
	_send( func(): _s_snapshot.rpc(bytes))




signal ball_snapshot_received(b: PackedFloat32Array)

func send_ball_snapshot(b: PackedFloat32Array) -> void :
	if fake_loss_pct > 0 and randi() % 100 < fake_loss_pct:
		return
	_send( func(): _s_ball_snapshot.rpc(b))

@rpc("authority", "call_remote", "unreliable_ordered")
func _s_ball_snapshot(b: PackedFloat32Array) -> void :
	_recv( func(): ball_snapshot_received.emit(b))

@rpc("authority", "call_remote", "unreliable_ordered")
func _s_snapshot(bytes: PackedByteArray) -> void :
	var data: = StateCodec.decode_snapshot(bytes)
	if data.is_empty():
		return
	_recv( func(): snapshot_received.emit(data))

func send_event(kind: String, args: Dictionary) -> void :
	_send( func(): _s_event.rpc(kind, args))

@rpc("authority", "call_remote", "reliable")
func _s_event(kind: String, args: Dictionary) -> void :
	_recv( func(): event_received.emit(kind, args))



func send_up(kind: String, args: Dictionary) -> void :
	_send( func(): _c_up.rpc_id(1, kind, args))



const UP_BUDGET: = {"gcast?": [1, 2000], "gstats?": [2, 1000], "skip_vote": [2, 1000], 
	"pa": [2, 1000], "callout": [3, 1000], "gco": [3, 1000], "seat": [2, 1000], 
	"toss": [6, 1000], "touch_try": [24, 1000]}
const UP_DEFAULT_BUDGET: = [20, 1000]
var _up_t: = {}
var _look_t: = {}

@rpc("any_peer", "call_remote", "reliable")
func _c_up(kind: String, args: Dictionary) -> void :
	if not is_host:
		return
	var id: = multiplayer.get_remote_sender_id()
	var budget: Array = UP_BUDGET.get(kind, UP_DEFAULT_BUDGET)
	if not _rate_ok(_up_t, "%d:%s" % [id, kind], int(budget[0]), int(budget[1])):
		return
	_recv( func(): up_event_received.emit(id, kind, args))
