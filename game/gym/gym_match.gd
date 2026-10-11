class_name GymMatch
extends Node3D

















const COURT_SCENE: = preload("res://game/court/court.tscn")
const BALL_SCENE: = preload("res://game/ball/ball.tscn")
const PLAYER_SCENE: = preload("res://game/player/player.tscn")
const BASE_HALF_W: = 4.5
const BASE_HALF_L: = 9.0
const SET_POINTS: = 7
const DEAD_TIME: = 1.6

enum Phase{DEAD, SERVE_PREP, LIVE, SET_OVER}

signal rally_ended(winner_side: int)


signal verdict_called(pos: Vector3, text: String, winner: int)
signal voice_called(bank: String, pos: Vector3, pitch: float)
signal block_broken_at(pos: Vector3, who: Player)


signal thumped_at(pos: Vector3, strength: float)
signal launched_at(pos: Vector3, charge: float)


signal whistle_at(reason: String, pos: Vector3)
signal toss_at(pos: Vector3)
signal flair_at(kind: String, who: Player)

var last_end_reason: = ""

var team_size: = 2
var endless: = false
var net_puppet_court: = false
var net_phase: = 0
var net_srv_gid: = 0
var net_serve_clock: = 0
var net_srv_name: = "someone"
var net_srv_is_me: = false
var ball: Ball





var humans: = {}
var set_over: = false






var _lod_tick: = 0


var sim_far: = false



var _crew_cache: = {}
var _roster_stamp: = 0
var _crew_stamp: = -1
var winner_team: = 0
var half_w: = BASE_HALF_W
var half_l: = BASE_HALF_L
var cx: = 0.0


var _lines: = Court.new()
var _rally: = Rally.new()





var _rally_live: bool:
	get: return _rally.live
var _server: Player:
	get: return _rally.server
	set(v): _rally.server = v
var _serve_done: bool:
	get: return _rally.serve_done
var _serve_crossed: bool:
	get: return _rally.serve_crossed
var _serve_clock: float:
	get: return _rally.serve_clock
var _touch_count: int:
	get: return _rally.touch_count
var _last_toucher: Player:
	get: return _rally.last_toucher
	set(v): _rally.last_toucher = v
var _team_last_toucher: Dictionary:
	get: return _rally.team_last_toucher

var scores: Dictionary:
	get: return _rally.scores
	set(v):
		_rally.scores.clear()
		for k in v:
			_rally.scores[k] = v[k]
var _court: Node3D
var _bots: = {}
var _all_players: Array = []
var _slots: = {}
var _names: = {}
var _stats: = {}
var _phase: = Phase.DEAD
var _dead_timer: = 1.0
var _pending_join: = {}
var _net_wobble: = 0.0
var current_sweat: = 0.0
var _last_kill_power: = 0.0
var _floor_mat: ShaderMaterial
var floor_reflect_mat: ShaderMaterial


var court_salt: = 0





static var _name_pool: Array = []
static var _name_pool_seed: = 2147483647

func _cpu_name(side: int, slot: int) -> String:
	if _name_pool_seed != GameConfig.match_seed or _name_pool.is_empty():
		_name_pool = CpuNames.shuffled(GameConfig.match_seed)
		_name_pool_seed = GameConfig.match_seed
	var idx: = court_salt * 12 + (0 if side > 0 else 6) + slot
	return "%s (CPU)" % String(_name_pool[idx % _name_pool.size()])





const HALL_BALLS: = ["training", "school", "grass"]




func _hall_ball() -> String:
	var h: = hash("%s|ball|%d" % [GameConfig.match_seed, court_salt])
	return HALL_BALLS[absi(h) % HALL_BALLS.size()]

func configure(size: int, w: float, l: float, endless_mode: = false) -> void :
	team_size = size
	half_w = w
	half_l = l
	endless = endless_mode

