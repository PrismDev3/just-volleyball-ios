extends Node3D


















const PLAYER_SCENE: = preload("res://game/player/player.tscn")








const COMPAT_BRIGHTNESS: = 1.0
const COMPAT_CONTRAST: = 0.93
const COMPAT_SATURATION: = 0.9









const COMPAT_BOX_SHADOW_MUL: = 0.0
const COMPAT_BLOB_SHADOW_MUL: = 0.4
const POINT_WIPE: = preload("res://game/ui/point_wipe.gd")
const MIGRATION_COVER: = preload("res://game/ui/migration_cover.gd")
const BASE_HALF_W: = 4.5
const BASE_HALF_L: = 9.0
const LINE_HALF_WIDTH: = 0.025
const SET_POINTS: = 7
const SETS_TO_WIN: = 2
const DEAD_TIME: = 2.3
const SET_BREAK_TIME: = 4.8
const SNAPSHOT_EVERY: = 2




const PSTATE_FLOATS: = ReplayData.NET_PLAYER_FLOATS







const INTERP_DELAY_MIN: = 40.0
const INTERP_DELAY_MAX: = 140.0






const INTERP_GAP_DECAY: = 0.97
const INTERP_GAP_MULT: = 1.15
const INTERP_GAP_MARGIN: = 25.0
const LAG_TOUCH_HISTORY_MS: = 280.0







const BALL_PRESENT_MAX_MS: = 100.0






const SNAP_MS: = 1000.0 / 30.0



const CLOCK_RELAX_MS: = 0.6
const CLOCK_WINDOW_SNAPS: = 90
const CLOCK_WARMUP_SNAPS: = 30
const CLOCK_SLEW_FAST: = 400.0





const CLOCK_SLEW: = 25.0
const DELAY_SLEW: = 40.0



const EXTRAPOLATE_MAX: = 0.045
const HARD_SNAP_DIST: = 1.2




const BALL_DESYNC_SNAP: = 5.0







const BALL_LEASH_DEAD: = 1.0
const BALL_LEASH_MIN: = 1.0
const BALL_LEASH_MAX: = 24.0
const BALL_LEASH_FULL: = 2.5



const INTRO_PER_PLAYER: = 0.95
const INTRO_FADE: = 0.9
const INTRO_HOLD: = 0.55
const COUNTDOWN_TIME: = 3.0
const WIN_TIME: = 6.0
const WIN_FADE: = 0.9
const SWEAT_DRY_TIME: = 2.5



const SWAP_DELAY: = 1.5
const SWAP_HOLD: = 0.8
const SWAP_FADE: = 1.8
const LOAD_FADE: = 1.0
const QUICK_COLOR: = Color(1.0, 0.45, 0.78)
const BREAK_COLOR: = Color(0.95, 0.18, 0.18)

const CINE_BLUE: = Rules.HOME_COLOR
const CINE_RED: = Rules.AWAY_COLOR




const REPLAY_LEAD: = 8.0
const REPLAY_TAIL: = 2.0
const REPLAY_BEAT: = 2.6
const REPLAY_CUT: = 0.25


const REPLAY_OUT_HOLD: = 0.35
const REPLAY_OUT_FADE: = 0.75
const REPLAY_ANGLE_TIME: = 4.5


const REPLAY_LAND_WINDOW: = 1.5
const REPLAY_MIN_RALLY: = 6.0
const REPLAY_DIR: = ReplayData.DIR
const HOME_SIDE: = 1



enum Phase{INTRO, COUNTDOWN, DEAD, SERVE_PREP, LIVE, WIN, STATS, REPLAY}
enum NetRole{OFFLINE, HOST, CLIENT}





var _spectating: = false
var _spec_clean: = 0
var _spec_ui: = true

var _watch_cam: WatchCamera = null
var _spec_bar_wired: = false
var reach_marker: ReachMarker = null
@onready var player: Player = $Player
@onready var ball: Ball = $Ball
@onready var court: Node3D = $Court
@onready var camera_rig: CameraRig = $CameraRig
@onready var aim_indicator: AimMarker = $AimIndicator
@onready var barred_marker: Node3D = $BarredMarker
@onready var landing_marker: Node3D = $LandingMarker
@onready var verdict_label: Label3D = $LandingMarker / VerdictLabel
@onready var fx: Fx = $Fx
@onready var sfx: Sfx = $Sfx
@onready var crowd: CrowdAudio = $Crowd
@onready var net_visual: MeshInstance3D = $Court / Net
@onready var hud: Hud = $UiLayer / Hud

var _input_collector: = InputCollector.new()
var _bots: = {}
var _all_players: Array = []
var _slots: = {}
var _names: = {}


var _cpu_name_pool: Array = []
var _cpu_name_i: = 0
var _stats: = {}
var _foley: = Foley.new()
var _half_w: = BASE_HALF_W
var _half_l: = BASE_HALF_L
var _lines: = Court.new()
var _serve_zone: ServeZoneMarker
var _rally: = Rally.new()


var _phase: = Phase.DEAD
var _dead_timer: = 0.8
var _cine_time: = 0.0
var _last_count_n: = 0
var _did_intro: = false




var _pre_intro: = true
var _cine_prev_phase: = Phase.DEAD
var _music_phase: = -1


const MUSIC_CLOSE_POINTS: = 2










const MUSIC_SAVE_SPIKE: = 0.8
const MUSIC_HEAT_HOLD: = 6.0
var _music_heat: = 0
var _music_spike_power: = 0.0
var _music_heat_t: = 0.0
var _match_winner: = 0
var _stats_built: = false
var _grabbed_home: = false
var _diss_left: = 0.0
var _diss_fade: = 1.0
var _quick_set_side: int:
	get: return _rally.quick_set_side
	set(v): _rally.quick_set_side = v
var _sweat_shown: = 0.0
var _recorder: = ReplayRecorder.new()
var _director: = ReplayDirector.new()
var _replay_pending: = false
var _replay_starting: = false
var _replay_exiting: = false
var _replay_wait: = 0.0
var _skip_votes: = {}
var _voted_skip: = false
var _replay_saved: = false


const WIN_TAIL: = 2.6
var _win_delay: = 0.0
var _win_pending: = 0



var _run_side: = 0
var _run_len: = 0
var _last_verdict_pos: = Vector3.ZERO
var _puppet_saved: Array = []




var _ball_puppet_saved: = false



var _replay_enabled: = true
var _replay_shot: = -1
var replay_loops: = 0


var _replay_lead: = 0.0



var _replay_prev_t: = 0.0
var _replay_cur_t: = 0.0
var _replay_focus: = Vector3.ZERO
var _replay_on_land: = false
var _replay_cam_side: = 0.0


var _last_spike_power: = 0.0
var _touch_lock: float:
	get: return _rally.touch_lock
	set(v): _rally.touch_lock = v
var _touch_lock_side: int:
	get: return _rally.touch_lock_side
	set(v): _rally.touch_lock_side = v
var _replay_sfx_at: = 0
var _swap_delay: = 0.0
var _serve_prelaid: = false
var _cine_snap_phase: = -1
var _cine_want_snap: = false


var _intro_locked: = false
var _floor_mat: ShaderMaterial

var _sand_deform: SandDeform = null
var _sand_mat: ShaderMaterial = null
var _sand_surround_mat: ShaderMaterial = null
var _sand_deck: MeshInstance3D = null




var _stage_painted: = {}
var _stage_shell: Node = null
var _wall_base: = {}
var _last_accent: = Color(0.85, 0.85, 0.85)



var _last_tape: = Color(1, 1, 1)
var _has_tape: = false
var _net_wobble: = 0.0
var _tick_inputs: = {}








var _serve_clock: float:
	get: return _rally.serve_clock
	set(v): _rally.serve_clock = v
var _serve_side: int:
	get: return _rally.serve_side
	set(v): _rally.serve_side = v
var _server: Player:
	get: return _rally.server
	set(v): _rally.server = v
var _serve_done: bool:
	get: return _rally.serve_done
	set(v): _rally.serve_done = v
var _serve_launch_z: float:
	get: return _rally.serve_launch_z
	set(v): _rally.serve_launch_z = v
var _serve_crossed: bool:
	get: return _rally.serve_crossed
	set(v): _rally.serve_crossed = v
var _serve_attack_window: bool:
	get: return _rally.serve_attack_window
	set(v): _rally.serve_attack_window = v
var _bot_toss_delay: float:
	get: return _rally.bot_toss_delay
	set(v): _rally.bot_toss_delay = v
var _rally_live: bool:
	get: return _rally.live
	set(v): _rally.live = v
var _rally_time: float:
	get: return _rally.rally_time
	set(v): _rally.rally_time = v
var _touch_count: int:
	get: return _rally.touch_count
	set(v): _rally.touch_count = v
var _last_toucher: Player:
	get: return _rally.last_toucher
	set(v): _rally.last_toucher = v
var _last_touch_side: int:
	get: return _rally.last_touch_side
	set(v): _rally.last_touch_side = v
var _touch_side: int:
	get: return _rally.touch_side
	set(v): _rally.touch_side = v
var _team_last_toucher: Dictionary:
	get: return _rally.team_last_toucher
	set(v): _rally.team_last_toucher = v
var _prev_ball_side: float:
	get: return _rally.prev_ball_side
	set(v): _rally.prev_ball_side = v
var _rot: Dictionary:
	get: return _rally.rot
	set(v): _rally.rot = v
var _last_serve_side: int:
	get: return _rally.last_serve_side
	set(v): _rally.last_serve_side = v




var _scores: Dictionary:
	get: return _rally.scores
	set(v):
		_rally.scores.clear()
		for k in v:
			_rally.scores[k] = v[k]
var _set_wins: = {1: 0, -1: 0}
var _set_number: = 1



var _pending_set: = {}


var _net_role: = NetRole.OFFLINE
var _net_tick: = 0
const STATS_REBROADCAST_S: = 10.0
var _stats_bcast_accum: = 0.0
var _net_ids: = {}
var _by_net_id: = {}
var _peer_players: = {}
var _peer_applied: = {}



var _peer_touch_inputs: = {}


var _peer_queue: = {}
var _peer_seq_seen: = {}
var _peer_starved: = {}
var _peer_dropped: = {}
var _peer_trimmed: = {}


const INPUT_QUEUE_MAX: = 6






const INPUT_QUEUE_TARGET: = 2
const INPUT_QUEUE_DEEP_TICKS: = 30
var _peer_deep: = {}





var _local_pid_cache: = 1

func _local_pid() -> int:
	var mp: = get_multiplayer()
	if mp != null and mp.multiplayer_peer != null:
		_local_pid_cache = mp.get_unique_id()
	return _local_pid_cache
var _peer_input: = {}
var _peer_edges: = {}
var _snap_buf: Array = []


var _snap_gap: = 33.0
var _snap_seq: = 0
var _snap_newest: = -1
var _clock_offset: = INF
var _clock_offset_min: = INF
var _off_win_min: = INF
var _off_win_n: = 0
var _clock_warm: = 0
var _delay_now: = INTERP_DELAY_MIN
var _snap_jitter: = 0.0
var _snap_gap_max: = 33.0
var _last_snap_at: = 0
var _np: = {}
var _interp_hard: = false




var _ball_dead: = false



var _client_in_serve_prep: = false



var _in_chan: = NetSync.InputChannel.new()




var _pred: = NetSync.Predictor.new()
var _ball_host_strikes: = -1.0
var _ball_err: = Vector3.ZERO
var _ball_60hz: = true
var _ball_interp: = false
var _ball_present: = true
var _ball_present_lead_ms: = 0.0





var _velsync: = false
const VELSYNC_VEL_WEIGHT: = 0.85
const VELSYNC_POS_WEIGHT: = 0.06
var _ball_handoff: = 0.0
var _ball_predicting: = false
var _ball_ballistic: = false
var _bm_prev: = {}






var _ball_grace: = 0.0
var _ball_grace_seq: = -1.0
var _pred_touch_seen: = 0
var _pred_strike_mutes: = 0
var _pred_thumps: Array = []
var _toss_pred: = 0.0

var _toss_visual_state: Array = []
var _toss_unfrozen_snaps: = 0



var _dbg_ball_err_sum: = 0.0
var _dbg_ball_err_max: = 0.0
var _dbg_ball_err_n: = 0
var _dbg_stale_drops: = 0
var _dbg_grace_skips: = 0
var _dbg_pred_err_sum: = 0.0
var _dbg_pred_err_max: = 0.0
var _dbg_pred_err_n: = 0
var _dbg_unfair_floor: = 0
var _dbg_rejected_touch: = 0
var _dbg_since: = 0.0
var _render_host_ms: = -1.0
var _lag_touch: = true
var _lag_history: Array = []
var _lag_touch_requests: Array = []




var _ball_event_flight: = {}
var _match_over: = false


var _last_match_reward: = {}


var _match_rallies: = 0




var _ach_touch: = {}
var _ach_bam: = {}
var _ach_roll: Player = null
var _ach_time_acc: = 0.0
const ACH_TIME_TICK: = 10.0
var _wait_peers: = {}
var _wait_timeout: = 12.0




var _peer_heard: = {}
const PEER_SILENT_TIMEOUT: = 8.0
var _net_log: = false
var _snap_count: = 0

var _net_shot: = false
var _shot_count: = 0

func _ready() -> void :
	GameConfig.use_cursor(true)

	# Warm the lobby while the match runs so its exit wipe swaps from memory.
	# Deferred: keep menu.gd's script parse off this scene's heavy _ready.
	get_tree().create_timer(1.5).timeout.connect( func():
		GameConfig.preload_scene("res://game/ui/menu.tscn")
		GameConfig.preload_venue(GameConfig.freeplay_stage))


	Haptics.wire(player)



	MusicManager.set_muffled(false)
	MusicManager.stop(0.6)


	_net_log = OS.get_cmdline_user_args().has("--net-log")\
	or GameConfig.debug_net_log
	_net_shot = OS.get_cmdline_user_args().has("--net-shot")
	_ball_60hz = not OS.get_cmdline_user_args().has("--no-ball60")





	_ball_interp = not OS.get_cmdline_user_args().has("--no-ball-interp")
	_ball_present = not OS.get_cmdline_user_args().has("--no-ball-present")



	_velsync = OS.get_cmdline_user_args().has("--ball-velsync")\
	and not OS.get_cmdline_user_args().has("--no-ball-velsync")
	_ball_ballistic = OS.get_cmdline_user_args().has("--ball-ballistic")
	_lag_touch = not OS.get_cmdline_user_args().has("--no-lag-touch")
	_half_w = GameConfig.court_half_width
	_half_l = GameConfig.court_half_length


	_lines = Court.new().configure(0.0, _half_w, _half_l)

	_serve_zone = ServeZoneMarker.new()
	_serve_zone.setup(0.0, _half_w, _half_l)
	add_child(_serve_zone)
	if Net.active and Net.in_match and GameConfig.net_roster.size() > 0:
		_net_role = NetRole.HOST if Net.is_host else NetRole.CLIENT
	elif GameConfig.net_roster.size() > 0 and not Net.active:





		GameConfig.net_roster = []
		GameConfig.lobby_notice = "the session ended before the match loaded"
		set_process(false)
		set_physics_process(false)
		GameConfig.goto_scene.call_deferred("res://game/ui/menu.tscn")
		return
	if _net_role == NetRole.HOST:



		Net.team_of = func(pid: int) -> Variant:
			if pid == 1:
				if _spectating or player == null:
					return 0
				return player.team_side
			var b: Player = _peer_players.get(pid)
			if b == null:



				return 0 if Net.players.has(pid) else null
			return b.team_side
	court.scale = Vector3(_half_w / BASE_HALF_W, 1.0, _half_l / BASE_HALF_L)



	CourtDress.unique_net(net_visual, court.scale.x)


	aim_indicator.net_mat = (net_visual.mesh as PlaneMesh).material as ShaderMaterial
	_floor_mat = CourtDress.unique_floor(court)
	var reflector: = FloorReflector.new()
	add_child(reflector)
	reflector.setup(camera_rig.camera)
	CourtDress.wire_reflection(_floor_mat, reflector.texture())
	reflector.floor_mats = [_floor_mat]
	_apply_stage()


	if _stage_shell != null:
		for n in _stage_shell.find_children("*", "Node3D", true, false):
			if n.has_method("wire_reflection"):
				n.wire_reflection(reflector.texture())


	reflector.feet_provider = func(): return _all_players + [ball]
	ball.net_half_width = Ball.PHYS.net_half_width * (_half_w / BASE_HALF_W)
	ball.antenna_half_width = Ball.PHYS.antenna_half_width * (_half_w / BASE_HALF_W)



	ball.court_half_w = _half_w
	ball.court_half_l = _half_l
	ball.wall_min = Vector3(-21.7, -1000000.0, -27.7)


	ball.wall_max = Vector3(21.7, 34.0, 27.7)

	_input_collector.aim_min = Vector2( - _half_w - 1.5, - _half_l - 2.5)
	_input_collector.aim_max = Vector2(_half_w + 1.5, _half_l + 2.5)
	if _net_role == NetRole.OFFLINE:
		_spawn_teams()
	else:
		_spawn_teams_net()
	if _net_role != NetRole.CLIENT:
		TeamBot.ensure_team_jump_servers(_bots)





	_rally.setup(_lines, GameConfig.team_size, ball, _all_players, _slots, 
		_bots, _stats)
	_rally.set_points = GameConfig.set_points
	_rally.win_by_two = GameConfig.win_by_two
	_rally.input_for = func(p: Player): return _tick_inputs.get(p)
	_rally.point.connect(_on_rally_point)
	_rally.set_won.connect( func(w: int): _win_set(w))
	_rally.whistle_fault.connect(_on_rally_whistle)
	_rally.verdict.connect(_on_rally_verdict)

	LandingCall.dress(landing_marker, verdict_label)
	_rally.tossed.connect(_on_rally_tossed)
	_rally.touch_flair.connect(_on_rally_flair)
	for p in _all_players:
		var member: Player = p
		member.ball = ball
		member.quick_check = _quick_set_ready
		member.contact_priority_check = _rally.queued_contact_has_priority
		member.set_display_name(_cpu_tagged(_names[member])\
		if _gone_bodies.has(member) else _names[member])
		_stats[member] = {"pts": 0, "spk": 0, "blk": 0, "rcv": 0, "set": 0, "ast": 0}
		if _net_role != NetRole.CLIENT:
			member.touched.connect(_on_touched.bind(member))
			member.float_shown.connect(_on_float_shown.bind(member))
			member.combo_shown.connect(_on_combo_shown.bind(member))
			member.thumped.connect(_on_thumped.bind(member))
			member.launched.connect(_on_launched.bind(member))
			member.voiced.connect(_on_voiced.bind(member))
			member.block_broken.connect(_on_block_broken.bind(member))
			member.callout_made.connect(_on_callout_made.bind(member))
	if _net_role == NetRole.CLIENT:
		player.touch_attempted.connect(_on_local_touch_attempted)
		player.thumped.connect(_on_predicted_thumped)
	player.knock_started.connect( func(pos: Vector3, strength: float):


		camera_rig.shake(0.22 * strength))




	_start_recording()
	camera_rig.player = player
	camera_rig.ball = ball

	camera_rig.mode = clampi(GameConfig.default_camera, 0, 
		CameraRig.Mode.size() - 1) as CameraRig.Mode
	camera_rig.mode_changed.connect(hud.show_camera_name)
	camera_rig.apply_mouse_mode()
	camera_rig.home_side = float(player.team_side)
	camera_rig.court_span = _half_l
	ball.home_side = float(player.team_side)
	fx.setup(camera_rig)

	reach_marker = ReachMarker.new()
	add_child(reach_marker)
	reach_marker.setup(camera_rig.camera)

	aim_indicator.set_rig(camera_rig)

	# The on-screen pad aims and looks through this pair; see TouchControls.
	TouchControls.bind(camera_rig, _input_collector)


	reach_marker.entered_reach.connect( func():
		_play_local_reach("reach_in", -8.0))
	reach_marker.action_queued.connect( func():
		_play_local_reach("reach_queue", -2.0))
	reach_marker.took.connect( func():
		_play_local_reach("reach_take", -4.0, 1.15))
	reach_marker.missed.connect( func():
		_play_local_reach("reach_miss", -8.0))
	reach_marker.early.connect( func():
		_play_local_reach("reach_miss", -8.0))
	player.out_of_range.connect( func():
		_play_local_reach("reach_miss", -8.0))


	_input_collector.dive_denied.connect( func():
		if _spectating or _phase == Phase.REPLAY:
			return
		_play_local_reach("reach_miss", -8.0)
		hud.dive_denied()
		player.dive_denied())
	Ink.apply(camera_rig.camera)
	if _net_role != NetRole.CLIENT:
		ball.bounced.connect(_on_ball_bounced)
		ball.wall_hit.connect(_on_ball_wall_hit)
		ball.struck.connect(_on_ball_struck)
		ball.net_hit.connect(_on_net_hit)
	else:




		ball.struck.connect(_on_predicted_strike)
	if _net_role != NetRole.OFFLINE:


		Net.match_started.connect(_on_net_match_started)
		_my_peer_id = _local_pid()


		_in_chan.gen = GameConfig.match_seed
		_match_gen = GameConfig.match_seed
	if _net_role == NetRole.HOST and not GameConfig.migrate_carry.is_empty():


		var carry: Dictionary = GameConfig.migrate_carry
		GameConfig.migrate_carry = {}
		_scores = {1: int(carry.s1), -1: int(carry.s2)}
		_set_wins = {1: int(carry.w1), -1: int(carry.w2)}
		_set_number = maxi(int(carry.n), 1)
		Rules.set_swapped = _set_number % 2 == 0
		_migrate_resume = true
	match _net_role:
		NetRole.HOST:
			Net.input_received.connect(_on_net_input)
			Net.up_event_received.connect(_on_up_event)
			Net.peer_left_match.connect(_on_peer_left)
			Net.late_joiner.connect(_on_late_joiner)


			Net.peer_match_ready.connect( func(id: int):
				_wait_peers.erase(id)



				_net_event("stats", {"r": _stat_rows()}))
			for peer_id in _peer_players:
				if not Net.match_ready_peers.has(peer_id):
					_wait_peers[peer_id] = true
		NetRole.CLIENT:




			player.sim_authority = false
			ball.net_puppet = not _velsync_on()
			Net.snapshot_received.connect(_on_snapshot)
			Net.ball_snapshot_received.connect(_on_ball_snapshot)
			Net.event_received.connect(_on_net_event)
			Net.session_ended.connect(_on_session_ended)
			Net.notify_match_ready()
			if GameConfig.quick_backfill_side != 0 and _spectating:



				Net.send_up("seat", {"s": GameConfig.quick_backfill_side})



				hud.flash_banner("joining at the next serve")
			GameConfig.quick_backfill_side = 0








	if _net_role == NetRole.HOST:
		call_deferred("_relay_pending_late_joiners")



	hud.set_teams_available(_net_role != NetRole.OFFLINE
		and not GameConfig.ranked_match)
	hud.seat_requested.connect(_on_seat_requested)

	hud.pause_opened.connect( func():
		camera_rig.input_frozen = true




		_input_collector.swallow_held(["jump", "contact", "dive", "serve"])
		_input_collector.clear_buffers()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE)
	hud.pause_closed.connect( func():
		camera_rig.input_frozen = false



		_input_collector.swallow_held(["jump", "contact", "dive", "serve"])
		_input_collector.clear_buffers()


		if hud.stats_open():
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			camera_rig.apply_mouse_mode())
	hud.pause_pauses_tree = _net_role == NetRole.OFFLINE
	hud.apply_pause_mode()
	hud.play_again_pressed.connect(_on_play_again)
	hud.to_lobby_pressed.connect(_on_to_lobby)

	hud.set_loading(1.0)
	_park_ball()

