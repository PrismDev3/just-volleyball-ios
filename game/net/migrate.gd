extends Node




















const REJOIN_WAIT: = 15.0
const JOIN_RETRY: = 1.5
const FAIL_AFTER: = 25.0

var state: = {}
var _t: = 0.0
var _retry_t: = 0.0
var _hosting: = false
var _relaunched: = false
var _probe: PacketPeerUDP = null

static func begin(tree: SceneTree, st: Dictionary) -> void :
	var m: Node = (load("res://game/net/migrate.gd") as GDScript).new()
	m.state = st
	tree.root.add_child.call_deferred(m)




func _over() -> bool:
	return bool(state.get("over", false))




func _land_post_match() -> void :
	if bool(state.get("room", false)):
		_land_lobby()
	else:
		_land_menu()







func _land_menu() -> void :
	_relaunched = true
	(load("res://game/ui/migration_cover.gd") as GDScript).call("dismiss")
	Net.leave()
	GameConfig.quick_match = false
	var tree: = get_tree()
	queue_free()
	if tree != null:

		GameConfig.goto_scene("res://game/ui/menu.tscn")







func _land_lobby() -> void :
	_relaunched = true
	if _hosting:
		GameConfig.quick_match = bool(state.quick)
		Net.custom_lobby = bool(state.get("room", false))
		Net.team_size = int(state.size)
		Net.stage = String(state.stage)
		Net.sync_lobby()
	Net.restore_chat()
	(load("res://game/ui/migration_cover.gd") as GDScript).call("dismiss")
	var tree: = get_tree()
	queue_free()
	if tree != null and tree.current_scene != null\
	and tree.current_scene.scene_file_path != "res://game/ui/menu.tscn":
		GameConfig.goto_scene("res://game/ui/menu.tscn")

func _survivors() -> Array:
	var ids: Array = (state.survivors as Dictionary).keys()\
	.filter( func(id): return int(id) != 1)
	ids.sort()
	return ids

func _ready() -> void :




	if _over() and not bool(state.get("room", false)):
		_relaunched = true
		_land_menu.call_deferred()
		return
	var ids: = _survivors()
	if ids.is_empty() or not ids.has(int(state.my_id)):
		_fail("nobody left to take over")
		return
	if int(ids[0]) == int(state.my_id):
		_host_up()

func _exit_tree() -> void :



	if not _relaunched:
		Net.migrate_advertise(false)
	if _probe != null:
		_probe.close()
		_probe = null

func _host_up() -> void :



	var shared_account: = false
	var mine: = Net.my_steam_id()
	for id in _survivors():
		if int(id) != int(state.my_id) and mine != 0\
		and int((state.survivors[id] as Dictionary).get("sid", 0)) == mine:
			shared_account = true











	if bool(state.quick):
		Net.mark_lobby_hidden()
	var ok: bool
	if bool(state.steam) and not shared_account:
		ok = Net.host_game_steam(String(state.my_name)) == OK
	else:
		ok = Net.host_game(String(state.my_name)) == OK
	if not ok:
		_fail("couldn't take over hosting")
		return
	_hosting = true


	Net.session_token = int(state.token)
	Net.migrate_advertise(true)

func _process(delta: float) -> void :





	if Net.in_match:
		Net.restore_chat()
		queue_free()
		return
	_t += delta
	if _relaunched:
		return
	if _hosting:



		var expected: = _survivors().size() - 1
		if Net.players.size() - 1 >= expected or _t >= REJOIN_WAIT:
			if _over():
				_land_post_match()
			else:
				_relaunch()
		return



	if _t >= FAIL_AFTER and not Net.in_match:
		_fail("couldn't reach the new host")
		return
	if Net.active:


		if _over():
			_land_post_match()
		return
	_collect_probe_replies()
	_retry_t -= delta
	if _retry_t <= 0.0:
		_retry_t = JOIN_RETRY
		_try_join()

func _try_join() -> void :
	var ids: = _survivors()
	var successor: = int(ids[0])
	var sid: = int((state.survivors[successor] as Dictionary).get("sid", 0))




	if bool(state.steam) and sid != 0 and sid != Net.my_steam_id():
		Net.join_game_steam(sid, String(state.my_name))
		return


	if _probe == null:
		_probe = PacketPeerUDP.new()
		_probe.set_broadcast_enabled(true)
	for i in QuickPlay.LAN_PORTS:
		for ip in ["255.255.255.255", "127.0.0.1"]:
			_probe.set_dest_address(ip, QuickPlay.LAN_PORT_BASE + i)
			_probe.put_packet(("QUICK?").to_utf8_buffer())

func _collect_probe_replies() -> void :
	while _probe != null and _probe.get_available_packet_count() > 0:
		var pkt: = _probe.get_packet()
		var ip: = _probe.get_packet_ip()
		var d: Variant = JSON.parse_string(pkt.get_string_from_utf8())
		if d == null or typeof(d) != TYPE_DICTIONARY:
			continue



		var mig: Variant = (d as Dictionary).get("migrate", 0)
		if not (typeof(mig) in [TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_BOOL]):
			continue
		if int(mig) != int(state.token):
			continue

		var sh: Variant = (d as Dictionary).get("steam_host", 0)
		var steam_host: = int(sh) if typeof(sh) in \
		[TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_BOOL] else 0




		var ids: = _survivors()
		var expect_sid: = int((state.survivors[int(ids[0])] as Dictionary).get("sid", 0))\
		if not ids.is_empty() else 0





		if expect_sid != 0 and steam_host != expect_sid\
		and not (steam_host == 0 and expect_sid == Net.my_steam_id()):
			continue
		var ok: bool
		if steam_host != 0 and steam_host != Net.my_steam_id():
			ok = Net.join_game_steam(steam_host, String(state.my_name)) == OK
		else:
			ok = Net.join_game(ip, String(state.my_name)) == OK
		if ok:
			_probe.close()
			_probe = null
			return

func _relaunch() -> void :
	_relaunched = true
	Net.migrate_advertise(false)



	var roster: Array = state.roster
	var used: = {}


	for e in roster:



		e["peer"] = 0
		for pid in Net.players:
			if used.has(pid):
				continue
			if String(Net.players[pid].name) == String(e.name):
				e["peer"] = pid
				used[pid] = true






				var live_cfg: Dictionary = (Net.players[pid] as Dictionary)\
				.get("cfg", {})
				if not live_cfg.is_empty():
					e["cfg"] = live_cfg
				break






		e["gone"] = int(e.peer) == 0 and not bool(e.get("spec", false))\
		and not String(e.name).begins_with("cpu")

	roster = roster.filter( func(e):
		return not bool(e.get("spec", false)) or int(e.get("peer", 0)) != 0)
	GameConfig.migrate_carry = state.carry
	GameConfig.quick_match = bool(state.quick)


	Net.custom_lobby = bool(state.get("room", false))
	Net.team_size = int(state.size)
	Net.stage = String(state.stage)
	Net.sync_lobby()
	Net.restore_chat()

	Net.start_match(roster, int(state.get("seed", randi())))
	queue_free()

func _fail(reason: String) -> void :

	(load("res://game/ui/migration_cover.gd") as GDScript).call("dismiss")

	GameConfig.lobby_notice = "migration failed, %s" % reason
	if Net.active:
		Net.leave()
	GameConfig.migrate_carry = {}
	var tree: = get_tree()
	queue_free()
	if tree != null and tree.current_scene != null\
	and tree.current_scene.scene_file_path != "res://game/ui/menu.tscn":
		GameConfig.goto_scene("res://game/ui/menu.tscn")