func _ready() -> void :
	cx = global_position.x
	_lines = Court.new().configure(cx, half_w, half_l)




	_court = COURT_SCENE.instantiate()
	add_child(_court)
	_court.scale = Vector3(half_w / BASE_HALF_W, 1.0, half_l / BASE_HALF_L)

	CourtDress.unique_net(_court.get_node("Net"), _court.scale.x)
	_floor_mat = CourtDress.unique_floor(_court)
	_floor_mat.set_shader_parameter("base_color", Stage.val("training", "floor_color", Color(0.85, 0.5, 0.25)))
	Stage.dress_court(_court, "training")
	floor_reflect_mat = _floor_mat
	ball = BALL_SCENE.instantiate()





	ball.stage_ball = _hall_ball()
	add_child(ball)
	ball.global_position = Vector3(cx, 1.0, 0.0)
	ball.net_half_width = Ball.PHYS.net_half_width * (half_w / BASE_HALF_W)
	ball.antenna_half_width = Ball.PHYS.antenna_half_width * (half_w / BASE_HALF_W)
	ball.court_center_x = cx
	ball.court_half_w = half_w
	ball.court_half_l = half_l
	ball.bounced.connect( func(): _rally.ball_bounced())
	ball.wall_hit.connect( func(): _rally.ball_hit_wall())
	ball.net_hit.connect(_on_net_hit)


	_rally.setup(_lines, team_size, ball, _all_players, _slots, _bots, _stats)
	_rally.set_points = SET_POINTS
	_rally.win_by_two = false
	_rally.endless = endless
	_rally.input_for = func(p: Player) -> Variant:
		return (humans.get(p, {}) as Dictionary).get("input", null)
	_rally.verdict.connect( func(pos: Vector3, text: String, winner: int):
		verdict_called.emit(pos, text, winner))
	_rally.whistle_fault.connect( func(reason: String, pos: Vector3):
		whistle_at.emit(reason, pos))
	_rally.tossed.connect( func(server: Player):


		server.present_serve_toss(true)
		toss_at.emit(server.chest_position()))
	_rally.touch_flair.connect( func(kind: String, who: Player):
		flair_at.emit(kind, who))
	_rally.point.connect(_on_point)
	_rally.set_won.connect(_on_set_won)


	if not net_puppet_court:
		for i in range(team_size):
			_spawn_bot(i, 1)
		for i in range(team_size):
			_spawn_bot(i, -1)
		TeamBot.ensure_team_jump_servers(_bots)




func net_material() -> ShaderMaterial:
	if _court == null:
		return null
	var n: = _court.get_node_or_null("Net") as MeshInstance3D
	if n == null:
		return null
	return (n.mesh as PlaneMesh).material as ShaderMaterial

func _on_net_hit() -> void :

	_net_wobble = clampf(ball.last_net_impact / 13.0, 0.35, 1.9)
	var mat: ShaderMaterial = (_court.get_node("Net").mesh as PlaneMesh).material
	mat.set_shader_parameter("hit_x", (ball.global_position.x - cx) / _court.scale.x)

func _check_net_touch() -> void :

	for p in _all_players:
		var member: Player = p
		if absf(member.global_position.z) < 0.45\
		and absf(member.global_position.x - cx) < half_w\
		and member.velocity.length() > 1.0:
			_net_wobble = maxf(_net_wobble, 0.45)
			var mat: ShaderMaterial = (_court.get_node("Net").mesh as PlaneMesh).material
			mat.set_shader_parameter("hit_x", 
				(member.global_position.x - cx) / _court.scale.x)

func _crew(p: Player) -> Dictionary:
	if _crew_stamp != _roster_stamp:
		_crew_cache.clear()
		_crew_stamp = _roster_stamp
	var c = _crew_cache.get(p)
	if c == null:
		c = {"a": _lines.allies_of(_all_players, p), 
			"o": _lines.opponents_of(_all_players, p)}
		_crew_cache[p] = c
	return c

func _spawn_bot(slot: int, side: int) -> Player:
	_roster_stamp += 1
	var bot: Player = PLAYER_SCENE.instantiate()
	bot.team_side = side
	add_child(bot)
	bot.global_position = _formation_spot(slot, team_size, side)
	bot.is_bot = true
	bot.charge_ui_enabled = false
	bot.set_team_color(Rules.side_color(side).darkened(0.06 * slot))
	_register(bot, slot, _cpu_name(side, slot))
	var brain: = TeamBot.new()
	brain.configure(half_w, half_l, slot, team_size, cx)
	brain.apply_difficulty(1)
	_bots[bot] = brain
	return bot

func _register(member: Player, slot: int, display_name: String) -> void :
	member.ball = ball
	member.quick_check = _quick_set_ready
	member.contact_priority_check = _rally.queued_contact_has_priority


	var cb: = func(kind: int): _rally.judge_touch(kind, member)
	if humans.has(member):
		humans[member]["cb"] = cb
	member.touched.connect(cb)
	member.voiced.connect(_on_voiced.bind(member))
	member.block_broken.connect( func(pos: Vector3):
		block_broken_at.emit(pos, member))
	member.thumped.connect( func(pos: Vector3, strength: float):
		thumped_at.emit(pos, strength))
	member.launched.connect( func(pos: Vector3, charge: float):
		launched_at.emit(pos, charge))
	_slots[member] = slot
	_names[member] = display_name
	member.set_display_name(display_name)





	var look: CharacterConfig = (humans.get(member, {}) as Dictionary)\
	.get("look", null)
	if look == null:
		look = GameConfig.bot_character(member.team_side, slot, court_salt)
	member.set_character(look.gym_look(), look.gym_kit())
	_stats[member] = {"pts": 0, "blk": 0, "rcv": 0, "set": 0, "ast": 0}
	_all_players.append(member)

