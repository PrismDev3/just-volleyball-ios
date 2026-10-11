class_name MyPark
extends Node











const GYM_SCENE: = "res://game/gym/open_gym.tscn"
const SCAN_WINDOW: = 1.2
const STEAM_WINDOW: = 2.0
const JOIN_TIMEOUT: = 6.0

var force_lan: = false
var _query: PacketPeerUDP = null
var _t: = 0.0
var _phase: = ""
var _best: = {}

func begin(lan: bool) -> void :
	force_lan = lan
	if Net.my_name == "":
		Net.my_name = Net.local_display_name()
	_phase = "scan"
	Net.gym_joined.connect(_on_joined)
	var use_steam: = Net.steam_transport_available() and not force_lan
	_t = STEAM_WINDOW if use_steam else SCAN_WINDOW
	if use_steam:
		Net.steam_lobbies.connect(_on_rows)
		Net.steam_request_lobbies()
		return
	_query = PacketPeerUDP.new()
	_query.set_broadcast_enabled(true)
	if _query.bind(0) != OK:
		_query = null
		_t = 0.0
		return
	for i in QuickPlay.LAN_PORTS:
		for ip in ["255.255.255.255", "127.0.0.1"]:
			_query.set_dest_address(ip, QuickPlay.LAN_PORT_BASE + i)
			_query.put_packet("QUICK?".to_utf8_buffer())




static func park_score(humans: int, ping: int) -> float:
	var band: = 999 if ping < 0 else ping / 40
	return float(band) * 100.0 - float(humans)

func _on_rows(rows: Array) -> void :
	if _phase != "scan":
		return
	for row in rows:
		if String(row.get("kind", "")) != "gym":
			continue
		if not row.get("compatible", false) == true:
			continue


		if String(row.get("priv", "public")) != "public":
			continue

		if Net.ni(row.get("host_id", 0), 0) == Net.my_steam_id():
			continue
		var humans: = Net.ni(row.get("humans", 0), 0)
		if humans >= Net.MAX_PLAYERS:
			continue
		if _best.is_empty() or park_score(humans, Net.ni(row.get("ping", -1), -1))\
		< park_score(Net.ni(_best.get("humans", 0), 0), Net.ni(_best.get("ping", -1), -1)):
			_best = row

func _collect_lan() -> void :
	while _query != null and _query.get_available_packet_count() > 0:
		var pkt: = _query.get_packet()
		var ip: = _query.get_packet_ip()
		var d: Variant = JSON.parse_string(pkt.get_string_from_utf8())
		if d == null or typeof(d) != TYPE_DICTIONARY:
			continue
		if not d.get("gym", false) == true:
			continue
		if Net.ni(d.get("proto", 0), 0) != Net.PROTO:
			continue


		if Net.ni(d.get("steam_host", 0), 0) != 0:
			continue
		if Net.ni(d.get("priv", 0), 0) != 0:
			continue
		var humans: = Net.ni(d.get("members", 0), 0)
		if humans >= Net.MAX_PLAYERS:
			continue
		d["ip"] = ip
		d["humans"] = humans
		d["ping"] = -1
		if _best.is_empty()\
		or humans > Net.ni(_best.get("humans", 0), 0):
			_best = d

func _process(delta: float) -> void :
	match _phase:
		"scan":
			_collect_lan()
			_t -= delta
			if _t <= 0.0:
				_scan_done()
		"join":
			_t -= delta


			if _t <= 0.0 or not Net.active:
				_host()

func _scan_done() -> void :
	if _query != null:
		_query.close()
		_query = null
	if _best.is_empty():
		_host()
		return
	_phase = "join"
	_t = JOIN_TIMEOUT
	var err: = ERR_UNAVAILABLE
	var host_id: = Net.ni(_best.get("host_id", 0), 0)
	if bool(_best.get("steam", false)) and host_id != 0:
		err = Net.join_game_steam(host_id, Net.my_name)
	elif String(_best.get("ip", "")) != "":
		err = Net.join_game(String(_best.get("ip", "")), Net.my_name)
	if err != OK:
		_host()

func _on_joined() -> void :
	_phase = "done"
	GameConfig.goto_scene(GYM_SCENE)

func cancel() -> void :

	_phase = "done"
	if _query != null:
		_query.close()
		_query = null
	if Net.active and not Net.in_match:
		Net.leave()
	queue_free()

func _host() -> void :
	_phase = "done"


	Net.host_gym(Net.my_name, force_lan)
	GameConfig.goto_scene(GYM_SCENE)