func _process(_delta: float) -> void :



	_poll_stats_input()




	if _phase == Phase.REPLAY and _director != null and not _replay_stand_off:
		_director.seek_anims(lerpf(_replay_prev_t, _replay_cur_t, 
			Engine.get_physics_interpolation_fraction()))
	_music_heat_decay(_delta)


	if player != null and not _spectating and not _match_over and _phase in [Phase.DEAD, Phase.SERVE_PREP, Phase.LIVE]:
		_ach_time_acc += _delta
		if _ach_time_acc >= ACH_TIME_TICK:
			var whole: = int(_ach_time_acc)
			_ach_time_acc -= float(whole)
			Achievements.notify("play_time", {"amount": whole, "quiet": true})
	if _migrating:
		return


	_ad_t += _delta
	if _ad_t >= 3.0:
		_ad_t = 0.0
		_quick_ad_refresh()




	if _loading_up:
		_cover_t += _delta
		if _effective_phase() == Phase.INTRO:
			if _net_role != NetRole.CLIENT:
				_loading_up = false
			else:







				_reveal_a = clampf(1.0 - _cine_time / LOAD_FADE, 0.0, _reveal_a)




				hud.set_loading(_reveal_a)
				if _reveal_a <= 0.0:
					_loading_up = false






		elif _net_role == NetRole.CLIENT and (_snap_count > 0\
		or _cover_t > REVEAL_TIMEOUT_S) and not _awaiting_first_intro():
			if _pre_intro:



				_pre_intro = false
				ball.frozen = false


				_interp_hard = true
			_reveal_a = maxf(_reveal_a - _delta * 1.5, 0.0)
			hud.set_loading(_reveal_a)
			if _reveal_a <= 0.0:
				_loading_up = false





	var phase: = _effective_phase()
	_music_tick(phase)
	var playable: bool = phase == Phase.LIVE or phase == Phase.SERVE_PREP\
	or phase == Phase.DEAD or phase == Phase.COUNTDOWN
	_apply_seat_markers()
	_tick_reach_marker(phase)









	# One flag for "the player owns the input right now". The on-screen pad
	# claims touches on exactly the same terms the mouse owns the cursor.
	var touch_live: = playable and not (_intro_locked and phase == Phase.INTRO)\
		and not _spectating and not hud.pause_is_open()\
		and not hud.chat_typing() and not camera_rig.input_frozen
	TouchControls.set_live(touch_live)
	_input_collector.follow_cursor(camera_rig, touch_live)

	hud.set_aim_cursor(_input_collector.soft_cursor_active(), 
		_input_collector.soft_cursor_pos())


	if aim_indicator.visible:
		aim_indicator.follow_point(_input_collector.aim_point())

	_input_collector.snap_targets = []
	_input_collector.foe_targets = []
	if not _spectating and player != null:
		for sp in _all_players:
			var sb: Player = sp
			if sb == player:
				continue
			if sb.team_side == player.team_side:
				_input_collector.snap_targets.append(sb)
			else:
				_input_collector.foe_targets.append(sb)

		_input_collector.team_touches = _rally.touch_count\
		if _rally.touch_side == player.team_side else 0


	hud.track_ball_marker(camera_rig.camera, ball, 
		playable and not (_intro_locked and phase == Phase.INTRO)
		and not _spectating and not hud.pause_is_open(), player)

	if _spectating:
		_spec_tick(_delta)


	if _net_role != NetRole.OFFLINE and (hud.pause_is_open() or _spectating):
		_refresh_seat_menu()







func _apply_seat_markers() -> void :
	for p in _all_players:
		var body: Player = p



		var mine: = _is_own_body(body)
		body.indicator_enabled = mine
		body.charge_ui_enabled = mine







func _tick_reach_marker(phase: int) -> void :
	if reach_marker == null:
		return



	var live: = (phase == Phase.LIVE or phase == Phase.SERVE_PREP) and not _ball_dead
	reach_marker.drive(player, ball, 
		GameConfig.reach_marker and live and not _spectating)

func _exit_tree() -> void :
	TouchControls.unbind(camera_rig)


	GameConfig.stage_barefoot = false
	GameConfig.stage_reflections = true
	Net.team_of = Callable()




	if _net_role != NetRole.OFFLINE and not _rematch_reload:
		Net.end_match()

func _unhandled_input(event: InputEvent) -> void :



	_input_collector.feed_motion(event)



	if _spectating and _watch_cam != null and not hud.pause_is_open():


		if event.is_action_pressed("camera_toggle"):
			_watch_cam.cycle_mode()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			return



		if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo and (event as InputEventKey).keycode == KEY_H:
			_spec_ui = not _spec_ui
			hud.set_watch_ui_visible(_spec_ui)
			return
		if _watch_cam.handle_input(event):
			return



	if _net_role == NetRole.OFFLINE:
		return



	if not GameConfig.debug_menu:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key: = event as InputEventKey
		if not key.ctrl_pressed:
			return



		match key.keycode:
			KEY_1:
				Net.fake_latency_ms = 0
				Net.fake_jitter_ms = 0
			KEY_2:
				Net.fake_latency_ms = 40
				Net.fake_jitter_ms = 12
			KEY_3:
				Net.fake_latency_ms = 80
				Net.fake_jitter_ms = 25
			KEY_4:
				Net.fake_latency_ms = 150
				Net.fake_jitter_ms = 45

func _net_info_tick() -> void :
	if _net_role == NetRole.OFFLINE or _net_tick % 20 != 0:
		return



	if not GameConfig.debug_menu:
		hud.set_net_info("")
		return
	var rtt: = 0.0
	if _net_role == NetRole.CLIENT:
		rtt = Net.peer_rtt_ms(1)
	else:
		for peer_id in _peer_players:
			rtt = maxf(rtt, Net.peer_rtt_ms(peer_id))
	var lag_note: = "  ·  fake lag +%dms (±%dj)" % [Net.fake_latency_ms, Net.fake_jitter_ms]\
	if Net.fake_latency_ms > 0 or Net.fake_jitter_ms > 0 else ""



	var buf_note: = ""
	if GameConfig.debug_menu and _net_role == NetRole.CLIENT:
		buf_note = "  ·  buffer %.0fms (gap %.0f, jitter %.0f)"\
		%[interp_delay(), _snap_gap, _snap_jitter]


	var presets: = "  ·  ctrl+1-4 lag presets" if GameConfig.debug_menu else ""
	hud.set_net_info("online  ·  rtt %.0fms%s%s%s"\
	%[rtt, lag_note, buf_note, presets] + _pos_debug())


	if _net_log:
		_net_line_t += get_process_delta_time()
		if _net_line_t >= 1.0:
			_net_line_t = 0.0
			print("[net] ", _net_line(rtt))










var _net_line_t: = 0.0

func _net_line(rtt: float) -> String:
	if _net_role == NetRole.CLIENT:
		var mine: = player.global_position
		var host: = mine
		var idx: = _all_players.find(player)
		if not _np.is_empty() and idx >= 0:
			var st: = _pstate(_np.get("p", PackedFloat32Array()), idx)
			if not st.is_empty():
				host = Vector3(st[0], st[1], st[2])
		var ack: = int(_np.get("ack", {}).get(_local_pid(), 0))
		return ("CLIENT rtt=%.0f buf=%.0f gap=%.0f jit=%.0f err=%.3f lead=%.3f "
			+ "ackLag=%d me=(%.2f,%.2f) host=(%.2f,%.2f)") % [
			rtt, interp_delay(), _snap_gap, _snap_jitter, _pred.err.length(), 
			mine.distance_to(host), _in_chan.seq - ack, mine.x, mine.z, host.x, host.z]
	var out: = "HOST rtt=%.0f" % rtt
	for peer_id in _peer_players:
		var body: Player = _peer_players[peer_id]
		if body == null or not is_instance_valid(body):
			continue
		out += " | peer%d pos=(%.2f,%.2f) q=%d applied=%d starve=%d drop=%d trim=%d" % [
			peer_id, body.global_position.x, body.global_position.z, 
			(_peer_queue.get(peer_id, []) as Array).size(), 
			int(_peer_applied.get(peer_id, 0)), 
			int(_peer_starved.get(peer_id, 0)), 
			int(_peer_dropped.get(peer_id, 0)), 
			int(_peer_trimmed.get(peer_id, 0))]
	out += " | touch ok=%d reach=%d kind=%d dead=%d expired=%d" % [
		_lag_reject.ok, _lag_reject.reach, _lag_reject.kind, 
		_lag_reject.dead, _lag_reject.expired]
	for k in _lag_reject:
		_lag_reject[k] = 0
	return out









func _awaiting_first_intro() -> bool:
	if _cover_t > REVEAL_TIMEOUT_S or _np.is_empty():
		return false
	return _effective_phase() == Phase.DEAD\
	and int(_np.get("s1", 0)) == 0 and int(_np.get("s2", 0)) == 0\
	and int(_np.get("w1", 0)) == 0 and int(_np.get("w2", 0)) == 0\
	and int(_np.get("sn", 1)) <= 1







func _pos_debug() -> String:



	if not GameConfig.debug_menu:
		return ""
	if _net_role == NetRole.CLIENT:
		var mine: = player.global_position
		var host: = mine
		var idx: = _all_players.find(player)
		if not _np.is_empty() and idx >= 0:
			var st: = _pstate(_np.get("p", PackedFloat32Array()), idx)
			if not st.is_empty():
				host = Vector3(st[0], st[1], st[2])




		return """
ME (%.2f, %.2f)  ·  host (%.2f, %.2f)  ·  ERR %.2fm  ·  lead %.2fm""" %[mine.x, mine.z, host.x, host.z, _pred.err.length(), 
			mine.distance_to(host)]

	var out: = ""
	for peer_id in _peer_players:
		var body: Player = _peer_players[peer_id]
		if body == null or not is_instance_valid(body):
			continue
		out += """
CLIENT %d (%.2f, %.2f)  ·  ack %d  ·  q %d  ·  starve %d  ·  drop %d""" %[peer_id, body.global_position.x, body.global_position.z, 
			int(_peer_applied.get(peer_id, 0)), 
			(_peer_queue.get(peer_id, []) as Array).size(), 
			int(_peer_starved.get(peer_id, 0)), 
			int(_peer_dropped.get(peer_id, 0))]
	return out

func _on_session_ended(reason: String) -> void :














	var _real_survivors: = Net.last_players.keys()\
	.filter( func(id): return int(id) != 1).size()
	if reason == "host left" and _real_survivors >= 1:
		_migrating = true



		MIGRATION_COVER.hold(get_tree())
		var surv: = Net.last_players.keys().filter( func(id): return int(id) != 1)
		surv.sort()
		var successor_sid: = int((Net.last_players[surv[0]] as Dictionary)\
		.get("sid", 0))
		(load("res://game/net/migrate.gd") as GDScript).begin(get_tree(), {
			"survivors": Net.last_players, 
			"my_id": _my_peer_id, 
			"my_name": Net.my_name, 
			"token": Net.session_token, 
			"steam": Net.steam_transport_available() and successor_sid != 0, 
			"roster": _live_cast(), 
			"carry": {"s1": int(_scores[1]), "s2": int(_scores[-1]), 
				"w1": int(_set_wins[1]), "w2": int(_set_wins[-1]), 
				"n": _set_number}, 
			"quick": GameConfig.quick_match, 

			"over": _match_over, 
			"solo": _real_survivors == 1, 
			"room": Net.custom_lobby, 
			"stage": GameConfig.stage, 
			"size": GameConfig.team_size, 
			"seed": GameConfig.match_seed, 
		})
		return

	UiWipe.wipe(get_tree(), func():
		GameConfig.goto_scene("res://game/ui/menu.tscn"))












func _teamwear(cfg: CharacterConfig, home: bool) -> CharacterConfig:
	if bool(Stage.val(GameConfig.stage, "casual", false)):
		return cfg
	return GameConfig.dress_in_team_gear(cfg, home)

func _stage_outfit(cfg: CharacterConfig, kit: Array) -> Array:
	if not bool(Stage.val(GameConfig.stage, "casual", false)):
		return [cfg, kit]
	if GameConfig.team_size <= 1:
		return [cfg.gym_look(), cfg.gym_kit()]



	var look: = cfg.gym_look()
	if bool(Stage.val(GameConfig.stage, "scrimmage_pinny", false)):
		look.wear_pinny = true


		look.pinny_color = kit[0]
		look.pinny_accent = Color(0.96, 0.96, 0.95)
	return [look, look.gym_kit()]

func _spawn_teams() -> void :


	GameConfig.new_match_seed()
	var n: = GameConfig.team_size
	var my_side: = 1 if GameConfig.local_side >= 0 else -1
	player.team_side = my_side
	_slots[player] = 0
	_names[player] = Net.local_display_name()
	player.global_position = _formation_spot(0, n, my_side)



	var own_fit: = _stage_outfit(GameConfig.character, GameConfig.team_kit(my_side > 0))
	player.set_character(own_fit[0], own_fit[1])
	_all_players = [player]
	_reset_cpu_names()



	var cpus: Dictionary = GameConfig.local_cpus
	for i in range(1, n):
		var ac: = CpuSlots.lookup(cpus, my_side, i - 1)
		var ally: = _spawn_bot(i, n, my_side, _team_color(my_side, i), ac)
		_names[ally] = ("%s (CPU)" % String(ac.name)) if not ac.is_empty()\
		else _next_cpu_name()
		_all_players.append(ally)
	for i in range(n):
		var oc: = CpuSlots.lookup(cpus, - my_side, i)
		var opp: = _spawn_bot(i, n, - my_side, _team_color( - my_side, i), oc)
		_names[opp] = ("%s (CPU)" % String(oc.name)) if not oc.is_empty()\
		else _next_cpu_name()
		_all_players.append(opp)

func _team_color(side: int, slot: int) -> Color:

	return Rules.side_color(side).darkened(0.06 * slot)




func _reset_cpu_names() -> void :
	_cpu_name_pool = CpuNames.shuffled(GameConfig.match_seed)
	_cpu_name_i = 0



func _next_cpu_name() -> String:
	if _cpu_name_pool.is_empty():
		_reset_cpu_names()
	var raw: String = _cpu_name_pool[_cpu_name_i % _cpu_name_pool.size()]
	_cpu_name_i += 1
	return "%s (CPU)" % raw





func _cpu_tagged(base: String) -> String:
	return base if base.ends_with("(CPU)") else "%s (CPU)" % base

func _spawn_teams_net() -> void :



	var n: = GameConfig.team_size
	var my_peer: = _local_pid()


	var _net_my_side: = 1
	for entry in GameConfig.net_roster:
		if int(entry.peer) == my_peer:
			_net_my_side = int(entry.side)
			break

	for entry in GameConfig.net_roster:
		if int(entry.peer) == my_peer and bool(entry.get("spec", false)):
			_spectating = true
			break
	_all_players = []
	var net_id: = 0


	_reset_cpu_names()
	for entry in GameConfig.net_roster:


		if bool(entry.get("spec", false)):
			continue
		net_id += 1
		var body: Player
		if int(entry.peer) == my_peer and not _spectating:
			body = player
		else:
			body = PLAYER_SCENE.instantiate()
			add_child(body)
		body.team_side = int(entry.side)
		body.global_position = _formation_spot(int(entry.slot), n, int(entry.side))
		body.face_net()



		body.set_team_color(_team_color(int(entry.side), int(entry.slot)))

		var entry_cfg: Dictionary = entry.get("cfg", {})



		var look: = CharacterConfig.from_dict(entry_cfg) if not entry_cfg.is_empty()\
		else GameConfig.bot_character(int(entry.side), int(entry.slot))
		var kit: Array = (entry.get("kit", []) as Array).map(
			func(s): return Color.html(str(s)))
		var fit: = _stage_outfit(look, kit)
		body.set_character(fit[0], fit[1])


		body.set_tag_color(_team_color(int(entry.side), int(entry.slot)))
		_slots[body] = int(entry.slot)




		if int(entry.peer) == 0:



			var cname: = String(entry.get("cname", ""))
			_names[body] = ("%s (CPU)" % cname) if cname != "" else _next_cpu_name()
		else:
			_names[body] = String(entry.name)
		body.set_dev_tag(DevBadge.peer_tier(int(entry.peer)))
		if bool(entry.get("gone", false)):


			_gone_bodies[body] = true
		_net_ids[body] = net_id
		_by_net_id[net_id] = body
		_all_players.append(body)
		if body == player:
			continue
		if int(entry.peer) == 0:


			body.is_bot = true
			body.charge_ui_enabled = false
			if _net_role == NetRole.HOST:
				var brain: = TeamBot.new()
				brain.configure(_half_w, _half_l, int(entry.slot), n)

				brain.apply_difficulty(int(entry.get("diff", Net.cpu_difficulty)))
				_bots[body] = brain
		else:
			body.charge_ui_enabled = false
			if _net_role == NetRole.HOST:
				_peer_players[int(entry.peer)] = body
				_peer_edges[int(entry.peer)] = {"jr": 0, "cr": 0, "sr": 0, "dv": 0, "sv": 0}
		if _net_role == NetRole.CLIENT:
			body.net_puppet = true
	if _spectating:




		player.visible = false
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.global_position = Vector3(0.0, -100.0, 0.0)
		_become_spectator(_net_my_side)












func _is_own_body(body: Player) -> bool:
	return body == player and not _spectating




func _refresh_seat_menu() -> void :



	hud.set_seat_options(free_seats(1), free_seats(-1), 
		not _spectating or GameConfig.quick_backfill_side != 0)

func _on_seat_requested(side: int) -> void :

	if _net_role == NetRole.HOST:
		request_seat(_local_pid(), side)
	elif _net_role == NetRole.CLIENT:
		Net.send_up("seat", {"s": side})

func _on_seat_event(args: Dictionary) -> void :
	var body: Player = _by_net_id.get(Net.ev_i(args, "id", 0))
	if body == null:
		return
	var peer: = Net.ev_i(args, "p", 0)






	var was: = Net.ev_i(args, "was", 0)
	var me: = _local_pid()
	var mine: = peer == me or (peer == 0 and was == me)
	_names[body] = Net.ev_s(args, "n", "cpu", 64)
	body.set_display_name(_names[body])
	body.set_dev_tag(DevBadge.peer_tier(peer))
	body.is_bot = peer == 0





	if peer != 0:
		var look: = _roster_look(peer)
		if look != null:
			var fit: = _stage_outfit(look, _team_kit_for(body.team_side))
			body.set_character(fit[0], fit[1])
	else:


		var cslot: = int(_slots.get(body, 0))
		var cpu_fit: = _stage_outfit(GameConfig.bot_character(body.team_side, cslot), 
			_team_kit_for(body.team_side))
		body.set_character(cpu_fit[0], cpu_fit[1])
	if not mine:

		body.net_puppet = _net_role == NetRole.CLIENT
		return
	if peer == 0:
		if body == player:
			_leave_seat()
	else:
		_take_seat(body)






func _take_seat(body: Player) -> void :
	_spectating = false
	_watch_cam = null
	camera_rig.watched = false
	player = body
	body.net_puppet = false
	body.sim_authority = false
	body.is_bot = false
	_gone_bodies.erase(body)
	if not _stats.has(body):
		_stats[body] = {"pts": 0, "spk": 0, "blk": 0, "rcv": 0, "set": 0, "ast": 0}



	body.velocity = Vector3.ZERO
	body.reset_physics_interpolation()
	_interp_hard = true
	body.charge_ui_enabled = true
	body.indicator_enabled = true
	_pred.reset()
	camera_rig.player = body
	camera_rig.home_side = float(body.team_side)
	ball.home_side = float(body.team_side)
	camera_rig.mode = clampi(GameConfig.default_camera, 0, 
		CameraRig.Mode.size() - 1) as CameraRig.Mode
	camera_rig.apply_mouse_mode()
	hud.set_spectating(false)
	hud.set_play_ui_visible(true)
	hud.set_scoreboard_visible(true)
	_spec_apply_clean_all(true)


	hud.hide_seat_tell()


func _leave_seat() -> void :
	if _spectating:
		return
	player.indicator_enabled = false
	player.charge_ui_enabled = false
	player.net_puppet = _net_role == NetRole.CLIENT
	_spectating = true
	_become_spectator(int(player.team_side))
	hud.flash_banner("you are watching")

func _spec_apply_clean_all(show: bool) -> void :
	for p in _all_players:
		(p as Player).set_labels_visible(show)

func _become_spectator(my_side: int) -> void :


	if player != null:
		player.set_name_visible(true)
	var watch: Player = null
	for p in _all_players:


		if p == player:
			continue

		if (p as Player).team_side == my_side:
			watch = p
			break
	if watch == null:
		for p in _all_players:
			if p != player:
				watch = p
				break
	var ours: = player
	player = watch








	if ours != null and ours != watch and not _all_players.has(ours):
		ours.queue_free()
	if player == null:
		return

	player.indicator_enabled = false
	player.charge_ui_enabled = false

	camera_rig.mode = CameraRig.Mode.BROADCAST
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE




	camera_rig.watched = true
	_watch_cam = WatchCamera.new()
	_watch_cam.setup(camera_rig.camera)
	_watch_cam.bodies = _all_players
	_watch_cam.ball = ball
	_watch_cam.half_w = _half_w
	_watch_cam.half_l = _half_l
	var bar: = hud.spectate_controls()
	hud.set_spectating(true)



	hud.set_play_ui_visible(false)



	if _spec_bar_wired:
		return
	_spec_bar_wired = true
	bar.cam_pressed.connect( func():
		_watch_cam.cycle_mode()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE)
	bar.follow_pressed.connect( func(): _watch_cam.cycle_follow())
	bar.clean_pressed.connect( func():
		_spec_clean = (_spec_clean + 1) % 3
		_spec_apply_clean())
	bar.ui_pressed.connect( func():
		_spec_ui = not _spec_ui
		hud.set_watch_ui_visible(_spec_ui))

func _spec_tick(delta: float) -> void :
	if _watch_cam == null:
		return




	hud.set_play_ui_visible(false)
	_watch_cam.time += delta
	_watch_cam.drive(delta)
	var names: Array = []
	for p in _all_players:
		names.append(_names.get(p, "player"))
	var clean: String = ["off", "no names", "on"][_spec_clean]
	hud.spectate_controls().set_labels(_watch_cam.mode_name(), 
		_watch_cam.follow_name(names), clean, not _spec_ui)

func _spec_apply_clean() -> void :
	for p in _all_players:
		(p as Player).set_labels_visible(_spec_clean == 0)

func _spawn_bot(slot: int, n: int, side: int, color: Color, cpu: Dictionary = {}) -> Player:
	var bot: Player = PLAYER_SCENE.instantiate()
	bot.team_side = side
	add_child(bot)
	bot.global_position = _formation_spot(slot, n, side)
	bot.is_bot = true
	bot.charge_ui_enabled = false
	bot.set_team_color(color)





	var is_mine: = side == player.team_side
	var bot_kit: Array = GameConfig.team_kit(player.team_side > 0) if is_mine\
	else GameConfig.opponent_kit()

	var look: CharacterConfig = CharacterConfig.from_dict(cpu.cfg)\
	if not cpu.is_empty() else GameConfig.bot_character(side, slot)
	var bot_fit: = _stage_outfit(look, bot_kit)
	bot.set_character(bot_fit[0], bot_fit[1])
	_slots[bot] = slot
	var brain: = TeamBot.new()
	brain.configure(_half_w, _half_l, slot, n)




	brain.apply_difficulty(int(cpu.get("diff", GameConfig.difficulty)))
	_bots[bot] = brain
	return bot