func _on_voiced(bank: String, pitch: float, who: Player) -> void :

	voice_called.emit(bank, who.global_position + Vector3(0.0, 1.4, 0.0), pitch)

func _formation_spot(slot: int, n: int, side: int) -> Vector3:
	return _lines.formation_spot(slot, n, side)

func players() -> Array:
	return _all_players



func request_join(joiner: Player, side: int, slot: = -1, 
		display_name: = "", look: CharacterConfig = null) -> void :


	if set_over or humans.has(joiner):
		return
	_pending_join[joiner] = {"side": side, "slot": slot, 
		"name": display_name if display_name != "" else Net.local_display_name(), 
		"look": look if look != null else GameConfig.character}

func cancel_join(joiner: Player = null) -> void :
	if joiner == null:
		_pending_join = {}
	else:
		_pending_join.erase(joiner)

func set_member_input(body: Player, input: PlayerInput) -> void :
	if humans.has(body):
		humans[body]["input"] = input

func human_on(side: int, slot: int) -> bool:
	for body in humans:
		if int(humans[body].side) == side and int(humans[body].slot) == slot:
			return true
	return false

func _try_execute_join() -> void :
	if _pending_join.is_empty():
		return
	_roster_stamp += 1
	var queue: = _pending_join
	_pending_join = {}
	var any_joined: = false
	var last_side: = 1
	for joiner in queue:
		var req: Dictionary = queue[joiner]
		var side: int = req.side
		var bot_out: Player = null
		for p in _all_players:
			var member: Player = p
			if member.is_bot and member.team_side == side:
				bot_out = member
				if _slots[member] == int(req.slot):
					break
		if bot_out == null:
			continue
		var slot: int = _slots[bot_out]
		_unregister(bot_out)
		_bots.erase(bot_out)
		bot_out.queue_free()
		humans[joiner] = {"input": null, "slot": slot, "side": side, 
			"cb": Callable(), "look": req.look, "name": String(req.name)}
		joiner.team_side = side
		joiner.set_team_color(Rules.side_color(side))
		_register(joiner, slot, String(req.name))
		any_joined = true
		last_side = side
	if any_joined:
		ball.home_side = float(last_side)




		if maxi(int(scores.get(1, 0)), int(scores.get(-1, 0))) < 2:
			_rally.reset_set( - last_side)
		else:
			_rally.serve_side = - last_side
			_rally.live = false
		set_over = false
		_phase = Phase.DEAD
		_dead_timer = 1.5




func net_apply_sweat(v: float) -> void :
	current_sweat = v
	if _floor_mat != null:
		_floor_mat.set_shader_parameter("sweat", v)

func release_member(body: Player) -> void :
	if not humans.has(body):
		return
	_roster_stamp += 1
	var entry: Dictionary = humans[body]
	humans.erase(body)
	_unregister_human(body, entry)
	_unregister(body)
	body.touch_barred = false
	body.ball = null


	body.set_highlight(Color(0, 0, 0, 0))
	body.set_team_color(Rules.side_color(1))




	var look: CharacterConfig = entry.get("look", null)
	if look != null:
		body.set_character(look.gym_look(), look.gym_kit())
	_spawn_bot(int(entry.slot), int(entry.side))
	if humans.is_empty():
		_rally.reset_set()
		set_over = false
		_phase = Phase.DEAD
		_dead_timer = 2.0

func _unregister_human(body: Player, entry: Dictionary) -> void :
	var cb: Callable = entry.get("cb", Callable())
	if cb.is_valid() and body.touched.is_connected(cb):
		body.touched.disconnect(cb)

func _unregister(member: Player) -> void :


	_all_players.erase(member)
	_slots.erase(member)
	_names.erase(member)
	_stats.erase(member)



	_bots.erase(member)



	_rally.forget(member)

func _quick_set_ready(aim: Vector3, hitter: Player) -> bool:
	return _lines.quick_set_ready(_all_players, aim, hitter)


func _update_barred() -> void :
	_rally.pre_tick(0.0, _phase != Phase.LIVE)