func _formation_spot(slot: int, n: int, side: int) -> Vector3:
	return _lines.formation_spot(slot, n, side)

func _court_slot(who: Player) -> int:
	return _rally.court_slot(who)

func _player_in_slot(side: int, slot: int) -> Player:
	return _rally.player_in_slot(side, slot)

func _flush_motion_state() -> void :




	for peer_id in _peer_queue:
		(_peer_queue[peer_id] as Array).clear()
	_peer_touch_inputs.clear()




	_pred.reset()

func _reset_formation() -> void :
	_flush_motion_state()
	_rally.reset_formation()

func _quick_set_ready(aim: Vector3, hitter: Player) -> bool:
	return _lines.quick_set_ready(_all_players, aim, hitter)



func _physics_process(delta: float) -> void :





	if _migrating:
		return
	_poll_callouts()
	_poll_skip_vote()
	_sync_home_side()

	if _phase != Phase.REPLAY:
		_recorder.tick(delta)
	if _net_role == NetRole.CLIENT:
		_client_tick(delta)
		return
	if _phase == Phase.REPLAY:
		_replay_tick(delta)
		_update_indicators(_input_collector.collect(camera_rig, player))





		_decay_net_wobble(delta)
		if _net_role == NetRole.HOST:
			_net_tick += 1
			_net_info_tick()
			if _net_tick % SNAPSHOT_EVERY == 0:
				_snap_seq += 1
				Net.send_snapshot(_build_replay_snapshot())
		return


	_rally.pre_tick(delta, _phase != Phase.LIVE)



	for phase_player in _all_players:
		var phase_body: Player = phase_player
		phase_body.contact_enabled = _phase == Phase.LIVE\
		or (_phase == Phase.SERVE_PREP and phase_body == _server)
		phase_body.serve_charge_ui = _phase == Phase.SERVE_PREP\
		and phase_body == _server


		phase_body.team_touches = _rally.touch_count\
		if _rally.touch_side == phase_body.team_side else 0


	ball.serve_held = _phase == Phase.SERVE_PREP and not _rally.serve_done
	_record_lag_history()
	_tick_inputs.clear()









	var input: = PlayerInput.new()
	if not _spectating:
		input = _gate_cinematics(_input_collector.collect(camera_rig, player))
		if hud.chat_typing() or hud.pause_is_open():




			input = PlayerInput.new()
		_tick_inputs[player] = input
		player.simulate(input, delta)
	for peer_id in _peer_players:
		var remote: Player = _peer_players[peer_id]
		var rin: = _decode_peer_input(peer_id)
		_tick_inputs[remote] = rin
		remote.simulate(rin, delta)
		_remember_peer_touch_input(peer_id, remote, rin)
	var cine: = _phase == Phase.INTRO or _phase == Phase.COUNTDOWN\
	or _phase == Phase.WIN or _phase == Phase.STATS
	for p in _all_players:
		(p as Player).cinematic_hidden = cine
	for p in _bots:
		var bot_player: Player = p
		var bot_input: PlayerInput
		if cine:

			bot_input = PlayerInput.new()
		else:
			var bot: TeamBot = _bots[bot_player]






















			bot.aggression = _rally.bot_aggression()
			var serving: bool = bot_player == _server and not _serve_done



			var team_serving: bool = _server != null and not _serve_done\
			and _server.team_side == bot_player.team_side
			bot_input = bot.think(bot_player, _allies_of(bot_player), 
				_opponents_of(bot_player), ball, _touch_count, _rally_live, 
				serving, delta, _rally.last_touch_side, team_serving)
		bot_player.simulate(bot_input, delta)
	_process_lag_touch_requests()
	match _phase:
		Phase.INTRO:
			_intro_tick(delta)
		Phase.COUNTDOWN:
			_countdown_tick(delta)
		Phase.WIN:
			_win_tick(delta)
		Phase.STATS:
			pass
		Phase.DEAD:
			if _wait_peers.size() > 0:
				_wait_timeout -= delta
				if _wait_timeout <= 0.0:



					for peer_id in _wait_peers.keys():
						if _peer_players.has(peer_id):
							_on_peer_left(peer_id)
					_wait_peers.clear()
				hud.set_serve_prompt("waiting for players to load")
			elif _replay_pending:






				_replay_wait -= delta
				if _replay_wait <= 0.0 and not _replay_starting:
					_enter_replay()
			elif _win_delay > 0.0:


				_win_delay -= delta
				if _win_delay <= 0.0:
					_win_delay = 0.0
					_start_win(_win_pending)
			else:
				if _swap_delay > 0.0:
					_swap_delay -= delta
					if _swap_delay <= 0.0:
						_swap_delay = 0.0
						_switch_sides()




				if _serve_prelaid and _server != null:
					ball.global_position = _server.serve_cradle_point()
					ball.vel = Vector3.ZERO
				_dead_timer -= delta
				if _dead_timer <= 0.0:
					if _match_over:
						_leave_to_lobby()
					elif _migrate_resume:








						_migrate_resume = false
						_point_wipe( func():
							_loading_up = false
							hud.set_loading(0.0)


							MIGRATION_COVER.dismiss()
							hud.flash_banner("rally restarted")
							_start_countdown())
					elif not _did_intro:
						_start_intro()
					elif _serve_prelaid:



						_serve_prelaid = false
						_begin_serve(false)
					else:
						_begin_serve()
		Phase.SERVE_PREP:
			_serve_prep_tick(delta)
		Phase.LIVE:

			_rally.live_tick(delta)
	_check_air_bumps()
	for p in _all_players:
		var member: Player = p
		if absf(member.global_position.z) < 0.45\
		and absf(member.global_position.x) < _half_w\
		and member.velocity.length() > 1.0:
			_net_wobble = maxf(_net_wobble, 0.45)
	_motion_foley(delta)
	_decay_net_wobble(delta)
	_update_indicators(input)
	if _net_role == NetRole.HOST:
		_tick_peer_liveness(delta)





		if not _peer_players.is_empty():
			_stats_bcast_accum += delta
			if _stats_bcast_accum >= STATS_REBROADCAST_S:
				_stats_bcast_accum = 0.0
				_net_event("stats", {"r": _stat_rows()})
		_net_tick += 1
		_net_info_tick()
		if _net_tick % SNAPSHOT_EVERY == 0:
			_snap_seq += 1
			Net.send_snapshot(_build_snapshot())
		elif _ball_60hz:


			Net.send_ball_snapshot(_ball_net_state())

func _ball_net_state() -> PackedFloat32Array:
	return PackedFloat32Array([ball.global_position.x, ball.global_position.y, 
		ball.global_position.z, ball.vel.x, ball.vel.y, ball.vel.z, 
		1.0 if ball.frozen else 0.0, ball.curve, float(ball.strike_seq)])

func _decay_net_wobble(delta: float) -> void :
	if _net_wobble > 0.001:



		_net_wobble *= exp(-1.1 * delta)
		((net_visual.mesh as PlaneMesh).material as ShaderMaterial)\
		.set_shader_parameter("wobble", _net_wobble)



var _match_gen: = 0

func _on_net_input(peer_id: int, data: Dictionary) -> void :



	_peer_heard[peer_id] = 0.0



	if data.has("g") and Net.ni(data.get("g", 0)) != _match_gen:
		return


	for older in Net.ev_arr(data, "r", 8):
		if older is Dictionary:
			_ingest_peer_input(peer_id, older)
	_ingest_peer_input(peer_id, data)

func _ingest_peer_input(peer_id: int, data: Dictionary) -> void :
	var seq: = Net.ev_i(data, "s")
	if seq <= int(_peer_seq_seen.get(peer_id, 0)):
		return
	_peer_seq_seen[peer_id] = seq








	var q: Array = _peer_queue.get(peer_id, [])
	q.append(data)







	while q.size() > INPUT_QUEUE_MAX:
		q.pop_front()
		_peer_dropped[peer_id] = int(_peer_dropped.get(peer_id, 0)) + 1
	_peer_queue[peer_id] = q

func _tick_peer_liveness(delta: float) -> void :




	for peer_id in _peer_players.keys():
		_peer_heard[peer_id] = float(_peer_heard.get(peer_id, 0.0)) + delta
		if _peer_heard[peer_id] > PEER_SILENT_TIMEOUT:
			_peer_heard.erase(peer_id)
			_on_peer_left(peer_id)

func _decode_peer_input(peer_id: int) -> PlayerInput:


	var input: = PlayerInput.new()

	var q: Array = _peer_queue.get(peer_id, [])



	while q.size() > INPUT_QUEUE_MAX:
		q.pop_front()
		_peer_dropped[peer_id] = int(_peer_dropped.get(peer_id, 0)) + 1






	if q.size() > INPUT_QUEUE_TARGET:
		_peer_deep[peer_id] = int(_peer_deep.get(peer_id, 0)) + 1
		if int(_peer_deep[peer_id]) >= INPUT_QUEUE_DEEP_TICKS:
			_peer_deep[peer_id] = 0
			q.pop_front()
			_peer_trimmed[peer_id] = int(_peer_trimmed.get(peer_id, 0)) + 1
	else:
		_peer_deep[peer_id] = 0
	if q.size() > 0:
		_peer_input[peer_id] = q.pop_front()
	else:




		_peer_starved[peer_id] = int(_peer_starved.get(peer_id, 0)) + 1
	_peer_queue[peer_id] = q
	var msg: Dictionary = _peer_input.get(peer_id, {})
	if msg.is_empty():
		return input









	_peer_applied[peer_id] = int(msg.get("s", 0))


	return NetSync.decode_input_fields(msg, _peer_edges[peer_id])

func _remember_peer_touch_input(peer_id: int, body: Player, 
		input: PlayerInput) -> void :
	var seq: = int(_peer_applied.get(peer_id, 0))
	if seq <= 0:
		return
	var history: Dictionary = _peer_touch_inputs.get(peer_id, {})



	if history.has(seq):
		return







	var power: = body.hold_power()
	var finesse: = body._hold_real <= Player.FEEL.tap_hold
	if input.contact_released or input.set_released:
		power = maxf(power, body._armed_power)
		finesse = body._armed_finesse
	history[seq] = {"input": input, "power": power, "finesse": finesse}
	for old_seq in history.keys():
		if int(old_seq) < seq - 32:
			history.erase(old_seq)
	_peer_touch_inputs[peer_id] = history

func _on_peer_left(peer_id: int) -> void :


	var body: Player = _peer_players.get(peer_id)
	if body == null:
		return
	_wait_peers.erase(peer_id)
	_peer_players.erase(peer_id)
	_pa_opt.erase(peer_id)
	_pa_push_states()
	_peer_heard.erase(peer_id)
	_peer_input.erase(peer_id)
	_peer_queue.erase(peer_id)
	_peer_seq_seen.erase(peer_id)
	_peer_applied.erase(peer_id)
	_peer_touch_inputs.erase(peer_id)
	_peer_starved.erase(peer_id)
	_peer_dropped.erase(peer_id)
	_peer_trimmed.erase(peer_id)
	_peer_deep.erase(peer_id)
	_peer_edges.erase(peer_id)
	body.is_bot = true
	var brain: = TeamBot.new()
	brain.configure(_half_w, _half_l, _slots[body], GameConfig.team_size)
	brain.apply_difficulty(Net.cpu_difficulty if _net_role != NetRole.OFFLINE else 1)
	_bots[body] = brain
	var gone: = String(_names[body])


	_names[body] = _cpu_tagged(gone)
	body.set_display_name(_names[body])
	body.set_dev_tag(DevBadge.Tier.NONE)
	hud.notice("%s has left the game" % gone)
	_net_event("left", {"id": _net_ids.get(body, 0), "n": gone})














var _join_queue: = {}

func request_seat(peer_id: int, side: int) -> void :
	_join_queue[peer_id] = side
	if _seat_boundary_safe():
		_apply_seat_requests()















func _seat_boundary_safe() -> bool:
	if _rally_live:
		return false



	if _replay_pending:
		return false
	return _phase == Phase.DEAD or _phase == Phase.SERVE_PREP

func _apply_seat_requests() -> void :
	if _join_queue.is_empty():
		return
	var queued: = _join_queue.duplicate()
	_join_queue.clear()
	for peer_id in queued:
		var side: = int(queued[peer_id])
		if side == 0:
			_release_seat(int(peer_id))
		else:
			_claim_seat(int(peer_id), side)

func free_seats(side: int) -> int:
	var n: = 0
	for p in _all_players:
		var body: Player = p




		if body.team_side == side and body.is_bot:
			n += 1
	return n



func _roster_look(peer_id: int) -> CharacterConfig:
	for entry in GameConfig.net_roster:
		if int(entry.get("peer", 0)) != peer_id:
			continue
		var cfg: Dictionary = entry.get("cfg", {})
		if cfg.is_empty():
			return null
		return CharacterConfig.from_dict(cfg)




	var pcfg: Dictionary = (Net.players.get(peer_id, {}) as Dictionary)\
	.get("cfg", {})
	if not pcfg.is_empty():
		return CharacterConfig.from_dict(pcfg)
	if _is_local_peer(peer_id):
		return GameConfig.character
	return null

func _team_kit_for(side: int) -> Array:
	for entry in GameConfig.net_roster:
		if int(entry.get("side", 0)) == side and not entry.get("kit", []).is_empty():
			return (entry.get("kit", []) as Array).map(
				func(c): return Color.html(str(c)))





	var home_side: = 1 if GameConfig.local_side >= 0 else -1
	if _team_identity(side) == home_side:
		return GameConfig.team_kit(home_side > 0)
	return GameConfig.opponent_kit()



func _announce_seat(who: String, side: int, _body: Player) -> void :
	if side == 0:
		hud.notice("%s is spectating" % who)
		return
	hud.notice("%s joined %s" % [who, _side_name(side)])

func _is_local_peer(peer_id: int) -> bool:




	return _net_role != NetRole.CLIENT and peer_id == _local_pid()

func _claim_seat(peer_id: int, side: int) -> bool:



	if free_seats(side) <= 0:
		return false
	if _peer_players.has(peer_id) or (_is_local_peer(peer_id) and not _spectating):
		_release_seat(peer_id)
	var body: Player = null
	for p in _all_players:
		var candidate: Player = p
		if candidate.team_side == side and candidate.is_bot:
			body = candidate
			break
	if body == null:
		return false
	_bots.erase(body)
	body.is_bot = false
	_gone_bodies.erase(body)


	if not _stats.has(body):
		_stats[body] = {"pts": 0, "spk": 0, "blk": 0, "rcv": 0, "set": 0, "ast": 0}
	if _is_local_peer(peer_id):

		_spectating = false
		_watch_cam = null
		camera_rig.watched = false
		player = body
		body.charge_ui_enabled = true
		body.indicator_enabled = true
		camera_rig.player = body
		camera_rig.home_side = float(body.team_side)
		ball.home_side = float(body.team_side)




		camera_rig.mode = clampi(GameConfig.default_camera, 0, 
			CameraRig.Mode.size() - 1) as CameraRig.Mode
		camera_rig.apply_mouse_mode()
		hud.set_spectating(false)
		hud.set_play_ui_visible(true)





	else:
		body.charge_ui_enabled = false
		_peer_players[peer_id] = body
	_peer_edges[peer_id] = {"jr": 0, "cr": 0, "sr": 0, "dv": 0, "sv": 0}
	_peer_queue[peer_id] = []
	_peer_heard[peer_id] = 0.0
	var who: = String((Net.players.get(peer_id, {}) as Dictionary).get("name", 
		"player"))



	var look: = _roster_look(peer_id)
	if look != null:
		var fit: = _stage_outfit(look, _team_kit_for(body.team_side))
		body.set_character(fit[0], fit[1])
	_names[body] = who
	body.set_display_name(who)
	body.set_dev_tag(DevBadge.peer_tier(peer_id))
	_announce_seat(who, body.team_side, body)
	_net_event("seat", {"id": _net_ids.get(body, 0), "p": peer_id, "n": who, 
		"who": who, "side": body.team_side})
	return true

func _release_seat(peer_id: int) -> void :


	var body: Player = _peer_players.get(peer_id)
	if body == null and _is_local_peer(peer_id) and not _spectating:
		body = player
	if body == null:
		return
	_peer_players.erase(peer_id)
	_peer_input.erase(peer_id)
	_peer_queue.erase(peer_id)
	_peer_seq_seen.erase(peer_id)
	_peer_applied.erase(peer_id)
	_peer_touch_inputs.erase(peer_id)
	_peer_starved.erase(peer_id)
	_peer_dropped.erase(peer_id)
	_peer_trimmed.erase(peer_id)
	_peer_deep.erase(peer_id)
	_peer_edges.erase(peer_id)
	body.is_bot = true
	var brain: = TeamBot.new()
	brain.configure(_half_w, _half_l, _slots[body], GameConfig.team_size)
	brain.apply_difficulty(Net.cpu_difficulty)
	_bots[body] = brain




	var cslot: = int(_slots.get(body, 0))
	var cpu_fit: = _stage_outfit(GameConfig.bot_character(body.team_side, cslot), 
		_team_kit_for(body.team_side))
	body.set_character(cpu_fit[0], cpu_fit[1])
	var gone: = String(_names[body])


	_names[body] = _cpu_tagged(gone)
	body.set_display_name(_names[body])
	body.set_dev_tag(DevBadge.Tier.NONE)
	if _is_local_peer(peer_id):
		_spectating = true
		_become_spectator(int(body.team_side))
	_announce_seat(gone, 0, body)



	_net_event("seat", {"id": _net_ids.get(body, 0), "p": 0, "n": _cpu_tagged(gone), 
		"who": gone, "side": 0, "was": peer_id})



func _build_snapshot() -> Dictionary:





	var pstates: = PackedFloat32Array()
	for p in _all_players:
		pstates.append_array((p as Player).net_capture())
	var acks: = {}
	for peer_id in _peer_input:
		acks[peer_id] = _peer_applied.get(peer_id, 0)
	return {
		"ph": _phase, "sc": _serve_clock, "rt": _rally_time, 
		"tc": _touch_count, "sv": _net_ids.get(_server, 0), 
		"lt": _net_ids.get(_last_toucher, 0), 
		"sd": _serve_done, 
		"s1": _scores[1], "s2": _scores[-1], 
		"w1": _set_wins[1], "w2": _set_wins[-1], "sn": _set_number, 
		"b": PackedFloat32Array([ball.global_position.x, ball.global_position.y, 
			ball.global_position.z, ball.vel.x, ball.vel.y, ball.vel.z, 
			1.0 if ball.frozen else 0.0, ball.curve, 
			float(ball.strike_seq)]), 
		"p": pstates, "ack": acks, 


		"sq": _snap_seq, 
	}

func _build_replay_snapshot() -> Dictionary:





	var acks: = {}
	for peer_id in _peer_input:
		acks[peer_id] = _peer_applied.get(peer_id, 0)
	return {
		"ph": Phase.REPLAY, 
		"s1": _scores[1], "s2": _scores[-1], 
		"w1": _set_wins[1], "w2": _set_wins[-1], "sn": _set_number, 
		"ack": acks, "sq": _snap_seq, 
	}

func _pstate(flat: PackedFloat32Array, idx: int) -> PackedFloat32Array:

	var base: = idx * PSTATE_FLOATS
	if idx < 0 or base + PSTATE_FLOATS > flat.size():
		return PackedFloat32Array()
	return flat.slice(base, base + PSTATE_FLOATS)

func _net_event(kind: String, args: Dictionary) -> void :
	if _net_role == NetRole.HOST:
		Net.send_event(kind, args)






func _ach_emit(body: Player, event: String, data: Dictionary) -> void :
	if body == null or body.is_bot:
		return
	if body == player and not _spectating:
		Achievements.notify(event, data)
	_net_event("ach", {"id": int(_net_ids.get(body, -1)), "e": event, "d": data})

func _ach_touched(kind: int, who: Player) -> void :
	if _net_role == NetRole.CLIENT or who == null:
		return

	if _ach_roll != null and _ach_roll != who:
		_ach_emit(_ach_roll, "roll_save", {})
		_ach_roll = null
	var name: = ""
	match kind:
		Player.TouchKind.SPIKE:
			name = "spike"
		Player.TouchKind.DUMP:
			name = "dump"
		Player.TouchKind.BLOCK:
			name = "block"
		Player.TouchKind.SET:
			name = "set"
		Player.TouchKind.BUMP:
			name = "bump"


	var foot: = int(who.get("_kick_foot")) != 0
	var bam: = bool(_ach_bam.get(who, false))
	_ach_bam[who] = false


	var high: = false
	if kind == Player.TouchKind.SET and ball != null:
		var low: = who.grounded()\
		and ball.global_position.y - who.global_position.y < Player.FEEL.set_low_height
		high = not low
	_ach_touch[who] = {"kind": name, "foot": foot, "bam": bam, "quick": false, "high": high}
	if kind == Player.TouchKind.BLOCK:
		_ach_emit(who, "block", {})
	if kind == Player.TouchKind.BUMP and who.diving() and int(who.get("_dive_side")) != 0:
		_ach_roll = who

func _ach_point(winner_side: int, scorer: Player) -> void :
	if _net_role == NetRole.CLIENT:
		return

	if _ach_roll != null:
		if _ach_roll.team_side == winner_side:
			_ach_emit(_ach_roll, "roll_save", {})
		_ach_roll = null
	var helper: Player = null
	if scorer != null and _rally.get("_assist_spiker") == scorer:
		helper = _rally.get("_assist_helper")
	for p in _all_players:
		var body: Player = p
		if body.team_side != winner_side:
			continue
		var mine: = body == scorer
		var assist: = helper != null and body == helper
		if not mine and not assist:
			continue
		var t: Dictionary = _ach_touch.get(body, {})
		_ach_emit(body, "point", {
			"mine": mine, 
			"kind": String(t.get("kind", "")) if mine else "", 
			"quick": mine and bool(t.get("quick", false)), 
			"foot": mine and bool(t.get("foot", false)), 
			"bam": mine and bool(t.get("bam", false)), 
			"assist": assist, 
			"assist_high": assist and bool(t.get("high", false)), 
		})
	_ach_touch.clear()
	_ach_bam.clear()

func _ach_set_end(won: bool) -> void :
	var target: = GameConfig.set_points
	var deuce: bool = GameConfig.win_by_two\
	and mini(int(_scores[1]), int(_scores[-1])) >= target - 1
	Achievements.notify("set_end", {"won": won, "deuce": deuce})

func _on_float_shown(text: String, color: Color, priority: bool, who: Player) -> void :
	_net_event("float", {"id": _net_ids.get(who, 0), "t": text, 
		"c": color.to_html(), "pr": priority})


	_recorder.cue("float", {"s": _all_players.find(who), "t": text, 
		"c": color.to_html(), "pr": priority})

func _present_thump(pos: Vector3, strength: float) -> void :
	var at: = Vector3(pos.x, 0.08, pos.z)
	sfx.play("hit_soft", at, -2.0, 0.55)
	_contact_fx(at, strength, Vector3.UP)
	fx.puff(at)

func _on_predicted_thumped(pos: Vector3, strength: float) -> void :



	_pred_thumps.append({"t": Time.get_ticks_msec()})
	_present_thump(pos, strength)

func _on_thumped(pos: Vector3, strength: float, who: Player) -> void :



	var at: = Vector3(pos.x, 0.08, pos.z)
	_present_thump(at, strength)
	crowd.cheer(0.25 * strength)


	_net_event("thump", {"p": at, "s": strength, 
		"id": int(_net_ids.get(who, 0))})