func _physics_process(delta: float) -> void :
	if net_puppet_court:
		return
	var rate: = 1
	if humans.is_empty():



		_lod_tick += 1
		rate = 4 if sim_far else 2
		if _lod_tick % rate != 0:
			return
		delta *= float(rate)
	_rally.pre_tick(delta, _phase != Phase.LIVE)



	current_sweat = _rally.sweat_target()
	_floor_mat.set_shader_parameter("sweat", current_sweat)
	for p in _all_players:
		(p as Player).sweat = current_sweat


		(p as Player).sim_step_scale = float(rate)


		(p as Player).team_touches = _rally.touch_count\
		if _rally.touch_side == (p as Player).team_side else 0
	for p in _bots:
		var bot_player: Player = p
		var bot: TeamBot = _bots[bot_player]
		bot.aggression = _rally.bot_aggression()
		var serving: bool = bot_player == _rally.server and not _rally.serve_done




		bot_player.serve_charge_ui = _phase == Phase.SERVE_PREP\
		and bot_player == _rally.server
		var crew: = _crew(bot_player)
		var bot_input: = bot.think(bot_player, crew["a"], crew["o"], ball, 
			_rally.touch_count, _rally.live, serving, delta, _rally.last_touch_side)
		bot_player.simulate(bot_input, delta)
	_check_net_touch()


	ball.serve_held = _phase == Phase.SERVE_PREP and not _rally.serve_done
	match _phase:
		Phase.DEAD:
			_dead_timer -= delta
			if _dead_timer <= 0.0:
				_try_execute_join()
				_rally.begin_serve()
				if _rally.server != null:
					_phase = Phase.SERVE_PREP
		Phase.SERVE_PREP:
			_rally.serve_tick(delta)
			if _rally.live:
				_phase = Phase.LIVE


		Phase.LIVE:
			_rally.live_tick(delta)
		Phase.SET_OVER:
			if humans.is_empty():
				_dead_timer -= delta
				if _dead_timer <= 0.0:
					_rally.reset_set()
					set_over = false
					_phase = Phase.DEAD
					_dead_timer = 1.0
	if _net_wobble > 0.001:
		_net_wobble *= exp(-1.1 * delta)
		((_court.get_node("Net").mesh as PlaneMesh).material as ShaderMaterial)\
		.set_shader_parameter("wobble", _net_wobble)



func _on_point(winner_side: int, reason: String, _scorer: Player, 
		kill_power_in: float, _winners_ball: bool) -> void :
	last_end_reason = reason
	_last_kill_power = kill_power_in
	_phase = Phase.DEAD
	_dead_timer = DEAD_TIME
	rally_ended.emit(winner_side)

func _on_set_won(winner_side: int) -> void :
	set_over = true
	winner_team = winner_side
	_phase = Phase.SET_OVER
	_dead_timer = 3.0

func kill_power(_winner_side: int) -> float:

	return _last_kill_power

func stat_rows() -> Array:
	var rows: Array = []
	for p in _all_players:
		var member: Player = p
		var s: Dictionary = _stats[member]
		rows.append({"name": _names[member], "pts": s.pts, "blk": s.blk, 
			"rcv": s.rcv, "set": s.set, "ast": int(s.get("ast", 0)), 
			"side": member.team_side, 
			"cfg": member.character.to_dict() if member.character != null else {}})
	rows.sort_custom( func(a, b): return a.pts > b.pts)
	return rows

func in_serve_zone(p: Player) -> bool:
	return _rally.in_serve_zone(p)

func in_safe_serve_spot(p: Player) -> bool:
	return _rally.in_safe_serve_spot(p)




func serving_me(for_player: Player) -> bool:
	if net_puppet_court:
		return net_phase == Phase.SERVE_PREP and net_srv_is_me
	return _phase == Phase.SERVE_PREP and _server == for_player\
	and not _rally.serve_done

func serve_prompt(for_player: Player) -> String:


	if net_puppet_court:
		if net_phase != Phase.SERVE_PREP:
			return ""
		if net_srv_is_me:


			if not in_serve_zone(for_player):
				return "return to serve zone  %d" % net_serve_clock
			return "your serve: hold lmb to charge the toss & release to throw  %d" % net_serve_clock
		return "%s is serving...  %d" % [net_srv_name, net_serve_clock]
	if _phase != Phase.SERVE_PREP:
		return ""
	if _rally.server != for_player:
		return "%s is serving...  %0.0f" % [_names.get(_rally.server, "someone"), 
			_rally.serve_clock]
	if not in_serve_zone(for_player):
		return "return to serve zone  %0.0f" % _rally.serve_clock
	return "your serve: hold lmb to charge the toss & release to throw  %0.0f"\
	%_rally.serve_clock