func _on_launched(pos: Vector3, charge: float, _who: Player) -> void :


	if charge >= 1.5 and _who != null:
		_ach_bam[_who] = true



	var at: = Vector3(pos.x, 0.06, pos.z)
	fx.ring(at, Vector3.UP, 1.15 * charge)
	fx.puff(at)
	sfx.play("hit_soft", at, -4.0, 1.35)
	_net_event("launch", {"p": at, "c": charge})

func _on_combo_shown(count: int, fail: bool, who: Player) -> void :



	var home: = _team_identity(who.team_side) == 1
	_combo_sfx(count, fail, who.global_position, home)


	_net_event("combo", {"id": _net_ids.get(who, 0), "n": count, "f": fail, "h": home})
	_recorder.cue("combo", {"s": _all_players.find(who), "n": count, "f": fail})




const COMBO_DB: = -13.0
func _combo_sfx(count: int, fail: bool, pos: Vector3, home: bool) -> void :
	var bank: = "combo_fail" if fail\
	else "combo_%s_%d" % ["home" if home else "away", clampi(count, 1, 3)]


	sfx.play(bank, pos, COMBO_DB, 1.0, false, true)

func _on_block_broken(pos: Vector3, who: Player) -> void :


	fx.shield_crack(pos)
	sfx.play("block_hard", pos, 2.0, 0.85)
	who.show_float_text("block broken!", BREAK_COLOR, true)
	crowd.shock(0.95)
	_net_event("blockbreak", {"p": pos, "id": _net_ids.get(who, 0)})

func _on_voiced(bank: String, pitch: float, who: Player) -> void :


	sfx.play(bank, who.global_position + Vector3(0.0, 1.4, 0.0), -3.0, pitch)
	_net_event("voice", {"b": bank, "p": pitch, 
		"id": _net_ids.get(who, 0)})

func _on_callout_made(idx: int, who: Player) -> void :

	_net_event("callout", {"id": _net_ids.get(who, 0), "i": idx})
	_recorder.cue("callout", {"s": _all_players.find(who), "i": idx})

func _on_up_event(peer_id: int, kind: String, args: Dictionary) -> void :


	if kind == "skip_vote":
		_register_skip_vote(peer_id)
		return
	if kind == "pa":

		_pa_opt[peer_id] = true
		_pa_push_states()
		return
	if kind == "seat":


		request_seat(peer_id, clampi(Net.ev_i(args, "s"), -1, 1))
		return
	if kind == "toss":





		if _phase == Phase.SERVE_PREP and _rally.server != null\
		and not _rally.serve_done and ball.frozen\
		and _peer_players.get(peer_id) == _rally.server\
		and _rally.in_serve_zone(_rally.server, 0.8):


			_rally.request_toss(clampf(Net.ev_f(args, "u", 7.5), 6.5, 12.0))
		return
	if kind == "touch_try":
		if not _lag_touch:
			return




		var mine: = 0
		for r in _lag_touch_requests:
			if int(r.peer) == peer_id:
				mine += 1
		if mine >= 4:
			return
		_lag_touch_requests.append({"peer": peer_id, 
			"seq": Net.ev_i(args, "s"), "view": Net.ev_f(args, "v", -1.0), 
			"delay": Net.ev_f(args, "d", INTERP_DELAY_MIN), 
			"until": Time.get_ticks_msec() + 250})
		return
	if kind == "callout":
		var body: Player = _peer_players.get(peer_id)
		if body != null:
			body.show_callout(Net.ev_i(args, "i"))

func _poll_callouts() -> void :
	if hud.chat_typing():
		return
	if hud.pause_is_open():
		return






	if player == null or _phase == Phase.REPLAY or _spectating:
		return
	var idx: = -1
	for i in 4:
		if Input.is_action_just_pressed("callout_%d" % (i + 1)):
			idx = i
			break
	if idx < 0:
		return
	if _net_role == NetRole.CLIENT:
		player.show_callout(idx, false)
		Net.send_up("callout", {"i": idx})
	else:
		player.show_callout(idx)

func _on_local_touch_attempted() -> void :
	if not _lag_touch or _net_role != NetRole.CLIENT\
	or _spectating or _render_host_ms < 0.0:
		return






	Net.send_up("touch_try", {"s": _in_chan.seq, "v": _render_host_ms, 
		"d": maxf(_delay_now - _ball_present_lead_ms, 0.0)})

func _record_lag_history() -> void :
	if not _lag_touch or _net_role != NetRole.HOST or not _rally.live:
		return
	var bodies: = {}
	for body in _all_players:
		var member: Player = body
		bodies[int(_net_ids.get(member, 0))] = member.global_position
	_lag_history.append({"t": float(_net_tick) * 1000.0 / 60.0, 
		"p": ball.global_position, "v": ball.vel, "c": ball.curve, 
		"b": bodies})
	var cutoff: = float(_net_tick) * 1000.0 / 60.0 - LAG_TOUCH_HISTORY_MS
	while not _lag_history.is_empty() and float(_lag_history[0].t) < cutoff:
		_lag_history.pop_front()

func _lag_sample(peer_id: int, client_delay: float) -> Dictionary:
	if _lag_history.is_empty():
		return {}
	var now_ms: = float(_net_tick) * 1000.0 / 60.0










	var buf: = clampf(client_delay, 0.0, INTERP_DELAY_MAX + 20.0)
	var expected_age: = Net.peer_rtt_ms(peer_id) * 0.5 + buf
	var target: = clampf(now_ms - expected_age, now_ms - LAG_TOUCH_HISTORY_MS, now_ms)



	var lo: Dictionary = _lag_history[0]
	var hi: Dictionary = _lag_history[_lag_history.size() - 1]
	for s in _lag_history:
		if float(s.t) <= target:
			lo = s
		if float(s.t) > target:
			hi = s
			break
	var pos: Vector3 = lo.p
	var span: = float(hi.t) - float(lo.t)
	if span > 1.0:
		var a: = clampf((target - float(lo.t)) / span, 0.0, 1.0)
		pos = (lo.p as Vector3).lerp(hi.p as Vector3, a)
	return {"p": pos, "t": target}






var _lag_reject: = {"expired": 0, "dead": 0, "reach": 0, "kind": 0, "ok": 0}

func _process_lag_touch_requests() -> void :
	if _net_role != NetRole.HOST or _lag_touch_requests.is_empty():
		return
	var keep: Array = []
	for request in _lag_touch_requests:
		var peer_id: = int(request.peer)
		if Time.get_ticks_msec() > int(request.until):
			_lag_reject.expired += 1
			continue
		if int(_peer_applied.get(peer_id, 0)) < int(request.seq):
			keep.append(request)
			continue
		var body: Player = _peer_players.get(peer_id)
		var sample: = _lag_sample(peer_id, float(request.get("delay", INTERP_DELAY_MIN)))
		var input_history: Dictionary = _peer_touch_inputs.get(peer_id, {})
		var touch_state: Dictionary = input_history.get(int(request.seq), {})
		if body == null or sample.is_empty() or not _rally.live\
		or touch_state.is_empty() or body.touch_barred\
		or body._touch_lock > 0.0:
			_lag_reject.dead += 1
			continue
		var historic_ball: Vector3 = sample.p
		var applied_input: PlayerInput = touch_state.input



		var current_aim: = body.aim_point
		body.aim_point = applied_input.aim
		if not body.ball_position_in_reach(historic_ball):
			body.aim_point = current_aim
			_lag_reject.reach += 1
			continue
		var kind: = body.resolved_touch_at(historic_ball)
		if kind == Player.TouchKind.NONE or kind == Player.TouchKind.BLOCK:
			body.aim_point = current_aim
			_lag_reject.kind += 1
			continue
		_lag_reject.ok += 1
		for member in _all_players:
			(member as Player).contact_enabled = true
		var influence: Vector2 = body._air_influence(applied_input)
		var quick: = kind == Player.TouchKind.SET and body.quick_check.is_valid()\
		and bool(body.quick_check.call(body.aim_point, body))
		body._do_touch(kind, float(touch_state.power), bool(touch_state.finesse), 
			influence, quick)
		body.aim_point = current_aim
	_lag_touch_requests = keep



func _client_tick(delta: float) -> void :



	if int(_np.get("ph", Phase.DEAD)) == Phase.REPLAY:
		if _replay_stand_off:
			return
		if _phase != Phase.REPLAY\
		and Time.get_ticks_msec() - _rec_started_ms\
		< int((REPLAY_LEAD + REPLAY_TAIL + 1.0) * 1000.0):




			_replay_stand_off = true
			hud.set_replay_banner(true, 0, _skips_needed())
			return
		if _phase != Phase.REPLAY:
			_phase = Phase.REPLAY
			_setup_director()
			_voted_skip = false
			_input_collector.clear_buffers()





			_begin_dissolve(0.0, REPLAY_CUT)
			hud.set_replay_banner(true, 0, _skips_needed())
		_replay_client_tick(delta)
		return
	if _replay_stand_off:

		_replay_stand_off = false
		hud.set_replay_banner(false, 0, 0)
		_interp_hard = true
		_snap_buf.clear()
	if _phase == Phase.REPLAY:
		_phase = Phase.DEAD
		hud.set_replay_banner(false, 0, 0)
		_replay_lead = 0.0





		_input_collector.swallow_held(["jump", "contact", "dive", "serve"])
		_input_collector.clear_buffers()
		_begin_dissolve(REPLAY_OUT_HOLD, REPLAY_OUT_FADE)



		camera_rig.cinematic = false
		camera_rig.cine_snap = false
		ball.net_puppet = _ball_puppet_saved
		ball.show_landing_ring = true
		_interp_hard = true
		_snap_buf.clear()



		_reset_formation()
		for i in _all_players.size():
			var body: Player = _all_players[i]


			body.net_puppet = not _is_own_body(body)
			body.cinematic_hidden = false
			body.suppress_names(false)
			body.hide_callout()
			body.reset_physics_interpolation()
		_puppet_saved.clear()










	var input_phase: = int(_np.get("ph", Phase.DEAD))
	var input_server: Player = _by_net_id.get(int(_np.get("sv", 0)))
	player.serve_charge_ui = input_phase == Phase.SERVE_PREP\
	and input_server == player and not _spectating


	ball.serve_held = input_phase == Phase.SERVE_PREP and ball.frozen
	player.contact_enabled = input_phase == Phase.LIVE\
	or (input_phase == Phase.SERVE_PREP and input_server == player)
	var input: = PlayerInput.new()
	if not _spectating:
		input = _gate_cinematics(_input_collector.collect(camera_rig, player))
		if hud.chat_typing() or hud.pause_is_open():




			input = PlayerInput.new()
		_send_client_input(input)
		player.simulate(input, delta)



		_pred.hard_snap = HARD_SNAP_DIST
		_pred.tick(player, _in_chan.seq, delta)





	if _velsync_on() and not _spectating and player.touch_seq != _pred_touch_seen:
		_pred_touch_seen = player.touch_seq
		if not ball.frozen:
			_ball_grace = Net.peer_rtt_ms(1) * 0.001 + 0.25
			_ball_grace_seq = _ball_host_strikes
			_pred_strike_mutes += 1
	if _ball_grace > 0.0:
		_ball_grace = maxf(_ball_grace - delta, 0.0)
		if _ball_grace <= 0.0:
			_pred_strike_mutes = 0







	_toss_pred = maxf(_toss_pred - delta, 0.0)
	if _np.has("b"):
		var _b_arr: PackedFloat32Array = _np.b
		if _b_arr.size() > 6:
			var host_frozen: = _b_arr[6] > 0.5








			if _toss_visual_state.is_empty() or _toss_pred <= 0.0:
				ball.frozen = host_frozen
	if _toss_pred <= 0.0 and not _toss_visual_state.is_empty():
		_toss_visual_state.clear()
		_toss_unfrozen_snaps = 0



		_ball_handoff = maxf(_ball_handoff, 0.12)



	var velsync: = _velsync_on() and not ball.frozen
	ball.net_puppet = not ball.frozen and not velsync
	if ball.frozen:

		_ball_dead = false
		var holder: Player = _by_net_id.get(int(_np.get("sv", 0)))
		if holder != null:
			ball.global_position = holder.serve_cradle_point()
			ball.vel = Vector3.ZERO






		if not _spectating and holder == player\
		and (input.serve_pressed or input.contact_released)\
		and _rally.in_serve_zone(player):
			var up: = 7.5 if input.serve_pressed\
			else lerpf(6.5, 12.0, player.hold_power())
			ball.frozen = false
			ball.serve_assist = true
			ball.toss(player.serve_cradle_point(), up)
			player.present_serve_toss(true)





			Net.send_up("toss", {"u": up})
			if not _velsync_on():
				ball.net_puppet = true
				_toss_visual_state = [ball.global_position, ball.vel, ball.curve]
				_toss_unfrozen_snaps = 0





			_toss_pred = Net.peer_rtt_ms(1) * 0.001 + 1.1
	elif not velsync and not (_ball_interp and ball.net_puppet):





		var e: = _ball_err.length()
		if e > BALL_LEASH_DEAD:
			var rate: = lerpf(BALL_LEASH_MIN, BALL_LEASH_MAX, 
				clampf((e - BALL_LEASH_DEAD) / BALL_LEASH_FULL, 0.0, 1.0))
			var excess: = _ball_err * ((e - BALL_LEASH_DEAD) / e)
			var bfix: = excess * minf(1.0, delta * rate)
			ball.global_position += bfix
			_ball_err -= bfix
	if not _toss_visual_state.is_empty():


		_toss_visual_state = Ball.step_flight(_toss_visual_state[0], 
			_toss_visual_state[1], _toss_visual_state[2], delta, 
			ball.net_half_width, ball.court_center_x, ball.wall_min, ball.wall_max)
		ball.global_position = _toss_visual_state[0]
		ball.vel = _toss_visual_state[1]
		ball.curve = _toss_visual_state[2]
	_client_interp()
	for p in _all_players:
		var member: Player = p
		if not _is_own_body(member):
			member.puppet_tick(delta)
	var _ph_now: int = _np.get("ph", Phase.DEAD)
	_rally_live = _ph_now == Phase.LIVE







	if _ph_now == Phase.SERVE_PREP:
		_ball_dead = false
		if player != null:
			player.contact_enabled = true




		if not _client_in_serve_prep:
			_client_in_serve_prep = true





			if player != null:
				player.dive_cooldown = 0.0
			if _sand_deform != null:
				_sand_deform.reset()
	else:
		_client_in_serve_prep = false
	_rally_time = _np.get("rt", 0.0)
	_motion_foley(delta)
	_decay_net_wobble(delta)
	_update_indicators_client(input)
	_net_tick += 1
	_net_info_tick()
	_dbg_ball_report(delta)
	if _net_shot and _net_tick % 240 == 120 and _shot_count < 6:
		_shot_count += 1
		var img: = get_viewport().get_texture().get_image()
		img.save_png("res://game/dev/shots/net_%d.png" % _shot_count)

func _send_client_input(input: PlayerInput) -> void :
	Net.send_input(_in_chan.encode(input))

func _velsync_on() -> bool:
	return _velsync












func _dbg_ball_report(delta: float) -> void :
	if not _net_log:
		return
	_dbg_since += delta
	if _dbg_since < 1.0:
		return
	print("[ball] err avg=%.3f max=%.3f n=%d | pred avg=%.3f max=%.3f n=%d | stale=%d grace=%d unfair=%d rejected=%d present=%.0fms" % [
		_dbg_ball_err_sum / maxf(_dbg_ball_err_n, 1), _dbg_ball_err_max, _dbg_ball_err_n, 
		_dbg_pred_err_sum / maxf(_dbg_pred_err_n, 1), _dbg_pred_err_max, _dbg_pred_err_n, 
		_dbg_stale_drops, _dbg_grace_skips, _dbg_unfair_floor, _dbg_rejected_touch, 
		_ball_present_lead_ms])
	_dbg_ball_err_sum = 0.0
	_dbg_ball_err_max = 0.0
	_dbg_ball_err_n = 0
	_dbg_pred_err_sum = 0.0
	_dbg_pred_err_max = 0.0
	_dbg_pred_err_n = 0
	_dbg_stale_drops = 0
	_dbg_grace_skips = 0
	_dbg_unfair_floor = 0
	_dbg_rejected_touch = 0
	_dbg_since = 0.0









func _on_ball_snapshot(b: PackedFloat32Array) -> void :
	if _net_role != NetRole.CLIENT or b.size() < 9 or not _velsync_on():
		return
	if ball.frozen or not ball.is_inside_tree():
		return
	if int(_np.get("ph", Phase.DEAD)) == Phase.REPLAY:
		return





	var n: = float(b[8])
	if n < _ball_host_strikes:
		if _net_log:
			_dbg_stale_drops += 1
		return
	_ball_host_strikes = n




	if _ball_grace > 0.0:
		if _ball_host_strikes > _ball_grace_seq:
			_ball_grace = 0.0
		else:
			if _net_log:
				_dbg_grace_skips += 1
			return
	if _net_log:


		var e: = ball.global_position.distance_to(Vector3(b[0], b[1], b[2]))
		_dbg_ball_err_sum += e
		_dbg_ball_err_max = maxf(_dbg_ball_err_max, e)
		_dbg_ball_err_n += 1
	ball.vel = ball.vel.lerp(Vector3(b[3], b[4], b[5]), VELSYNC_VEL_WEIGHT)
	ball.global_position = ball.global_position.lerp(
		Vector3(b[0], b[1], b[2]), VELSYNC_POS_WEIGHT)
	ball.curve = b[7]

func _on_snapshot(data: Dictionary) -> void :
	_snap_count += 1
	_np = data
	if int(data.get("ph", Phase.DEAD)) == Phase.REPLAY:










		_last_snap_at = Time.get_ticks_msec()
		return




	var now: = Time.get_ticks_msec()
	var seq: = int(data.get("sq", -1))
	if seq >= 0:



		if seq <= _snap_newest:
			return
		_snap_newest = seq



		var off: = float(now) - float(seq) * SNAP_MS











		var stalled: = get_process_delta_time() > 0.1 and _clock_offset != INF
		if not stalled:
			_off_win_min = minf(_off_win_min, off)
			_off_win_n += 1
			if _clock_offset_min == INF:
				_clock_offset_min = off
			elif _off_win_n >= CLOCK_WINDOW_SNAPS:
				_clock_offset_min = _off_win_min
				_off_win_min = INF
				_off_win_n = 0
			else:
				_clock_offset_min = minf(off, _clock_offset_min + CLOCK_RELAX_MS)






			_clock_warm += 1
			if _clock_warm <= CLOCK_WARMUP_SNAPS:
				_clock_offset = _clock_offset_min
		if _clock_offset == INF:
			_clock_offset = _clock_offset_min
			_delay_now = interp_delay()
	if _last_snap_at != 0:

		var gap: = float(now - _last_snap_at)
		_snap_jitter = lerpf(_snap_jitter, absf(gap - _snap_gap), 0.15)
		_snap_gap = lerpf(_snap_gap, gap, 0.15)
		_snap_gap_max = maxf(gap, _snap_gap_max * INTERP_GAP_DECAY)
	_last_snap_at = now
	_snap_buf.append({"at": now, "hm": float(seq) * SNAP_MS, "d": data})
	if not _toss_visual_state.is_empty() and data.b.size() > 6\
	and data.b[6] < 0.5:
		_toss_unfrozen_snaps += 1
	while _snap_buf.size() > 40:
		_snap_buf.pop_front()


	_reconcile_local(data)







func _adopt_strike_flight(args: Dictionary, remote: = false) -> void :
	if _net_role != NetRole.CLIENT:
		return

	if not (args.get("bv") is Vector3 and args.get("bp") is Vector3):
		return
	if not ((args.bv as Vector3).is_finite() and (args.bp as Vector3).is_finite()):
		return
	if not ball.is_inside_tree():
		return

	if ball.frozen:
		return
	var n: = Net.ev_f(args, "n", -1.0)



	if n >= 0.0 and _ball_host_strikes >= n:
		return
	if n >= 0.0:



		_ball_host_strikes = n
		ball.strike_seq = int(n)




		if not _toss_visual_state.is_empty():
			_toss_visual_state.clear()
			_toss_unfrozen_snaps = 0
			_toss_pred = 0.0
			_ball_handoff = maxf(_ball_handoff, 0.2)

	var fs: = Net.ev_i(args, "fs", 0)
	if fs != 0:
		ball.start_float(fs)
	else:
		ball.stop_float()





	if ball.net_puppet:
		if args.has("ht"):
			_ball_event_flight = {
				"hm": Net.ev_f(args, "ht"), 
				"p": args.bp, 
				"v": args.bv, 
				"c": Net.ev_f(args, "c", 0.0), 
				"n": n, 
			}
		return


	var age: = Net.peer_rtt_ms(1) * 0.0005
	var _st: = _ball_exact(args.bp, args.bv, Net.ev_f(args, "c", 0.0), age)
	var pos: Vector3 = _st[0]
	var vel: Vector3 = _st[1]
	ball.curve = _st[2]
	var jump: = pos - ball.global_position





	ball.vel = vel
	ball.curve = _st[2]
	if jump.length() > BALL_DESYNC_SNAP:
		ball.global_position = pos
		ball.reset_physics_interpolation()
		_ball_err = Vector3.ZERO
	elif remote:





		if _velsync_on():
			ball.global_position = ball.global_position.lerp(pos, 0.5)
		else:
			_ball_err = jump





func _adopt_bounce_flight(args: Dictionary) -> void :
	if _net_role != NetRole.CLIENT or not args.has("p")\
	or not ball.is_inside_tree():
		return
	ball.global_position = Net.ev_v3(args, "p")
	ball.vel = Net.ev_v3(args, "bv")
	ball.curve = 0.0
	ball.reset_physics_interpolation()
	ball.trail.restart()
	_ball_err = Vector3.ZERO
	_ball_event_flight.clear()

func _tick_dead_ball_visual(delta: float) -> void :
	if not _ball_dead or ball.frozen or not ball.is_inside_tree():
		return
	var state: = Ball.step_flight(ball.global_position, ball.vel, ball.curve, delta, 
		ball.net_half_width, ball.court_center_x, ball.wall_min, ball.wall_max)
	ball.global_position = state[0]
	ball.vel = state[1]
	ball.curve = state[2]





func _ball_exact(pos: Vector3, vel: Vector3, curve: float, age: float) -> Array:
	var dt: = get_physics_process_delta_time()
	if dt <= 0.0 or age <= 0.0:
		return [pos, vel, curve]
	if _ball_ballistic:
		return [pos + vel * age + Vector3(0.0, -0.5 * Ball.PHYS.gravity * age * age, 0.0), 
			vel - Vector3(0.0, Ball.PHYS.gravity * age, 0.0), curve]
	var st: Array = [pos, vel, curve]
	var whole_ticks: = int(floor(age / dt))
	for _i in whole_ticks:
		st = Ball.step_flight(st[0], st[1], st[2], dt, 
			ball.net_half_width, ball.court_center_x, ball.wall_min, ball.wall_max)




	var remainder: = age - float(whole_ticks) * dt
	if remainder > 0.0001:
		st = Ball.step_flight(st[0], st[1], st[2], remainder, 
			ball.net_half_width, ball.court_center_x, ball.wall_min, ball.wall_max)
	return st







func _measure_ball_model(data: Dictionary, age: float, corr: float) -> void :
	var b: PackedFloat32Array = data.b
	var seq: = int(data.get("sq", -1))
	if seq < 0 or b.size() < 9:
		return
	var cur: = Vector3(b[0], b[1], b[2])
	if not _bm_prev.is_empty():
		var pb: PackedFloat32Array = _bm_prev.b
		var pseq: = int(_bm_prev.seq)
		if seq > pseq and b[8] == pb[8] and b[6] < 0.5 and pb[6] < 0.5:
			var dt: = get_physics_process_delta_time()
			var ticks: = (seq - pseq) * SNAPSHOT_EVERY
			var t: = float(ticks) * dt
			var st: Array = [Vector3(pb[0], pb[1], pb[2]), 
				Vector3(pb[3], pb[4], pb[5]), pb[7]]
			for _i in ticks:
				st = Ball.step_flight(st[0], st[1], st[2], dt, 
					ball.net_half_width, ball.court_center_x, 
					ball.wall_min, ball.wall_max)
			var model_exact: float = (st[0] as Vector3).distance_to(cur)
			var bpos: = Vector3(pb[0], pb[1], pb[2])\
			+ Vector3(pb[3], pb[4], pb[5]) * t\
			+ Vector3(0.0, -0.5 * Ball.PHYS.gravity * t * t, 0.0)
			var model_ballistic: = bpos.distance_to(cur)
	_bm_prev = {"seq": seq, "b": b}



func _reckon_ball(st: PackedFloat32Array, dt: float) -> Vector3:
	var p: = Vector3(st[0], st[1], st[2])
	if st[6] > 0.5:
		return p
	var v: = Vector3(st[3], st[4], st[5])
	return p + v * dt + Vector3(0.0, -0.5 * Ball.PHYS.gravity * dt * dt, 0.0)








func _interp_ball(render_at: float) -> void :
	if _snap_buf.size() == 0 or not ball.is_inside_tree() or _ball_dead:
		return




	_ball_present_lead_ms = minf(_delay_now, BALL_PRESENT_MAX_MS)\
	if _ball_present else 0.0
	var ball_at: = render_at + _ball_present_lead_ms
	var a: Dictionary = _snap_buf[0]
	var b: Dictionary = _snap_buf[_snap_buf.size() - 1]
	for i in _snap_buf.size():
		if float(_snap_buf[i].hm) <= ball_at:
			a = _snap_buf[i]
			b = _snap_buf[mini(i + 1, _snap_buf.size() - 1)]
	var ba: PackedFloat32Array = a.d.b
	var bb: PackedFloat32Array = b.d.b
	if bb.size() < 9:
		return
	var target: Vector3
	var target_vel: = Vector3(bb[3], bb[4], bb[5])
	var target_curve: = float(bb[7])
	var span: = float(b.hm) - float(a.hm)
	if span > 1.0:
		var alpha: = clampf((ball_at - float(a.hm)) / span, 0.0, 1.0)
		var ta: = (ball_at - float(a.hm)) / 1000.0
		var tb: = (ball_at - float(b.hm)) / 1000.0
		target = _reckon_ball(ba, ta).lerp(_reckon_ball(bb, tb), alpha)
		var va: = Vector3(ba[3], ba[4], ba[5])\
		- Vector3(0.0, Ball.PHYS.gravity * ta, 0.0)
		var vb: = Vector3(bb[3], bb[4], bb[5])\
		- Vector3(0.0, Ball.PHYS.gravity * tb, 0.0)
		target_vel = va.lerp(vb, alpha)
		target_curve = lerpf(ba[7], bb[7], alpha)
	else:



		var age: = maxf((ball_at - float(b.hm)) / 1000.0, 0.0)
		var state: = _ball_exact(Vector3(bb[0], bb[1], bb[2]), 
			Vector3(bb[3], bb[4], bb[5]), bb[7], age)
		target = state[0]
		target_vel = state[1]
		target_curve = state[2]



	if not _ball_event_flight.is_empty():
		var event_n: = float(_ball_event_flight.n)






		if ba[8] >= event_n and ball_at >= float(a.hm):
			_ball_event_flight.clear()
		elif ball_at >= float(_ball_event_flight.hm):
			var event_age: = (ball_at - float(_ball_event_flight.hm)) / 1000.0
			var event_state: = _ball_exact(_ball_event_flight.p, 
				_ball_event_flight.v, float(_ball_event_flight.c), event_age)
			target = event_state[0]
			target_vel = event_state[1]
			target_curve = event_state[2]
	ball.vel = target_vel
	ball.curve = target_curve
	if ball.global_position.distance_to(target) > 3.0:

		ball.reset_physics_interpolation()
		ball.global_position = target
	elif _ball_handoff > 0.0:


		_ball_handoff = maxf(_ball_handoff - get_physics_process_delta_time(), 0.0)
		ball.global_position = ball.global_position.lerp(target, 
			minf(1.0, get_physics_process_delta_time() * 6.0))
	else:
		ball.global_position = target

func _reconcile_ball(data: Dictionary) -> void :
	if not ball.is_inside_tree():




		return




	var b: PackedFloat32Array = data.b








	if b.size() > 8:
		if b[8] < _ball_host_strikes:
			return
		_ball_host_strikes = b[8]
	var was_frozen: = ball.frozen
	ball.frozen = b[6] > 0.5
	if ball.frozen:
		ball.curve = b[7]
		return


	if _ball_grace > 0.0:
		if _ball_host_strikes != _ball_grace_seq:
			_ball_grace = 0.0
		else:
			return
	if _ball_interp:


		return
	var age: = Net.peer_rtt_ms(1) * 0.0005



	var _st: = _ball_exact(Vector3(b[0], b[1], b[2]), 
		Vector3(b[3], b[4], b[5]), b[7], age)
	var host_pos: Vector3 = _st[0]
	var host_vel: Vector3 = _st[1]
	var err: = host_pos - ball.global_position

	if _net_log and data.has("sq"):
		_measure_ball_model(data, age, err.length())







	if was_frozen or err.length() > BALL_DESYNC_SNAP:
		ball.global_position = host_pos
		ball.vel = host_vel
		ball.curve = _st[2]
		ball.reset_physics_interpolation()
		_ball_err = Vector3.ZERO
	else:
		_ball_err = err

func _reconcile_local(data: Dictionary) -> void :

	if _spectating:
		return
	var state: = _pstate(data.p, _all_players.find(player))
	if state.is_empty():
		return



	player.touch_barred = ((int(state[11]) >> 10) & 1) == 1
	player.touch_barred_self = ((int(state[11]) >> 14) & 1) == 1



	var ack: = int(data.ack.get(_local_pid(), 0))
	var host_pos: = Vector3(state[0], state[1], state[2])
	var err_v: Variant = _pred.measure(ack, host_pos)
	if err_v == null:
		return
	var err: Vector3 = err_v
	var host_knocked: bool = state[13] > 0.0
	if err.length() > HARD_SNAP_DIST or (host_knocked and not player.knocked()):

		player.net_force_state(state)
		_pred.reset()
	else:
		_pred.commit(err, ack)




func interp_delay() -> float:
	return clampf(_snap_gap_max * INTERP_GAP_MULT + INTERP_GAP_MARGIN, 
		INTERP_DELAY_MIN, INTERP_DELAY_MAX)

func _client_interp() -> void :


	var dt: = get_physics_process_delta_time()
	_tick_dead_ball_visual(dt)
	if _snap_buf.size() == 0:
		return



	if _clock_offset == INF:
		return






	var clock_err: = absf(_clock_offset - _clock_offset_min)
	var slew: = CLOCK_SLEW if clock_err < 40.0\
	else lerpf(CLOCK_SLEW, CLOCK_SLEW_FAST, clampf(clock_err / 300.0, 0.0, 1.0))
	_clock_offset = move_toward(_clock_offset, _clock_offset_min, slew * dt)
	_delay_now = move_toward(_delay_now, interp_delay(), DELAY_SLEW * dt)
	var render_at: = float(Time.get_ticks_msec()) - _clock_offset - _delay_now
	_render_host_ms = render_at



	NetSync.interp_world(_snap_buf, render_at, _all_players, PSTATE_FLOATS, 
		func(body: Player) -> bool: return _is_own_body(body), 
		EXTRAPOLATE_MAX, _interp_hard)


	if _ball_interp and ball.net_puppet and _toss_visual_state.is_empty():
		_interp_ball(render_at)
	if _interp_hard:
		ball.reset_physics_interpolation()
		player.reset_physics_interpolation()
	_interp_hard = false

func _on_net_event(kind: String, args: Dictionary) -> void :
	match kind:
		"strike":








			_music_heat_touch(Net.ev_i(args, "k", Player.TouchKind.NONE), 
				Net.ev_f(args, "w", 0.0), Net.ev_b(args, "sv", false))
			var own_confirmed: = Net.ev_i(args, "id", -1)\
			== int(_net_ids.get(player, -2))
			var accepted_body: Player = _by_net_id.get(Net.ev_i(args, "id", 0))
			if accepted_body != null:
				accepted_body.present_authoritative_touch(
					Net.ev_i(args, "k", Player.TouchKind.NONE) as Player.TouchKind, 
					Net.ev_f(args, "hs", 0.0))




			if ball != null and ball.net_puppet:
				ball.hitstop_left = maxf(ball.hitstop_left, Net.ev_f(args, "hs", 0.0))


			if own_confirmed\
			and Net.ev_i(args, "k", -1) == Player.TouchKind.SPIKE\
			and Net.ev_f(args, "hs", 0.0) > 0.0:
				camera_rig.shake(minf(0.12 + Net.ev_f(args, "hs", 0.0) * 2.0, 0.4))
			if own_confirmed and ball.net_puppet:



				player.touch_seq += 1
			elif not own_confirmed and reach_marker != null:



				reach_marker.authoritative_touch(false)
			if own_confirmed and _pred_strike_mutes > 0:



				_pred_strike_mutes -= 1
				_adopt_strike_flight(args, false)
			else:


				ball.combo_tier = Net.ev_i(args, "cb", 0)


				_on_ball_struck(Net.ev_v3(args, "p"), Net.ev_f(args, "w"), 
					Net.ev_i(args, "k"), Net.ev_v3(args, "bv"))
				ball.pulse()
				_adopt_strike_flight(args, not own_confirmed)
		"bounce":
			if _ball_dead:
				return




			var marker_was_lit: = reach_marker != null\
			and (reach_marker.state() == ReachMarker.State.READY\
			or reach_marker.state() == ReachMarker.State.QUEUED)
			if _net_log and reach_marker != null\
			and reach_marker.state() == ReachMarker.State.READY:




				_dbg_unfair_floor += 1




			if marker_was_lit:
				reach_marker.authoritative_touch(false)



			if _net_log and _ball_grace > 0.0:
				_dbg_rejected_touch += 1
			_ball_dead = true
			_ball_grace = 0.0
			_pred_strike_mutes = 0
			if player != null:
				player.contact_enabled = false
				player.cancel_contact()
			_adopt_bounce_flight(args)

			var impact: = Net.ev_f(args, "is", 
				Net.ev_v3(args, "bv").length() / maxf(Ball.PHYS.floor_bounce, 0.1))
			ball.floor_squash(impact)
			_bounce_fx(Net.ev_v3(args, "p"), impact)
		"toss":
			var tossing_body: Player = _by_net_id.get(Net.ev_i(args, "id", 0))
			if tossing_body != null:
				tossing_body.present_serve_toss()
		"servestrike":


			if Net.ev_b(args, "j", false):
				crowd.serve_hit()
			else:
				crowd.serve_stop()
		"net":
			_net_hit_fx(Net.ev_f(args, "x"), Net.ev_f(args, "s", 1.0), 
				Net.ev_f(args, "y", 0.5))
		"whistle":
			sfx.play("whistle", Net.ev_v3(args, "p"))
		"verdict":
			_show_verdict(Net.ev_v3(args, "p"), Net.ev_s(args, "t", "", 64), 
				Net.ev_i(args, "w", 0))
		"callout":
			var caller: Player = _by_net_id.get(Net.ev_i(args, "id", 0))
			if caller != null:
				caller.show_callout(Net.ev_i(args, "i", 0), false)
				_recorder.cue("callout", 
					{"s": _all_players.find(caller), "i": Net.ev_i(args, "i", 0)})
		"pa_state":
			var marks: = {}
			for pair in Net.ev_arr(args, "l", 32):
				if pair is Array and (pair as Array).size() == 2:
					marks[pair[0]] = pair[1]
			hud.set_pa_marks(marks)
		"rally_end":



			_ball_dead = true
			_ball_grace = 0.0
			_pred_strike_mutes = 0


			crowd.serve_stop()
			if player != null:
				player.contact_enabled = false
				player.cancel_contact()
			_present_rally_end(args)
		"ach":

			if player != null and not _spectating\
			and Net.ev_i(args, "id") == int(_net_ids.get(player, -1)):
				var d: Variant = args.get("d", {})
				Achievements.notify(Net.ev_s(args, "e", "", 32), 
					d if d is Dictionary else {})
		"set_end":
			_present_set_end(Net.ev_i(args, "w"))



			_scores = {1: 0, -1: 0}
		"over":
			_present_match_over(Net.ev_i(args, "w"))
		"rematch":





			_stats_built = false
			_match_over = false
			_match_winner = 0
			_scores = {1: 0, -1: 0}
			_set_wins = {1: 0, -1: 0}
			_set_number = 1
			Rules.set_swapped = false
			_pending_set = {}
			_music_heat = 0
			MusicManager.set_floor(0)
			MusicManager.set_intensity(0)
			hud.hide_match_stats()
			hud.hide_cine_name()
			hud.set_loading(1.0)
		"replay_go":
			_replay_focus = Net.ev_v3(args, "f")
			_replay_lead = Net.ev_f(args, "ld")
			if _phase == Phase.REPLAY:
				_setup_director()
		"blockbreak":
			fx.shield_crack(Net.ev_v3(args, "p"))
			crowd.shock(0.95)
			var bb: Player = _by_net_id.get(Net.ev_i(args, "id", 0))
			if bb != null:
				bb.show_float_text("block broken!", BREAK_COLOR, true)
		"voice":
			var vb: Player = _by_net_id.get(Net.ev_i(args, "id", 0))
			if vb != null:
				sfx.play(Net.ev_s(args, "b", "", 32), 
					vb.global_position + Vector3(0.0, 1.4, 0.0), -3.0, 
					clampf(Net.ev_f(args, "p", 1.0), 0.5, 2.0))
		"skip_tally":
			hud.set_replay_banner(true, Net.ev_i(args, "n", 0), 
				Net.ev_i(args, "k", 1))
		"skip_done":
			hud.set_replay_banner(false, 0, 0)
		"to_lobby":
			if Net.i_am_fold():




				Net.leave()

				GameConfig.lobby_notice = "the host left the match"
				hud.hide_match_stats()
				UiWipe.wipe(get_tree(), func():
					GameConfig.goto_scene("res://game/ui/menu.tscn"))
			else:
				_leave_to_lobby()
		"serve":
			landing_marker.visible = false
			_interp_hard = true
			_snap_buf.clear()
			crowd.serve_build()
		"reset":
			_interp_hard = true
			_snap_buf.clear()
			var rr: Array = args.get("r", [])
			if rr.size() == 2:
				_rot = {1: int(rr[0]), -1: int(rr[1])}
		"wipe":





			_play_wipe( func():
				if MIGRATION_COVER.dismiss():
					_loading_up = false
					hud.set_loading(0.0)
					hud.flash_banner("rally restarted"), 
				Net.ev_s(args, "v", "", 24))
		"sides":



			_begin_dissolve(SWAP_HOLD, SWAP_FADE)
			for pair in Net.ev_arr(args, "l", 32):
				if not (pair is Array) or (pair as Array).size() != 2:
					continue
				var body: Player = _by_net_id.get(Net.ni(pair[0]))
				if body != null:



					body.team_side = clampi(Net.ni(pair[1]), -1, 1)
			camera_rig.home_side = float(player.team_side)
			camera_rig.face_net()
			ball.home_side = float(player.team_side)
			_interp_hard = true
			_snap_buf.clear()



			_flush_motion_state()
		"arrive":
			hud.notice("%s joined as a spectator" % Net.ev_s(args, "who", "someone", 64))
		"seat":
			_on_seat_event(args)
			if args.has("who"):
				_announce_seat(Net.ev_s(args, "who", "", 64), 
					Net.ev_i(args, "side", 0), null)
		"float":
			var body: Player = _by_net_id.get(Net.ev_i(args, "id"))
			var ftext: = Net.ev_s(args, "t", "", 48)
			var fcol_s: = Net.ev_s(args, "c", "ffffff", 9)
			var fcol: = Color.html(fcol_s) if Color.html_is_valid(fcol_s) else Color.WHITE
			var fpr: = Net.ev_b(args, "pr")
			if body != null and body != player:
				body.show_float_text(ftext, fcol, fpr)
			elif body == player and fpr:

				body.show_float_text(ftext, fcol, fpr)
		"combo":
			var cbody: Player = _by_net_id.get(Net.ev_i(args, "id"))
			if cbody != null:
				var cfail: = Net.ev_b(args, "f")


				cbody.show_combo_local(Net.ev_i(args, "n"), cfail)
				_combo_sfx(Net.ev_i(args, "n"), cfail, cbody.global_position, Net.ev_b(args, "h"))






				_recorder.cue("combo", 
					{"s": _all_players.find(cbody), "n": Net.ev_i(args, "n"), "f": cfail})
		"thump":
			var own_thump: = Net.ev_i(args, "id", -1)\
			== int(_net_ids.get(player, -2))
			var now: = Time.get_ticks_msec()
			while not _pred_thumps.is_empty()\
			and now - int((_pred_thumps[0] as Dictionary).get("t", 0)) > 2000:
				_pred_thumps.pop_front()
			if own_thump and not _pred_thumps.is_empty():
				_pred_thumps.pop_front()
			else:
				_present_thump(Net.ev_v3(args, "p"), Net.ev_f(args, "s"))
		"launch":
			var lp: = Net.ev_v3(args, "p")
			fx.ring(lp, Vector3.UP, 1.15 * Net.ev_f(args, "c"))
			fx.puff(lp)
			sfx.play("hit_soft", lp, -4.0, 1.35)
		"bump_fx":
			var bp: = Net.ev_v3(args, "p")
			sfx.play("block_soft", bp, -4.0)
			fx.impact(bp, 0.7, Vector3.UP)
			fx.puff(bp)
		"cheer":
			crowd.cheer(Net.ev_f(args, "a", 0.5))
		"shock":
			crowd.shock(Net.ev_f(args, "a", 0.8))
		"slowmo":
			fx.slowmo(0.35, 0.8)
		"stats":
			hud.store_stat_rows(Net.ev_arr(args, "r", 32))
		"left":
			var body: Player = _by_net_id.get(Net.ev_i(args, "id"))
			var lname: = Net.sanitize_name(Net.ev_s(args, "n", "player", 64))
			if body != null:
				_names[body] = _cpu_tagged(lname)
				body.set_display_name(_names[body])
				body.set_dev_tag(DevBadge.Tier.NONE)
			hud.notice("%s has left the game" % lname)

func _present_rally_end(args: Dictionary) -> void :


	if not (args.get("w") is int and args.get("s1") is int and args.get("s2") is int):
		return
	var winner: = clampi(int(args.w), -1, 1)
	_scores[1] = clampi(int(args.s1), 0, 999)
	_scores[-1] = clampi(int(args.s2), 0, 999)


	hud.point_moment(winner, _team_identity(1), Net.ev_s(args, "r", "", 64), 
		int(_scores[1]), int(_scores[-1]))


	var ann: = Net.ev_s(args, "ann", "", 32)
	if ann != "":
		hud.announce_moment(ann, clampi(Net.ev_i(args, "as", 0), -1, 1))


	_music_rally_end(Net.ev_b(args, "rp", false))

func _present_set_end(winner_id: int) -> void :
	if player != null and not _spectating:
		_ach_set_end(winner_id == _team_identity(player.team_side))





func _present_match_over(winner_side: int) -> void :


	_match_winner = winner_side
	_match_over = true

func _leave_to_lobby() -> void :



	Net.end_match()
	UiWipe.wipe(get_tree(), func():
		GameConfig.goto_scene("res://game/ui/menu.tscn"))









func _park_ball() -> void :
	_pre_intro = true
	ball.frozen = true
	ball.vel = Vector3.ZERO
	ball.visible = false

func _start_intro() -> void :
	_phase = Phase.INTRO
	_cine_time = 0.0
	_grabbed_home = false
	_park_ball()
	_layout_showcase()
	camera_rig.cinematic = true
	camera_rig.cine_snap = true

func _layout_showcase() -> void :

	var n: = GameConfig.team_size
	for p in _all_players:
		var member: Player = p
		member.global_position = _showcase_spot(_slots[member], n, member.team_side)
		member.velocity = Vector3.ZERO

		member.visual.rotation.y = PI if member.team_side > 0 else 0.0
		member.reset_physics_interpolation()

func _showcase_spot(slot: int, n: int, side: int) -> Vector3:
	var frac: = (float(slot) + 0.5) / float(n)
	var x: = lerpf( - _half_w + 1.4, _half_w - 1.4, frac)
	return Vector3(x, 0.0, side * _half_l * 0.5)

func _intro_tick(delta: float) -> void :
	_cine_time += delta
	var team_dur: = GameConfig.team_size * INTRO_PER_PLAYER
	var total: = team_dur + INTRO_FADE + team_dur
	if _cine_time >= total:
		_start_countdown()

var _finale_tip_shown: = false

func _start_countdown() -> void :


	hud.grab_dissolve()
	_phase = Phase.COUNTDOWN


	if GameConfig.tutorial_finale and not _finale_tip_shown:
		_finale_tip_shown = true
		hud.notice("you can leave this match at any time by opening the pause menu!")


	_start_recording()
	_cine_time = 0.0
	camera_rig.cinematic = false
	_prepare_serve()
	_pre_intro = false
	ball.visible = true

func _countdown_tick(delta: float) -> void :
	_cine_time += delta



	if _server != null:
		ball.global_position = _server.serve_cradle_point()
		ball.vel = Vector3.ZERO
	if _cine_time >= COUNTDOWN_TIME:
		_did_intro = true
		_intro_locked = false
		hud.hide_cinematics()
		sfx.play("whistle", Vector3.ZERO)
		_net_event("whistle", {"p": Vector3.ZERO})
		_begin_serve(false)



func _start_win(winner_side: int, covered: = false) -> void :


	_replay_pending = false
	_save_match_replay()


	if not covered:
		hud.grab_dissolve()
	_match_winner = winner_side
	_match_over = true
	_stats_built = false
	_phase = Phase.WIN
	_cine_time = 0.0
	ball.frozen = true
	ball.vel = Vector3.ZERO
	ball.visible = false



	landing_marker.visible = false
	ball.show_landing_ring = false


	var winners: = _team_players(winner_side)
	for i in winners.size():
		var m: Player = winners[i]
		m.global_position = _win_spot(i, winners.size(), winner_side)
		m.velocity = Vector3.ZERO
		m.visual.rotation.y = PI if winner_side > 0 else 0.0
		m.clear_action_state()
		m.reset_physics_interpolation()




	var losers: = _team_players( - winner_side)
	for i in losers.size():
		var m: Player = losers[i]
		m.global_position = _showcase_spot(_slots[m], GameConfig.team_size, 
			- winner_side)
		m.velocity = Vector3.ZERO
		m.visual.rotation.y = PI if - winner_side > 0 else 0.0
		m.clear_action_state()
		m.reset_physics_interpolation()
	camera_rig.cinematic = true
	camera_rig.cine_snap = true

func _win_tick(delta: float) -> void :
	_cine_time += delta



	if _cine_time >= WIN_TIME:
		_phase = Phase.STATS



func _play_local_reach(bank: String, volume_db: float, pitch: = 1.0) -> void :



	if _phase == Phase.REPLAY:
		return
	sfx.play(bank, player.global_position, volume_db, pitch)

func _start_recording() -> void :
	_rec_started_ms = Time.get_ticks_msec()
	var slot_info: Array = []
	for p in _all_players:
		var body: Player = p



		var look: CharacterConfig = body.character
		slot_info.append({
			"name": String(_names.get(body, "player")), 
			"side": body.team_side, 
			"slot": int(_slots.get(body, 0)), 
			"is_bot": body.is_bot, 
			"is_you": body == player, 
			"cfg": look.to_dict() if look != null else {}, 
			"kit": body.replay_kit.map(
				func(c): return (c as Color).to_html(false)), 
			"tint": _team_color(body.team_side, 
				int(_slots.get(body, 0))).to_html(false), 


			"pinny": look.pinny_color.to_html(false)\
			if look != null and look.wear_pinny else "", 
			"pinny_acc": look.pinny_accent.to_html(false)\
			if look != null and look.wear_pinny else "", 
		})
	_recorder.begin(_all_players, slot_info, ball, {
		"team_size": GameConfig.team_size, 
		"stage": GameConfig.stage, 

		"half_w": _half_w, "half_l": _half_l, 
		"set_points": GameConfig.set_points, 
		"sets_to_win": GameConfig.sets_to_win, 
		"recorded_at": Time.get_datetime_string_from_system(), 
		"online": _net_role != NetRole.OFFLINE, 




		"match_seed": GameConfig.match_seed, 
		"school_accent": _last_accent, 
		"court_tape": _last_tape, 
		"has_tape": _has_tape, 
	})

	sfx.recorder = _recorder
	fx.recorder = _recorder
	crowd.recorder = _recorder
	ball.recorder = _recorder
	_replay_saved = false

func _contact_fx(pos: Vector3, strength: float, axis: Vector3, kind: = -1, 
		combo_tier: = 0) -> void :




	Rules.contact_fx(fx, pos, strength, axis, _sweat_shown, true, kind, combo_tier)

func _replay_fire(c: Dictionary) -> void :


	_recorder.replaying = true


	ReplayCues.play(c, sfx, fx, crowd, ball, _all_players, false)
	_recorder.replaying = false

func _replay_sfx_rewind() -> void :
	_replay_sfx_at = 0
	var evs: Array = _recorder.data.events
	while _replay_sfx_at < evs.size()\
	and float(evs[_replay_sfx_at]["t"]) < _director.time:
		_replay_sfx_at += 1

func _replay_sfx_tick() -> void :
	var evs: Array = _recorder.data.events
	while _replay_sfx_at < evs.size()\
	and float(evs[_replay_sfx_at]["t"]) <= _director.time:
		_replay_fire(evs[_replay_sfx_at])
		_replay_sfx_at += 1

func _replay_humans() -> int:

	if _net_role == NetRole.OFFLINE:
		return 1
	return _peer_players.size() + 1

func _skips_needed() -> int:
	return int(ceil(_replay_humans() / 2.0))





func _point_wipe(mid: = Callable(), variant: = "") -> void :
	if variant == "":
		variant = POINT_WIPE.variant_for_stage(GameConfig.stage)





	_net_event("wipe", {"v": variant})
	_play_wipe(mid, variant)



func _play_wipe(mid: = Callable(), variant: = "") -> void :
	if variant == "":
		variant = POINT_WIPE.variant_for_stage(GameConfig.stage)
	_rally.serve_locked = true
	POINT_WIPE.play(get_tree(), mid, 0.0, variant, 
		func(): _rally.serve_locked = false)

func _enter_replay() -> void :
	if _recorder.data.frame_count() < 4:
		_replay_pending = false
		return




	_replay_starting = true
	_point_wipe(_do_enter_replay)

func _do_enter_replay() -> void :
	_replay_pending = false
	_replay_starting = false
	_phase = Phase.REPLAY
	_skip_votes.clear()
	_voted_skip = false
	_input_collector.clear_buffers()



	if aim_indicator.net_mat != null:
		aim_indicator.net_mat.set_shader_parameter("cut_radius", 0.0)
	_replay_lead = minf(REPLAY_LEAD, _rally_time + 1.0) + REPLAY_TAIL
	_setup_director()





	if _sand_deform != null:
		_sand_deform.reset()



	_net_event("replay_go", {"f": _replay_focus, "ld": _replay_lead})
	hud.set_replay_banner(true, 0, _skips_needed())

func _setup_director() -> void :
	_director.setup(_recorder.data, _all_players, ball)


	if _replay_lead <= 0.0:


		_replay_lead = minf(REPLAY_LEAD, _rally_time + 1.0) + REPLAY_TAIL
	_director.seek_clip(_recorder.window_start_time(_replay_lead))
	_director.playing = true
	_director.speed = 1.0
	_replay_shot = -1
	_replay_cam_side = 0.0
	_replay_on_land = false
	_replay_sfx_rewind()





	if _puppet_saved.is_empty():


		_ball_puppet_saved = ball.net_puppet
		for p in _all_players:
			_puppet_saved.append((p as Player).net_puppet)
	_replay_prev_t = _director.time
	_replay_cur_t = _director.time
	for p in _all_players:
		var body: Player = p
		body.net_puppet = true
		body.cinematic_hidden = true
		body.suppress_names(true)
		body.hide_combo()
		body.hide_callout()

func _replay_tick(delta: float) -> void :


	_director.advance(minf(delta, 0.05))
	_replay_prev_t = _replay_cur_t
	_replay_cur_t = _director.time



	if _director.finished():
		_exit_replay()

func _exit_replay() -> void :
	if _phase != Phase.REPLAY or _replay_exiting:
		return

	_replay_exiting = true
	_point_wipe(_do_exit_replay)

func _do_exit_replay() -> void :
	_replay_exiting = false
	_phase = Phase.DEAD







	_dead_timer = 0.12


	_input_collector.swallow_held(["jump", "contact", "dive", "serve"])



	_input_collector.clear_buffers()
	hud.set_replay_banner(false, 0, 0)
	_replay_lead = 0.0
	_replay_restore()





	if _win_delay > 0.0:
		_win_delay = 0.0
		_start_win(_win_pending, true)
	elif not _pending_set.is_empty():
		_swap_delay = 0.0
		_do_switch_sides()

func _replay_client_tick(delta: float) -> void :









	if not _director.finished():
		_director.advance(minf(delta, 0.05))
	elif replay_loops == 0:
		replay_loops = 1
	_replay_prev_t = _replay_cur_t
	_replay_cur_t = _director.time





	if not _spectating:
		_send_client_input(PlayerInput.new())
	_present_replay(delta)
	hud.set_scoreboard_visible(true)
	_decay_net_wobble(delta)

func _replay_restore() -> void :

	ball.net_puppet = _ball_puppet_saved
	ball.frozen = true
	ball.vel = Vector3.ZERO
	ball.show_landing_ring = true
	ball.reset_visuals()
	ball.reset_physics_interpolation()
	for i in _all_players.size():
		var body: Player = _all_players[i]





		body.net_puppet = _net_role == NetRole.CLIENT and not _is_own_body(body)
		body.cinematic_hidden = false
		body.suppress_names(false)
		body.hide_callout()
		body.reset_physics_interpolation()
	_puppet_saved.clear()
	_reset_formation()
	_floor_mat.set_shader_parameter("sweat", _sweat_shown)

func _present_replay(delta: float) -> void :

	_director.apply()
	_director.pose_tick(delta)
	_replay_sfx_tick()
	_tick_dissolve(delta)


	_floor_mat.set_shader_parameter("sweat", _director.sweat)


	if _director.sweat > 0.12:
		for p in _all_players:
			if randf() < _director.sweat * 0.22:
				fx.sweat((p as Player).global_position + Vector3(
					randf_range(-0.3, 0.3), randf_range(1.35, 1.7), 
					randf_range(-0.3, 0.3)))
	camera_rig.cinematic = true
	var focus: = ball.global_position
	var side: = signf(focus.z)
	if side == 0.0:
		side = 1.0





	if _replay_cam_side == 0.0:
		_replay_cam_side = 1.0 if side >= 0.0 else -1.0
	var sx: = _replay_cam_side
	var elapsed: = _director.elapsed()
	var shot: = int(elapsed / REPLAY_ANGLE_TIME)
	var snap: = shot != _replay_shot
	_replay_shot = shot



	var to_end: = _director.end_time() - _director.time
	var eye: = Vector3.ZERO
	if to_end < REPLAY_LAND_WINDOW and _replay_focus != Vector3.ZERO:
		focus = _replay_focus + Vector3(0.0, 0.35, 0.0)
		eye = _replay_focus + Vector3(sx * 3.2, 1.3, sx * 1.4)
		snap = snap or not _replay_on_land
		_replay_on_land = true
	else:
		_replay_on_land = false
		match shot % 3:
			0:
				eye = Vector3(sx * (_half_w + 8.0), 5.0, focus.z * 0.5)
			1:
				eye = focus + Vector3(sx * 5.0, 2.2, 0.0)
			_:
				eye = Vector3(sx * (_half_w + 11.0), 8.0, 0.0)
	camera_rig.cine_eye = eye
	camera_rig.cine_target = focus
	camera_rig.cine_snap = snap


	hud.set_play_hud_visible(false)
	hud.set_crosshair_visible(false)
	hud.set_serve_prompt("")
	aim_indicator.visible = false
	barred_marker.visible = false
	ball.landing_ring_muted = false
	landing_marker.visible = false
	ball.show_landing_ring = false

func _poll_skip_vote() -> void :



	if _phase != Phase.REPLAY or _voted_skip or _spectating:
		return
	if hud.chat_typing():
		return
	if not Input.is_action_just_pressed("ui_accept"):
		return
	_voted_skip = true
	if _net_role == NetRole.CLIENT:
		Net.send_up("skip_vote", {})
	else:
		_register_skip_vote(0)

func _register_skip_vote(voter: int) -> void :

	if _phase != Phase.REPLAY:
		return
	if voter != 0 and not _peer_players.has(voter):
		return
	_skip_votes[voter] = true
	var needed: = _skips_needed()
	hud.set_replay_banner(true, _skip_votes.size(), needed)
	_net_event("skip_tally", {"n": _skip_votes.size(), "k": needed})
	if _skip_votes.size() >= needed:
		_net_event("skip_done", {})
		_exit_replay()

func _save_match_replay() -> void :
	if not GameConfig.replay_capture:
		return


	if LaunchGate.public_beta():
		return
	if _replay_saved or _recorder.data.frame_count() < 30:
		return
	_replay_saved = true
	_recorder.stop()
	var stamp: = Time.get_datetime_string_from_system().replace(":", "-")\
	.replace("T", "_")
	var name_part: = "%dv%d" % [GameConfig.team_size, GameConfig.team_size]
	var path: = "%s/%s_%s.vbr" % [REPLAY_DIR, stamp, name_part]
	_recorder.data.meta["duration"] = _recorder.data.duration()
	_recorder.data.meta["title"] = "%s %s" % [name_part, stamp]



	_recorder.data.meta["home_score"] = int(_scores[HOME_SIDE])
	_recorder.data.meta["away_score"] = int(_scores[ - HOME_SIDE])
	_recorder.data.meta["home_sets"] = int(_set_wins[HOME_SIDE])
	_recorder.data.meta["away_sets"] = int(_set_wins[ - HOME_SIDE])
	_recorder.data.save_to(path)

func _begin_dissolve(hold: float, fade: float) -> void :





	hud.grab_dissolve()
	_diss_fade = maxf(fade, 0.01)
	_diss_left = hold + _diss_fade

func _tick_dissolve(delta: float) -> void :

	if _diss_left <= 0.0:
		return
	_diss_left -= delta

	hud.set_dissolve(clampf(_diss_left / _diss_fade, 0.0, 1.0))
	if _diss_left <= 0.0:
		_diss_left = 0.0
		hud.set_dissolve(0.0)

func _side_name(side: int) -> String:
	return Rules.side_name(side)










func _team_identity(side: int, set_number: = -1) -> int:
	var sn: = set_number if set_number > 0 else _set_number
	return side if sn % 2 == 1 else - side

const WIN_LINE: = 0.72

func _win_spot(i: int, n: int, side: int) -> Vector3:
	var frac: = (float(i) + 0.5) / float(n)
	var x: = lerpf( - _half_w + 1.4, _half_w - 1.4, frac)
	return Vector3(x, 0.0, side * _half_l * WIN_LINE)

func _present_win(ct: float) -> void :

	var winners: = _team_players(_match_winner)
	var center: = Vector3(0.0, 0.0, _match_winner * _half_l * WIN_LINE)
	var dist: = 4.0 + winners.size() * 0.85
	camera_rig.cine_eye = center + Vector3(0.0, 2.6, - _match_winner * dist)
	camera_rig.cine_target = center + Vector3(0.0, 1.15, 0.0)
	camera_rig.cine_snap = _cine_want_snap
	_cine_want_snap = false

	hud.show_cine_name(_side_name(_match_winner) + " wins", 
		_side_color(_match_winner))
	hud.set_dissolve(clampf(1.0 - ct / WIN_FADE, 0.0, 1.0))








const PA_WINDOW: = 15.0
var _pa_left: = 0.0
var _pa_grace: = 0.0
var _pa_opted: = false
var _pa_opt: = {}
var _pa_names: = {}




func _pa_push_states() -> void :
	if _net_role != NetRole.HOST or _pa_names.is_empty():
		return
	var states: = {}
	for pid in _pa_names:


		var pa_name: String = _pa_names[pid]
		if pid == 1:
			pa_name += "  (host)"
		if not Net.players.has(pid):
			states[pa_name] = "out"
		elif _pa_opt.has(pid):
			states[pa_name] = "in"
		else:
			states[pa_name] = "wait"
	hud.set_pa_marks(states)
	var l: = []
	for pa_name in states:
		l.append([pa_name, states[pa_name]])
	_net_event("pa_state", {"l": l})

func _quick_post() -> bool:
	return GameConfig.quick_match and _net_role != NetRole.OFFLINE





func _rematch_window() -> bool:
	return _net_role != NetRole.OFFLINE and (GameConfig.quick_match or Net.party)



func _party_follower() -> bool:
	return Net.party and _net_role == NetRole.CLIENT

func _tick_play_again() -> void :
	if not _rematch_window() or not Net.active:
		return


	var delta: = get_physics_process_delta_time()


	if _net_role == NetRole.HOST and _pa_left > 0.0\
	and not _pa_opt.is_empty() and _pa_opt.size() >= Net.players.size():
		_pa_left = 0.0
		_pa_grace = 0.3
		hud.set_quick_wait("everyone's in!")
		return
	if _pa_left > 0.0:
		_pa_left -= delta


		var n: = ceili(maxf(_pa_left, 0.0))
		hud.set_quick_wait(("starting in %d, waiting for the others..."\
		%n) if _pa_opted else "window closes in %d" % n)
		if _pa_left <= 0.0:
			if Net.party:





				if _net_role == NetRole.HOST:
					_net_event("to_lobby", {})
					_leave_to_lobby()
			elif _net_role == NetRole.HOST:









				for pid in Net.players.keys():
					if pid != 1 and not _pa_opt.has(pid):
						Net.refuse_peer(pid, "sat out the rematch")
				if not _pa_opted:

					Net.leave()
					hud.hide_match_stats()
					UiWipe.wipe(get_tree(), func():
						GameConfig.goto_scene("res://game/ui/menu.tscn"))
				else:


					_pa_grace = 1.5
			else:



				_pa_overdue += delta
				hud.set_quick_wait("waiting for the host...")
				if _pa_overdue > PA_OVERDUE_S:
					Net.leave()
					hud.hide_match_stats()
					UiWipe.wipe(get_tree(), func():
						GameConfig.goto_scene("res://game/ui/menu.tscn"))
	elif _pa_grace > 0.0 and _net_role == NetRole.HOST:
		_pa_grace -= delta
		if _pa_grace <= 0.0:
			_quick_rematch()

func _quick_rematch() -> void :



	var ids: = Net.players.keys()
	ids.sort()
	var kits: = Net.captain_kits(Net.players)
	var roster: = Net.build_roster(ids, Net.players, Net.team_size, kits, Net.cpu_slots)
	Net.sync_lobby()
	Net.start_match(roster, randi())

var _rematch_reload: = false
var _pa_overdue: = 0.0
const PA_OVERDUE_S: = 8.0
var _ad_t: = 0.0
var _my_peer_id: = 1
var _migrating: = false
var _migrate_resume: = false
var _gone_bodies: = {}
var _loading_up: = true
var _reveal_a: = 1.0
var _cover_t: = 0.0



const REVEAL_TIMEOUT_S: = 8.0
var _replay_stand_off: = false
var _rec_started_ms: = 0






func _quick_ad_refresh() -> void :
	if _net_role != NetRole.HOST or not GameConfig.quick_match\
	or not Net.in_match:
		return
	var open: = 0
	for p in _all_players:
		if (p as Player).is_bot:
			open += 1
	Net.quick_backfill_ad(0 if _near_end() or _match_over else open)

func _near_end() -> bool:


	for side in [1, -1]:
		if int(_set_wins[side]) == GameConfig.sets_to_win - 1\
		and int(_scores[side]) >= GameConfig.set_points - 3:
			return true
	return false

func _on_late_joiner(id: int) -> void :









	if _match_over:
		Net.refuse_peer(id, "that match just ended")
		return



	if GameConfig.quick_match and _near_end()\
	and bool((Net.players.get(id, {}) as Dictionary).get("qjoin", false)):
		Net.refuse_peer(id, "that match is about to end, still searching")
		return
	var entries: = _live_cast()
	if entries.is_empty():




		return
	var auto_side: = _backfill_side() if GameConfig.quick_match else 0
	Net.send_late_join(id, entries, auto_side)




	if auto_side == 0 and not _arrival_told.has(id):
		_arrival_told[id] = true
		var who: = String((Net.players.get(id, {}) as Dictionary).get("name", "someone"))
		hud.notice("%s joined as a spectator" % who)
		_net_event("arrive", {"who": who})

var _arrival_told: = {}







func _relay_pending_late_joiners() -> void :
	if _net_role != NetRole.HOST or not Net.in_match:
		return
	var seated: = {}
	for e in GameConfig.net_roster:
		seated[int((e as Dictionary).get("peer", 0))] = true
	for pid in Net.players.keys():
		var p: = int(pid)
		if p == 1 or seated.has(p) or _peer_players.has(p)\
		or Net.match_ready_peers.has(p):
			continue
		_on_late_joiner(p)






func _live_cast() -> Array:
	var entries: = []
	var nids: = _by_net_id.keys()
	nids.sort()
	var playing: Array = GameConfig.net_roster.filter(
		func(e): return not bool(e.get("spec", false)))
	for i in nids.size():
		var body: Player = _by_net_id[nids[i]]
		var e: Dictionary = (playing[i] as Dictionary).duplicate()\
		if i < playing.size() else {"cfg": {}, "kit": []}
		var peer: = 0
		if _is_own_body(body):
			peer = _my_peer_id
		for pid in _peer_players:
			if _peer_players[pid] == body:
				peer = pid
		e["peer"] = peer
		e["name"] = String(_names.get(body, e.get("name", "cpu")))
		e["side"] = body.team_side
		e["slot"] = int(_slots.get(body, int(e.get("slot", 0))))
		e["spec"] = false




		if peer > 0:
			var live_cfg: Dictionary = (Net.players.get(peer, {})\
			as Dictionary).get("cfg", {})
			if not live_cfg.is_empty():
				e["cfg"] = live_cfg
		entries.append(e)
	for pid in Net.players:
		var seated: bool = (pid == 1 and not _spectating)\
		or _peer_players.has(pid)
		if not seated:
			entries.append({"peer": pid, 
				"name": String(Net.players[pid].name), 
				"side": 0, "slot": -1, "spec": true, 
				"cfg": Net.players[pid].get("cfg", {}), "kit": []})
	return entries

func _backfill_side() -> int:


	var best: = 0
	var best_humans: = 99
	for p in _all_players:
		var body: Player = p
		if not body.is_bot:
			continue
		var humans: = 0
		for q in _all_players:
			if (q as Player).team_side == body.team_side\
			and not (q as Player).is_bot:
				humans += 1
		if humans < best_humans:
			best_humans = humans
			best = body.team_side
	return best

func _on_net_match_started(roster: Array) -> void :


	_rematch_reload = true
	GameConfig.set_mode(Net.team_size)
	GameConfig.stage = Net.stage
	Net.apply_rules_to_config()
	GameConfig.net_roster = roster
	GameConfig.goto_scene("res://game/main/main.tscn")

func _present_stats() -> void :
	hud.hide_cine_name()
	hud.set_dissolve(0.0)
	_tick_play_again()
	if not _stats_built:
		_stats_built = true
		var rows: = _stat_rows() if _net_role != NetRole.CLIENT\
		else hud.stored_stat_rows()



		hud.show_match_stats(rows, _team_identity(_match_winner), 
			_team_identity(player.team_side), _net_role != NetRole.CLIENT)
		if _net_role == NetRole.CLIENT and not _rematch_window():


			hud.room_stats_mode()
		if _rematch_window():
			hud.quick_stats_mode( not _party_follower())
			_pa_left = PA_WINDOW
			_pa_opted = false
			_pa_opt = {}
			_pa_names = {}
			for pid in Net.players:
				_pa_names[pid] = String(Net.players[pid].name)
			_pa_push_states()



		if not _spectating:
			for row in rows:
				if String(row.get("name", "")) == String(_names.get(player, "")):
					var won: = _match_winner == player.team_side






					var max_sets: = 2 * maxi(GameConfig.sets_to_win, 1) - 1
					var sets_ok: = clampi(int(_set_wins[1]) + int(_set_wins[-1]), 1, max_sets)
					var max_rallies: = sets_ok * (2 * maxi(GameConfig.set_points, 1) + 12)
					var rallies_ok: = clampi(_match_rallies, 0, max_rallies)
					var safe: = {}
					for k in ["pts", "spk", "blk", "rcv", "set", "ast"]:
						safe[k] = clampi(Net.ev_i(row, k, 0), 0, rallies_ok)
					Career.record_match(safe, won)
					Achievements.notify("match_end", {"won": won})




					_last_match_reward = Progression.grant_match(won, sets_ok, 
						rallies_ok)
					break

func _restart_match() -> void :

	_stats_built = false
	_match_over = false
	_match_winner = 0
	_did_intro = false
	_scores = {1: 0, -1: 0}
	_set_wins = {1: 0, -1: 0}
	_run_side = 0
	_run_len = 0
	_music_heat = 0
	MusicManager.set_floor(0)
	MusicManager.set_intensity(0)
	_match_rallies = 0
	_set_number = 1
	Rules.set_swapped = false
	_rot = {1: 0, -1: 0}
	for p in _stats:
		_stats[p] = {"pts": 0, "spk": 0, "blk": 0, "rcv": 0, "set": 0, "ast": 0}
	hud.hide_match_stats()
	hud.hide_cinematics()
	_diss_left = 0.0
	_swap_delay = 0.0
	_serve_prelaid = false
	_rally.serve_locked = false
	_sweat_shown = 0.0
	_replay_pending = false
	_start_recording()
	hud.set_loading(1.0)
	_park_ball()
	_phase = Phase.DEAD
	_dead_timer = 0.6

func _on_play_again() -> void :
	if _rematch_window():

		if _pa_opted or _pa_left <= 0.0:
			return
		_pa_opted = true
		hud.set_play_again("you're in!", true)
		if _net_role == NetRole.CLIENT:
			Net.send_up("pa", {})
		else:
			_pa_opt[1] = true
			_pa_push_states()
		return
	if _net_role == NetRole.CLIENT:
		return
	_net_event("rematch", {})
	_restart_match()

func _on_to_lobby() -> void :
	if _rematch_window():
		if Net.party:




			if _net_role != NetRole.CLIENT:
				_net_event("to_lobby", {})
				_leave_to_lobby()
			return



		Net.leave()
		hud.hide_match_stats()
		UiWipe.wipe(get_tree(), func():
			GameConfig.goto_scene("res://game/ui/menu.tscn"))
		return
	if _net_role == NetRole.CLIENT:








		if bool(Net.home_party.get("is_leader", false))\
		and bool(Net.home_party.get("room", false)):



			Net.send_party_home()
			hud.hide_match_stats()
			UiWipe.wipe(get_tree(), func():
				Net.leave()
				GameConfig.goto_scene("res://game/ui/menu.tscn"))
			return
		Net.leave()
		hud.hide_match_stats()
		UiWipe.wipe(get_tree(), func():
			GameConfig.goto_scene("res://game/ui/menu.tscn"))
		return
	if _net_role == NetRole.OFFLINE:
		hud.hide_match_stats()

		if not GameConfig.tutorial_finale:
			GameConfig.menu_return_local = true
		UiWipe.wipe(get_tree(), func():
			GameConfig.goto_scene("res://game/ui/menu.tscn"))
	else:
		_net_event("to_lobby", {})
		_leave_to_lobby()

func _side_color(side: int) -> Color:
	return CINE_BLUE if side > 0 else CINE_RED

func _team_players(side: int) -> Array:
	var list: = _all_players.filter( func(o): return o.team_side == side)
	list.sort_custom( func(a, b): return _slots[a] < _slots[b])
	return list

func _cine_focus(spot: Vector3, side: int) -> void :


	camera_rig.cine_eye = spot + Vector3(0.9, 1.7, - side * 3.2)
	camera_rig.cine_target = spot + Vector3(0.0, 1.1, 0.0)

func _subject_spot(subject: Player) -> Vector3:
	return _showcase_spot(_slots.get(subject, 0), GameConfig.team_size, 
		subject.team_side)




func _effective_phase() -> int:
	if _net_role == NetRole.CLIENT:
		return int(_np.get("ph", _phase))
	return _phase

























func _music_tick(phase: int) -> void :
	if phase == _music_phase:
		return
	_music_phase = phase
	match phase:
		Phase.SERVE_PREP, Phase.LIVE:






			MusicManager.set_floor(_music_tier())
			MusicManager.set_intensity(_music_effective_tier())
			MusicManager.play("match", MusicManager.QUICK_FADE, false)
		Phase.REPLAY:
			MusicManager.play("replay", MusicManager.QUICK_FADE, true)
		Phase.WIN:

			MusicManager.stinger("win")
		Phase.INTRO:
			MusicManager.stop(0.6)









func _music_rally_end(replay_incoming: bool) -> void :


	_music_heat = 0
	_music_spike_power = 0.0
	_music_heat_t = 0.0



	if replay_incoming or _music_point_won_match():
		MusicManager.stop(MusicManager.QUICK_FADE)
	elif _music_point_won_set():




		MusicManager.set_floor(0)
		MusicManager.set_intensity(0)
	else:



		MusicManager.set_floor(_music_tier())
		MusicManager.set_intensity(_music_effective_tier())






func _music_point_won_match() -> bool:
	var side: = _music_point_won_set()
	if side == 0:
		return false

	var key: = "w1" if side == 1 else "w2"
	var won: = int(_np.get(key, _set_wins[side])) if _np.has(key) else int(_set_wins[side])
	return won + 1 >= GameConfig.sets_to_win



func _music_point_won_set() -> int:
	var target: = maxi(GameConfig.set_points, 1)
	for side in [1, -1]:
		var mine: = int(_scores[side])
		var lead: = mine - int(_scores[ - side])
		if mine >= target and ( not GameConfig.win_by_two or lead >= 2):
			return side
	return 0


func _music_effective_tier() -> int:
	return clampi(_music_tier() + _music_heat, 0, 2)












func _music_heat_touch(kind: int, power: float, laid_out: bool) -> void :
	var before: = _music_heat
	match kind:
		Player.TouchKind.SPIKE, Player.TouchKind.DUMP:
			_music_spike_power = power if kind == Player.TouchKind.SPIKE else 0.0
		Player.TouchKind.BUMP, Player.TouchKind.SET, Player.TouchKind.BLOCK:
			if laid_out and _music_spike_power >= MUSIC_SAVE_SPIKE:
				_music_heat = mini(_music_heat + 1, 2)
				_music_heat_t = 0.0
			_music_spike_power = 0.0
	if _music_heat != before:
		MusicManager.set_intensity(_music_effective_tier())




func _music_heat_decay(delta: float) -> void :
	if _music_heat <= 0:
		return
	_music_heat_t += delta
	if _music_heat_t < MUSIC_HEAT_HOLD:
		return
	_music_heat_t = 0.0
	_music_heat -= 1
	MusicManager.set_intensity(_music_effective_tier(), 1.2)







func _music_tier() -> int:
	var target: = maxi(GameConfig.set_points, 1)
	var lead: = maxi(int(_scores[1]), int(_scores[-1]))
	var deuce: bool = GameConfig.win_by_two\
	and mini(int(_scores[1]), int(_scores[-1])) >= target - 1
	if deuce or lead >= target - MUSIC_CLOSE_POINTS:
		return 2
	if lead * 2 >= target:
		return 1
	return 0

func _gate_cinematics(input: PlayerInput) -> PlayerInput:
	var phase: = _effective_phase()




	if phase == Phase.STATS:
		return PlayerInput.new()






	if not _intro_locked or phase != Phase.INTRO:
		return input
	var held: = PlayerInput.new()
	held.aim = input.aim
	return held

func _present_intro(ct: float) -> void :







	var home: = _team_players(HOME_SIDE)
	var enemy: = _team_players( - HOME_SIDE)
	var per: = INTRO_PER_PLAYER
	var home_dur: = home.size() * per
	var enemy_start: = home_dur + INTRO_FADE
	var enemy_dur: = enemy.size() * per
	var dissolve: = 0.0
	var snap: = _cine_want_snap

	_intro_locked = player.team_side != (HOME_SIDE if ct < home_dur else - HOME_SIDE)
	if ct < home_dur:
		_pan_across(home, HOME_SIDE, ct / home_dur)
		hud.show_cine_name(_intro_label(HOME_SIDE), _side_color(HOME_SIDE))
	elif ct < enemy_start:
		if not _grabbed_home:
			_grabbed_home = true




			if not _loading_up:
				hud.grab_dissolve()
			else:
				_grabbed_home = false



			snap = true
		_pan_across(enemy, - HOME_SIDE, 0.0)
		dissolve = 1.0 - (ct - home_dur) / INTRO_FADE
		hud.hide_cine_name()
	else:
		_pan_across(enemy, - HOME_SIDE, (ct - enemy_start) / maxf(enemy_dur, 0.01))
		hud.show_cine_name(_intro_label( - HOME_SIDE), _side_color( - HOME_SIDE))


	camera_rig.cine_snap = snap
	_cine_want_snap = false
	hud.set_dissolve(dissolve)
	hud.set_loading(clampf(1.0 - ct / LOAD_FADE, 0.0, 1.0))

func _intro_label(side: int) -> String:

	return Rules.side_name(side)

func _pan_across(team: Array, side: int, frac: float) -> void :

	if team.is_empty():
		return
	var n: = GameConfig.team_size
	var x0: = _showcase_spot(_slots.get(team[0], 0), n, side).x
	var x1: = _showcase_spot(_slots.get(team[team.size() - 1], 0), n, side).x
	var e: = smoothstep(0.0, 1.0, clampf(frac, 0.0, 1.0))
	_cine_focus(Vector3(lerpf(x0, x1, e), 0.0, side * _half_l * 0.5), side)

func _cine_present(phase: int, ct: float) -> void :







	if phase != _cine_snap_phase:
		_cine_snap_phase = phase
		_cine_want_snap = true
	hud.set_scoreboard_visible(false)
	hud.set_crosshair_visible(false)
	hud.set_serve_prompt("")
	hud.set_play_hud_visible(false)
	aim_indicator.visible = false
	camera_rig.cinematic = phase == Phase.INTRO or phase == Phase.WIN\
	or phase == Phase.STATS
	if phase == Phase.WIN:
		_present_win(ct)
		return
	if phase == Phase.STATS:
		_present_stats()
		return
	if phase == Phase.INTRO:
		_present_intro(ct)
	elif phase == Phase.COUNTDOWN:
		hud.hide_cine_name()



		hud.set_dissolve(clampf(1.0 - ct / INTRO_FADE, 0.0, 1.0) if _grabbed_home else 0.0)
		var n: = ceili(COUNTDOWN_TIME - ct)
		if n >= 1:

			if n != _last_count_n:
				_last_count_n = n
				sfx.play("count_tick", Vector3.ZERO)
			hud.show_countdown(n)
		else:
			hud.hide_countdown()
			_last_count_n = 0

func _prepare_serve() -> void :



	_flush_motion_state()
	_lag_touch_requests.clear()
	_lag_history.clear()
	_ball_event_flight.clear()
	_toss_visual_state.clear()
	_toss_unfrozen_snaps = 0
	for member in _all_players:
		(member as Player).contact_enabled = true
	_rally.prepare_serve()

func _begin_serve(prepare: = true) -> void :





	if _net_role == NetRole.HOST:
		_apply_seat_requests()
	landing_marker.visible = false
	ball.visible = true
	camera_rig.cinematic = false
	if prepare:
		_prepare_serve()
	_rally.begin_serve(false)
	_phase = Phase.SERVE_PREP

	if _sand_deform != null:
		_sand_deform.reset()


	crowd.serve_build()


	sfx.play("whistle", Vector3.ZERO, -3.0)
	_net_event("whistle", {"p": Vector3.ZERO})
	_net_event("serve", {})

func _serve_prep_tick(delta: float) -> void :
	_rally.serve_tick(delta)

func _in_serve_zone(p: Player) -> bool:
	return _rally.in_serve_zone(p)

func _do_toss(up_speed: float) -> void :
	_rally.do_toss(up_speed)

func _allies_of(p: Player) -> Array:
	return _lines.allies_of(_all_players, p)

func _opponents_of(p: Player) -> Array:
	return _lines.opponents_of(_all_players, p)

func _update_barred() -> void :
	_rally.pre_tick(0.0, _phase != Phase.LIVE)

func _on_ball_wall_hit() -> void :
	_rally.ball_hit_wall()

func _on_touched(kind: int, who: Player) -> void :




	if who == _rally.server and not _rally.serve_done:
		if not who.grounded():
			crowd.serve_hit()
			_net_event("servestrike", {"j": true})
		else:
			crowd.serve_stop()
			_net_event("servestrike", {"j": false})
	_ach_touched(kind, who)


	_rally.judge_touch(kind, who)




func _bounce_fx(pos: Vector3, impact: float) -> void :
	var hard: = clampf((impact - 6.0) / 12.0, 0.0, 1.0)
	sfx.play("hit_soft", pos, lerpf(-10.0, -3.0, hard), lerpf(0.75, 0.62, hard))
	ball.pulse()
	var floor_pos: = Vector3(pos.x, 0.06, pos.z)
	fx.ring(floor_pos, Vector3.UP, lerpf(0.35, 1.5, hard))
	fx.puff(floor_pos)

	if hard > 0.25:
		fx.floor_gust(floor_pos, hard)

func _on_ball_bounced() -> void :



	var impact: = ball.vel.length()
	if not _rally.live:
		_bounce_fx(ball.global_position, impact)
		return
	_replay_focus = ball.global_position




	var bounce_vel: = Vector3(ball.vel.x * Ball.PHYS.floor_friction, 
		- ball.vel.y * Ball.PHYS.floor_bounce, 
		ball.vel.z * Ball.PHYS.floor_friction)
	if bounce_vel.y < 1.2:
		bounce_vel.y = 0.0
	_commit_floor(ball.global_position, bounce_vel, impact)

func _commit_floor(pos: Vector3, bounce_vel: Vector3, impact: float) -> void :
	_bounce_fx(pos, impact)

	_net_event("bounce", {"p": pos, "bv": bounce_vel, "is": impact})


	_rally.ball_bounced()

func _end_rally(winner_side: int) -> void :



	if _phase == Phase.DEAD:
		return
	_rally._ended = false
	_rally.end_rally(winner_side, "")



func _on_rally_whistle(reason: String, pos: Vector3) -> void :


	sfx.play("whistle", pos)
	_net_event("whistle", {"p": pos, "t": reason})

func _on_rally_verdict(pos: Vector3, text: String, winner: int) -> void :
	_last_verdict_pos = pos
	_show_verdict(pos, text, winner)
	_net_event("verdict", {"p": pos, "t": text, "w": winner})

func _on_rally_tossed(server_body: Player) -> void :
	_phase = Phase.LIVE
	server_body.present_serve_toss(true)
	sfx.play("hit_soft", ball.global_position, -10.0, 1.1)



	_net_event("toss", {"id": int(_net_ids.get(server_body, 0))})

func _on_rally_flair(kind: String, who: Player) -> void :
	if kind == "quick" and _ach_touch.has(who):
		_ach_touch[who]["quick"] = true
	match kind:
		"quick":
			crowd.shock(0.7)
			_net_event("shock", {"a": 0.7})
		"perfect":
			sfx.play("hit_hard", who.chest_position(), -2.0, 1.1)
			fx.ring(ball.global_position, ball.vel, 1.1)
		"dive":
			crowd.shock(0.85)
			_net_event("shock", {"a": 0.85})




func _point_call(winner_side: int, reason: String, winners_ball: bool) -> Array:

	var broke: = winner_side != _run_side and _run_len >= 3
	if winner_side == _run_side:
		_run_len += 1
	else:
		_run_side = winner_side
		_run_len = 1
	var wsc: = int(_scores[winner_side])
	var lsc: = int(_scores[ - winner_side])
	var lead: = wsc - lsc

	if wsc >= GameConfig.set_points and ( not GameConfig.win_by_two or lead >= 2):
		var match_win: bool = int(_set_wins[winner_side]) + 1 >= GameConfig.sets_to_win
		return ["game" if match_win else "set", winner_side]


	var target: = GameConfig.set_points
	if maxi(wsc, lsc) == target - 1\
	or (GameConfig.win_by_two and mini(wsc, lsc) >= target - 1):
		return ["", winner_side]




	if reason == "foot fault" or reason == "line fault":
		return ["foot_fault", winner_side]


	if reason == "serve foul" or reason == "outside the antenna"\
	or reason == "illegal attack on serve":
		return ["fault", winner_side]


	if broke:
		return ["break_point", winner_side]

	if reason == "":




		var serving_side: = _rally.server.team_side if _rally.server != null else 0
		if winner_side == serving_side and not _rally.serve_received:
			return ["ace", winner_side]
		if winners_ball and _landed_on_line():
			return ["line", winner_side]
		return ["", winner_side]
	if reason == "ball out":
		return ["out", winner_side]
	return ["", winner_side]




func _landed_on_line() -> bool:




	var band: = Ball.PHYS.radius + 0.02
	var p: = _last_verdict_pos
	return absf(absf(p.x) - _half_w) < band or absf(absf(p.z) - _half_l) < band

func _on_rally_point(winner_side: int, reason: String, _scorer: Player, 
		kill_power: float, winners_ball: bool) -> void :
	_phase = Phase.DEAD
	_dead_timer = DEAD_TIME
	_match_rallies += 1
	_ach_point(winner_side, _scorer)



	crowd.serve_stop()

	if _rally.rally_time >= REPLAY_MIN_RALLY and not _match_over and _replay_enabled:
		_replay_pending = true
		_replay_wait = REPLAY_BEAT
	_last_spike_power = 0.0
	sfx.play("whistle", ball.global_position)
	_net_event("whistle", {"p": ball.global_position})












	var moment: = _point_call(winner_side, reason, winners_ball)
	var call_side: = _team_identity(int(moment[1]))
	hud.point_moment(winner_side, _team_identity(1), reason, 
		_scores[1], _scores[-1])



	var home_side: = 1 if _team_identity(1) == 1 else -1
	_recorder.cue("point", {"w": _team_identity(winner_side), 
		"h": int(_scores[home_side]), "a": int(_scores[ - home_side]), 
		"set": _set_number, "r": reason})
	if String(moment[0]) != "":
		hud.announce_moment(String(moment[0]), call_side)
	_net_event("rally_end", {"w": winner_side, "r": reason, 
		"s1": _scores[1], "s2": _scores[-1], "rp": _replay_pending, 
		"ann": moment[0], "as": call_side})




	_music_rally_end(_replay_pending)
	_net_event("stats", {"r": _stat_rows()})
	if winners_ball and kill_power > 0.65:
		fx.slowmo(0.35, 0.8)
		crowd.cheer(1.0)
		_net_event("slowmo", {})
		_net_event("cheer", {"a": 1.0})
	else:
		crowd.cheer(0.45)
		_net_event("cheer", {"a": 0.45})

func _win_set(winner_side: int) -> void :
	if player != null and not _spectating:
		_ach_set_end(winner_side == player.team_side)
	if int(_set_wins[winner_side]) + 1 >= GameConfig.sets_to_win:

		_set_wins[winner_side] = int(_set_wins[winner_side]) + 1
		_net_event("over", {"w": winner_side})
		_net_event("stats", {"r": _stat_rows()})


		_win_delay = WIN_TAIL
		_win_pending = winner_side
		return


	var winner_id: = _team_identity(winner_side)
	_net_event("set_end", {"w": winner_id})

	_pending_set = {"w": winner_side, "n": _set_number + 1}


	_swap_delay = SWAP_DELAY

	_serve_side = - winner_side
	_dead_timer = SET_BREAK_TIME







func _sync_home_side() -> void :
	if player == null or _spectating or player.team_side == 0:
		return
	var hs: = float(player.team_side)
	if camera_rig.home_side != hs:
		camera_rig.home_side = hs
		ball.home_side = hs
		camera_rig.face_net()





func _switch_sides() -> void :
	_point_wipe(_do_switch_sides)

func _do_switch_sides() -> void :

	if not _pending_set.is_empty():
		var w: = int(_pending_set["w"])
		_set_wins[w] = int(_set_wins[w]) + 1
		_scores = {1: 0, -1: 0}
		_run_side = 0
		_run_len = 0
		_set_number = int(_pending_set["n"])
		Rules.set_swapped = _set_number % 2 == 0
		_pending_set = {}
	for p in _all_players:
		var member: Player = p
		member.team_side = - member.team_side






	_set_wins = {1: _set_wins[-1], -1: _set_wins[1]}

	_rot = {1: _rot[-1], -1: _rot[1]}




	_last_serve_side = - _last_serve_side
	camera_rig.home_side = float(player.team_side)
	camera_rig.face_net()
	ball.home_side = float(player.team_side)






	_prepare_serve()
	_serve_prelaid = true
	var sides: Array = []
	for p in _all_players:
		sides.append([_net_ids.get(p, 0), (p as Player).team_side])
	_net_event("sides", {"l": sides})



func _on_predicted_strike(pos: Vector3, power: float, kind: int) -> void :





	_on_ball_struck(pos, power, kind)

func _on_ball_struck(pos: Vector3, power: float, kind: int, 
		flight_vel: = Vector3.INF) -> void :







	var burst_vel: = flight_vel if flight_vel.is_finite()\
	and flight_vel.length_squared() > 0.01 else ball.vel




	var strength: = Rules.contact_strength(kind, power)
	var snd: = Rules.contact_sound(kind, power)
	sfx.play(String(snd["n"]), pos, float(snd["db"]), float(snd["pt"]))


	var laid_out: = kind == Player.TouchKind.BLOCK or (ball.strike_source != null and ball.strike_source.diving())
	_music_heat_touch(kind, power, laid_out)



	var tier: = ball.combo_tier if kind == Player.TouchKind.SPIKE else 0
	if tier == 3:
		strength = maxf(strength, 1.0) * 1.35
	if kind == Player.TouchKind.SPIKE:
		_last_spike_power = power
		if power > 0.8 or tier == 3:
			fx.big_spike(pos, burst_vel, 
				Player.combo_color(tier) if tier >= 1 else Color(0, 0, 0, 0), tier)



		if ball.strike_source == player and ball.hitstop_left > 0.0:
			camera_rig.shake(minf(0.12 + ball.hitstop_left * 2.0, 0.4))





	var burst_tier: = tier
	if kind == Player.TouchKind.BUMP or kind == Player.TouchKind.SET:





		var recv_side: = ball.strike_source.team_side if ball.strike_source != null else 0
		var post_count: = 1 if recv_side != _rally.touch_side else _rally.touch_count + 1
		burst_tier = clampi(post_count, 1, 3)
	_contact_fx(pos, strength, burst_vel, kind, burst_tier)







	ball.pulse()






	_net_event("strike", {"p": pos, "w": power, "k": kind, 
		"bp": ball.global_position, "bv": ball.vel, "c": ball.curve, 
		"fs": ball.float_seed if ball.float_serve else 0, 
		"n": float(ball.strike_seq), 
		"ht": float(_net_tick) * 1000.0 / 60.0, 


		"hs": ball.hitstop_left, 
		"sv": laid_out, 
		"cb": ball.combo_tier, 
		"id": int(_net_ids.get(ball.strike_source, 0))})

func _net_hit_fx(hit_x: float, strength: = 1.0, hit_y: = 0.5) -> void :



	sfx.play("hit_soft", Vector3(hit_x, Ball.PHYS.net_height, 0.0), -4.0 + 4.0 * strength, 
		0.6)
	_net_wobble = maxf(_net_wobble, strength)
	var mat: ShaderMaterial = (net_visual.mesh as PlaneMesh).material
	mat.set_shader_parameter("hit_x", hit_x / court.scale.x)
	mat.set_shader_parameter("hit_y", hit_y)
	if strength > 1.1:

		fx.puff(Vector3(hit_x, Ball.PHYS.net_height * hit_y * 2.0, 0.0))

func _net_hit_strength() -> float:


	return clampf(ball.last_net_impact / 13.0, 0.35, 1.9)

func _net_hit_height() -> float:

	return clampf(ball.global_position.y / Ball.PHYS.net_height, 0.0, 1.0)

func _on_net_hit() -> void :
	var strength: = _net_hit_strength()
	var at_y: = _net_hit_height()
	_net_hit_fx(ball.global_position.x, strength, at_y)
	_net_event("net", {"x": ball.global_position.x, "s": strength, "y": at_y})

func _show_verdict(pos: Vector3, text: String, winner: int) -> void :




	landing_marker.visible = true
	landing_marker.global_position = Vector3(pos.x, maxf(0.03, SandDeform.decal_y), pos.z)
	LandingCall.apply(landing_marker, verdict_label, text, 
		Rules.side_color(_team_identity(winner)))

func _check_air_bumps() -> void :

	for hit in Rules.air_bumps(_all_players):
		var mid: Vector3 = hit.pos
		sfx.play("block_soft", mid, -4.0)
		_contact_fx(mid, 0.7, hit.dir)
		fx.puff(mid)
		_net_event("bump_fx", {"p": mid})

func _motion_foley(delta: float) -> void :

	for p in _all_players:
		var member: Player = p
		member.serving = member == _server and not _serve_done






	var sweat_target: = _rally.sweat_target()
	if sweat_target >= _sweat_shown:
		_sweat_shown = sweat_target
	else:
		_sweat_shown = maxf(_sweat_shown - delta / SWEAT_DRY_TIME, sweat_target)
	var sweat_level: = _sweat_shown
	_floor_mat.set_shader_parameter("sweat", sweat_level)
	_recorder.sweat = sweat_level
	hud.set_sweat(sweat_level)
	for p in _all_players:
		var member: Player = p
		member.sweat = sweat_level

		if member.sweat > 0.12:
			for _d in range(2):
				if randf() < member.sweat * 0.22:
					fx.sweat(member.global_position + Vector3(
						randf_range(-0.3, 0.3), randf_range(1.35, 1.7), 
						randf_range(-0.3, 0.3)))


	_foley.tick(_all_players, delta, sfx, fx)













func _apply_stage() -> void :
	var id: String = GameConfig.stage\
	if Stage.STAGES.has(GameConfig.stage) else "nationals"


	GameConfig.stage_barefoot = bool(Stage.val(id, "barefoot", false))
	GameConfig.stage_reflections = bool(Stage.val(id, "reflect", true))

	_foley.surface = String(Stage.val(id, "surface", "court"))
	Stage.apply_reverb(id)


	_foley.water_x = float(Stage.val(id, "water_x", INF))
	_foley.water_side = float(Stage.val(id, "water_side", 1.0))


	crowd.set_active(Stage.has_crowd(id))
	_floor_mat.set_shader_parameter("reflect_on", GameConfig.reflections_live())





	if bool(Stage.val(id, "owns_floor", false)):
		_floor_mat.shader = load("res://game/court/floor_overlay.gdshader")
		var cf: = court.get_node_or_null("CourtFloor") as MeshInstance3D
		if cf != null:
			cf.position.y += 0.06


	var shell: = (load(String(Stage.info(id).venue)) as PackedScene).instantiate()
	_stage_shell = shell
	add_child(shell)





	var gym: = shell.get_node_or_null("Gym")
	_stage_painted = {}
	_wall_base = {}
	if bool(Stage.val(id, "hand_painted", false)) and gym != null:

		for node in gym.find_children("*", "MeshInstance3D", true, false):
			if String(node.name).to_lower().contains("cutter"):
				(node as Node3D).visible = false
		_stage_painted = \
		(preload("res://game/court/env_paint.gd") as GDScript).apply(gym, 
			Stage.val(id, "emissive_mats", {}))


	_paint_stage_look(id)

	if not _stage_painted.is_empty() and gym != null:
		(preload("res://game/court/gym_props.gd") as GDScript).dress(shell, court, _last_accent)




	if Stage.has_crowd(id):
		(preload("res://game/court/gym_crowd.gd") as GDScript).fill(shell, GameConfig.match_seed, 
			Stage.val(id, "seat_mats", []), Stage.val(id, "crowd_spacing", 0.0), 
			int(Stage.val(id, "crowd_max", 0)), Stage.val(id, "crowd_fill", 0.0), 
			Stage.val(id, "crowd_lift", 0.15), Stage.val(id, "crowd_push", 0.0), 
			Stage.val(id, "crowd_tint", Color(1, 1, 1)), 
			(Stage.val(id, "haze_color", Color(0.83, 0.87, 0.93)) as Color).darkened(0.62), 
			float(Stage.val(id, "crowd_haze", float(Stage.val(id, "haze_amt", 0.0)) * 2.7)), 
			Stage.val(id, "crowd_shade", {}))



	var cbox: Vector3 = Stage.val(id, "collision_box", Vector3.ZERO)
	var has_dome: = cbox != Vector3.ZERO and bool(Stage.val(id, "force_wall", false))
	if cbox != Vector3.ZERO:


		if has_dome:
			(preload("res://game/stage/stage_collision.gd") as GDScript).build_ring(shell, cbox)
		else:
			(preload("res://game/stage/stage_collision.gd") as GDScript).build_box(shell, cbox)
	elif gym != null and not _stage_painted.is_empty():
		(preload("res://game/stage/stage_collision.gd") as GDScript).build(gym)



	if has_dome:
		var fw: Node3D = (preload("res://game/court/force_dome.gd") as GDScript).new()
		shell.add_child(fw)
		fw.build(cbox, Stage.val(id, "force_wall_color", Color(0.28, 0.62, 1.0)))




	var backdrop: Dictionary = Stage.val(id, "backdrop", {})
	if not backdrop.is_empty():
		(preload("res://game/stage/stage_backdrop.gd") as GDScript).build(shell, backdrop, _half_w, _half_l)




	for piece in shell.get_children():
		if piece.has_method("configure"):
			piece.call("configure", _half_w, _half_l)
	_setup_sand_deform(id)
	_setup_grass(id)






func _setup_grass(_id: String) -> void :
	if _stage_shell == null:
		return
	for n in _stage_shell.find_children("*", "Node3D", true, false):
		if n.has_method("set_feeds"):
			n.set_feeds( func(): return _all_players, func(): return ball)




			if n.has_method("indicator_clearance_y"):
				SandDeform.decal_y = n.indicator_clearance_y()
				SandDeform.decal_y_feet = n.indicator_feet_y()





func _setup_sand_deform(id: String) -> void :
	SandDeform.decal_y = 0.0
	SandDeform.decal_y_feet = 0.0
	if _sand_deform != null:
		_sand_deform.queue_free()
		_sand_deform = null
	if _sand_deck != null:
		_sand_deck.queue_free()
		_sand_deck = null
	_sand_mat = null
	_floor_mat.set_shader_parameter("sand_on", false)





	var court_floor: = court.get_node_or_null("CourtFloor") as MeshInstance3D
	if String(Stage.val(id, "surface", "court")) != "sand":
		if court_floor != null:
			court_floor.visible = true
		return
	if court_floor != null:
		court_floor.visible = false


	var r: = SandDeform.build(self, id, _stage_shell, court, _half_w, _half_l, 
		func(): return _all_players, func(): return ball)
	_sand_deform = r.get("deform")
	_sand_deck = r.get("deck")
	_sand_mat = r.get("mat")
	_sand_surround_mat = r.get("surround")



func _paint_sand_look(id: String) -> void :
	SandDeform.paint_look(_sand_mat, id)

	SandDeform.paint_grade(_sand_mat, id)
	SandDeform.paint_grade(_sand_surround_mat, id)





func _paint_stage_look(id: String) -> void :
	_floor_mat.set_shader_parameter("base_color", 
		Stage.val(id, "floor_color", Color(0.85, 0.5, 0.25)))





	_floor_mat.set_shader_parameter("pool_strength", float(Stage.val(id, "pool_strength", 0.0)))
	_floor_mat.set_shader_parameter("floor_vignette", float(Stage.val(id, "floor_vignette", 0.0)))



	_floor_mat.set_shader_parameter("pool_warm", Color(1.0, 0.9, 0.72))
	_floor_mat.set_shader_parameter("pool_radius", maxf(_half_w, _half_l) * 1.25)
	_paint_sand_look(id)
	Stage.dress_court(court, id)


	aim_indicator.net_mat = (net_visual.mesh as PlaneMesh).material as ShaderMaterial
	_apply_stage_env(id)
	_soften_compat_shadows()
	if _stage_painted.is_empty():
		return


	var look: = Stage.config(id)
	if look != null and look.has_method("apply"):
		look.apply(_stage_painted)



	var recolors: Dictionary = Stage.val(id, "recolors", {})
	for mname in recolors:
		for mat in _stage_painted.get(mname, []):
			var sm: = mat as ShaderMaterial
			sm.set_shader_parameter("albedo", recolors[mname])



			sm.set_shader_parameter("use_tex", false)






	var accents: Array = Stage.val(id, "accents", [])
	_last_accent = Color(0.85, 0.85, 0.85)
	_has_tape = false
	if accents.is_empty():
		return
	var pick: = absi(hash("school_accent:%d" % GameConfig.match_seed))
	_last_accent = accents[pick % accents.size()]
	var tapes: Array = Stage.val(id, "tape_by_accent", [])
	if not tapes.is_empty():
		_last_tape = tapes[pick % tapes.size()]
		_has_tape = true
	Stage.apply_school_accent(_stage_painted, court, id, _last_accent, 
		_last_tape if _has_tape else null, _wall_base)




func _apply_stage_env(id: String) -> void :
	var we: = $WorldEnvironment as WorldEnvironment
	var env: = we.environment.duplicate() as Environment
	if bool(Stage.val(id, "use_sky_color", false)):
		env.background_mode = Environment.BG_COLOR
		env.background_color = Stage.val(id, "sky_color", Color(0.5, 0.74, 0.95))


	if bool(Stage.val(id, "anime_sky", false)):
		env.background_mode = Environment.BG_SKY
		var sky: = Sky.new()
		var sky_mat: = ShaderMaterial.new()


		var custom_sky: Variant = Stage.val(id, "sky_shader", null)
		sky_mat.shader = custom_sky if custom_sky is Shader\
		else preload("res://game/court/anime_sky.gdshader")
		sky.sky_material = sky_mat





		env.sky = sky



	env.glow_enabled = bool(Stage.val(id, "bloom", false)) and GameConfig.bloom
	if env.glow_enabled:
		env.glow_intensity = 0.6
		env.glow_strength = 0.9



		env.glow_bloom = 0.0
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
		env.glow_hdr_threshold = 1.0




	env.fog_enabled = bool(Stage.val(id, "fog", false))
	if env.fog_enabled:
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_light_color = Stage.val(id, "fog_color", Color(0.02, 0.03, 0.05))
		env.fog_light_energy = 1.0
		env.fog_depth_begin = float(Stage.val(id, "fog_begin", 20.0))
		env.fog_depth_end = float(Stage.val(id, "fog_end", 65.0))
		env.fog_depth_curve = float(Stage.val(id, "fog_curve", 1.0))
		env.fog_density = 1.0
		env.fog_sky_affect = float(Stage.val(id, "fog_sky", 0.0))
		env.fog_aerial_perspective = 0.0





		var hd: = float(Stage.val(id, "fog_height_density", 0.0))
		env.fog_height = float(Stage.val(id, "fog_height", 0.0))
		env.fog_height_density = - hd


	if GameConfig.is_compatibility():
		env.adjustment_enabled = true
		env.adjustment_brightness = COMPAT_BRIGHTNESS
		env.adjustment_contrast = COMPAT_CONTRAST
		env.adjustment_saturation = COMPAT_SATURATION
	we.environment = env






func _soften_compat_shadows() -> void :
	if not GameConfig.is_compatibility():
		return
	for c in court.find_children("*", "MeshInstance3D", true, false):
		var mi: = c as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var mat: = mi.get_active_material(s) as ShaderMaterial
			if mat == null or mat.shader == null:
				continue
			var sp: = mat.shader.resource_path
			var mul: = -1.0
			if sp.ends_with("box_shadow.gdshader"):
				mul = COMPAT_BOX_SHADOW_MUL
			elif sp.ends_with("shadow_blob.gdshader"):
				mul = COMPAT_BLOB_SHADOW_MUL
			else:
				continue
			if bool(mat.get_meta("compat_softened", false)):
				continue
			var st: Variant = mat.get_shader_parameter("strength")
			mat.set_shader_parameter("strength", 
				(float(st) if st != null else 0.8) * mul)
			mat.set_meta("compat_softened", true)




func relight_stage() -> void :
	var id: String = GameConfig.stage\
	if Stage.STAGES.has(GameConfig.stage) else "nationals"
	Stage.config(id, true)
	_paint_stage_look(id)





func _own_name_visible(phase: int) -> bool:
	return GameConfig.show_own_name\
	or phase == Phase.INTRO or phase == Phase.COUNTDOWN\
	or phase == Phase.WIN or phase == Phase.STATS






func _apply_touch_highlight(lt: Player) -> void :

	if not GameConfig.touch_highlight or GameConfig.team_size <= 1:
		lt = null

	for p in _all_players:
		var b: Player = p
		if b == lt:



			b.set_highlight(Rules.side_color(_team_identity(b.team_side)))
		else:
			b.set_highlight(Color(0.0, 0.0, 0.0, 0.0))








func _apply_nametags() -> void :
	var my_team: = 0
	if player != null and not _spectating:
		my_team = player.team_side



	var phase: = _effective_phase()
	var reveal: = phase == Phase.DEAD or phase == Phase.SERVE_PREP\
	or phase == Phase.COUNTDOWN or phase == Phase.INTRO
	for p in _all_players:
		var body: Player = p
		var want: = String(_names.get(body, body.display_name()))
		if my_team != 0 and body != player and body.team_side != my_team\
		and not reveal:
			want = ""
		if body.display_name() != want:
			body.set_display_name(want)

func _update_indicators(input: PlayerInput) -> void :
	if not _spectating and player != null:
		player.set_name_visible(_own_name_visible(_phase))
		player.set_first_person(
			camera_rig.mode == CameraRig.Mode.FIRST_PERSON)
	_apply_touch_highlight(_last_toucher if _phase == Phase.LIVE else null)
	_apply_nametags()
	if _phase == Phase.REPLAY:



		hud.set_scoreboard_visible( not _spectating or _spec_ui)
		_present_replay(get_physics_process_delta_time())
		return
	if _phase != Phase.DEAD and _phase != Phase.SERVE_PREP and _phase != Phase.LIVE:
		_diss_left = 0.0
		_cine_present(_phase, _cine_time)
		return
	_tick_dissolve(get_physics_process_delta_time())







	hud.set_scoreboard_visible( not _spectating or _spec_ui)
	hud.set_play_hud_visible( not _spectating)
	var ball_side: = signf(ball.global_position.z)
	if ball_side != 0.0:
		camera_rig.possession = ball_side



	camera_rig.focus_boost = 0.0
	var ally_serving: = _server != null and _server.team_side == player.team_side
	if _phase == Phase.SERVE_PREP:
		camera_rig.focus_boost = 1.0 if ally_serving else 0.25
	elif _phase == Phase.LIVE and ally_serving and not _serve_crossed\
	and ball.global_position.z * player.team_side\
	> player.global_position.z * player.team_side:
		camera_rig.focus_boost = 1.0
	var free: = camera_rig.mode == CameraRig.Mode.ACTION or camera_rig.mode == CameraRig.Mode.FIRST_PERSON



	aim_indicator.visible = not free and not _spectating
	var aim_ib: = absf(input.aim.x) <= _half_w and absf(input.aim.z) <= _half_l
	if not _spectating:
		aim_indicator.aim_at(input.aim, float(player.team_side), aim_ib, 
			camera_rig.shake_offset)
	_update_barred_marker(_rally_live and not _spectating)
	player.serve_charge_ui = _phase == Phase.SERVE_PREP and _server == player\
	and not _spectating

	camera_rig.serve_view = _server == player and not _spectating\
	and (_phase == Phase.SERVE_PREP\
	or (_phase == Phase.LIVE and not _serve_done))
	hud.set_crosshair_visible(free and not _spectating)
	hud.set_crosshair_side(input.aim.z, aim_ib)
	hud.set_touches(_touch_count)
	hud.set_dive(player.dive_cooldown)








	var h: = _team_identity(1)
	hud.set_score_colors(1)
	hud.set_score(_scores[h], _scores[ - h], 
		_set_wins[h], _set_wins[ - h], _set_number)
	hud.set_serve_prompt(_serve_prompt(), 
		_phase == Phase.SERVE_PREP and _server == player, _serve_clock)



	var zsrv: Player = _server if GameConfig.debug_serve_zones\
	else (player if _server == player and not _spectating else null)
	_serve_zone.tick(_phase == Phase.SERVE_PREP and zsrv != null, 
		float(zsrv.team_side) if zsrv != null else 1.0, 
		zsrv != null and _rally.in_safe_serve_spot(zsrv))
	if GameConfig.show_cam_debug:
		hud.set_net_info(camera_rig.debug_line())
	elif _net_role == NetRole.OFFLINE:
		hud.set_net_info("")
	_update_controls(_phase == Phase.SERVE_PREP and _server == player)

	hud.update_state(player)

func _update_indicators_client(input: PlayerInput) -> void :

	var phase: = int(_np.get("ph", Phase.DEAD))



	_set_number = int(_np.get("sn", _set_number))
	Rules.set_swapped = _set_number % 2 == 0


	var srv_body: Player = _by_net_id.get(int(_np.get("sv", 0)))
	var zsrv: Player = srv_body if GameConfig.debug_serve_zones\
	else (player if srv_body == player and not _spectating else null)
	_serve_zone.tick(phase == Phase.SERVE_PREP and zsrv != null, 
		float(zsrv.team_side) if zsrv != null else 1.0, 
		zsrv != null and _rally.in_safe_serve_spot(zsrv))
	if not _spectating and player != null:
		player.set_name_visible(_own_name_visible(phase))
		player.set_first_person(
			camera_rig.mode == CameraRig.Mode.FIRST_PERSON)



	_apply_nametags()
	_apply_touch_highlight(_by_net_id.get(int(_np.get("lt", 0)))\
	if phase == Phase.LIVE else null)
	if phase != Phase.DEAD and phase != Phase.SERVE_PREP and phase != Phase.LIVE:

		if phase != _cine_prev_phase:
			_cine_time = 0.0
			if phase == Phase.INTRO:
				_grabbed_home = false
			elif _cine_prev_phase == Phase.INTRO and not _loading_up:
				hud.set_loading(0.0)





			if (phase == Phase.COUNTDOWN or phase == Phase.WIN)\
			and not _loading_up and not MIGRATION_COVER.is_up():
				hud.grab_dissolve()
			else:
				hud.set_dissolve(0.0)
			if phase != Phase.STATS:
				_stats_built = false
		_cine_time += get_physics_process_delta_time()
		_cine_prev_phase = phase
		_diss_left = 0.0
		player.cinematic_hidden = true

		ball.visible = phase == Phase.COUNTDOWN
		if phase == Phase.COUNTDOWN:


			_pre_intro = false
		_cine_present(phase, _cine_time)
		return
	if _cine_prev_phase == Phase.STATS or _cine_prev_phase == Phase.WIN:
		hud.hide_match_stats()
		hud.hide_cine_name()
	if _cine_prev_phase == Phase.COUNTDOWN or _cine_prev_phase == Phase.INTRO:



		hud.hide_countdown()
		hud.hide_cine_name()






		if _diss_left <= 0.0:
			hud.set_dissolve(0.0)
		if not _loading_up:
			hud.set_loading(0.0)
	_cine_prev_phase = phase
	_tick_dissolve(get_physics_process_delta_time())
	player.cinematic_hidden = false


	ball.visible = not _pre_intro



	hud.set_scoreboard_visible( not _spectating or _spec_ui)
	hud.set_play_hud_visible( not _spectating)
	var server: Player = _by_net_id.get(int(_np.get("sv", 0)))
	var ball_side: = signf(ball.global_position.z)
	if ball_side != 0.0:
		camera_rig.possession = ball_side
	camera_rig.focus_boost = 0.0
	var ally_serving: = server != null and server.team_side == player.team_side
	if phase == Phase.SERVE_PREP:
		camera_rig.focus_boost = 1.0 if ally_serving else 0.25
	elif phase == Phase.LIVE and ally_serving\
	and ball.global_position.z * player.team_side\
	> player.global_position.z * player.team_side:
		camera_rig.focus_boost = 1.0
	var free: = camera_rig.mode == CameraRig.Mode.ACTION or camera_rig.mode == CameraRig.Mode.FIRST_PERSON







	aim_indicator.visible = not free and not _spectating and not _ball_dead
	var caim_ib: = absf(input.aim.x) <= _half_w and absf(input.aim.z) <= _half_l
	if not _spectating:
		aim_indicator.aim_at(input.aim, float(player.team_side), caim_ib, 
			camera_rig.shake_offset)
	_update_barred_marker(_rally_live and not _spectating)
	player.serve_charge_ui = phase == Phase.SERVE_PREP and server == player\
	and not _spectating
	camera_rig.serve_view = server == player and not _spectating\
	and (phase == Phase.SERVE_PREP\
	or (phase == Phase.LIVE and not bool(_np.get("sd", true))))
	hud.set_crosshair_visible(free and not _spectating)
	hud.set_crosshair_side(input.aim.z, caim_ib)
	hud.set_touches(int(_np.get("tc", 0)))
	hud.set_dive(player.dive_cooldown)
	var s1: = int(_np.get("s1", 0))
	var s2: = int(_np.get("s2", 0))
	var w1: = int(_np.get("w1", 0))
	var w2: = int(_np.get("w2", 0))
	var sn: = int(_np.get("sn", 1))




	var h: = _team_identity(1, sn)
	hud.set_score_colors(1)
	if h > 0:
		hud.set_score(s1, s2, w1, w2, sn)
	else:
		hud.set_score(s2, s1, w2, w1, sn)
	hud.set_serve_prompt("spectating: c changes camera" if _spectating\
	else _client_serve_prompt(phase, server), 
		phase == Phase.SERVE_PREP and server == player and not _spectating, 
		float(_np.get("sc", 0.0)))

	hud.update_state(player)
	_update_controls(phase == Phase.SERVE_PREP and server == player\
	and not _spectating)











func _update_barred_marker(live: bool) -> void :
	var barred: = live and player.touch_barred_self
	barred_marker.visible = barred
	ball.landing_ring_muted = barred
	if barred:



		barred_marker.global_position = Vector3(ball.global_position.x, 
			maxf(0.03, SandDeform.decal_y), ball.global_position.z)

func _update_controls(serving: bool) -> void :


	hud.refresh_controls(player, serving)

func _client_serve_prompt(phase: int, server: Player) -> String:
	if phase != Phase.SERVE_PREP or server == null:
		return ""
	var clock: = float(_np.get("sc", 0.0))
	if server != player:
		return "%s serving   %0.0f" % [_names[server], clock]
	if not _in_serve_zone(player):
		return "return to serve zone   %0.0f" % clock
	return "your serve   hold to toss   %0.0f" % clock

func _serve_prompt() -> String:
	if _phase != Phase.SERVE_PREP:
		return ""
	if _server != player:
		return "%s serving   %0.0f" % [_names[_server], _serve_clock]
	if not _in_serve_zone(player):
		return "return to serve zone   %0.0f" % _serve_clock
	return "your serve   hold to toss   %0.0f" % _serve_clock

func _poll_stats_input() -> void :



	if hud == null:
		return
	if _match_over or _migrating or hud.pause_is_open():
		hud.hide_stats()
		return
	if Input.is_action_pressed("stats"):
		var rows: Array = _stat_rows() if _net_role != NetRole.CLIENT\
		else hud.stored_stat_rows()
		hud.show_stats(rows)
	elif Input.is_action_just_released("stats"):
		hud.hide_stats()

func _stat_rows() -> Array:




	var pm: Array = Net.party_members()
	var pm_set: = {}
	for pid in pm:
		pm_set[pid] = true
	var multi_party: bool = pm.size() >= 2
	var body_peer: = {}
	if not _spectating:
		body_peer[player] = 1
	for peer_id in _peer_players:
		body_peer[_peer_players[peer_id]] = peer_id
	var rows: Array = []
	for p in _all_players:
		var member: Player = p


		var s: Dictionary = _stats.get(member, {})
		var row_name: = String(_names.get(member, ""))
		var pgroup: = 0
		if multi_party and body_peer.has(member)\
		and pm_set.has(body_peer[member]):
			pgroup = 1




		if _net_role == NetRole.HOST and _is_own_body(member):
			pass




		var mpeer: = int(body_peer.get(member, 0))
		var mping: = -2
		if mpeer == 1:
			mping = -1

		elif mpeer > 1:
			mping = int(round(Net.peer_rtt_ms(mpeer)))
		rows.append({
			"name": row_name, "ready_name": String(_names.get(member, "")), 
			"pts": int(s.get("pts", 0)), "spk": int(s.get("spk", 0)), 
			"blk": int(s.get("blk", 0)), 
			"rcv": int(s.get("rcv", 0)), "set": int(s.get("set", 0)), 
			"ast": int(s.get("ast", 0)), 
			"side": _team_identity(member.team_side), 
			"party": pgroup, 
			"peer": mpeer, "ping": mping, 
			"cfg": member.character.to_dict() if member.character != null else {}, 
		})

	return rows
