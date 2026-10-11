extends Node3D













const SETTINGS_PANEL: = preload("res://game/ui/settings_panel.tscn")


const FEEDBACK_FORM_URL: = "https://forms.gle/nPmZ17h2BVBAKbDy7"
const HOW_TO_PLAY: = preload("res://game/ui/how_to_play.tscn")
const HUD_SCENE: = preload("res://game/ui/hud.tscn")
const PLAYER_SCENE: = preload("res://game/player/player.tscn")
const BALL_SCENE: = preload("res://game/ball/ball.tscn")
const COURT_SCENE: = preload("res://game/court/court.tscn")
const LOGO: = preload("res://game/logo/jvlogo_sd.png")


const SWEAT_RATES: = [0.0, 1.0, 3.0, 8.0]
const SWEAT_RATE_NAMES: = ["off", "normal", "fast", "chaos"]
const COURT_HW: = 7.6
const COURT_HL: = 13.6
const HALL_X: = 17.0
const HALL_Z: = 21.0
const HOME_SPOT: = Vector3(6.3, 0.0, 9.2)
const DIFF_NAMES: = ["cpu: easy", "cpu: normal", "cpu: hard"]
const OUTFITS: = ["gym", "home", "away"]


const BALL_SKINS: = ["nationals", "school", "beach"]
const BALL_LABELS: = {"nationals": "pro", "school": "school", "beach": "outdoor"}



const PARTY_SPOTS: = [
	Vector3(0.0, 0.0, 0.0), 
	Vector3(-1.7, 0.0, 0.0), 
	Vector3(-3.2, 0.0, -0.3), 
	Vector3(-0.9, 0.0, -1.6), 
	Vector3(-2.4, 0.0, -1.8), 
	Vector3(-3.9, 0.0, -1.4), 
]

@onready var menu_cam: Camera3D = $MenuCam
@onready var camera_rig: CameraRig = $CameraRig
@onready var ui: CanvasLayer = $Ui

var player: Player = null
var ball: Ball = null
var fx: Fx = null
var sfx: Sfx = null
var hud: Hud = null
var _chat: ChatPanel = null
var aim_indicator: AimMarker = null
var _menu_net_mat: ShaderMaterial = null
var reach_marker: ReachMarker = null
var _floor_mat: ShaderMaterial = null
var _foley: = Foley.new()
var _input_collector: = InputCollector.new()

var _local_guests: Array = []



const LOCAL_COOP_DROPIN: = false
var _freeplay: = false
var _serving: = false
var _aim_at_cam: = Vector3.ZERO
var _base_yaw: = 0.0
var _spin: = 0.0
var _dragging: = false
var _outfit: = "gym"
var _ball_skin: = "nationals"
var _freeplay_stage: = "nationals"
var _arena_nodes: Array[Node] = []
var _stage_btn: Button = null
var _reflector = null
var _sand_deform: SandDeform = null
var _swapping_stage: = false

var _root: Control = null
var _home: Control = null
var _online: Control = null
var _local: Control = null
var _practice: Control = null
var _drills: Control = null
var _profile: Control = null
var _achievements: Control = null
var _awards_tab: Button = null
var _awards_badge: Label = null
var _ach_new: Array = []
var _ach_tab_kinds: = ["daily", "weekly", "global", ""]
var _ach_tab_badges: Array = []
var _profile_pfp: TextureRect = null
var _recent: Control = null
var _custom: Control = null
var _settings: Control = null
var _howto: Control = null


var _browse: Control = null
var _host: Control = null
var _room: Control = null
var _direct: Control = null
var _fp_hint: Control = null
var _quick: Control = null
var _qp: QuickPlay = null
var _mm_label: Label = null
var _mm_cancel: Button = null
var _quick_chips: = {}
var _quick_any: Button = null
var _quick_fresh: CheckBox = null
var _top_panel: Control = null
var _bottom_panel: PanelContainer = null
var _bar_normal: StyleBoxFlat = null
var _bar_green: StyleBoxFlat = null
var _steam_pill: Label = null
var _mm_title: Label = null
var _mm_chip: PanelContainer = null
var _mm_chip_label: Label = null



var _pc_avatar: TextureRect = null
var _pc_name: Label = null
var _pc_level: Label = null
var _pc_xp: ProgressBar = null
var _pc_xp_text: Label = null
var _pc_coins: Label = null
var _pc_div: Panel = null
var _member_queuing: = false
var _friends_btn: Button = null
var _friends_panel: PanelContainer = null
var _friends_list: VBoxContainer = null
var _friends_scrim: Control = null
var _invited_ids: = {}
var _friends_poll: = 0.0


var _tilt: Array = []


var _lean: Array = []
var _top_strip: Panel = null
var _bottom_strip: Panel = null
var _logo_rect: TextureRect = null
var _tilt_fake: = 0.0
var _cam_side_target: = 1.0
var _cam_look_now: = Vector3.ZERO

var _steam_up: = false
var _browse_hint: Label = null
var _browse_list: VBoxContainer = null

var _bw_search: LineEdit = null
var _bw_code: LineEdit = null
var _bw_region: UiSelect = null
var _bw_sort: UiSelect = null
var _bw_full: CheckBox = null
var _bw_friends: CheckBox = null
var _bw_auto: CheckBox = null
var _bw_rows: Array = []
var _bw_auto_t: = 0.0

const BW_REGIONS: = ["closest", "nearby", "far", "worldwide"]
const BW_REGION_MS: = [70, 140, 260, 1000000]
var _side_btns: Dictionary = {}
var _side_tell: Label = null
var _blue_list: VBoxContainer = null
var _red_list: VBoxContainer = null
var _spec_list: VBoxContainer = null
var _size_opt: UiSelect = null
var _diff_opt: UiSelect = null
var _stage_opt: UiSelect = null
var _start_btn: Button = null
var _room_hint: Label = null

var _room_sets: UiSelect = null
var _room_points: SpinBox = null
var _room_wbt: CheckBox = null
var _room_sweat: CheckBox = null
var _room_rate: UiSelect = null
var _priv_opt: UiSelect = null
var _max_players_opt: UiSelect = null


const MAX_PLAYER_CHOICES: = [2, 4, 6, 8, 10, 12]
var _settings_panel: SettingsPanel = null
var _settings_title: Label = null
var _pw_edit: LineEdit = null
var _host_status: Label = null
var _host_online_card: Control = null
var _host_steam_card: Control = null
var _ip_edit: LineEdit = null
var _direct_pw: LineEdit = null
var _direct_status: Label = null
var _pw_panel: PanelContainer = null
var _joining_live: = false
var _online_ready: = false
var _web_join_consumed := false
var _party_strip: HBoxContainer = null
var _party_was_open: = false




var _top_bar: HBoxContainer = null
var _bottom_bar: HBoxContainer = null
var _zone_cd: = 0.0


var _card_local: Button = null
var _card_custom_lobby: Button = null
var _card_direct: Button = null
var _replays_tab: Button = null

var _party_bodies: = {}
var _party_balls: = {}



var _ball_driver: = {}




const SHARED_BALLS: = false
var _party_outfit: = {}
var _party_ball_skin: = {}
var _party_in_freeplay: = {}
var _fake_party_n: = 0
var _party_puppets: = NetSync.PuppetBuffer.new()
var _party_ball_buf: = NetSync.BallBuffer.new()
var _party_seen: = {}

var _reform_target: = {}
var _reform_left: = 0.0

var _server_join: = {}
var _server_join_t: = 0.0



var _in_party_room: = false


const PARTY_RELAY_FLUSH: = 0.35
var _fp_send_tick: = 0
var _drill_runner: DrillRunner = null
var _drill_progress: = DrillProgress.new()
var _drill_active: = ""
var _drill_hud: PanelContainer = null
var _drill_title: Label = null
var _drill_instruction: Label = null
var _drill_count: Label = null
var _drill_timer: Label = null
var _drill_info: PanelContainer = null
var _drill_info_body: VBoxContainer = null
var _drill_results: PanelContainer = null
var _drill_result_time: Label = null
var _drill_next: Button = null



const GUIDED_PATH: = ["movement", "receiving_1", "setting_1", "spiking_1"]
var _guided: = false
var _tutorial = null
const TUTORIAL_DIRECTOR: = preload("res://game/drills/tutorial_director.gd")
const TUTORIAL_OVERLAY: = preload("res://game/ui/tutorial_overlay.gd")
const DRILL_DIRECTOR: = preload("res://game/drills/drill_director.gd")

var _drill_director = null
var _drill_overlay: Control = null
var _drill_rows: = {}
var _drill_tabs: = {}
var _drill_list: VBoxContainer = null
var _drill_category: = "movement"
var _drill_return_stage: = ""

func _ready() -> void :


	if not GameConfig.pre_tutorial_settings.is_empty():
		var r: Dictionary = GameConfig.pre_tutorial_settings
		GameConfig.stage = String(r.get("stage", GameConfig.stage))
		GameConfig.difficulty = int(r.get("difficulty", GameConfig.difficulty))
		GameConfig.team_size = int(r.get("team_size", GameConfig.team_size))
		GameConfig.set_points = int(r.get("set_points", GameConfig.set_points))
		GameConfig.sets_to_win = int(r.get("sets_to_win", GameConfig.sets_to_win))
		GameConfig.win_by_two = bool(r.get("win_by_two", GameConfig.win_by_two))
		GameConfig.local_side = int(r.get("local_side", GameConfig.local_side))
		GameConfig.simple_bot_serves = false
		GameConfig.tutorial_finale = false
		GameConfig.pre_tutorial_settings = {}


	var bubbles: = ChatBubbles.new( func():
		var out: Array = _party_bodies.values()
		if player != null:
			out.append(player)
		return out, func(): return player, 
		func(): return _freeplay, 


		func(pid: int):
			if pid == _my_party_id():
				return player
			return _party_bodies.get(pid, null))
	add_child(bubbles)
	if "--bubble-demo" in OS.get_cmdline_user_args():
		_bubble_demo.call_deferred()
	GameConfig.use_cursor(false)
	Rules.set_swapped = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not InputPrompts.changed.is_connected(_on_input_device_changed):
		InputPrompts.changed.connect(_on_input_device_changed)
	GameConfig.net_roster = []



	MusicManager.play("menu")
	MusicManager.set_muffled(false)
	MusicManager.unduck()
	if GameConfig.menu_outfit in OUTFITS:
		_outfit = GameConfig.menu_outfit
	if GameConfig.menu_ball in BALL_SKINS:
		_ball_skin = GameConfig.menu_ball
	if Stage.STAGES.has(GameConfig.freeplay_stage):
		_freeplay_stage = GameConfig.freeplay_stage
	# Warm the match scene (and the venue it will load) during the lobby
	# dwell: the play-button wipe then swaps from memory instead of paying
	# the synchronous load under solid yellow.
	GameConfig.preload_scene("res://game/main/main.tscn")
	GameConfig.preload_venue(GameConfig.stage)
	_build_arena()
	_build_player()
	_build_ui()
	_drill_progress.load_local()
	_refresh_drill_rows()

	if GameConfig.lobby_notice != "":
		_flash_notice(GameConfig.lobby_notice)
		GameConfig.lobby_notice = ""


	Achievements.unlocked.connect(_on_achievement_moved)
	Achievements.progressed.connect(_on_achievement_moved)
	Achievements.unseen_changed.connect( func(_n: int): _refresh_awards_badge())
	ProfileStore.changed.connect(_refresh_awards_badge)
	_refresh_awards_badge()





	_maybe_resume_home_party()



	if Net.active and Net.players.size() > 0 and not Net.party:
		_show_room()


	elif GameConfig.menu_return_local:
		GameConfig.menu_return_local = false
		_populate_local()
		_show(_local)



	if Net.active:
		Net.send_party_look(_outfit)
		Net.send_party_ball(_ball_skin)


	var uargs: = OS.get_cmdline_user_args()
	if "--party-host" in uargs:




		( func():
			Net.host_party("host", true)
			_refresh_party_strip()).call_deferred()
	var pj: = uargs.find("--party-join")
	if pj != -1:
		var ip: = "127.0.0.1"
		if pj + 1 < uargs.size() and not String(uargs[pj + 1]).begins_with("--"):
			ip = String(uargs[pj + 1])
		Net.join_game.call_deferred(ip, "guest %d" % (randi() % 100))


	if "--freeplay" in uargs and not ("--shot" in uargs):
		_enter_freeplay()
		if "--fp-offset" in uargs:
			player.global_position = HOME_SPOT + Vector3(3.2, 0.0, -2.5)
	var drill_arg: = uargs.find("--drill")
	if drill_arg != -1 and drill_arg + 1 < uargs.size():
		_start_drill(String(uargs[drill_arg + 1]))


	var bf: = uargs.find("--browse-fake")
	if bf != -1:
		var n: = 50
		if bf + 1 < uargs.size() and String(uargs[bf + 1]).is_valid_int():
			n = int(uargs[bf + 1])
		_browse_fake.call_deferred(n)


	if "--quick-probe" in uargs:
		(load("res://game/dev/quick_probe.gd") as GDScript).maybe_spawn(get_tree())
	if "--party-probe" in uargs:
		(load("res://game/dev/party_probe.gd") as GDScript).maybe_spawn(get_tree())
	if "--travel-probe" in uargs:
		(load("res://game/dev/travel_probe.gd") as GDScript).maybe_spawn(get_tree())
	var pl: = uargs.find("--party-launch")
	if pl != -1:
		var sz: = 2
		if pl + 1 < uargs.size() and uargs[pl + 1].is_valid_int():
			sz = int(uargs[pl + 1])
		get_tree().create_timer(3.5).timeout.connect( func(): _go_to_match(sz))


	var pqueue: = uargs.find("--party-queue")
	if pqueue != -1:
		var sz: = 2
		if pqueue + 1 < uargs.size() and uargs[pqueue + 1].is_valid_int():
			sz = int(uargs[pqueue + 1])
		_qp.force_lan = true
		_qp.soft_fill_after = 4.0




		_party_queue_when_formed(sz, 10.0)


	var fkp: = uargs.find("--fake-party")
	if fkp != -1:
		var n: = 6
		if fkp + 1 < uargs.size() and uargs[fkp + 1].is_valid_int():
			n = int(uargs[fkp + 1])
		_fake_party_n = n
		if _friends_btn != null:
			_friends_btn.visible = true


		if _party_strip != null:
			for c in _party_strip.get_children():
				c.queue_free()
			_party_strip.add_child(_party_disc("singleplayer", UiStyle.PRIMARY, 
				"you", Callable(), true))
			for m in range(1, n):
				_party_strip.add_child(_party_disc("singleplayer", 
					UiStyle.SECONDARY, "member", Callable()))
			var db: = Button.new()
			db.text = "disband"
			UiStyle.style_button(db, "tertiary", 13)
			db.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			_party_strip.add_child(db)
		for slot in range(1, mini(n, PARTY_SPOTS.size())):
			var d: Player = PLAYER_SCENE.instantiate()
			add_child(d)
			d.net_puppet = true
			d.sim_authority = false
			d.collision_layer = 0
			d.collision_mask = 0
			d.charge_ui_enabled = false
			d.indicator_enabled = false
			d.set_character(GameConfig.character.gym_look(), 
				GameConfig.character.gym_kit())
			d.set_name_visible(false)
			d.global_position = HOME_SPOT + PARTY_SPOTS[slot]
			var db: Ball = BALL_SCENE.instantiate()
			db.stage_ball = "nationals"
			db.net_puppet = true
			db.show_landing_ring = false
			add_child(db)
			db.global_position = HOME_SPOT + PARTY_SPOTS[slot]\
			+ Vector3(-0.45, 0.4, 0.5)




	if "--onboard" in OS.get_cmdline_user_args():
		_offer_tutorial.call_deferred(true)
	elif OS.get_cmdline_user_args().is_empty() and not Net.active\
	and not GameConfig.tutorial_seen:
		_offer_tutorial.call_deferred()
	if "--menu-quick" in OS.get_cmdline_user_args():

		(load("res://game/dev/quick_probe.gd") as GDScript).maybe_spawn(get_tree())
		_qp.force_lan = true
		_quick_any.set_pressed_no_signal(true)
		_find_quick()






	if OS.get_cmdline_user_args().is_empty() and not Net.active:
		_prewarm_local_faces.call_deferred()
	var args: = OS.get_cmdline_user_args()
	if "--shot" in args:

		var page: = "home"
		var at: = args.find("--shot")
		if at + 1 < args.size() and not String(args[at + 1]).begins_with("--"):
			page = String(args[at + 1])
		match page:
			"online": _show(_online)
			"local":
				_populate_local()
				_show(_local)
			"lobby1", "lobby2", "lobby3", "lobby4", "lobby5", "lobby6":
				_show(_local)
				_on_local_rule("size", int(page.substr(5)))
			"lobby-drop":
				_show(_local)
				_on_local_rule("size", 4)
				await get_tree().create_timer(0.4).timeout
				_local_panel.rules.open_select("size")
			"practice": _show(_practice)
			"drills": _open_drills()
			"drillrun":

				_show(_practice)
				await get_tree().create_timer(0.1).timeout
				_start_drill("spiking_1")
			"quick": _show(_quick)
			"profile": _show(_profile)
			"achievements": _show_achievements()
			"custom": _open_custom()
			"settings": _open_settings(SettingsPanel.Scope.SYSTEM)
			"profile-settings": _open_settings(SettingsPanel.Scope.PROFILE)
			"howto": _show(_howto)
			"browse": _show(_browse)
			"host": _show(_host)
			"direct": _show(_direct)
			"room":
				Net.host_game("host")
				Net.custom_lobby = true
				if "--big" in args:
					Net.set_team_size(6)


				if "--fill" in args:
					for i in range(2, 7):
						Net.players[i] = {"name": "friend %d" % i, 
							"cfg": Net.local_character_dict(), 
							"side": [1, -1, 1, 0, -1][i - 2]}
				_show_room()
				if "--big" in args or "--fill" in args:
					await get_tree().create_timer(0.3).timeout
					_refresh_room()
			"party":
				Net.host_party("host", true)
				_refresh_party_strip()
				_show(_home)
			"freeplay":


				_enter_freeplay()
		var wait: = 0.16 if "--early" in args else 1.4
		if page == "freeplay":
			wait = 2.2
		if page.begins_with("lobby") or page == "room":
			wait = 3.0
		if page == "drillrun":
			wait = 6.0

		get_tree().create_timer(12.0).timeout.connect( func(): get_tree().quit())
		await get_tree().create_timer(wait).timeout
		if "--trail" in args:

			var c: = get_viewport().get_visible_rect().size * 0.5
			for i in 18:
				var ang: = -1.6 + float(i) * 0.13
				Input.warp_mouse(c + Vector2(cos(ang), sin(ang)) * 260.0)
				await get_tree().process_frame
		get_viewport().get_texture().get_image()\
		.save_png("res://game/dev/shots/menu_%s.png" % page)
		get_tree().quit()



func _build_arena() -> void :

	_build_stage_arena()
	fx = Fx.new()
	add_child(fx)
	sfx = Sfx.new()
	add_child(sfx)



func _build_stage_arena() -> void :
	var id: = _freeplay_stage




	_foley.surface = String(Stage.val(id, "surface", "court"))
	Stage.apply_reverb(id)

	_foley.water_x = float(Stage.val(id, "water_x", INF))
	_foley.water_side = float(Stage.val(id, "water_side", 1.0))
	_apply_freeplay_env(id)
	var shell: = (load(String(Stage.info(id).venue))\
	as PackedScene).instantiate()
	add_child(shell)
	_arena_nodes.append(shell)






	for piece in shell.get_children():
		if piece.has_method("configure"):
			piece.call("configure", COURT_HW, COURT_HL)



	var painted: = {}
	var gym: = shell.get_node_or_null("Gym")
	if bool(Stage.val(id, "hand_painted", false)) and gym != null:
		for node in gym.find_children("*", "MeshInstance3D", true, false):
			if String(node.name).to_lower().contains("cutter"):
				(node as Node3D).visible = false
		painted = (preload("res://game/court/env_paint.gd") as GDScript).apply(gym, 
			Stage.val(id, "emissive_mats", {}))
	var court: Node3D = COURT_SCENE.instantiate()
	add_child(court)
	_arena_nodes.append(court)
	court.scale = Vector3(COURT_HW / 4.5, 1.0, COURT_HL / 9.0)
	CourtDress.unique_net(court.get_node("Net"), court.scale.x)
	_floor_mat = CourtDress.unique_floor(court)




	if bool(Stage.val(id, "owns_floor", false)):
		var cf: = court.get_node_or_null("CourtFloor") as MeshInstance3D
		if cf != null:
			if bool(Stage.val(id, "mirror_overlay", false)):




				_floor_mat.shader = load("res://game/court/floor_overlay.gdshader")
				cf.position.y += 0.06
			else:
				cf.visible = false
	_floor_mat.set_shader_parameter("base_color", 
		Stage.val(id, "floor_color", Color(0.85, 0.5, 0.25)))
	_floor_mat.set_shader_parameter("reflect_on", false)


	_floor_mat.set_shader_parameter("pool_strength", float(Stage.val(id, "pool_strength", 0.0)))
	_floor_mat.set_shader_parameter("floor_vignette", float(Stage.val(id, "floor_vignette", 0.0)))
	_floor_mat.set_shader_parameter("pool_warm", Color(1.0, 0.9, 0.72))

	_floor_mat.set_shader_parameter("checker_size", float(Stage.val(id, "checker_size", 0.0)))
	_floor_mat.set_shader_parameter("checker_color", 
		Stage.val(id, "checker_color", Color(0.66, 0.67, 0.69)))
	_floor_mat.set_shader_parameter("pool_radius", maxf(COURT_HW, COURT_HL) * 1.25)
	Stage.dress_court(court, id)



	var _net_node: = court.get_node_or_null("Net") as MeshInstance3D
	if _net_node != null:
		_menu_net_mat = (_net_node.mesh as PlaneMesh).material as ShaderMaterial
		if aim_indicator != null:
			aim_indicator.net_mat = _menu_net_mat






	_sand_deform = null
	SandDeform.decal_y = 0.0
	SandDeform.decal_y_feet = 0.0
	var sand: = SandDeform.build(self, id, shell, court, COURT_HW, COURT_HL, 
		func(): return [player] + _party_live_bodies(), 
		func(): return ball)
	if not sand.is_empty():
		_sand_deform = sand.get("deform")
		_arena_nodes.append(_sand_deform)
		_arena_nodes.append(sand.get("deck"))





	for piece in shell.find_children("*", "Node3D", true, false):
		if piece.has_method("set_feeds"):
			piece.set_feeds( func(): return [player] + _party_live_bodies(), 
				func(): return ball)
		if piece.has_method("wire_reflection") and _reflector != null:
			piece.wire_reflection(_reflector.texture())


			if piece.has_method("indicator_clearance_y"):
				SandDeform.decal_y = piece.indicator_clearance_y()
				SandDeform.decal_y_feet = piece.indicator_feet_y()




	var cbox: Vector3 = Stage.val(id, "collision_box", Vector3.ZERO)
	var has_dome: = cbox != Vector3.ZERO and bool(Stage.val(id, "force_wall", false))
	if cbox != Vector3.ZERO:
		var sc: = preload("res://game/stage/stage_collision.gd") as GDScript
		if has_dome:
			sc.build_ring(shell, cbox)
		else:
			sc.build_box(shell, cbox)
	if has_dome:
		var dome: Node3D = (preload("res://game/court/force_dome.gd") as GDScript).new()
		add_child(dome)
		_arena_nodes.append(dome)
		dome.build(cbox, Stage.val(id, "force_wall_color", Color(0.28, 0.62, 1.0)))




	if not painted.is_empty():
		var look: = Stage.config(id)
		if look != null and look.has_method("apply"):
			look.apply(painted)




		for mats in painted.values():
			for m in mats:
				var sm: = m as ShaderMaterial
				if sm == null:
					continue
				sm.set_shader_parameter("ambient", 0.6)
				sm.set_shader_parameter("focus_dim", 0.32)
				sm.set_shader_parameter("haze_amt", 0.16)




		var accents: Array = Stage.val(id, "accents", [])
		if not accents.is_empty():
			var pick: = absi(hash("school_accent:%s:%d" % [id, GameConfig.match_seed]))
			var tapes: Array = Stage.val(id, "tape_by_accent", [])
			Stage.apply_school_accent(painted, court, id, accents[pick % accents.size()], 
				tapes[pick % tapes.size()] if not tapes.is_empty() else null, {})
		var recolors: Dictionary = Stage.val(id, "recolors", {})




		var seat_lift: Dictionary = {
			"SeatShader": true, "CourtSeatShader": true, 
			"BlackCarpetShader": true, "RedCarpetShader": true, 
		}
		for mname in recolors:
			var col: Color = recolors[mname]
			if seat_lift.has(mname):
				col = col.lightened(0.12)
			for mat in painted.get(mname, []):
				var sm: = mat as ShaderMaterial
				sm.set_shader_parameter("albedo", col)
				sm.set_shader_parameter("use_tex", false)

	for z in [-5.0, 5.0]:
		var light: = OmniLight3D.new()
		light.position = Vector3(0.0, 7.0, z)
		light.light_energy = 1.3
		light.light_color = Color(1, 0.96, 0.88)
		light.omni_range = 24.0
		add_child(light)
		_arena_nodes.append(light)


	_wire_floor_reflection(id)




func _swap_stage(id: String, broadcast: = true, persist: = true, force: = false) -> void :


	if _swapping_stage or (Net.party and not force) or not Stage.STAGES.has(id)\
	or id == _freeplay_stage:
		return
	_swapping_stage = true


	_freeplay_stage = id
	for n in _arena_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_arena_nodes.clear()
	_build_stage_arena()
	if _stage_btn != null:
		_stage_btn.text = "stage: %s" % Stage.title(id).to_lower()
	if persist:
		GameConfig.freeplay_stage = id
		GameConfig.save_settings()
	if broadcast:
		Net.send_party_stage(id)
	_swapping_stage = false

func _on_party_stage(id: String) -> void :


	_swap_stage(id, false, false)




func _apply_freeplay_env(id: String) -> void :
	var we: = $WorldEnvironment as WorldEnvironment
	if we == null:
		return
	var env: = we.environment.duplicate() as Environment
	if bool(Stage.val(id, "anime_sky", false)):
		env.background_mode = Environment.BG_SKY
		var sky: = Sky.new()
		var sky_mat: = ShaderMaterial.new()
		var custom_sky: Variant = Stage.val(id, "sky_shader", null)
		sky_mat.shader = custom_sky if custom_sky is Shader\
		else preload("res://game/court/anime_sky.gdshader")
		sky.sky_material = sky_mat



		env.sky = sky
	elif bool(Stage.val(id, "use_sky_color", false)):
		env.background_mode = Environment.BG_COLOR
		env.background_color = Stage.val(id, "sky_color", Color(0.5, 0.74, 0.95))



		env.sky = null
	else:

		env.background_mode = Environment.BG_COLOR
		env.background_color = Stage.val(id, "fog_color", Color(0.03, 0.04, 0.06))
		env.sky = null
	env.glow_enabled = bool(Stage.val(id, "bloom", false)) and GameConfig.bloom
	env.fog_enabled = bool(Stage.val(id, "fog", false))
	if env.fog_enabled:
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_light_color = Stage.val(id, "fog_color", Color(0.02, 0.03, 0.05))
		env.fog_depth_begin = float(Stage.val(id, "fog_begin", 40.0))
		env.fog_depth_end = float(Stage.val(id, "fog_end", 90.0))
		env.fog_sky_affect = 0.0

		env.fog_height = float(Stage.val(id, "fog_height", 0.0))
		env.fog_height_density = - float(Stage.val(id, "fog_height_density", 0.0))
	we.environment = env

func _refresh_stage_btn() -> void :

	if _stage_btn != null:
		_stage_btn.disabled = Net.party





func _wire_floor_reflection(id: String) -> void :
	if _reflector == null or _floor_mat == null:
		return
	var reflects: bool = bool(Stage.val(id, "reflect", true))\
	and ( not bool(Stage.val(id, "owns_floor", false))
		or bool(Stage.val(id, "mirror_overlay", false)))
	if reflects:
		CourtDress.wire_reflection(_floor_mat, _reflector.texture())
		_reflector.floor_mats = [_floor_mat]
	else:
		_floor_mat.set_shader_parameter("reflect_on", false)
		_reflector.floor_mats = []

func _build_player() -> void :
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_position = HOME_SPOT
	player.team_side = 1
	player.set_name_visible(false)
	player.charge_ui_enabled = false
	Haptics.wire(player)
	_apply_outfit()
	ball = BALL_SCENE.instantiate()
	ball.stage_ball = _ball_skin
	add_child(ball)
	ball.global_position = HOME_SPOT + Vector3(-0.45, 0.4, 0.5)
	ball.court_center_x = 0.0
	ball.court_half_w = COURT_HW
	ball.court_half_l = COURT_HL
	ball.net_half_width = Ball.PHYS.net_half_width * (COURT_HW / 4.5)
	ball.antenna_half_width = Ball.PHYS.antenna_half_width * (COURT_HW / 4.5)
	ball.wall_min = Vector3( - HALL_X, -1000000.0, - HALL_Z)
	ball.wall_max = Vector3(HALL_X, 30.0, HALL_Z)
	ball.struck.connect( func(pos: Vector3, power: float, kind: int):
		_play_contact_fx(pos, power, kind, ball.vel, ball.combo_tier)

		if Net.party and _freeplay:
			Net.send_freeplay_fx(kind, pos, power, ball.vel))
	ball.bounced.connect( func():
		var floor_pos: = Vector3(ball.global_position.x, 0.06, 
			ball.global_position.z)
		sfx.play("hit_soft", ball.global_position, -12.0, 0.75)
		fx.ring(floor_pos, Vector3.UP, clampf(ball.vel.y * 0.12, 0.3, 0.9))
		fx.puff(floor_pos))
	player.thumped.connect( func(pos: Vector3, strength: float):
		var at: = Vector3(pos.x, 0.08, pos.z)
		sfx.play("hit_soft", at, -2.0, 0.55)
		Rules.contact_fx(fx, at, strength, Vector3.UP, 0.0)
		fx.puff(at)

		if Net.party and _freeplay:
			Net.send_freeplay_fx(-2, at, strength, Vector3.UP))
	player.knock_started.connect( func(_pos: Vector3, strength: float):
		camera_rig.shake(0.22 * strength))
	player.launched.connect( func(pos: Vector3, charge: float):
		var at: = Vector3(pos.x, 0.06, pos.z)
		fx.ring(at, Vector3.UP, 1.15 * charge)
		fx.puff(at)
		sfx.play("hit_soft", at, -4.0, 1.35)

		if Net.party and _freeplay:
			Net.send_freeplay_fx(-1, at, charge, Vector3.UP))
	player.voiced.connect( func(bank: String, pitch: float):
		sfx.play(bank, player.global_position, -3.0, pitch))
	camera_rig.player = player
	camera_rig.ball = ball
	camera_rig.roam = false


	camera_rig.mode_changed.connect( func(name_in: String):
		if hud != null:
			hud.show_camera_name(name_in))
	camera_rig.tv_center_x = 0.0
	camera_rig.court_span = COURT_HL
	camera_rig.home_side = 1.0
	_configure_freeplay_aim_bounds()
	fx.setup(camera_rig)


	_reflector = FloorReflector.new()
	add_child(_reflector)
	_reflector.setup(camera_rig.camera)
	_reflector.feet_provider = func(): return [player, ball] + _party_live_bodies()
	_wire_floor_reflection(_freeplay_stage)

	menu_cam.fov = 50.0



	menu_cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	menu_cam.global_position = HOME_SPOT + Vector3(-0.78, 1.35, 3.7)
	_face_camera()
	_cam_look_now = player.global_position + Vector3(-1.15, 1.0, 0.0)
	menu_cam.current = true

func _configure_freeplay_aim_bounds() -> void :




	_input_collector.aim_min = Vector2( - COURT_HW - 1.5, - COURT_HL - 2.5)
	_input_collector.aim_max = Vector2(COURT_HW + 1.5, COURT_HL + 2.5)

func _face_camera() -> void :
	var to_cam: = menu_cam.global_position - player.global_position
	_base_yaw = atan2(to_cam.x, to_cam.z) - 0.38
	player.visual.rotation.y = _base_yaw + _spin
	_aim_at_cam = player.global_position\
	+ Vector3(to_cam.x, 0.0, to_cam.z).normalized() * 6.0
	player.aim_point = _aim_at_cam
	menu_cam.look_at(player.global_position + Vector3(-1.15, 1.0, 0.0))





func _sync_local_guests() -> void :
	var want: = {}
	for i in range(1, LocalPlayers.slots.size()):
		want[LocalPlayers.slots[i].device] = LocalPlayers.slots[i]

	for g in _local_guests.duplicate():
		var dev: int = g["slot"].device
		if not _freeplay or not want.has(dev):
			if is_instance_valid(g["player"]):
				g["player"].queue_free()
			_local_guests.erase(g)

	if _freeplay:
		var have: = {}
		for g in _local_guests:
			have[g["slot"].device] = true
		for dev in want:
			if not have.has(dev):
				_local_guests.append({"slot": want[dev], "player": _spawn_guest(want[dev])})

	_input_collector.set_exclude_pads(LocalPlayers.claimed_pads())

func _spawn_guest(slot: LocalPlayerSlot) -> Player:
	var gp: = PLAYER_SCENE.instantiate() as Player
	add_child(gp)
	gp.global_position = HOME_SPOT + Vector3(2.2, 0.0, 0.0)
	gp.team_side = 1
	gp.set_name_visible(false)
	gp.charge_ui_enabled = false
	gp.indicator_enabled = false
	gp.ball = ball
	var cfg: CharacterConfig = CharacterConfig.from_dict(slot.profile.character)\
	if slot.profile != null and not slot.profile.character.is_empty()\
	else CharacterConfig.random()
	gp.set_character(cfg, GameConfig.team_kit(true))
	var col: = slot.make_collector()
	col.aim_min = _input_collector.aim_min
	col.aim_max = _input_collector.aim_max
	Haptics.wire(gp)
	return gp

func _apply_outfit() -> void :
	match _outfit:
		"home":
			player.set_character(GameConfig.character, GameConfig.team_kit(true))
		"away":
			player.set_character(GameConfig.character, GameConfig.team_kit(false))
		_:
			player.set_character(GameConfig.character.gym_look(), 
				GameConfig.character.gym_kit())




func _broadcast_menu_look() -> void :
	Net.send_party_look(_outfit)



func _build_ui() -> void :
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_root)


	hud = HUD_SCENE.instantiate()
	ui.add_child(hud)
	hud.visible = false
	hud.pause_enabled = false




	_chat = hud.get_node_or_null("Chat")
	if _chat != null:
		hud.remove_child(_chat)
		ui.add_child(_chat)
		_dock_chat(true)
	aim_indicator = AimMarker.new()
	add_child(aim_indicator)
	aim_indicator.visible = false



	aim_indicator.net_mat = _menu_net_mat
	reach_marker = ReachMarker.new()
	add_child(reach_marker)
	reach_marker.setup(camera_rig.camera)
	reach_marker.entered_reach.connect( func():
		sfx.play("reach_in", player.global_position, -8.0))
	reach_marker.action_queued.connect( func():
		sfx.play("reach_queue", player.global_position, -2.0))
	reach_marker.took.connect( func():
		sfx.play("reach_take", player.global_position, -4.0, 1.15))
	reach_marker.missed.connect( func():
		sfx.play("reach_miss", player.global_position, -8.0))
	reach_marker.early.connect( func():
		sfx.play("reach_miss", player.global_position, -8.0))
	player.out_of_range.connect( func():
		sfx.play("reach_miss", player.global_position, -8.0))

	_input_collector.dive_denied.connect( func():
		if player == null:
			return
		sfx.play("reach_miss", player.global_position, -8.0)
		if hud != null:
			hud.dive_denied()
		player.dive_denied())
	_build_bars()
	_home = _page(false)
	_build_home()
	_online = _page(false)
	_build_online()
	_local = _page()
	_build_local()
	_practice = _page(false)
	_build_practice()
	_drills = _page()
	_build_drills()
	_profile = _page()
	_build_profile()
	_achievements = _page()
	_build_achievements()
	_recent = _page()
	_build_recent()
	_quick = _page()
	_build_quick()


	_settings = _page()
	_build_settings()
	_howto = _page()
	_build_howto()


	_browse = _page()
	_build_browse()
	_host = _page()
	_build_host()
	_room = _page()
	_build_room()
	_direct = _page()
	_build_direct()
	_build_friends_panel()
	_setup_online()
	var hint: = Label.new()
	hint.text = "esc: back to the menu     c: camera"
	UiStyle.style_label(hint, "small", Color(1, 1, 1, 0.6))
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.position = Vector2(48, -40)
	hint.visible = false
	ui.add_child(hint)
	_fp_hint = hint
	_build_matchmaking()
	_build_drill_runtime()
	_show(_home)

func _bar_box(top: bool) -> HBoxContainer:


	var bar: = PanelContainer.new()
	var b: = StyleBoxFlat.new()
	b.bg_color = Color(UiStyle.card(), 0.97)
	b.content_margin_left = 28.0
	b.content_margin_right = 28.0

	b.content_margin_top = 18.0 if top else 9.0
	b.content_margin_bottom = 18.0 if top else 9.0
	bar.add_theme_stylebox_override("panel", b)
	if top:
		bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		_top_panel = bar
	else:
		bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
		bar.offset_bottom = 0.0
		_bottom_panel = bar

		_bar_normal = b
		_bar_green = b.duplicate()
		_bar_green.bg_color = Color(UiStyle.SUCCESS, 0.94)


	ui.add_child(bar)


	var strip: = Panel.new()
	var sb: = StyleBoxFlat.new()
	sb.bg_color = UiStyle.PRIMARY
	strip.add_theme_stylebox_override("panel", sb)
	strip.custom_minimum_size.y = 4
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_sibling(strip)
	if top:
		strip.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		_top_strip = strip
	else:
		strip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		strip.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_bottom_strip = strip
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	bar.add_child(h)
	return h



func _place_strips() -> void :
	if _top_strip != null and _top_panel != null:
		_top_strip.offset_top = _top_panel.size.y
		_top_strip.offset_bottom = _top_panel.size.y + 4.0
	if _bottom_strip != null and _bottom_panel != null:
		_bottom_strip.offset_top = - _bottom_panel.size.y - 4.0
		_bottom_strip.offset_bottom = - _bottom_panel.size.y

func _tab(text: String, active: bool, on_press: Callable, 
		icon_name: = "", icon_w: = 20) -> Button:
	var b: = Button.new()
	b.text = text
	if icon_name != "":
		b.icon = UiStyle.icon(icon_name, active and not UiStyle.dark)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", icon_w)
		b.add_theme_constant_override("h_separation", 8)
	b.custom_minimum_size = Vector2(76, 52)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiStyle.style_button(b, "primary" if active else "tertiary", 17)
	if not active:
		b.add_theme_color_override("font_color", UiStyle.muted())
		b.add_theme_color_override("font_hover_color", UiStyle.text())
	if on_press.is_valid():
		b.pressed.connect(on_press)
	return b

func _build_bars() -> void :

	var top: = _bar_box(true)
	_top_bar = top


	var hole: = Control.new()
	hole.custom_minimum_size.x = 164
	top.add_child(hole)
	top.add_child(_tab("play", true, _on_play_tab, "right"))
	top.add_child(_tab("locker", false, func():
		_wipe_to("res://game/character/locker.tscn"), "star"))




	var beta: = LaunchGate.public_beta()
	if not beta:
		top.add_child(_tab("shop", false, func():
			_wipe_to("res://game/shop/shop.tscn"), "shoppingCart"))


	if not beta:
		var replays: = _tab("replays", false, func():
			_wipe_to("res://game/replay/replay_viewer.tscn"), "movie", 26)
		_replays_tab = replays
		if Net.active:


			replays.disabled = true
			replays.tooltip_text = "not while you're in an online session"
		top.add_child(replays)
	top.add_child(_tab("profile", false, func(): _show(_profile), "singleplayer"))
	if not beta:
		_awards_tab = _tab("awards", false, func(): _show_achievements(), "medal1")
		top.add_child(_awards_tab)
	var spring: = Control.new()
	spring.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spring)



	_party_strip = HBoxContainer.new()
	_party_strip.add_theme_constant_override("separation", 4)
	_party_strip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_party_strip)
	var spring_b: = Control.new()
	spring_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spring_b)


	_friends_btn = UiStyle.icon_button("multiplayer", "secondary", 40)
	_friends_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_friends_btn.tooltip_text = "friends"
	_friends_btn.visible = Net.steam_transport_available()
	_friends_btn.pressed.connect(_toggle_friends_panel)
	top.add_child(_friends_btn)


	var settings: = UiStyle.icon_button("gear", "secondary", 40)
	settings.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	settings.tooltip_text = "settings"


	settings.pressed.connect( func(): _open_settings(SettingsPanel.Scope.SYSTEM))
	top.add_child(settings)
	var quit: = UiStyle.icon_button("power", "exit", 40)
	quit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	quit.tooltip_text = "quit"
	quit.pressed.connect( func():
		UiStyle.confirm(self, "quit the game?", "", 
			func():
				GameConfig.flush_saves()
				get_tree().quit(), "quit", "stay", "exit"))
	top.add_child(quit)
	var logo: = TextureRect.new()
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size = Vector2(200, 62)
	logo.position = Vector2(14, 14)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(logo)
	_logo_rect = logo

	var bottom: = _bar_box(false)
	_bottom_bar = bottom


	bottom.add_child(_build_player_card())
	var spring_mm_l: = Control.new()
	spring_mm_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(spring_mm_l)


	_mm_title = Label.new()
	_mm_title.text = "matchmaking..."
	UiStyle.style_label(_mm_title, "title", Color.WHITE)
	_mm_title.add_theme_font_size_override("font_size", 17)
	_mm_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_mm_title.visible = false
	bottom.add_child(_mm_title)
	_mm_label = Label.new()
	_mm_label.text = ""
	UiStyle.style_label(_mm_label, "small", Color(1, 1, 1, 0.92))
	_mm_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_mm_label.visible = false
	bottom.add_child(_mm_label)
	_mm_cancel = Button.new()
	_mm_cancel.text = "cancel"
	UiStyle.style_button(_mm_cancel, "tertiary", 14)
	_mm_cancel.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	_mm_cancel.add_theme_color_override("font_hover_color", Color.WHITE)
	_mm_cancel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_mm_cancel.visible = false
	_mm_cancel.pressed.connect( func():
		_qp.cancel()
		if _park != null and is_instance_valid(_park):
			_park.cancel()
			_park = null
		_set_matchmaking(false))
	bottom.add_child(_mm_cancel)
	var spring_mm_r: = Control.new()
	spring_mm_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(spring_mm_r)



	if SHOW_FEEDBACK_BUTTON:
		var report: = Button.new()
		report.text = "report a bug"
		UiStyle.style_button(report, "secondary", 14)
		report.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		report.pressed.connect(_open_feedback)
		bottom.add_child(report)

	var outfit: = Button.new()
	outfit.text = "outfit: %s" % _outfit
	UiStyle.style_button(outfit, "secondary", 15)
	outfit.pressed.connect( func():
		_outfit = OUTFITS[(OUTFITS.find(_outfit) + 1) % OUTFITS.size()]
		outfit.text = "outfit: %s" % _outfit
		_apply_outfit()
		Net.send_party_look(_outfit)

		GameConfig.menu_outfit = _outfit
		GameConfig.save_settings())
	bottom.add_child(outfit)
	var ballbtn: = Button.new()
	ballbtn.text = "ball: %s" % BALL_LABELS.get(_ball_skin, _ball_skin)
	UiStyle.style_button(ballbtn, "secondary", 15)
	ballbtn.pressed.connect( func():
		_ball_skin = BALL_SKINS[(BALL_SKINS.find(_ball_skin) + 1) % BALL_SKINS.size()]
		ballbtn.text = "ball: %s" % BALL_LABELS.get(_ball_skin, _ball_skin)
		if ball != null:
			ball.set_ball_skin(_ball_skin)
		Net.send_party_ball(_ball_skin)

		GameConfig.menu_ball = _ball_skin
		GameConfig.save_settings())
	bottom.add_child(ballbtn)


	var stagebtn: = Button.new()
	stagebtn.text = "stage: %s" % Stage.title(_freeplay_stage).to_lower()
	UiStyle.style_button(stagebtn, "secondary", 15)
	stagebtn.pressed.connect( func():
		var ids: = Stage.ids(false)
		_swap_stage(ids[(ids.find(_freeplay_stage) + 1) % ids.size()]))
	stagebtn.disabled = Net.party
	_stage_btn = stagebtn
	bottom.add_child(stagebtn)
	var fp: = Button.new()
	fp.text = "freeplay"
	UiStyle.style_button(fp, "primary", 18)
	fp.pressed.connect(_enter_freeplay)
	bottom.add_child(fp)
	var version: = Label.new()
	version.text = "v%s" % GameConfig.VERSION
	UiStyle.style_label(version, "small")
	version.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	version.custom_minimum_size.x = 56


	if LaunchGate.public_beta():
		version.text = "pre beta build - content not final"
		version.custom_minimum_size.x = 0
		version.add_theme_color_override("font_color", Color(0, 0, 0, 0.45))
	bottom.add_child(version)
	_refresh_player_card()







func _build_player_card() -> Control:
	var card: = HBoxContainer.new()
	card.add_theme_constant_override("separation", 12)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER






	var hole: = Control.new()
	hole.custom_minimum_size.x = 62
	card.add_child(hole)
	var pfp: = TextureRect.new()
	pfp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pfp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pfp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(pfp)
	pfp.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	pfp.offset_left = 20
	pfp.offset_right = 84
	pfp.offset_top = -64
	pfp.offset_bottom = 0
	_pc_avatar = pfp



	_load_card_pfp.call_deferred(pfp)


	var col: = VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_pc_name = Label.new()
	UiStyle.style_label(_pc_name, "body")
	_pc_name.add_theme_font_size_override("font_size", 15)
	col.add_child(_pc_name)
	var lvrow: = HBoxContainer.new()
	lvrow.add_theme_constant_override("separation", 8)
	_pc_level = Label.new()
	UiStyle.style_label(_pc_level, "small", UiStyle.muted())
	_pc_level.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lvrow.add_child(_pc_level)
	_pc_xp = ProgressBar.new()
	_pc_xp.show_percentage = false
	_pc_xp.min_value = 0.0
	_pc_xp.max_value = 1.0
	_pc_xp.custom_minimum_size = Vector2(128, 10)
	_pc_xp.size_flags_vertical = Control.SIZE_SHRINK_CENTER


	var track: = StyleBoxFlat.new()
	track.bg_color = Color(0.0, 0.0, 0.0, 0.16)
	track.set_corner_radius_all(4)
	var fill: = StyleBoxFlat.new()
	fill.bg_color = UiStyle.PRIMARY
	fill.set_corner_radius_all(4)
	_pc_xp.add_theme_stylebox_override("background", track)
	_pc_xp.add_theme_stylebox_override("fill", fill)
	lvrow.add_child(_pc_xp)
	_pc_xp_text = Label.new()
	UiStyle.style_label(_pc_xp_text, "small", UiStyle.muted())
	_pc_xp_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lvrow.add_child(_pc_xp_text)
	col.add_child(lvrow)
	card.add_child(col)


	var coinbox: = HBoxContainer.new()
	coinbox.add_theme_constant_override("separation", 7)
	coinbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coinbox.add_child(_coin_disc(20))
	_pc_coins = Label.new()
	UiStyle.style_label(_pc_coins, "body")
	_pc_coins.add_theme_font_size_override("font_size", 16)
	coinbox.add_child(_pc_coins)
	card.add_child(coinbox)



	if LaunchGate.public_beta():
		lvrow.visible = false
		coinbox.visible = false



	_pc_div = Panel.new()
	_pc_div.custom_minimum_size = Vector2(2, 34)
	var db: = StyleBoxFlat.new()
	db.bg_color = Color(UiStyle.muted(), 0.25)
	db.set_corner_radius_all(1)
	_pc_div.add_theme_stylebox_override("panel", db)
	_pc_div.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.add_child(_pc_div)
	return card



func _tint_player_card(on_green: bool) -> void :
	if _pc_name == null:
		return
	var strong: = Color.WHITE if on_green else UiStyle.text()
	var soft: = Color(1.0, 1.0, 1.0, 0.85) if on_green else UiStyle.muted()
	_pc_name.add_theme_color_override("font_color", strong)
	_pc_coins.add_theme_color_override("font_color", strong)
	_pc_level.add_theme_color_override("font_color", soft)
	_pc_xp_text.add_theme_color_override("font_color", soft)
	if _pc_div != null:
		var sb: = _pc_div.get_theme_stylebox("panel") as StyleBoxFlat
		if sb != null:
			sb.bg_color = Color(1.0, 1.0, 1.0, 0.7) if on_green\
			else Color(UiStyle.muted(), 0.25)



func _refresh_player_card() -> void :
	if _pc_name == null:
		return
	var p: = ProfileStore.active()
	if p == null:
		return
	_pc_name.text = p.name
	_pc_level.text = "lv. %d" % p.level
	var need: = Progression.xp_for_next(p.level)
	_pc_xp.value = clampf(float(p.xp) / float(maxi(1, need)), 0.0, 1.0)
	_pc_xp_text.text = "%s / %s xp" % [_comma(p.xp), _comma(need)]
	_pc_coins.text = _comma(p.coins)


func _load_card_pfp(rect: TextureRect) -> void :
	var tex: = await CharacterPortrait.render(GameConfig.character, "head", 
		Vector2i(140, 140), self)
	if is_instance_valid(rect):
		rect.texture = tex



func _coin_disc(px: = 20) -> Panel:
	var coin: = Panel.new()
	coin.custom_minimum_size = Vector2(px, px)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var cs: = StyleBoxFlat.new()
	cs.bg_color = Color(0.96, 0.78, 0.16)
	cs.set_corner_radius_all(99)
	cs.set_border_width_all(2)
	cs.border_color = Color(0.74, 0.55, 0.05)
	coin.add_theme_stylebox_override("panel", cs)
	return coin


func _comma(n: int) -> String:
	var s: = str(absi(n))
	var out: = ""
	var c: = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out

func _page(carded: = true) -> Control:
	var holder: = MarginContainer.new()
	holder.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	holder.position.x = 96



	holder.add_theme_constant_override("margin_top", 100)
	holder.add_theme_constant_override("margin_bottom", 92)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(holder)
	var center: = VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(center)
	var panel: = PanelContainer.new()
	panel.name = "Panel"
	if carded:
		UiStyle.style_panel(panel, UiStyle._AUTO, UiStyle.RADIUS_SOFT)
	else:
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	center.add_child(panel)
	var v: = VBoxContainer.new()
	v.name = "Box"
	v.add_theme_constant_override("separation", 14)
	v.custom_minimum_size.x = 340
	panel.add_child(v)
	return holder

func _box(page: Control) -> VBoxContainer:
	return page.find_child("Box", true, false) as VBoxContainer

func _menu_btn(text: String, kind: String, on_press: Callable) -> Button:
	var b: = Button.new()
	b.text = text
	b.custom_minimum_size.y = 62
	UiStyle.style_button(b, kind, 22)
	if on_press.is_valid():
		b.pressed.connect(on_press)
	return b

func _group(v: VBoxContainer, text: String) -> void :

	var p: = Label.new()
	p.text = text
	UiStyle.style_label(p, "title")
	v.add_child(p)
	var rule: = Panel.new()
	rule.custom_minimum_size = Vector2(56, 5)
	var rb: = StyleBoxFlat.new()
	rb.bg_color = UiStyle.PRIMARY
	rb.set_corner_radius_all(3)
	rule.add_theme_stylebox_override("panel", rb)
	v.add_child(rule)



func _build_home() -> void :



	var v: = _box(_home)
	v.add_theme_constant_override("separation", 12)
	var online_card: = _card_btn("massiveMultiplayer", "online", 
		MenuCopy.sub("online"), "primary", _open_online)
	var local_card: = _card_btn("singleplayer", "local", 
		MenuCopy.sub("local"), "info", func():
			_populate_local()
			_show(_local))
	_card_local = local_card.get_child(0) as Button
	var practice_card: = _card_btn("target", "practice", 
		MenuCopy.sub("practice"), "info", func(): _show(_practice))



	var settings_card: = _card_btn("gear", "system settings", 
		"configure audio, video, display", "quiet", 
		func(): _open_settings(SettingsPanel.Scope.SYSTEM))
	var cards: = [online_card, local_card, practice_card, settings_card]


	if LaunchGate.public_beta():
		var feedback_card: = _card_btn("question", "feedback & bug reports", 
			"", "quiet", 
			func(): _open_feedback())
		cards.append(feedback_card)
	for card in cards:
		v.add_child(card)


	var btns: Array = []
	for card in cards:
		btns.append((card as Control).get_child(0) as Button)
	for i in btns.size():
		var b: = btns[i] as Button
		if b == null:
			continue
		if i > 0:
			b.focus_neighbor_top = b.get_path_to(btns[i - 1] as Button)
		if i < btns.size() - 1:
			b.focus_neighbor_bottom = b.get_path_to(btns[i + 1] as Button)








func _tilt_cards(delta: float) -> void :
	if _freeplay or _tilt.is_empty():
		return
	var vp: = get_viewport().get_visible_rect().size
	if vp.x <= 0.0:
		return
	var off: = (ui.get_viewport().get_mouse_position() / vp)\
	- Vector2(0.5, 0.5)
	if _tilt_fake != 0.0:
		off.x = _tilt_fake
	var k: = clampf(delta * 9.0, 0.0, 1.0)
	var depth: = 0
	for c in _tilt:
		var card: = c as Button
		if not is_instance_valid(card):
			continue
		if not card.is_visible_in_tree():
			continue




		card.offset_transform_enabled = true
		card.offset_transform_pivot_ratio = Vector2(0.5, 0.5)


		var hovered: = card.has_focus() or card.get_global_rect().has_point(
			ui.get_viewport().get_mouse_position())




		var recede: = 1.0 - 0.026 * float(depth)
		var fan: = 0.028 - 0.016 * float(depth)
		var want_rot: = 0.0 if hovered else fan - off.x * 0.06
		var want_scale: = 1.07 if hovered else recede - absf(off.x) * 0.012
		var want_x: = (52.0 if hovered else 8.0 * float(depth))\
		- off.x * (26.0 + 8.0 * float(depth))
		card.offset_transform_rotation = lerpf(
			card.offset_transform_rotation, want_rot, k)
		card.offset_transform_scale = card.offset_transform_scale.lerp(
			Vector2.ONE * want_scale, k)
		card.offset_transform_position.x = lerpf(
			card.offset_transform_position.x, want_x, k)

		card.z_index = 2 if hovered else 0
		depth += 1



func _lean_tiles(delta: float) -> void :
	if _freeplay or _lean.is_empty():
		return
	var vp: = get_viewport().get_visible_rect().size
	if vp.x <= 0.0:
		return
	var mouse: = ui.get_viewport().get_mouse_position()
	var off: = (mouse / vp) - Vector2(0.5, 0.5)
	if _tilt_fake != 0.0:
		off.x = _tilt_fake
	var k: = clampf(delta * 9.0, 0.0, 1.0)
	for c in _lean:
		var t: = c as Control
		if not is_instance_valid(t) or not t.is_visible_in_tree():
			continue
		t.offset_transform_enabled = true
		t.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
		var hovered: = t.get_global_rect().has_point(mouse)
		var want_rot: = 0.0 if hovered else - off.x * 0.05
		var want_scale: = 1.08 if hovered else 1.0 - absf(off.x) * 0.01
		t.offset_transform_rotation = lerpf(t.offset_transform_rotation, want_rot, k)
		t.offset_transform_scale = t.offset_transform_scale.lerp(
			Vector2.ONE * want_scale, k)
		t.offset_transform_position.x = lerpf(
			t.offset_transform_position.x, - off.x * 14.0, k)
		t.z_index = 2 if hovered else 0

func _card_btn(icon_name: String, title: String, sub: String, 
		kind: String, on_press: Callable) -> Control:
	var yellow: = kind == "primary"
	var disc_c: = UiStyle.INK if yellow\
	else (UiStyle.muted() if kind == "quiet" else UiStyle.SECONDARY)
	var b: = Button.new()
	b.custom_minimum_size = Vector2(430, 78)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var fill: = UiStyle.PRIMARY if yellow else UiStyle.card()
	for state in [["normal", fill, 9], ["hover", fill.lightened(0.06), 9], 
		["pressed", fill.darkened(0.05), 3], 
		["focus", fill.lightened(0.06), 9], 
		["disabled", Color(UiStyle.muted(), 0.3), 3]]:
		var box: = StyleBoxFlat.new()
		box.bg_color = state[1]
		box.set_corner_radius_all(18)



		box.border_width_bottom = int(state[2])
		box.border_color = (state[1] as Color).darkened(0.3)
		box.shadow_color = Color(0, 0, 0, 0.42)
		box.shadow_size = 14
		box.shadow_offset = Vector2(4, 9)
		b.add_theme_stylebox_override(String(state[0]), box)



	var focus_ring: = StyleBoxFlat.new()
	focus_ring.bg_color = fill.lightened(0.06)
	focus_ring.set_corner_radius_all(18)
	focus_ring.set_border_width_all(4)
	focus_ring.border_color = UiStyle.SECONDARY
	focus_ring.shadow_color = Color(0, 0, 0, 0.42)
	focus_ring.shadow_size = 14
	focus_ring.shadow_offset = Vector2(4, 9)
	b.add_theme_stylebox_override("focus", focus_ring)
	var pad: = MarginContainer.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		pad.add_theme_constant_override("margin_%s" % side, 16)
	b.add_child(pad)
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(row)


	var disc_wrap: = MarginContainer.new()
	disc_wrap.add_theme_constant_override("margin_left", 2)
	disc_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(disc_wrap)
	var disc: = TextureRect.new()
	disc.texture = UiStyle.icon_disc(icon_name, disc_c, 58, true)
	disc.custom_minimum_size = Vector2(58, 58)
	disc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	disc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc_wrap.add_child(disc)
	var col: = VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	var t: = Label.new()
	t.text = title
	UiStyle.style_label(t, "title", UiStyle.INK if yellow else UiStyle.text())
	t.add_theme_font_size_override("font_size", 27)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(t)

	if sub != "":
		var s: = Label.new()
		s.text = sub
		UiStyle.style_label(s, "small", 
			Color(UiStyle.INK, 0.66) if yellow else UiStyle.muted())
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(s)
	b.pressed.connect(UiStyle.press_bounce.bind(b))
	b.pressed.connect(UiStyle.sfx.bind("confirm" if yellow else "press"))
	UiStyle.hover_sound(b)
	if on_press.is_valid():
		b.pressed.connect(on_press)
	var card_wrap: = MarginContainer.new()
	card_wrap.add_theme_constant_override("margin_left", 30)
	card_wrap.add_child(b)
	_tilt.append(b)
	return card_wrap

func _ribbon_box(fill: Color) -> StyleBoxFlat:
	var rb: = StyleBoxFlat.new()
	rb.bg_color = fill
	rb.set_corner_radius_all(99)
	rb.content_margin_left = 30.0
	rb.content_margin_right = 56.0
	rb.content_margin_top = 8.0
	rb.content_margin_bottom = 10.0
	return rb

func _hero_btn(text_in: String, on_press: Callable) -> Button:
	var b: = Button.new()
	b.text = text_in
	b.add_theme_stylebox_override("normal", _ribbon_box(Color(UiStyle.INK, 0.45)))
	b.add_theme_stylebox_override("hover", _ribbon_box(Color(UiStyle.INK, 0.6)))
	b.add_theme_stylebox_override("pressed", _ribbon_box(Color(UiStyle.INK, 0.6)))
	b.add_theme_stylebox_override("focus", _ribbon_box(Color(UiStyle.INK, 0.6)))
	b.add_theme_stylebox_override("disabled", _ribbon_box(Color(UiStyle.INK, 0.3)))
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	b.add_theme_font_size_override("font_size", 46)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", UiStyle.PRIMARY)
	b.add_theme_color_override("font_pressed_color", 
		UiStyle.PRIMARY.darkened(0.1))
	b.add_theme_color_override("font_hover_pressed_color", UiStyle.PRIMARY)
	b.add_theme_color_override("font_focus_color", UiStyle.PRIMARY)
	b.add_theme_color_override("font_outline_color", UiStyle.INK)
	b.add_theme_constant_override("outline_size", 12)
	b.pressed.connect(UiStyle.press_bounce.bind(b))
	b.pressed.connect(UiStyle.sfx.bind("press"))
	UiStyle.hover_sound(b)
	b.pressed.connect(on_press)
	return b




func _ribbon_btn(text_in: String, kind: String, on_press: Callable) -> Button:
	var b: = Button.new()
	b.text = text_in
	if kind == "back":
		for st in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(st, StyleBoxEmpty.new())


		var back_focus: = StyleBoxFlat.new()
		back_focus.bg_color = Color(0, 0, 0, 0.3)
		back_focus.set_corner_radius_all(10)
		back_focus.set_border_width_all(3)
		back_focus.border_color = UiStyle.SECONDARY
		back_focus.set_content_margin_all(6)
		b.add_theme_stylebox_override("focus", back_focus)
		b.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_color_override("font_outline_color", UiStyle.INK)
		b.add_theme_constant_override("outline_size", 8)
		b.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.add_theme_color_override("font_pressed_color", Color.WHITE)
		b.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
		b.add_theme_color_override("font_focus_color", Color.WHITE)
	else:
		var yellow: = kind == "primary"
		var fill: = Color(UiStyle.PRIMARY, 0.96) if yellow else Color(UiStyle.INK, 0.45)
		var hov: = UiStyle.PRIMARY if yellow else Color(UiStyle.INK, 0.62)
		b.add_theme_stylebox_override("normal", _ribbon_box(fill))
		b.add_theme_stylebox_override("hover", _ribbon_box(hov))
		b.add_theme_stylebox_override("pressed", _ribbon_box(hov))
		b.add_theme_stylebox_override("focus", _ribbon_box(hov))
		b.add_theme_stylebox_override("disabled", 
			_ribbon_box(Color(UiStyle.INK, 0.25)))
		b.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
		b.add_theme_font_size_override("font_size", 26)
		var tc: = UiStyle.INK if yellow else Color.WHITE
		var th: = UiStyle.INK if yellow else UiStyle.PRIMARY
		b.add_theme_color_override("font_color", tc)
		b.add_theme_color_override("font_hover_color", th)
		b.add_theme_color_override("font_pressed_color", th)
		b.add_theme_color_override("font_hover_pressed_color", th)
		b.add_theme_color_override("font_focus_color", th)
		b.add_theme_color_override("font_outline_color", UiStyle.INK)
		b.add_theme_constant_override("outline_size", 0 if yellow else 6)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(UiStyle.press_bounce.bind(b))
	b.pressed.connect(UiStyle.sfx.bind("confirm" if kind == "primary" else "press"))
	UiStyle.hover_sound(b)
	if on_press.is_valid():
		b.pressed.connect(on_press)
	return b


func _hero_head(v: VBoxContainer, text_in: String, on_card: = false) -> Label:


	var box: = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var l: = Label.new()
	l.text = text_in
	l.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	l.add_theme_font_size_override("font_size", 38)
	if on_card:
		l.add_theme_color_override("font_color", UiStyle.text())
	else:
		l.add_theme_color_override("font_color", Color.WHITE)
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
		l.add_theme_constant_override("shadow_offset_x", 2)
		l.add_theme_constant_override("shadow_offset_y", 3)
		l.add_theme_constant_override("shadow_outline_size", 2)
	box.add_child(l)
	var rule: = Panel.new()
	rule.custom_minimum_size = Vector2(150, 6)
	var rb: = StyleBoxFlat.new()
	rb.bg_color = UiStyle.PRIMARY
	rb.set_corner_radius_all(3)
	rule.add_theme_stylebox_override("panel", rb)
	box.add_child(rule)
	var hwrap: = MarginContainer.new()
	hwrap.add_theme_constant_override("margin_bottom", 8)
	hwrap.add_child(box)
	v.add_child(hwrap)
	return l




func _open_online() -> void :
	if not OnlineTerms.require(_open_online):
		return
	_show(_online)

func _build_online() -> void :
	var v: = _box(_online)
	v.add_theme_constant_override("separation", 12)
	_hero_head(v, "online")
	v.add_child(_card_btn("massiveMultiplayer", "quick match", 
		MenuCopy.sub("quick_match"), "primary", func(): _show(_quick)))


	if not LaunchGate.public_beta():
		v.add_child(_card_btn("multiplayer", "open gym", 
			MenuCopy.sub("open_gym"), "info", _open_gym))
	v.add_child(_card_btn("menuList", "server browser", 
		MenuCopy.sub("server_browser"), "info", func():
			_show(_browse)
			_refresh_browser()))
	var custom_card: = _card_btn("plus", "custom lobby", 
		MenuCopy.sub("custom_lobby"), "info", func(): _show(_host))
	_card_custom_lobby = custom_card.get_child(0) as Button
	v.add_child(custom_card)


	if not LaunchGate.public_beta():
		var direct_card: = _card_btn("share1", "direct join", 
			MenuCopy.sub("direct_join"), "quiet", func(): _show(_direct))
		_card_direct = direct_card.get_child(0) as Button
		v.add_child(direct_card)
	_back_row(v, func(): _show(_home))





func _build_local() -> void :



	var v: = _box(_local)
	v.add_theme_constant_override("separation", 10)
	_local.add_theme_constant_override("margin_top", 88)
	_local.add_theme_constant_override("margin_bottom", 70)
	_local_panel = LobbyPanel.new()
	_local_panel.stage_changed.connect( func(id: String):
		GameConfig.stage = id
		GameConfig.preload_venue(id)
		GameConfig.save_settings()
		_refresh_local())
	_local_panel.rule_changed.connect(_on_local_rule)
	_local_panel.global_cpu_changed.connect( func(d: int):
		GameConfig.difficulty = clampi(d, 0, 2)
		CpuSlots.set_all_diff(GameConfig.local_cpus, GameConfig.difficulty)
		_refresh_local())
	_local_panel.cpu_diff_step.connect( func(id: String, dir: int):
		_cpu_step(GameConfig.local_cpus, id, dir, _refresh_local))
	_local_panel.cpu_reroll.connect( func(id: String):
		_cpu_reroll(GameConfig.local_cpus, id, _refresh_local))
	_local_panel.side_pressed.connect( func(side: int):
		if side != 0:
			GameConfig.local_side = side
			_refresh_local())
	_local_panel.start_pressed.connect(_start_local)
	_local_panel.back_pressed.connect( func(): _show(_home))
	_local_panel.reset_pressed.connect( func():
		GameConfig.set_points = int(Net.RULE_DEFAULTS.pts)
		GameConfig.sets_to_win = int(Net.RULE_DEFAULTS.sets)
		GameConfig.win_by_two = bool(Net.RULE_DEFAULTS.wbt)
		GameConfig.sweat_enabled = bool(Net.RULE_DEFAULTS.sweat)
		GameConfig.sweat_rate = float(Net.RULE_DEFAULTS.rate)
		_refresh_local())
	v.add_child(_local_panel)

var _local_panel: LobbyPanel = null
var _local_size: = 2

func _on_local_rule(key: String, value: Variant) -> void :
	match key:
		"size":
			_local_size = clampi(int(value), 1, 6)
		"sets":
			GameConfig.sets_to_win = clampi(int(value), 1, 3)
		"points":
			GameConfig.set_points = clampi(int(value), 3, 25)
		"rate":
			var ri: = clampi(int(value), 0, SWEAT_RATES.size() - 1)
			GameConfig.sweat_enabled = ri > 0
			if ri > 0:
				GameConfig.sweat_rate = SWEAT_RATES[ri]
		"wbt":
			GameConfig.win_by_two = bool(value)
		"sweat":
			GameConfig.sweat_enabled = bool(value)
	_refresh_local()


func _rate_index(rate: float, enabled: bool) -> int:
	if not enabled:
		return 0
	var nearest: = 1
	for i in range(1, SWEAT_RATES.size()):
		if absf(SWEAT_RATES[i] - rate) < absf(SWEAT_RATES[nearest] - rate):
			nearest = i
	return nearest


func _cpu_step(slots: Dictionary, id: String, dir: int, after: Callable) -> void :
	var cpu: Dictionary = slots.get(id, {})
	if cpu.is_empty():
		return
	CpuSlots.set_diff(slots, id, wrapi(int(cpu.diff) + dir, 0, CpuSlots.DIFF_NAMES.size()))
	after.call()

func _cpu_reroll(slots: Dictionary, id: String, after: Callable) -> void :
	CpuSlots.reroll(slots, id)
	after.call()




func _refresh_local() -> void :
	if _local_panel == null:
		return
	var my_side: = 1 if GameConfig.local_side >= 0 else -1
	var mine: Array = []
	if Net.party:
		var ids: = Net.players.keys()
		ids.sort()
		for id in ids:
			mine.append({"kind": "human", "name": String(Net.players[id].name), 
				"cfg": Net.players[id].get("cfg", {}), "host": id == 1, 
				"you": id == _my_party_id(), "dev": DevBadge.peer_tier(id)})
	else:
		mine.append({"kind": "human", "name": Net.local_display_name(), 
			"cfg": GameConfig.character.to_dict() if GameConfig.character != null else {}, 
			"you": true, "dev": DevBadge.my_tier()})
	mine = mine.slice(0, _local_size)
	var humans: = {my_side: mine.size(), - my_side: 0}
	CpuSlots.reconcile(GameConfig.local_cpus, _local_size, humans, GameConfig.difficulty)
	var entries: = {1: [], -1: []}
	entries[my_side] = mine
	for side in [1, -1]:
		for cpu in CpuSlots.ordered(GameConfig.local_cpus, side):
			entries[side].append({"kind": "cpu", "name": String(cpu.name), 
				"cfg": cpu.cfg, "diff": int(cpu.diff), 
				"id": CpuSlots.id_for(side, int(cpu.k))})
	_local_panel.apply({"title": "local match", "stage_ids": Stage.ids(), 
		"stage": GameConfig.stage if Stage.STAGES.has(GameConfig.stage) else "nationals", 
		"size": _local_size, "home": entries[1], "away": entries[-1], 
		"rules": {"sets": GameConfig.sets_to_win, "points": GameConfig.set_points, 
			"wbt": GameConfig.win_by_two, "sweat": GameConfig.sweat_enabled, 
			"rate": _rate_index(GameConfig.sweat_rate, GameConfig.sweat_enabled)}, 
		"rate_names": SWEAT_RATE_NAMES, 
		"cpu": CpuSlots.global_diff(GameConfig.local_cpus), 
		"editable": true, "my_side": my_side, "side_mode": "local", 
		"side_editable": true, "can_start": true, "invite": false})



func _populate_local() -> void :
	_local_size = clampi(GameConfig.team_size, 1, 6)
	_refresh_local()






var _faces_warmed: = false
func _prewarm_local_faces() -> void :
	if _faces_warmed:
		return
	_faces_warmed = true



	await get_tree().create_timer(1.5).timeout
	if not is_instance_valid(self) or Net.active or _local == null:
		return
	if _local.visible:
		return
	_populate_local()


func _back_row(v: VBoxContainer, on_press: Callable) -> void :
	var gap: = Control.new()
	gap.custom_minimum_size.y = 10
	v.add_child(gap)
	v.add_child(_ribbon_btn("back", "back", on_press))

func _build_practice() -> void :
	var v: = _box(_practice)
	v.add_theme_constant_override("separation", 12)
	_hero_head(v, "practice")
	v.add_child(_card_btn("target", "freeplay", 
		MenuCopy.sub("freeplay"), "primary", _enter_freeplay))


	v.add_child(_card_btn("star", "tutorial", 
		"learn the basics of the game", "info", _start_tutorial))




	var drills_card: = _card_btn("checkmark", "drills", 
		"coming soon", "info", _open_drills)
	var drills_btn: = drills_card.get_child(0) as Button
	if drills_btn != null:
		drills_btn.disabled = true
		drills_btn.focus_mode = Control.FOCUS_NONE
	drills_card.modulate = Color(1, 1, 1, 0.55)
	v.add_child(drills_card)
	v.add_child(_card_btn("question", "how to play", 
		MenuCopy.sub("how_to_play"), "info", func(): _show(_howto)))
	_back_row(v, func(): _show(_home))

func _build_drills() -> void :
	var v: = _box(_drills)
	_group(v, "drills")



	var stack: = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 0)
	v.add_child(stack)
	var tabs: = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 3)
	stack.add_child(tabs)
	for cat in DrillCatalog.CATEGORIES:
		var cid: = String(cat.id)
		var tab: = Button.new()
		tab.text = String(cat.name)
		tab.focus_mode = Control.FOCUS_NONE
		_style_drill_tab(tab, cid == _drill_category)
		tab.pressed.connect(_show_drill_category.bind(cid))
		tabs.add_child(tab)
		_drill_tabs[cid] = tab
	var card: = PanelContainer.new()
	UiStyle.style_panel(card, UiStyle.card(), UiStyle.RADIUS)
	stack.add_child(card)
	var scroll: = ScrollContainer.new()

	scroll.custom_minimum_size = Vector2(640, 340)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(scroll)
	_drill_list = VBoxContainer.new()
	_drill_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_drill_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_drill_list)
	_back_row(v, func(): _show(_practice))
	_show_drill_category(_drill_category)



func _style_drill_tab(btn: Button, active: bool) -> void :
	var box: = StyleBoxFlat.new()
	box.bg_color = UiStyle.PRIMARY if active else Color(UiStyle.muted(), 0.16)
	box.corner_radius_top_left = 10
	box.corner_radius_top_right = 10
	box.content_margin_left = 15.0
	box.content_margin_right = 15.0
	box.content_margin_top = 7.0
	box.content_margin_bottom = 7.0
	btn.add_theme_stylebox_override("normal", box)
	btn.add_theme_stylebox_override("pressed", box)
	var hov: StyleBoxFlat = box.duplicate()
	hov.bg_color = UiStyle.PRIMARY if active else Color(UiStyle.muted(), 0.3)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", UiStyle.INK if active else UiStyle.muted())
	btn.add_theme_color_override("font_hover_color", UiStyle.INK if active else UiStyle.text())
	btn.add_theme_color_override("font_pressed_color", UiStyle.INK if active else UiStyle.text())


func _show_drill_category(cid: String) -> void :
	_drill_category = cid
	for id in _drill_tabs:
		_style_drill_tab(_drill_tabs[id], id == cid)
	for child in _drill_list.get_children():
		child.queue_free()
	_drill_rows = {}
	for item in DrillCatalog.by_category(cid):
		var row: = Button.new()
		row.custom_minimum_size = Vector2(610, 56)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_theme_constant_override("icon_max_width", 40)
		var thumbnail: = String(item.get("thumbnail", "question"))
		row.icon = UiStyle.icon(thumbnail)
		UiStyle.style_button(row, 
			"secondary" if bool(item.get("available", false)) else "tertiary", 17)
		var id: = String(item.id)
		row.disabled = not bool(item.get("available", false))
		if row.disabled:
			row.tooltip_text = "coming soon"
		else:
			row.pressed.connect(_start_drill.bind(id))
		_drill_list.add_child(row)
		_drill_rows[id] = {"button": row, "item": item}
	_refresh_drill_rows()

func _open_drills() -> void :
	_show_drill_category(_drill_category)
	_show(_drills)

func _refresh_drill_rows() -> void :
	for id in _drill_rows:
		var entry: Dictionary = _drill_rows[id]
		var item: Dictionary = entry.item
		var row: Button = entry.button
		var saved: = _drill_progress.row(String(id))
		var status: = "coming soon"
		if bool(item.get("available", false)):
			status = "not complete"
			if bool(saved.get("complete", false)):
				status = "complete"
				var best: = int(saved.get("best_ms", 0))
				if best > 0:
					status += "   best %s" % _drill_time(best)
		var tag: = "   (advanced)" if bool(item.get("advanced", false)) else ""
		row.text = """%s%s
%s   %s""" %[String(item.name), tag, 
			String(item.objective), status]

	for cid in _drill_tabs:
		var counts: = DrillCatalog.category_counts(String(cid), _drill_progress)
		var cat_name: = ""
		for cat in DrillCatalog.CATEGORIES:
			if String(cat.id) == String(cid):
				cat_name = String(cat.name)
		(_drill_tabs[cid] as Button).text = cat_name if counts.y == 0 else "%s  %d/%d" % [cat_name, counts.x, counts.y]

func _build_drill_runtime() -> void :
	_drill_runner = DrillRunner.new()
	add_child(_drill_runner)
	_drill_runner.setup(player, ball)
	_drill_runner.progress_changed.connect( func(done: int, required: int):
		_drill_count.text = "%d / %d" % [done, required])
	_drill_runner.instruction_changed.connect( func(text: String):
		_drill_instruction.text = text)
	_drill_runner.completed.connect(_on_drill_completed)
	_drill_hud = PanelContainer.new()
	UiStyle.style_panel(_drill_hud, Color(UiStyle.card(), 0.96), UiStyle.RADIUS)
	_drill_hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_drill_hud.position = Vector2(32, 32)
	_drill_hud.custom_minimum_size = Vector2(390, 130)
	var hv: = VBoxContainer.new()
	hv.add_theme_constant_override("separation", 5)
	_drill_hud.add_child(hv)


	var head: = HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	hv.add_child(head)
	_drill_title = Label.new()
	UiStyle.style_label(_drill_title, "title")
	_drill_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_drill_title)
	_drill_count = Label.new()
	UiStyle.style_label(_drill_count, "title")
	head.add_child(_drill_count)
	_drill_instruction = Label.new()
	UiStyle.style_label(_drill_instruction, "body")
	hv.add_child(_drill_instruction)


	var foot: = HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	hv.add_child(foot)
	_drill_timer = Label.new()
	UiStyle.style_label(_drill_timer, "title", UiStyle.muted())
	_drill_timer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(_drill_timer)
	_drill_hud.visible = false
	ui.add_child(_drill_hud)
	_build_drill_info()
	_drill_runner.countdown_changed.connect( func(text: String):



		var number: = int(text) if text.is_valid_int() else 0
		if number > 0:
			hud.show_countdown(number)
		else:
			hud.hide_countdown())
	_drill_results = PanelContainer.new()
	UiStyle.style_panel(_drill_results, Color(UiStyle.card(), 0.98), UiStyle.RADIUS)
	_drill_results.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_drill_results.position = Vector2(-220, -150)
	_drill_results.custom_minimum_size = Vector2(440, 300)
	var rv: = VBoxContainer.new()
	rv.alignment = BoxContainer.ALIGNMENT_CENTER
	rv.add_theme_constant_override("separation", 12)
	_drill_results.add_child(rv)


	var badge: = PanelContainer.new()
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bb: = StyleBoxFlat.new()
	bb.bg_color = UiStyle.SUCCESS
	bb.set_corner_radius_all(20)
	bb.content_margin_left = 20.0
	bb.content_margin_right = 20.0
	bb.content_margin_top = 7.0
	bb.content_margin_bottom = 7.0
	badge.add_theme_stylebox_override("panel", bb)
	var complete: = Label.new()
	complete.text = "drill complete"
	complete.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	complete.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	complete.add_theme_font_size_override("font_size", 17)
	complete.add_theme_color_override("font_color", Color.WHITE)
	badge.add_child(complete)
	rv.add_child(badge)
	_drill_result_time = Label.new()
	_drill_result_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.style_label(_drill_result_time, "title")
	rv.add_child(_drill_result_time)
	var actions: = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)
	rv.add_child(actions)
	actions.add_child(_menu_btn("retry", "secondary", _retry_drill))
	actions.add_child(_menu_btn("drills", "secondary", _leave_drill))
	_drill_next = _menu_btn("finish", "primary", _next_drill)
	actions.add_child(_drill_next)
	_drill_results.visible = false
	ui.add_child(_drill_results)




func _build_drill_info() -> void :
	_drill_info = PanelContainer.new()
	UiStyle.style_panel(_drill_info, Color(UiStyle.card(), 0.96), UiStyle.RADIUS)
	_drill_info.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_drill_info.position = Vector2(-32 - 360, 32)
	_drill_info.custom_minimum_size = Vector2(360, 0)
	_drill_info_body = VBoxContainer.new()
	_drill_info_body.add_theme_constant_override("separation", 8)
	_drill_info.add_child(_drill_info_body)
	_drill_info.visible = false
	ui.add_child(_drill_info)
	if not InputPrompts.changed.is_connected(_refresh_drill_glyphs):
		InputPrompts.changed.connect(_refresh_drill_glyphs)




func _populate_drill_info(id: String) -> void :
	for c in _drill_info_body.get_children():
		c.queue_free()
	var entry: = DrillCatalog.entry(id)
	var inputs: Array = entry.get("inputs", [])
	if not inputs.is_empty():
		var head: = Label.new()
		head.text = "controls"
		UiStyle.style_label(head, "small")
		_drill_info_body.add_child(head)
		for pair in inputs:

			var action: = "aim" if String(pair[0]) == "@mouse" else String(pair[0])
			_drill_info_body.add_child(_drill_glyph_row(String(pair[1]), action))
	var note: = String(entry.get("info", ""))
	if note != "":
		if not inputs.is_empty():
			var sep: = HSeparator.new()
			_drill_info_body.add_child(sep)
		var info: = Label.new()
		info.text = note
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.custom_minimum_size.x = 320
		UiStyle.style_label(info, "body")
		_drill_info_body.add_child(info)




func _drill_glyph_row(verb: String, action: String) -> Control:
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var lbl: = Label.new()
	lbl.text = verb
	UiStyle.style_label(lbl, "body")
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	if action == "move":
		row.add_child(_drill_move_cluster())
	else:
		row.add_child(_glyph_plate(InputPrompts.glyph(action)))
	return row



func _drill_move_cluster() -> Control:
	if InputPrompts.using_gamepad():
		return _glyph_plate(InputPrompts.glyph("move"))
	var col: = VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 3)
	var top: = HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(_glyph_plate(_kbm_key("w"), Vector2(24, 20)))
	col.add_child(top)
	var bot: = HBoxContainer.new()
	bot.alignment = BoxContainer.ALIGNMENT_CENTER
	bot.add_theme_constant_override("separation", 3)
	for k in ["a", "s", "d"]:
		bot.add_child(_glyph_plate(_kbm_key(k), Vector2(24, 20)))
	col.add_child(bot)
	return col

func _kbm_key(name: String) -> Texture2D:
	var path: = "res://game/ui_icon/Keyboard & Mouse/Default/keyboard_%s.png" % name
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


func _glyph_plate(tex: Texture2D, min_size: = Vector2(30, 24)) -> PanelContainer:
	var plate: = PanelContainer.new()
	var pb: = StyleBoxFlat.new()
	pb.bg_color = Color("141a26") if UiStyle.dark else UiStyle.INK
	pb.set_corner_radius_all(8)
	pb.set_content_margin_all(5.0)
	pb.border_color = Color(1, 1, 1, 0.08)
	pb.set_border_width_all(1)
	plate.add_theme_stylebox_override("panel", pb)
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var icon: = TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = min_size
	icon.texture = tex
	plate.add_child(icon)
	return plate



func _refresh_drill_glyphs() -> void :
	if _drill_info != null and _drill_info.visible and _drill_active != "":
		_populate_drill_info(_drill_active)

func _start_drill(id: String) -> void :
	if DrillCatalog.entry(id).is_empty() or not bool(DrillCatalog.entry(id).get("available", false)):
		return
	_drill_active = id
	_drill_progress.record_attempt(id)


	if _drill_return_stage == "":
		_drill_return_stage = _freeplay_stage
		_swap_stage("void", false, false, true)
	_enter_freeplay()
	_fp_hint.text = "esc: leave drill     c: camera"
	_fp_hint.visible = true
	hud.set_serve_prompt("")
	_drill_title.text = String(DrillCatalog.entry(id).name)
	_populate_drill_info(id)
	_drill_info.visible = _drill_info_body.get_child_count() > 0


	_drill_hud.visible = false
	_drill_results.visible = false
	_ensure_drill_overlay(DrillCatalog.entry(id))
	_drill_runner.start(id)


func _ensure_drill_overlay(entry: Dictionary) -> void :
	if _drill_director != null and is_instance_valid(_drill_overlay):
		_drill_director.arm(entry)
		return
	_drill_overlay = TUTORIAL_OVERLAY.new()
	ui.add_child(_drill_overlay)
	ui.move_child(_drill_overlay, hud.get_index())
	_drill_director = DRILL_DIRECTOR.new()
	add_child(_drill_director)
	_drill_director.sfx = sfx
	_drill_director.setup(_drill_runner, _drill_overlay, entry)

func _teardown_drill_overlay() -> void :
	if _drill_director != null:
		_drill_director.teardown()
		_drill_director.queue_free()
		_drill_director = null
	_drill_overlay = null

func _retry_drill() -> void :
	_drill_progress.record_attempt(_drill_active)
	_drill_results.visible = false
	_drill_hud.visible = false
	_drill_info.visible = _drill_info_body.get_child_count() > 0
	_ensure_drill_overlay(DrillCatalog.entry(_drill_active))
	camera_rig.apply_mouse_mode()
	_drill_runner.retry()

func _on_drill_completed(id: String, elapsed_ms: int) -> void :
	if _tutorial != null:
		return
	_drill_progress.record_complete(id, elapsed_ms)
	_drill_hud.visible = false
	_drill_info.visible = false
	if _drill_director != null:
		_drill_director.hide()
	hud.hide_countdown()
	_drill_result_time.text = "%s\ntime %s" % [String(DrillCatalog.entry(id).name), 
		_drill_time(elapsed_ms)]


	if _guided:
		_drill_next.text = "next" if _guided_after(id) != "" else "play a rally!"
	else:
		var next: = DrillCatalog.next_available(id)
		_drill_next.text = "next" if next != "" else "finish"
	_drill_results.visible = true



	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameConfig.use_cursor(false)
	player.clear_action_state()

func _next_drill() -> void :
	if _guided:
		var nx: = _guided_after(_drill_active)
		if nx == "":
			_finish_tutorial()
		else:
			_start_drill(nx)
		return
	var next: = DrillCatalog.next_available(_drill_active)
	if next == "":
		_leave_drill()
	else:
		_start_drill(next)




func _offer_tutorial(preview: = false) -> void :
	if not is_inside_tree():
		return
	if not preview:
		if GameConfig.tutorial_seen:
			return


		GameConfig.tutorial_seen = true
		GameConfig.save_settings()
	UiStyle.confirm(self, "welcome to just volleyball!", 
		"if it's your first time playing, it's heavily recommended that you learn properly first!", 
		func(): _start_tutorial(), 
		"learn the basics", "don't need to!", "primary")

func _start_tutorial() -> void :
	_guided = true


	if _drill_return_stage == "":
		_drill_return_stage = _freeplay_stage
		_swap_stage("void", false, false, true)
	_drill_active = "tutorial"
	_enter_freeplay()

	DrillObjective.practice_dress = true
	player.set_character(GameConfig.character.gym_look(), GameConfig.character.gym_kit())
	MusicManager.play("gym")
	_fp_hint.visible = false
	hud.set_serve_prompt("")
	_drill_hud.visible = false
	_drill_info.visible = false
	_drill_results.visible = false
	player.clear_action_state()
	player.global_position = Vector3(0.0, 0.0, 6.0)
	player.team_side = 1
	player.face_net()
	player.reset_physics_interpolation()
	ball.frozen = true
	ball.vel = Vector3.ZERO
	ball.global_position = Vector3(0.0, -4.0, 0.0)
	var overlay: Control = TUTORIAL_OVERLAY.new()
	ui.add_child(overlay)

	ui.move_child(overlay, hud.get_index())
	_tutorial = TUTORIAL_DIRECTOR.new()
	add_child(_tutorial)
	_tutorial.setup(_drill_runner, overlay, _tutorial_section)
	_tutorial.cam_rig = camera_rig
	_drill_runner.cam_rig = camera_rig
	_tutorial.control_hud = hud.get_node_or_null("Controls")
	_tutorial.sfx = sfx
	_tutorial.finished.connect(_finish_tutorial)

	hud.pause_enabled = true
	(hud.get_node("PauseMenu") as PauseMenu).leave_override = _leave_drill


	(hud.get_node("PauseMenu") as PauseMenu).set_tutorial_skip( func():
		if _tutorial != null:
			_tutorial.skip_to_end())
	if not hud.pause_opened.is_connected(_on_tutorial_pause_opened):
		hud.pause_opened.connect(_on_tutorial_pause_opened)
		hud.pause_closed.connect(_on_tutorial_pause_closed)
	_tutorial.begin()



func _tutorial_section(objective_id: String) -> void :
	_drill_active = objective_id
	_drill_runner.start(objective_id, true)




func _on_tutorial_pause_opened() -> void :
	camera_rig.input_frozen = true
	_input_collector.swallow_held(["jump", "contact", "dive", "serve", "set"])
	_input_collector.clear_buffers()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_tutorial_pause_closed() -> void :


	camera_rig.input_frozen = _tutorial != null and _tutorial.blocking_input()
	_input_collector.swallow_held(["jump", "contact", "dive", "serve", "set"])
	_input_collector.clear_buffers()
	if _tutorial != null:
		camera_rig.apply_mouse_mode(false)

func _teardown_tutorial(back_to_menu: = true) -> void :
	if _tutorial == null:
		return
	_tutorial.teardown()
	_tutorial.queue_free()
	_tutorial = null
	hud.pause_enabled = false
	(hud.get_node("PauseMenu") as PauseMenu).leave_override = Callable()
	(hud.get_node("PauseMenu") as PauseMenu).set_tutorial_skip(Callable())
	if hud.pause_opened.is_connected(_on_tutorial_pause_opened):
		hud.pause_opened.disconnect(_on_tutorial_pause_opened)
		hud.pause_closed.disconnect(_on_tutorial_pause_closed)
	DrillObjective.practice_dress = false
	_apply_outfit()
	if back_to_menu:
		MusicManager.play("menu")


func _guided_after(id: String) -> String:
	var i: = GUIDED_PATH.find(id)
	if i == -1 or i + 1 >= GUIDED_PATH.size():
		return ""
	return String(GUIDED_PATH[i + 1])

func _finish_tutorial() -> void :
	_guided = false
	Achievements.notify("tutorial")
	_teardown_tutorial(false)



	if _drill_runner != null:
		_drill_runner.cancel()
	_drill_hud.visible = false
	_drill_info.visible = false
	_drill_results.visible = false
	_drill_active = ""
	_exit_freeplay()
	if _drill_return_stage != "":
		_drill_return_stage = ""


	GameConfig.pre_tutorial_settings = {
		"stage": GameConfig.stage, "difficulty": GameConfig.difficulty, 
		"team_size": GameConfig.team_size, "set_points": GameConfig.set_points, 
		"sets_to_win": GameConfig.sets_to_win, "win_by_two": GameConfig.win_by_two, 
		"local_side": GameConfig.local_side, 
	}
	GameConfig.set_points = 4
	GameConfig.sets_to_win = 1
	GameConfig.win_by_two = false
	GameConfig.difficulty = 0
	CpuSlots.set_all_diff(GameConfig.local_cpus, 0)
	GameConfig.simple_bot_serves = true
	GameConfig.tutorial_finale = true
	GameConfig.local_side = 1
	GameConfig.quick_match = false
	GameConfig.stage = "practice"
	_go_to_match(2)

func _leave_drill() -> void :
	_teardown_tutorial()
	_teardown_drill_overlay()
	if _drill_runner != null:
		_drill_runner.cancel()
	_drill_hud.visible = false
	_drill_info.visible = false
	hud.hide_countdown()
	_drill_results.visible = false
	_drill_active = ""
	_exit_freeplay()
	if _drill_return_stage != "":
		var back: = _drill_return_stage
		_drill_return_stage = ""
		_swap_stage(back, false, false, true)


	if _guided:
		_guided = false
		_show(_home)
	else:
		_open_drills()

func _drill_time(ms: int) -> String:
	return "%d:%02d.%02d" % [int(ms / 60000), int(ms / 1000) % 60, 
		int((ms % 1000) / 10)]

func _build_profile() -> void :
	var v: = _box(_profile)
	_hero_head(v, "profile", true)
	var prof: = ProfileStore.active()



	var scroll: = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(340, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UiStyle.style_scroll(scroll.get_v_scroll_bar())
	var body: = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)


	var body_pad: = MarginContainer.new()
	body_pad.add_theme_constant_override("margin_right", 18)
	body_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_pad.add_child(body)
	scroll.add_child(body_pad)




	var header: = HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	var av: = PanelContainer.new()
	UiStyle.style_panel(av, UiStyle.bg(), UiStyle.RADIUS)
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pfp: = TextureRect.new()
	pfp.custom_minimum_size = Vector2(96, 96)
	pfp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pfp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	av.add_child(pfp)
	header.add_child(av)
	_profile_pfp = pfp
	_load_profile_pfp.call_deferred(pfp)


	var idcol: = VBoxContainer.new()
	idcol.add_theme_constant_override("separation", 5)
	idcol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var name_l: = Label.new()



	name_l.text = prof.name if prof != null else Net.local_display_name()
	UiStyle.style_label(name_l, "title")
	idcol.add_child(name_l)
	var prog: = HBoxContainer.new()
	prog.add_theme_constant_override("separation", 16)
	var lvl: = Label.new()
	lvl.text = "lv. %d" % (prof.level if prof != null else 1)
	UiStyle.style_label(lvl, "body", UiStyle.muted())
	prog.add_child(lvl)
	var coinrow: = HBoxContainer.new()
	coinrow.add_theme_constant_override("separation", 6)
	coinrow.add_child(_coin_disc(18))
	var coins_l: = Label.new()
	coins_l.text = _comma(prof.coins if prof != null else 0)
	UiStyle.style_label(coins_l, "body")
	coinrow.add_child(coins_l)
	prog.add_child(coinrow)
	idcol.add_child(prog)

	if LaunchGate.public_beta():
		prog.visible = false
	header.add_child(idcol)




	var spring: = Control.new()
	spring.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spring)
	var prof_settings: = UiStyle.icon_button("wrench", "secondary", 40)
	prof_settings.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prof_settings.tooltip_text = "profile settings"
	prof_settings.pressed.connect( func(): _open_settings(SettingsPanel.Scope.PROFILE))
	header.add_child(prof_settings)
	body.add_child(header)
	_build_profile_hub(body, prof)
	var m: = int(Career.data.get("matches", 0))
	var rows: = [
		["matches", str(m)], 
		["wins", str(int(Career.data.get("wins", 0)))], 
		["losses", str(m - int(Career.data.get("wins", 0)))], 
		["winrate", "%d%%" % int(roundf(Career.winrate() * 100.0))], 
		["points", str(int(Career.data.get("points", 0)))], 
		["spikes", str(int(Career.data.get("spikes", 0)))], 
		["blocks", str(int(Career.data.get("blocks", 0)))], 
		["receives", str(int(Career.data.get("receives", 0)))], 
		["sets", str(int(Career.data.get("sets", 0)))], 
		["assists", str(int(Career.data.get("assists", 0)))], 
		["playtime", "%.1f h" % (float(Career.data.get("playtime", 0.0))
			/ 3600.0)], 
	]

	var grid: = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 7)
	for r in rows:
		var cell: = HBoxContainer.new()
		cell.custom_minimum_size.x = 195
		var k: = Label.new()
		k.text = r[0]
		UiStyle.style_label(k, "small")
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_child(k)
		var val: = Label.new()
		val.text = r[1]
		UiStyle.style_label(val, "body")
		cell.add_child(val)
		grid.add_child(cell)
	body.add_child(grid)
	v.add_child(scroll)



	var bottom: = HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	var back_b: = _menu_btn("back", "tertiary", _back_to_hub)
	back_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(back_b)
	if not ProfileStore.recently_deleted.is_empty():
		var recent_b: = Button.new()
		recent_b.text = "recently deleted (%d)" % ProfileStore.recently_deleted.size()
		UiStyle.style_button(recent_b, "secondary", 14)
		recent_b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		recent_b.pressed.connect( func(): _show(_recent))
		bottom.add_child(recent_b)
	v.add_child(bottom)




func _build_profile_hub(v: VBoxContainer, prof: SavedProfile) -> void :
	if prof == null:
		return

	var srow: = HBoxContainer.new()
	srow.add_theme_constant_override("separation", 10)
	var names: Array = []
	for p in ProfileStore.profiles:
		names.append(p.name)
	var picker: = UiSelect.new(names)
	picker.selected = ProfileStore.active_index
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.picked.connect( func(idx: int):
		ProfileStore.switch_to(idx)
		_refresh_profile())
	srow.add_child(picker)
	var new_b: = Button.new()
	new_b.text = "new"
	UiStyle.style_button(new_b, "secondary", 16)
	new_b.disabled = ProfileStore.profiles.size() >= ProfileStore.PROFILE_MAX
	new_b.pressed.connect( func():
		if ProfileStore.create_profile("Profile %d"
				%(ProfileStore.profiles.size() + 1)) != null:
			ProfileStore.switch_to(ProfileStore.profiles.size() - 1)
		_refresh_profile())
	srow.add_child(new_b)
	v.add_child(srow)

	var rrow: = HBoxContainer.new()
	rrow.add_theme_constant_override("separation", 10)
	var rename_edit: = LineEdit.new()
	rename_edit.text = prof.name
	rename_edit.max_length = SavedProfile.NAME_MAX
	rename_edit.placeholder_text = "name"
	rename_edit.custom_minimum_size = Vector2(180, 44)
	rename_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.style_line_edit(rename_edit)
	var do_rename: = func():
		ProfileStore.rename_profile(ProfileStore.active_index, rename_edit.text)
		_refresh_profile()
	rename_edit.text_submitted.connect( func(_t: String): do_rename.call())
	rrow.add_child(rename_edit)
	var rename_b: = Button.new()
	rename_b.text = "rename"
	UiStyle.style_button(rename_b, "secondary", 16)
	rename_b.pressed.connect(do_rename)
	rrow.add_child(rename_b)
	var del_b: = Button.new()
	del_b.text = "delete"
	UiStyle.style_button(del_b, "tertiary", 16)

	del_b.disabled = ProfileStore.profiles.size() <= 1 or ProfileStore.active_index == 0
	del_b.pressed.connect( func():
		var nm: String = prof.name

		UiStyle.confirm(self, "delete %s?" % nm, 
			"this profile will be moved into recently deleted and is recoverable", 
			func():
				ProfileStore.delete_profile(ProfileStore.active_index)


				_refresh_recent(), 
			"delete", "cancel", "exit", 5.0)
	)
	rrow.add_child(del_b)
	v.add_child(rrow)









var _ach_tabs: TabContainer = null

func _show_achievements() -> void :


	_ach_new = Achievements.unseen_ids()
	if "--badge-demo" in OS.get_cmdline_user_args():
		_ach_new = ["d_avatar", "getting_better", "w_play_20"]
	_rebuild_achievements()
	if not _ach_new.is_empty() and is_instance_valid(_ach_tabs):
		var first_kind: = ""
		for d in Achievements.defs():
			if d.id == _ach_new[0]:
				first_kind = d.kind
				break
		var tab_index: = _ach_tab_kinds.find(first_kind)
		if tab_index >= 0:
			_ach_tabs.current_tab = tab_index
	_show(_achievements)


func _ach_dismiss(id: String, card: Control) -> void :
	if not id in _ach_new:
		return
	_ach_new.erase(id)
	Achievements.mark_seen(id)
	if is_instance_valid(card):
		var sb: = card.get_theme_stylebox("panel")
		if sb is StyleBoxFlat:
			sb = sb.duplicate()
			(sb as StyleBoxFlat).border_color = Color(0, 0, 0, 0)
			card.add_theme_stylebox_override("panel", sb)
		var pill: Control = card.get_meta("pill", null)
		if is_instance_valid(pill):
			pill.visible = false
		var shine: Tween = card.get_meta("shine", null)
		if shine != null and shine.is_valid():
			shine.kill()
		var disc: Control = card.get_meta("disc", null)
		if is_instance_valid(disc):
			disc.modulate = Color.WHITE
	_refresh_ach_tab_badges()


func _ach_dismiss_kind(kind: String) -> void :
	var gone: Array = []
	for d in Achievements.defs(kind):
		if d.id in _ach_new:
			gone.append(d.id)
	for id in gone:
		_ach_new.erase(id)
		Achievements.mark_seen(id)
	if not gone.is_empty():
		_refresh_ach_tab_badges()

func _on_ach_tab_changed(_to: int) -> void :
	var from: int = _achievements.get_meta("ach_tab", 0) if is_instance_valid(_achievements) else 0
	if from >= 0 and from < _ach_tab_kinds.size() and _ach_tab_kinds[from] != "":
		_ach_dismiss_kind(_ach_tab_kinds[from])
	if is_instance_valid(_achievements):
		_achievements.set_meta("ach_tab", _to)


func _refresh_ach_tab_badges() -> void :
	if not is_instance_valid(_ach_tabs):
		return
	var bar: = _ach_tabs.get_tab_bar()
	for i in _ach_tab_badges.size():
		var old: Control = _ach_tab_badges[i]
		if is_instance_valid(old):
			old.queue_free()
	_ach_tab_badges = []
	for i in mini(_ach_tabs.get_tab_count(), _ach_tab_kinds.size()):
		var kind: String = _ach_tab_kinds[i]
		var n: = 0
		if kind != "":
			for d in Achievements.defs(kind):
				if d.id in _ach_new:
					n += 1
		if n <= 0:
			_ach_tab_badges.append(null)
			continue
		var b: = Label.new()
		b.text = str(n)
		b.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
		b.add_theme_font_size_override("font_size", 11)
		b.add_theme_color_override("font_color", Color.WHITE)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var sb: = StyleBoxFlat.new()
		sb.bg_color = UiStyle.RED
		sb.set_corner_radius_all(9)
		sb.content_margin_left = 5
		sb.content_margin_right = 5
		b.add_theme_stylebox_override("normal", sb)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.z_index = 2
		bar.add_child(b)
		var r: = bar.get_tab_rect(i)
		b.reset_size()
		b.custom_minimum_size = Vector2(18, 18)
		b.position = Vector2(r.position.x + r.size.x - 14.0, r.position.y - 4.0)
		_ach_tab_badges.append(b)


func _refresh_awards_badge() -> void :
	if not is_instance_valid(_awards_tab):
		return
	var n: = Achievements.unseen_count()
	if "--badge-demo" in OS.get_cmdline_user_args():
		n = 3
	if n <= 0:
		if is_instance_valid(_awards_badge):
			_awards_badge.queue_free()
			_awards_badge = null
		return
	if not is_instance_valid(_awards_badge):
		var b: = Label.new()
		b.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", Color.WHITE)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var sb: = StyleBoxFlat.new()
		sb.bg_color = UiStyle.RED
		sb.set_corner_radius_all(10)
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		b.add_theme_stylebox_override("normal", sb)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.z_index = 2
		_awards_tab.add_child(b)
		_awards_badge = b
	_awards_badge.text = str(n) if n < 100 else "99+"
	_awards_badge.custom_minimum_size = Vector2(20, 20)
	_place_awards_badge.call_deferred()

func _place_awards_badge() -> void :
	if not is_instance_valid(_awards_badge) or not is_instance_valid(_awards_tab):
		return
	_awards_badge.reset_size()
	_awards_badge.position = Vector2(_awards_tab.size.x - _awards_badge.size.x + 6, -6)

func _rebuild_achievements() -> void :
	if not is_instance_valid(_achievements):
		return
	var v: = _box(_achievements)
	if v == null:
		return
	var keep: = _ach_tabs.current_tab if is_instance_valid(_ach_tabs) else 0
	for c in v.get_children():
		v.remove_child(c)
		c.queue_free()
	_build_achievements()
	if is_instance_valid(_ach_tabs) and keep < _ach_tabs.get_tab_count():
		_ach_tabs.current_tab = keep


func _on_achievement_moved(_def: AchievementDef, _a: Variant, _b: Variant) -> void :
	if is_instance_valid(_achievements) and _achievements.visible:
		_rebuild_achievements()

func _build_achievements() -> void :
	var v: = _box(_achievements)
	v.custom_minimum_size.x = 620
	_hero_head(v, "achievements", true)
	var tabs: = TabContainer.new()
	_ach_tabs = tabs
	tabs.custom_minimum_size = Vector2(620, 400)
	tabs.tab_alignment = TabBar.ALIGNMENT_CENTER
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.style_tabs(tabs)
	tabs.tab_changed.connect(_on_ach_tab_changed)
	_achievements.set_meta("ach_tab", 0)
	_ach_tab(tabs, "daily", "daily", "resets in %s" % _ach_clock(Achievements.period_left("daily")))
	_ach_tab(tabs, "weekly", "weekly", "resets in %s" % _ach_clock(Achievements.period_left("weekly")))
	_ach_tab(tabs, "my profile", "global", "this profile's set")
	_ach_tab(tabs, "steam", "global", "earned on this machine" + (
		"" if Achievements.is_steam_live() else "   steam offline"), true)
	v.add_child(tabs)
	v.add_child(_menu_btn("back", "tertiary", _back_to_hub))
	_refresh_ach_tab_badges.call_deferred()



func _ach_tab(tabs: TabContainer, tab_name: String, kind: String, sub: String, 
		machine: = false) -> void :
	var scroll: = ScrollContainer.new()
	scroll.name = tab_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UiStyle.style_scroll(scroll.get_v_scroll_bar())
	var pad: = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_%s" % side, 12)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(pad)
	var col: = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	pad.add_child(col)
	tabs.add_child(scroll)
	var defs: Array = Achievements.defs(kind)
	var done: = 0
	for d in defs:
		if (Achievements.machine_done(d) if machine else bool(Achievements.progress(d).done)):
			done += 1
	var head: = HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var count: = Label.new()
	count.text = "%d / %d done" % [done, defs.size()]
	UiStyle.style_label(count, "small")
	head.add_child(count)
	var spring: = Control.new()
	spring.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spring)
	var s2: = Label.new()
	s2.text = sub
	UiStyle.style_label(s2, "small")
	head.add_child(s2)
	col.add_child(head)
	for d in defs:
		col.add_child(_ach_row(d, machine))

func _ach_row(d: AchievementDef, machine: bool) -> Control:
	var card: = PanelContainer.new()
	var finished: bool
	var value: = 0
	var when : = 0
	if machine:
		finished = Achievements.machine_done(d)
		when = Achievements.machine_done_at(d)
	else:
		var pr: = Achievements.progress(d)
		finished = bool(pr.done)
		value = int(pr.v)
		when = int(pr.at)
	UiStyle.style_panel(card, UiStyle.bg() if finished else UiStyle.card(), UiStyle.RADIUS)
	var is_new: = (d.id in _ach_new) and not machine

	var sb: = card.get_theme_stylebox("panel")
	if sb != null:
		sb = sb.duplicate()
		sb.content_margin_left = 12
		sb.content_margin_right = 14
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8


		sb.set_border_width_all(3)
		sb.border_color = UiStyle.PRIMARY if is_new else Color(0, 0, 0, 0)
		card.add_theme_stylebox_override("panel", sb)
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var disc: = TextureRect.new()
	disc.texture = UiStyle.icon_disc("medal1" if finished else "medal2", 
		UiStyle.PRIMARY if finished else Color(UiStyle.muted(), 0.35), 34)
	disc.custom_minimum_size = Vector2(34, 34)
	disc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	disc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(disc)
	if is_new:

		var shine: = disc.create_tween().set_loops()
		shine.tween_property(disc, "modulate", Color(1.14, 1.12, 1.0), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		shine.tween_property(disc, "modulate", Color.WHITE, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		card.set_meta("shine", shine)
		card.set_meta("disc", disc)
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		card.mouse_entered.connect( func(): _ach_dismiss(d.id, card))
	var col: = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 0)
	var title: = Label.new()
	title.text = d.title
	UiStyle.style_label(title, "body")
	title.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	col.add_child(title)
	var desc: = Label.new()
	desc.text = d.desc
	UiStyle.style_label(desc, "small")
	col.add_child(desc)

	if d.target > 1 and not machine:
		var bar: = ProgressBar.new()
		bar.min_value = 0.0
		bar.max_value = float(d.target)
		bar.value = float(value if not finished else d.target)
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 8)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiStyle.style_progress(bar)
		var wrap: = MarginContainer.new()
		wrap.add_theme_constant_override("margin_top", 6)
		wrap.add_theme_constant_override("margin_right", 24)
		wrap.add_child(bar)
		col.add_child(wrap)
	row.add_child(col)
	var right: = VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.add_theme_constant_override("separation", 0)
	if is_new:
		var pill: = Label.new()
		pill.text = "new"
		pill.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
		pill.add_theme_font_size_override("font_size", 11)
		pill.add_theme_color_override("font_color", UiStyle.INK)
		var ps: = StyleBoxFlat.new()
		ps.bg_color = UiStyle.PRIMARY
		ps.set_corner_radius_all(8)
		ps.content_margin_left = 7
		ps.content_margin_right = 7
		ps.content_margin_top = 1
		ps.content_margin_bottom = 1
		pill.add_theme_stylebox_override("normal", ps)
		pill.size_flags_horizontal = Control.SIZE_SHRINK_END
		right.add_child(pill)
		card.set_meta("pill", pill)
	if finished:

		var tick: = TextureRect.new()
		tick.texture = UiStyle.icon_disc("checkmark", UiStyle.SUCCESS, 22)
		tick.custom_minimum_size = Vector2(22, 22)
		tick.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tick.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tick.size_flags_horizontal = Control.SIZE_SHRINK_END
		right.add_child(tick)
	else:
		var status: = Label.new()
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status.text = d.progress_text(value) if d.target > 1 else ""
		UiStyle.style_label(status, "body")
		right.add_child(status)
	if d.coins > 0 and not finished:
		var reward: = HBoxContainer.new()
		reward.alignment = BoxContainer.ALIGNMENT_END
		reward.add_theme_constant_override("separation", 4)
		reward.add_child(_coin_disc(14))
		var amt: = Label.new()
		amt.text = str(d.coins)
		UiStyle.style_label(amt, "small")
		reward.add_child(amt)
		right.add_child(reward)
	elif finished and when > 0:
		var at: = Label.new()
		var dd: = Time.get_datetime_dict_from_unix_time( when )
		at.text = "%02d/%02d" % [int(dd.month), int(dd.day)]
		UiStyle.style_label(at, "small")
		at.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right.add_child(at)
	row.add_child(right)
	return card

func _ach_clock(seconds: int) -> String:
	var h: = seconds / 3600
	var m: = (seconds % 3600) / 60
	if h >= 48:
		return "%dd %dh" % [h / 24, h % 24]
	return "%dh %02dm" % [h, m]

func _refresh_profile() -> void :
	_rebuild_profile.call_deferred()

func _rebuild_profile() -> void :
	if not is_instance_valid(_profile):
		return
	var v: = _box(_profile)
	if v == null:
		return
	for c in v.get_children():
		v.remove_child(c)
		c.queue_free()
	_build_profile()



	if player != null and GameConfig.character != null:
		_apply_outfit()
		_broadcast_menu_look()
	if _profile_pfp != null:
		_load_profile_pfp.call_deferred(_profile_pfp)


	_refresh_player_card()
	if _pc_avatar != null:
		_load_card_pfp.call_deferred(_pc_avatar)
	_focus_current_page.call_deferred()



func _build_recent() -> void :
	var v: = _box(_recent)
	_hero_head(v, "recently deleted", true)
	if ProfileStore.recently_deleted.is_empty():
		var empty: = Label.new()
		empty.text = "no profiles"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size.x = 320
		UiStyle.style_label(empty, "small")
		v.add_child(empty)
	else:
		var full: = ProfileStore.profiles.size() >= ProfileStore.PROFILE_MAX
		for i in ProfileStore.recently_deleted.size():
			var p: SavedProfile = ProfileStore.recently_deleted[i]
			var idx: = i
			var row: = HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			var nm: = Label.new()
			nm.text = p.name
			UiStyle.style_label(nm, "body")
			nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(nm)
			var restore_b: = Button.new()
			restore_b.text = "restore"
			UiStyle.style_button(restore_b, "secondary", 16)
			restore_b.disabled = full
			restore_b.pressed.connect( func():
				ProfileStore.restore_profile(idx)
				_refresh_recent())
			row.add_child(restore_b)
			var purge_b: = Button.new()
			purge_b.text = "remove"
			UiStyle.style_button(purge_b, "tertiary", 16)
			purge_b.pressed.connect( func():
				UiStyle.confirm(self, "remove %s for good?" % p.name, 
					"this action cannot be undone", 
					func():
						ProfileStore.purge_deleted(idx)
						_refresh_recent(), 
					"remove", "cancel", "exit", 5.0))
			row.add_child(purge_b)
			v.add_child(row)
		var all_b: = _menu_btn("delete all", "exit", func():
			UiStyle.confirm(self, "remove every deleted profile for good?", 
				"this action cannot be undone", 
				func():
					ProfileStore.purge_all_deleted()
					_refresh_recent(), 
				"delete all", "cancel", "exit", 5.0))
		v.add_child(all_b)
	v.add_child(_menu_btn("back", "tertiary", func(): _show(_profile)))

func _refresh_recent() -> void :
	_rebuild_recent.call_deferred()

func _rebuild_recent() -> void :
	if not is_instance_valid(_recent):
		return
	var v: = _box(_recent)
	if v == null:
		return
	for c in v.get_children():
		v.remove_child(c)
		c.queue_free()
	_build_recent()
	_refresh_profile()
	_focus_current_page.call_deferred()


func _load_profile_pfp(rect: TextureRect) -> void :
	var tex: = await CharacterPortrait.render(GameConfig.character, "upper", 
		Vector2i(220, 220), self)
	if is_instance_valid(rect):
		rect.texture = tex




func _build_quick() -> void :
	var v: = _box(_quick)
	v.custom_minimum_size.x = 470
	v.add_theme_constant_override("separation", 14)
	_hero_head(v, "quick match", true)
	var pick: = Label.new()
	pick.text = "filter modes"
	UiStyle.style_label(pick, "small", UiStyle.muted())
	v.add_child(pick)



	var grid: = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for n in [1, 2, 3, 4, 5, 6]:
		var tile: = Button.new()
		tile.text = "%dv%d" % [n, n]
		tile.toggle_mode = true
		tile.custom_minimum_size = Vector2(142, 66)
		UiStyle.style_button(tile, "secondary", 23)
		tile.toggled.connect( func(on: bool):
			UiStyle.style_button(tile, "primary" if on else "secondary", 23)
			if on and _quick_any.button_pressed:
				_quick_any.set_pressed_no_signal(false)
				UiStyle.style_button(_quick_any, "secondary", 20))
		_quick_chips[n] = tile
		_lean.append(tile)
		grid.add_child(tile)
	v.add_child(grid)
	_quick_any = Button.new()
	_quick_any.text = "any mode"
	_quick_any.toggle_mode = true
	_quick_any.custom_minimum_size = Vector2(0, 54)
	_quick_any.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.style_button(_quick_any, "secondary", 20)
	_quick_any.toggled.connect( func(on: bool):
		UiStyle.style_button(_quick_any, 
			"primary" if on else "secondary", 20)
		if on:
			for n in _quick_chips:
				(_quick_chips[n] as Button).set_pressed_no_signal(false)
				UiStyle.style_button(_quick_chips[n], "secondary", 23))
	_lean.append(_quick_any)
	v.add_child(_quick_any)
	_quick_fresh = CheckBox.new()
	_quick_fresh.text = "fresh matches only"
	UiStyle.style_check(_quick_fresh)
	v.add_child(_quick_fresh)
	v.add_child(_card_btn("massiveMultiplayer", "find match", 
		MenuCopy.sub("find_match"), "primary", _find_quick))
	_back_row(v, func(): _show(_online))

func _build_matchmaking() -> void :
	_qp = QuickPlay.new()
	add_child(_qp)
	_qp.status.connect( func(t: String):
		if _mm_label != null:
			_mm_label.text = t
		if _mm_chip_label != null:
			_mm_chip_label.text = t)
	_qp.failed.connect( func(r: String):
		if _mm_label != null:
			_mm_label.text = r
		var tree: = get_tree()
		if tree != null:
			await tree.create_timer(2.5).timeout
		if _qp.state == QuickPlay.State.IDLE:
			_set_matchmaking(false))
	_qp.locked.connect( func():
		if _mm_cancel != null:
			_mm_cancel.disabled = true
		if _mm_title != null:
			_mm_title.text = "match found!")
	_qp.quick_start.connect(_quick_freeze_and_start)
	Net.match_started.connect(_menu_match_started)




	_mm_chip = PanelContainer.new()
	var cb: = UiStyle.card_box(Color(UiStyle.card(), 0.96), 99)
	cb.content_margin_left = 10.0
	cb.content_margin_right = 18.0
	cb.content_margin_top = 6.0
	cb.content_margin_bottom = 6.0
	cb.shadow_size = 8
	cb.shadow_offset = Vector2(0, 3)
	_mm_chip.add_theme_stylebox_override("panel", cb)
	var chip_row: = HBoxContainer.new()
	chip_row.add_theme_constant_override("separation", 10)
	_mm_chip.add_child(chip_row)
	var ring: = SearchRing.new()
	ring.custom_minimum_size = Vector2(22, 22)
	ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip_row.add_child(ring)
	var chip_col: = VBoxContainer.new()
	chip_col.add_theme_constant_override("separation", -2)
	chip_row.add_child(chip_col)
	var chip_title: = Label.new()
	chip_title.text = "finding a match"
	chip_title.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	chip_title.add_theme_font_size_override("font_size", 15)
	chip_title.add_theme_color_override("font_color", UiStyle.text())
	chip_col.add_child(chip_title)
	_mm_chip_label = Label.new()
	_mm_chip_label.text = "matchmaking..."
	UiStyle.style_label(_mm_chip_label, "small", UiStyle.muted())
	chip_col.add_child(_mm_chip_label)
	_mm_chip.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_mm_chip.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_mm_chip.offset_top = 14.0
	_mm_chip.visible = false
	ui.add_child(_mm_chip)


class SearchRing extends Control:
	var _a: = 0.0
	func _process(delta: float) -> void :
		_a += delta * 4.2
		queue_redraw()
	func _draw() -> void :
		var c: = size * 0.5
		var r: = minf(size.x, size.y) * 0.5 - 2.0
		draw_arc(c, r, 0.0, TAU, 32, Color(UiStyle.SUCCESS, 0.25), 3.0, true)
		draw_arc(c, r, _a, _a + 1.9, 16, UiStyle.SUCCESS, 3.0, true)



func _set_matchmaking(on: bool) -> void :
	_bottom_panel.add_theme_stylebox_override("panel", 
		_bar_green if on else _bar_normal)


	_tint_player_card(on)
	_mm_title.visible = on
	_mm_label.visible = on
	_mm_cancel.visible = on
	_mm_cancel.disabled = false
	_mm_title.text = "matchmaking..."
	if _freeplay:
		_bottom_panel.visible = on or not _freeplay
		if _pc_avatar != null:
			_pc_avatar.visible = _bottom_panel.visible



func _party_queue_when_formed(sz: int, give_up: float) -> void :
	var waited: = 0.0
	while Net.party_members().size() < 2 and waited < give_up:
		await get_tree().create_timer(0.25).timeout
		waited += 0.25
	await get_tree().create_timer(0.5).timeout
	if _quick_chips.has(sz):
		(_quick_chips[sz] as Button).button_pressed = true
	_find_quick()

func _find_quick() -> void :

	if Net.party and not Net.is_host:
		_flash_notice("only the party leader can queue")
		return
	if not OnlineTerms.require(_find_quick):
		return

	if _qp.state != QuickPlay.State.IDLE:
		_qp.cancel()
	var modes: Array = []
	for n in _quick_chips:
		if (_quick_chips[n] as Button).button_pressed:
			modes.append(n)
	if modes.is_empty() or _quick_any.button_pressed:
		modes = [1, 2, 3, 4, 5, 6]


	if Net.party:
		var floor_size: = Net.party_members().size()
		modes = modes.filter( func(m): return int(m) >= floor_size)
		if modes.is_empty():
			_flash_notice("your party of %d needs a bigger mode" % floor_size)
			return
	modes.sort()
	Net.my_name = Net.local_display_name()
	if Input.is_key_pressed(KEY_SHIFT):
		_qp.force_lan = true
	if Net.party:



		_qp.party_block = Net.party_members()
		_qp.begin(modes, _quick_fresh.button_pressed, true)
	else:
		_qp.begin(modes, _quick_fresh.button_pressed)
	_mm_label.text = "searching"
	_set_matchmaking(true)
	_update_presence()
	_show(_home)





func _build_friends_panel() -> void :
	_friends_panel = PanelContainer.new()
	UiStyle.style_panel(_friends_panel, UiStyle._AUTO, UiStyle.RADIUS_SOFT)
	_friends_panel.visible = false
	var pad: = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_%s" % side, 14)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.custom_minimum_size.x = 300


	_hero_head(v, "friends", true)
	var scroll: = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UiStyle.style_scroll(scroll.get_v_scroll_bar())
	_friends_list = VBoxContainer.new()
	_friends_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_friends_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_friends_list)
	v.add_child(scroll)
	pad.add_child(v)
	_friends_panel.add_child(pad)


	_friends_scrim = Control.new()
	_friends_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_friends_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_friends_scrim.visible = false
	_friends_scrim.gui_input.connect( func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_close_friends_panel())
	ui.add_child(_friends_scrim)
	ui.add_child(_friends_panel)
	_friends_panel.anchor_left = 1.0
	_friends_panel.anchor_right = 1.0
	_friends_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_friends_panel.grow_vertical = Control.GROW_DIRECTION_END
	_friends_panel.offset_right = -24.0
	_friends_panel.offset_top = 96.0

func _toggle_friends_panel() -> void :
	if _friends_panel == null:
		return
	if _friends_panel.visible:
		_close_friends_panel()
		return
	_friends_panel.visible = true
	_friends_scrim.visible = true
	_refresh_friends_panel()
	UiStyle.sfx("open")
	_focus_friends_first.call_deferred()

func _close_friends_panel() -> void :
	if _friends_panel == null or not _friends_panel.visible:
		return
	_friends_panel.visible = false
	_friends_scrim.visible = false
	UiStyle.sfx("close")

	if InputPrompts.using_gamepad() and _friends_btn != null:
		_friends_btn.grab_focus()

func _focus_friends_first() -> void :
	var btns: = _panel_buttons(_friends_panel)
	if not btns.is_empty():
		(btns[0] as Control).grab_focus()


func _panel_buttons(root: Node) -> Array:
	var out: Array = []
	if root == null:
		return out
	for c in root.find_children("*", "BaseButton", true, false):
		var b: = c as BaseButton
		if b != null and b.is_visible_in_tree() and not b.disabled\
		and b.focus_mode != Control.FOCUS_NONE:
			out.append(b)
	return out



func _drive_friends(delta: float) -> void :
	_nav_cooldown = maxf(_nav_cooldown - delta, 0.0)
	_accept_cd = maxf(_accept_cd - delta, 0.0)
	if Input.is_action_just_pressed("ui_cancel"):
		_close_friends_panel()
		return
	if Input.is_action_just_pressed("ui_accept") and _accept_cd <= 0.0:
		_accept_cd = ACCEPT_DEBOUNCE
		var foc: = get_viewport().gui_get_focus_owner()
		if foc is BaseButton and not (foc as BaseButton).disabled:
			(foc as BaseButton).pressed.emit()
		return
	var dir: = ""
	if Input.is_action_pressed("ui_down"): dir = "down"
	elif Input.is_action_pressed("ui_up"): dir = "up"
	if dir == "":
		_nav_dir = ""
		return
	if dir != _nav_dir:
		_nav_dir = dir
		_nav_repeat = NAV_FIRST_DELAY
		if _nav_cooldown <= 0.0:
			_nav_cooldown = NAV_DEBOUNCE
			_friends_step(dir)
	elif _nav_repeat <= 0.0:
		_nav_repeat = NAV_REPEAT_RATE
		_friends_step(dir)
	else:
		_nav_repeat -= delta

func _friends_step(dir: String) -> void :
	var btns: = _panel_buttons(_friends_panel)
	if btns.is_empty():
		return
	var foc: = get_viewport().gui_get_focus_owner()
	var i: = btns.find(foc)
	if i == -1:
		(btns[0] as Control).grab_focus()
		UiStyle.sfx("hover")
		return
	var step: = 1 if dir == "down" else -1
	var nxt: = btns[(i + step + btns.size()) % btns.size()] as Control
	nxt.grab_focus()
	_scroll_follow(nxt)
	UiStyle.sfx("hover")

func _refresh_friends_panel() -> void :
	if _friends_list == null or not _friends_panel.visible:
		return
	for c in _friends_list.get_children():
		c.queue_free()
	var friends: = Net.steam_friends()
	if friends.is_empty():
		var none: = Label.new()
		none.text = "no friends online"
		UiStyle.style_label(none, "small")
		_friends_list.add_child(none)
		return
	for f in friends:
		_friends_list.add_child(_friend_row(f))

func _friend_row(f: Dictionary) -> Control:
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var col: = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var in_game: bool = f.get("in_game", false)
	var nm: = Label.new()
	nm.text = String(f.get("name", "friend"))
	UiStyle.style_label(nm, "body", 
		UiStyle.SUCCESS if in_game else UiStyle.text())
	col.add_child(nm)
	var status: = String(f.get("status", ""))
	if not in_game:
		status = "online"
	elif status == "":
		status = "in just volleyball"
	var st: = Label.new()
	st.text = status
	UiStyle.style_label(st, "small")
	col.add_child(st)
	row.add_child(col)


	if in_game and int(f.get("lobby", 0)) != 0\
	and not _friend_in_my_party(int(f.get("id", 0))):
		var join: = Button.new()
		join.text = "join"
		UiStyle.style_button(join, "secondary", 13)
		join.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		join.pressed.connect( func(): Net.steam_join_friend_lobby(int(f.lobby)))
		row.add_child(join)



	if Net.is_host and Net.steam_lobby_id != 0:
		var fid: = int(f.get("id", 0))
		if _friend_in_my_party(fid):
			var tag: = Label.new()
			tag.text = "in party"
			UiStyle.style_label(tag, "small", UiStyle.SUCCESS)
			tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(tag)
		elif _invite_pending(fid):
			var sent: = Button.new()
			sent.text = "invited"
			UiStyle.style_button(sent, "tertiary", 13)
			sent.disabled = true
			sent.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(sent)
		else:
			var inv: = Button.new()
			inv.text = "invite"
			UiStyle.style_button(inv, "primary", 13)
			inv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			inv.pressed.connect( func():
				Net.steam_invite_friend(fid)
				_invited_ids[fid] = Time.get_ticks_msec()
				_refresh_friends_panel())
			row.add_child(inv)
	return row



const INVITE_PENDING_MS: = 30000
func _invite_pending(fid: int) -> bool:
	return _invited_ids.has(fid)\
	and Time.get_ticks_msec() - int(_invited_ids[fid]) < INVITE_PENDING_MS


func _friend_in_my_party(sid: int) -> bool:
	if not Net.party or sid == 0:
		return false
	for pid in Net.party_members():
		if int((Net.players[pid] as Dictionary).get("sid", 0)) == sid:
			return true
	return false



func _update_presence() -> void :
	var text: = "in the menu"
	var group: = ""
	var gsize: = 0
	var queuing: bool = _member_queuing\
	or (_qp != null and _qp.state != QuickPlay.State.IDLE)
	if Net.party:
		group = "party%d" % Net.session_token
		gsize = Net.party_members().size()
		if queuing:
			text = "looking for a match with friends"
		elif _freeplay:
			text = "warming up with a party"
		else:
			text = "in a party of %d" % gsize
	elif _freeplay:
		text = "in freeplay"
	elif queuing:
		text = "looking for a match"
	Net.set_presence(text, group, gsize)

func _on_member_quick_status(line: String) -> void :




	if Net.is_host or not (Net.party or Net.i_am_fold()):
		return
	if line == "":
		_member_queuing = false
		_set_matchmaking(false)
		_mm_chip.visible = false
		return
	_member_queuing = true
	_mm_title.text = "matchmaking..."
	_mm_label.text = line
	if _mm_chip_label != null:
		_mm_chip_label.text = line

	if _freeplay:
		_mm_chip.visible = true
		_set_matchmaking(false)
	else:
		_mm_chip.visible = false
		_set_matchmaking(true)


		_mm_cancel.visible = Net.i_am_fold()



func _quick_freeze_and_start() -> void :
	var ids: = Net.players.keys()
	ids.sort()
	var kits: = Net.captain_kits(Net.players)
	var roster: = Net.build_roster(ids, Net.players, Net.team_size, kits)
	GameConfig.set_mode(Net.team_size)
	GameConfig.stage = Net.stage
	GameConfig.ranked_match = false
	Net.start_match(roster, randi())

func _menu_match_started(roster: Array) -> void :

	if _feedback != null and is_instance_valid(_feedback):
		_feedback.queue_free()
		_feedback = null
	GameConfig.set_mode(Net.team_size)
	GameConfig.stage = Net.stage
	Net.apply_rules_to_config()
	GameConfig.net_roster = roster
	GameConfig.quick_match = _qp != null\
	and _qp.state != QuickPlay.State.IDLE
	UiWipe.wipe(get_tree(), func():
		GameConfig.goto_scene("res://game/main/main.tscn"))

var _c_size: UiSelect
var _c_sets: UiSelect
var _c_points: SpinBox
var _c_wbt: CheckBox
var _c_sweat: CheckBox
var _c_rate: UiSelect
var _c_stage: UiSelect
var _c_diff_local: UiSelect
var _c_side: UiSelect

func _build_custom() -> void :
	var v: = _box(_custom)
	_hero_head(v, "custom match", true)
	_c_size = UiSelect.new(["1v1", "2v2", "3v3", "4v4", "5v5", "6v6"])
	v.add_child(_labeled("teams", _c_size))
	_c_sets = UiSelect.new(["1 set", "best of 3", "best of 5"])
	v.add_child(_labeled("sets", _c_sets))
	_c_points = SpinBox.new()
	_c_points.min_value = 3
	_c_points.max_value = 25
	UiStyle.style_spin(_c_points)
	v.add_child(_labeled("points", _c_points))
	_c_wbt = CheckBox.new()
	_c_wbt.text = "win by two"
	UiStyle.style_check(_c_wbt)
	v.add_child(_c_wbt)
	_c_sweat = CheckBox.new()
	_c_sweat.text = "sweat builds up"
	UiStyle.style_check(_c_sweat)
	v.add_child(_c_sweat)
	_c_rate = UiSelect.new(SWEAT_RATE_NAMES)
	v.add_child(_labeled("sweat rate", _c_rate))
	var stage_titles: Array = []
	for id in Stage.ids():
		stage_titles.append(Stage.title(id))
	_c_stage = UiSelect.new(stage_titles)
	v.add_child(_labeled("stage", _c_stage))
	v.add_child(_menu_btn("start match", "primary", _start_custom))
	v.add_child(_menu_btn("back", "tertiary", func(): _show(_local)))

func _labeled(text: String, control: Control) -> Control:
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var l: = Label.new()
	l.text = text
	UiStyle.style_label(l, "body")
	l.custom_minimum_size.x = 96
	row.add_child(l)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row










const SHOW_FEEDBACK_BUTTON: = false
var _feedback: FeedbackPanel = null

func _open_feedback() -> void :
	if _feedback != null and is_instance_valid(_feedback):
		return
	_feedback = FeedbackPanel.new()
	_feedback.closed.connect( func(): _feedback = null)
	ui.add_child(_feedback)
	get_viewport().gui_release_focus()


	for c in _tilt:
		var card: = c as Button
		if is_instance_valid(card):
			card.offset_transform_enabled = false
			card.z_index = 0

func _open_settings(settings_scope: int) -> void :
	if _settings_panel != null:
		_settings_panel.set_scope(settings_scope)

	if _settings_title != null:
		_settings_title.text = "profile settings"\
		if settings_scope == SettingsPanel.Scope.PROFILE else "system settings"
	_show(_settings)

func _build_settings() -> void :
	var v: = _box(_settings)

	for c in v.get_children():
		v.remove_child(c)
		c.free()
	v.add_theme_constant_override("separation", 12)


	_settings_title = _hero_head(v, "system settings", true)
	var panel: = SETTINGS_PANEL.instantiate() as SettingsPanel
	_settings_panel = panel


	panel.retheme_requested.connect( func(_dark: bool):
		UiWipe.wipe(get_tree(), func():
			GameConfig.goto_scene("res://game/ui/menu.tscn")))


	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size.x = 860
	v.add_child(panel)

	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.add_child(_menu_btn("back", "tertiary", _back_to_hub))
	var reset_all: = _menu_btn("reset all", "exit", func(): panel.reset_all())
	reset_all.add_theme_font_size_override("font_size", 15)
	reset_all.custom_minimum_size.y = 44
	row.add_child(reset_all)
	var gap: = Control.new()
	gap.custom_minimum_size.y = 8
	v.add_child(gap)
	v.add_child(row)

func _build_howto() -> void :
	var v: = _box(_howto)
	_hero_head(v, "how to play", true)
	var scroll: = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UiStyle.style_scroll(scroll.get_v_scroll_bar())
	var manual: = HOW_TO_PLAY.instantiate()
	(manual as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(manual)
	v.add_child(scroll)
	v.add_child(_menu_btn("back", "tertiary", func(): _show(_practice)))

var _last_shown: Control = null

func _show(page: Control) -> void :
	if is_instance_valid(_achievements) and _achievements.visible and page != _achievements:
		var t: int = _achievements.get_meta("ach_tab", 0)
		if t >= 0 and t < _ach_tab_kinds.size() and _ach_tab_kinds[t] != "":
			_ach_dismiss_kind(_ach_tab_kinds[t])
	for p in [_home, _online, _local, _practice, _drills, _profile, _quick, _custom, 
		_settings, _howto, _browse, _host, _room, _direct, _recent, _achievements]:
		if p != null:
			p.visible = p == page


	_refresh_player_card()
	if page == null:
		return




	_stagger_reveal(page)
	var panel: = page.find_child("Panel", true, false) as Control
	if panel != null and page != _last_shown:
		panel.offset_transform_enabled = true
		panel.offset_transform_position.x = -36.0 if page == _home else 36.0
		panel.modulate.a = 0.0
		var t: = panel.create_tween().set_parallel(true)
		t.tween_property(panel, "offset_transform_position:x", 0.0, 0.26)\
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		t.tween_property(panel, "modulate:a", 1.0, 0.16)
	_last_shown = page


	call_deferred("_focus_first", page)




func _focus_first(page: Control) -> void :
	if page == null or not page.visible or _freeplay:
		return
	for b in page.find_children("*", "Button", true, false):
		var btn: = b as Button
		if btn != null and btn.is_visible_in_tree() and not btn.disabled\
		and btn.focus_mode != Control.FOCUS_NONE:
			btn.grab_focus()
			return

func _on_input_device_changed() -> void :

	if InputPrompts.using_gamepad() and not _freeplay\
	and get_viewport().gui_get_focus_owner() == null:
		for p in [_home, _online, _local, _practice, _drills, _profile, _quick, 
			_settings, _howto, _browse, _host, _room, _direct, _recent]:
			if p != null and p.visible:
				_focus_first(p)
				return




func _stagger_reveal(page: Control) -> void :
	var box: = _box(page)
	if box != null:
		UiStyle.stagger_reveal(box)



func _cancel_search() -> void :
	if _qp != null and _qp.state != QuickPlay.State.IDLE:
		_qp.cancel()


	if _member_queuing and Net.active and not Net.is_host and Net.i_am_fold():
		Net.leave()
	_member_queuing = false
	_mm_chip.visible = false
	_set_matchmaking(false)

func _wipe_to(path: String) -> void :


	_cancel_search()
	UiWipe.wipe(get_tree(), func(): GameConfig.goto_scene(path))

var _park: MyPark = null

func _open_gym() -> void :
	if LaunchGate.public_beta():
		return
	if not OnlineTerms.require(_open_gym):
		return


	_cancel_search()



	if Net.party:
		if not Net.is_host:
			_flash_notice("only the party leader can take the party to a gym")
			return
		Net.gym_from_party()
		return
	_mm_title.text = "open gym"
	_mm_label.text = "finding a gym..."
	_set_matchmaking(true)
	_park = MyPark.new()
	add_child(_park)
	_park.begin(Input.is_key_pressed(KEY_SHIFT))

func _start_local() -> void :


	GameConfig.quick_match = false
	GameConfig.save_settings()
	_go_to_match(_local_size)




func _go_to_match(size: int) -> void :
	GameConfig.set_mode(size)
	if Net.party:
		if not Net.is_host:
			_flash_notice("only the party leader can start a match")
			return
		_launch_party_match(size)
	else:
		_wipe_to("res://game/main/main.tscn")

func _launch_party_match(size: int) -> void :
	Net.set_team_size(size)
	for id in Net.party_members():
		Net.players[id].side = 1
	var ids: = Net.players.keys()
	ids.sort()



	var kits: = {1: GameConfig.team_kit(true).map( func(c): return (c as Color).to_html(false)), 
		-1: GameConfig.opponent_kit().map( func(c): return (c as Color).to_html(false))}

	var roster: = Net.build_roster(ids, Net.players, size, kits, GameConfig.local_cpus)
	GameConfig.ranked_match = false

	Net.init_rules_from_config()
	Net.sync_lobby()
	Net.start_match(roster, randi())



func _open_custom() -> void :
	_populate_local()
	_show(_local)

func _start_custom() -> void :
	GameConfig.sets_to_win = _c_sets.selected + 1
	GameConfig.set_points = int(_c_points.value)
	GameConfig.win_by_two = _c_wbt.button_pressed
	GameConfig.sweat_enabled = _c_sweat.button_pressed
	GameConfig.sweat_rate = SWEAT_RATES[maxi(_c_rate.selected, 0)]
	GameConfig.stage = Stage.ids()[maxi(_c_stage.selected, 0)]
	GameConfig.quick_match = false
	GameConfig.save_settings()
	_go_to_match(_c_size.selected + 1)








func _setup_online() -> void :
	_steam_up = Net.steam_init()
	if _steam_pill != null:
		_steam_pill.text = "steam authenticated" if _steam_up\
		or Net.steam_transport_available() else "steam not authenticated"
	if _host_steam_card != null:
		_host_steam_card.visible = Net.steam_transport_available()
	_refresh_online_cards()
	if not Net.active:
		Net.stage = GameConfig.stage
	if _online_ready:
		return
	_online_ready = true

	# Supabase auth finishes after the menu is built, so the availability gate has
	# to be re-evaluated once it lands or the card would stay hidden forever.
	SupabaseClient.auth_ready.connect(func(_id: String):
		_refresh_online_cards())


	Net.steam_ready.connect( func():
		_steam_up = true
		if _steam_pill != null:
			_steam_pill.text = "steam authenticated"
		if _host_steam_card != null:
			_host_steam_card.visible = Net.steam_transport_available()
		if _friends_btn != null:
			_friends_btn.visible = Net.steam_transport_available()
		if _browse.visible:
			_refresh_browser())
	Net.lobby_changed.connect(_refresh_room)
	Net.lobby_changed.connect(_refresh_party_strip)
	Net.lobby_changed.connect(_reconcile_party_bodies)
	Net.lobby_changed.connect( func(): Net.send_party_look(_outfit))
	Net.lobby_changed.connect( func(): Net.send_party_ball(_ball_skin))

	Net.lobby_changed.connect(_refresh_stage_btn)
	Net.lobby_changed.connect( func():
		if Net.active and not Net.party\
		and bool(Net.home_party.get("room", false)):
			_in_party_room = true)
	Net.party_joined.connect(_on_party_joined)
	Net.party_travel_to.connect(_on_party_travel_to)
	Net.party_home_called.connect(_on_party_home_called)
	Net.freeplay_pose.connect(_on_freeplay_pose)
	Net.ball_pose.connect(_on_ball_pose)
	Net.freeplay_fx.connect(_on_freeplay_fx)
	Net.party_look.connect(_on_party_look)
	Net.party_look.connect( func(_p: int, _o: String):
		if _room != null and _room.visible:
			_refresh_room())
	Net.party_ball.connect(_on_party_ball)
	Net.party_stage.connect(_on_party_stage)
	Net.quick_status.connect(_on_member_quick_status)



	_party_puppets.render_delay_ms = 110.0
	Net.session_ended.connect(_on_session_ended)
	Net.session_ended.connect( func(_r: String): _refresh_party_strip())

	Net.session_ended.connect( func(_r: String): _refresh_stage_btn())
	Net.steam_lobbies.connect(_on_steam_lobbies)
	SupabaseClient.lobbies_received.connect(_on_web_lobbies)
	SupabaseClient.auth_ready.connect(func(_id: String):
		_refresh_online_cards()
		if _browse != null and _browse.visible:
			_refresh_browser())
	SupabaseClient.auth_failed.connect(func(reason: String):
		_refresh_online_cards()
		if _browse_hint != null and _browse != null and _browse.visible:
			_browse_hint.text = "online login failed: " + reason)
	SupabaseClient.lobby_error.connect(func(reason: String):
		if _host_status != null:
			_host_status.text = reason)
	Net.gym_joined.connect( func():
		UiWipe.wipe(get_tree(), func():
			GameConfig.goto_scene("res://game/gym/open_gym.tscn")))
	_refresh_party_strip()

func _online_name() -> String:
	return Net.local_display_name()

# Online hosting only needs the Supabase signaling backend, which authenticates
# asynchronously after the menu is built. Re-check every time that can change so
# the card appears the moment a connection is actually available (and hides
# again if the login ultimately fails).
func _refresh_online_cards() -> void :
	if _host_online_card == null:
		return
	var available: bool = Net.online_hosting_available()
	if _host_online_card.visible == available:
		return
	_host_online_card.visible = available
	if available and _browse != null and _browse.visible:
		_refresh_browser()










func _refresh_party_strip() -> void :
	_apply_party_gating()
	_update_presence()
	_refresh_friends_panel()
	if _party_strip == null:
		return
	for c in _party_strip.get_children():
		c.queue_free()
	if not Net.party:
		var make: = Button.new()
		make.text = "create party"
		make.icon = UiStyle.icon("multiplayer")
		make.expand_icon = true
		make.add_theme_constant_override("icon_max_width", 20)
		make.add_theme_constant_override("h_separation", 8)
		UiStyle.style_button(make, "secondary", 15)
		make.tooltip_text = "start a party with friends"
		make.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		make.pressed.connect(_start_party)
		_party_strip.add_child(make)
		_party_was_open = false
		return



	var ids: = Net.party_members()
	ids.sort()
	for id in ids:
		var nm: = String(Net.players[id].get("name", "player"))
		var leader: bool = id == 1
		_party_strip.add_child(_party_disc("singleplayer", 
			UiStyle.PRIMARY if leader else UiStyle.SECONDARY, 
			(nm + "  (leader)") if leader else nm, 
			( func(): _party_member_menu(id)) if (Net.is_host and not leader)\
			else Callable(), leader))

	for i in range(ids.size(), Net.PARTY_MAX):
		_party_strip.add_child(_party_disc("plus", UiStyle.muted(), 
			"invite a friend", _party_add))


	if Net.is_host:
		var priv: = Button.new()

		priv.text = ["private", "friends", "friends+"][Net.party_privacy]
		UiStyle.style_button(priv, "tertiary", 12)
		_slim_button(priv)
		priv.tooltip_text = "who can join without an invite: %s (click to cycle)"\
		%Net.PARTY_PRIV_NAMES[Net.party_privacy]
		priv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		priv.pressed.connect( func():
			Net.set_party_privacy((Net.party_privacy + 1) % 3)
			_refresh_party_strip())
		_party_strip.add_child(priv)
	var out: = Button.new()
	out.text = "disband" if Net.is_host else "leave"
	UiStyle.style_button(out, "tertiary", 13)
	_slim_button(out)
	out.pressed.connect(_leave_party)
	out.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_party_strip.add_child(out)

	if not _party_was_open:
		_unfold_party()
	_party_was_open = true





func _apply_party_gating() -> void :
	var p: = Net.party
	if _card_local != null:
		_card_local.disabled = p
	if _card_custom_lobby != null:
		_card_custom_lobby.disabled = p
	if _card_direct != null:
		_card_direct.disabled = p
	if _replays_tab != null:


		_replays_tab.disabled = Net.active
		_replays_tab.tooltip_text = "not while you're in a party or online"\
		if Net.active else ""


	var floor_size: int = Net.party_members().size() if p else 1
	for n in _quick_chips:
		var tile: = _quick_chips[n] as Button
		if tile == null:
			continue
		var too_small: = int(n) < floor_size
		tile.disabled = too_small
		if too_small and tile.button_pressed:
			tile.set_pressed_no_signal(false)
			UiStyle.style_button(tile, "secondary", 22)


	if p:
		for page in [_local, _custom, _host, _direct, _room]:
			if page != null and page.visible:
				_show(_home)
				break


func _unfold_party() -> void :
	var i: = 0
	for c in _party_strip.get_children():
		var ctrl: = c as Control
		if ctrl == null:
			continue
		ctrl.offset_transform_enabled = true
		ctrl.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
		ctrl.offset_transform_scale = Vector2.ZERO
		var t: = ctrl.create_tween()
		t.tween_interval(0.04 * float(i))
		t.tween_property(ctrl, "offset_transform_scale", Vector2.ONE, 0.26)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1
	UiStyle.sfx("confirm")





func _slim_button(b: Button) -> void :
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb: = b.get_theme_stylebox(state)
		if sb == null:
			continue
		sb = sb.duplicate()
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		b.add_theme_stylebox_override(state, sb)
	b.custom_minimum_size.x = 0

func _party_disc(icon_name: String, color: Color, tip: String, 
		on_press: Callable, crown: = false) -> Control:
	if not on_press.is_valid():
		var disc: = TextureRect.new()
		disc.texture = UiStyle.icon_disc(icon_name, color, 34, true)
		disc.custom_minimum_size = Vector2(34, 34)
		disc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		disc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		disc.tooltip_text = tip
		if not crown:
			return disc

		var wrap_box: = Control.new()
		wrap_box.custom_minimum_size = Vector2(34, 34)
		wrap_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		wrap_box.tooltip_text = tip
		disc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		wrap_box.add_child(disc)
		var cr: = TextureRect.new()
		cr.texture = _crown_texture()
		cr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cr.custom_minimum_size = Vector2(22, 17)
		cr.size = Vector2(22, 17)
		cr.position = Vector2(6, -10)
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap_box.add_child(cr)
		return wrap_box
	var b: = Button.new()
	b.flat = true
	b.icon = UiStyle.icon_disc(icon_name, color, 34, true)
	b.expand_icon = true
	b.custom_minimum_size = Vector2(36, 36)
	b.add_theme_constant_override("icon_max_width", 34)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.tooltip_text = tip
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(UiStyle.press_bounce.bind(b))
	UiStyle.hover_sound(b)
	b.pressed.connect(on_press)
	return b

var _crown_tex: ImageTexture = null


func _crown_texture() -> ImageTexture:
	if _crown_tex != null:
		return _crown_tex
	var w: = 52
	var h: = 40
	var img: = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var gold: = Color("ffd23f")
	var base_top: = int(h * 0.64)
	var base_bot: = int(h * 0.88)
	var peaks: = [0.2, 0.5, 0.8]
	var pw: = float(w) * 0.24
	var ph: = float(h) * 0.6
	for x in range(int(w * 0.12), int(w * 0.88)):

		for y in range(base_top, base_bot):
			img.set_pixel(x, y, gold)

		var top: = base_top
		for pk in peaks:
			var px: = float(pk) * float(w)
			var hgt: = ph * (1.0 - absf(float(x) - px) / pw)
			if hgt > 0.0:
				top = mini(top, base_top - int(hgt))
		for y in range(top, base_top):
			img.set_pixel(x, y, gold)
	_crown_tex = ImageTexture.create_from_image(img)
	return _crown_tex


func _party_add() -> void :
	if not Net.party:
		_start_party()
	_invite_to_party()



func _party_member_menu(id: int) -> void :
	if not Net.is_host or id == 1 or not Net.players.has(id):
		return
	var pop: = PopupPanel.new()
	var box: = StyleBoxFlat.new()
	box.bg_color = UiStyle.card()
	box.set_corner_radius_all(10)
	box.set_content_margin_all(10)
	box.shadow_color = Color(0, 0, 0, 0.28)
	box.shadow_size = 8
	pop.add_theme_stylebox_override("panel", box)
	var col: = VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	var who: = Label.new()
	who.text = String(Net.players[id].get("name", "player"))
	UiStyle.style_label(who, "body")
	col.add_child(who)
	var kick: = _menu_btn("kick", "exit", func():


		_invited_ids.erase(int((Net.players[id] as Dictionary).get("sid", 0)))
		Net.kick_from_party(id)
		pop.hide())
	kick.add_theme_font_size_override("font_size", 14)
	kick.custom_minimum_size = Vector2(120, 38)
	col.add_child(kick)
	pop.add_child(col)
	add_child(pop)
	pop.popup_hide.connect( func(): pop.queue_free())
	var mp: = get_viewport().get_mouse_position()
	pop.popup(Rect2i(Vector2i(mp) + Vector2i(-10, 20), Vector2i.ZERO))














func _dock_chat(right: bool) -> void :
	if _chat == null:
		return
	var w: float = _chat.custom_minimum_size.x
	if right:
		_chat.anchor_left = 1.0
		_chat.anchor_right = 1.0
		_chat.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_chat.offset_right = -24.0
		_chat.offset_left = -24.0 - w
		_chat.offset_top = -240.0
		_chat.offset_bottom = -80.0
	else:
		_chat.anchor_left = 0.0
		_chat.anchor_right = 0.0
		_chat.grow_horizontal = Control.GROW_DIRECTION_END
		_chat.offset_left = 12.0
		_chat.offset_right = 12.0 + w
		_chat.offset_top = -206.0
		_chat.offset_bottom = -46.0

func _my_party_id() -> int:
	if Net.is_host:
		return 1


	if multiplayer == null or multiplayer.multiplayer_peer == null:
		return 0
	return multiplayer.get_unique_id()

func _on_freeplay_pose(peer_id: int, st: PackedFloat32Array) -> void :


	if not is_inside_tree() or not Net.party\
	or peer_id == _my_party_id() or not _is_party_member(peer_id):
		return
	_ensure_party_body(peer_id)



	_party_in_freeplay[peer_id] = st.size() > Player.NET_FLOATS\
	and st[Player.NET_FLOATS] > 0.5
	var now: = float(Time.get_ticks_msec())
	_party_puppets.add(peer_id, st, now)
	_party_seen[peer_id] = now

func _ensure_party_body(peer_id: int) -> void :
	if _party_bodies.has(peer_id):
		return
	var body: Player = PLAYER_SCENE.instantiate()
	add_child(body)




	body.net_puppet = true
	body.sim_authority = false
	body.charge_ui_enabled = false
	body.indicator_enabled = false


	body.collision_layer = 0
	body.collision_mask = 0
	var info: Dictionary = Net.players.get(peer_id, {})
	body.set_display_name(String(info.get("name", "friend")))
	body.set_dev_tag(DevBadge.peer_tier(peer_id))
	body.set_name_visible(false)
	body.global_position = HOME_SPOT
	_party_bodies[peer_id] = body
	_dress_party_body(body, peer_id)


func _dress_party_body(body: Player, peer_id: int) -> void :
	var info: Dictionary = Net.players.get(peer_id, {})
	var cfg_d: Dictionary = info.get("cfg", {})
	if cfg_d.is_empty():
		return
	var cfg: = CharacterConfig.from_dict(cfg_d)
	match String(_party_outfit.get(peer_id, "gym")):
		"home":
			body.set_character(cfg, cfg.kit_home)
		"away":
			body.set_character(cfg, cfg.kit_away)
		_:
			body.set_character(cfg.gym_look(), cfg.gym_kit())

func _on_party_look(peer_id: int, outfit: String) -> void :
	_party_outfit[peer_id] = outfit
	if _party_bodies.has(peer_id):
		_dress_party_body(_party_bodies[peer_id], peer_id)

func _on_party_ball(peer_id: int, skin: String) -> void :
	_party_ball_skin[peer_id] = skin


	if _party_balls.has(peer_id):
		(_party_balls[peer_id] as Ball).set_ball_skin(skin)



func _reconcile_party_bodies() -> void :
	for pid in _party_bodies.keys():
		if not Net.party or not _is_party_member(int(pid)):
			_free_party_body(int(pid))



func _is_party_member(pid: int) -> bool:
	return Net.players.has(pid)\
	and not bool((Net.players[pid] as Dictionary).get("qjoin", false))

func _free_party_body(peer_id: int) -> void :
	if _party_bodies.has(peer_id):
		(_party_bodies[peer_id] as Node).queue_free()
		_party_bodies.erase(peer_id)
	if _party_balls.has(peer_id):
		if player != null and player.ball == _party_balls[peer_id]:
			player.ball = ball
			camera_rig.ball = ball
		(_party_balls[peer_id] as Node).queue_free()
		_party_balls.erase(peer_id)
	_party_puppets.forget(peer_id)
	_party_ball_buf.forget(peer_id)
	_party_seen.erase(peer_id)



	_ball_driver.erase(peer_id)
	for bid in _ball_driver.keys():
		if int(_ball_driver[bid]) == peer_id:
			_ball_driver.erase(bid)
			var b: = _party_ball_for(int(bid))
			if b != null and _drives(int(bid)):
				_party_ball_buf.forget(int(bid))
				b.remote_driven = false
				b.show_landing_ring = true

func _clear_party_bodies() -> void :
	for pid in _party_bodies.keys():
		_free_party_body(int(pid))
	_ball_driver.clear()
	ball.remote_driven = false
	ball.show_landing_ring = true
	if player != null:
		player.ball = ball if player.ball != null else null
		camera_rig.ball = ball

	for pid in _party_balls.keys():
		_free_party_body(int(pid))





func _on_ball_pose(peer_id: int, st: PackedFloat32Array, bid: int) -> void :
	if not is_inside_tree() or not Net.party\
	or peer_id == _my_party_id():
		return
	if not _is_party_member(peer_id):
		return
	var b: = _party_ball_for(bid)
	if b == null:
		return
	if _drives(bid):


		b.remote_driven = true
		b.show_landing_ring = false
	_ball_driver[bid] = peer_id


	_party_ball_buf.add(int(bid), st, float(Time.get_ticks_msec()))
	_party_seen[peer_id] = Time.get_ticks_msec()


func _party_ball_for(bid: int) -> Ball:
	if bid == _my_party_id():
		return ball
	if not _is_party_member(bid):
		return null
	_ensure_party_ball(bid)
	return _party_balls[bid]


func _drives(bid: int) -> bool:
	return int(_ball_driver.get(bid, bid)) == _my_party_id()



func _driven_balls() -> Dictionary:
	var out: = {}
	if _drives(_my_party_id()):
		out[_my_party_id()] = ball
	for bid in _party_balls:
		if _drives(int(bid)):
			out[int(bid)] = _party_balls[bid]
	return out





func _take_party_ball(bid: int) -> void :
	var b: = _party_ball_for(bid)
	if b == null or _drives(bid) or not SHARED_BALLS:
		return
	_ball_driver[bid] = _my_party_id()
	_party_ball_buf.forget(bid)
	b.remote_driven = false
	b.show_landing_ring = true
	b.reset_physics_interpolation()

func _ensure_party_ball(peer_id: int) -> void :
	if _party_balls.has(peer_id):
		return
	var b: Ball = BALL_SCENE.instantiate()
	b.stage_ball = String(_party_ball_skin.get(peer_id, "nationals"))
	b.remote_driven = true
	b.net_puppet = not SHARED_BALLS
	b.show_landing_ring = false
	add_child(b)
	b.court_center_x = 0.0
	b.court_half_w = COURT_HW
	b.court_half_l = COURT_HL
	b.net_half_width = ball.net_half_width
	b.antenna_half_width = ball.antenna_half_width
	b.wall_min = ball.wall_min
	b.wall_max = ball.wall_max


	b.struck.connect( func(pos: Vector3, power: float, kind: int):
		_take_party_ball(peer_id)
		_play_contact_fx(pos, power, kind, b.vel, b.combo_tier)
		if Net.party and _freeplay:
			Net.send_freeplay_fx(kind, pos, power, b.vel))
	b.bounced.connect( func():
		if not _drives(peer_id):
			return
		var floor_pos: = Vector3(b.global_position.x, 0.06, b.global_position.z)
		sfx.play("hit_soft", b.global_position, -12.0, 0.75)
		fx.ring(floor_pos, Vector3.UP, clampf(b.vel.y * 0.12, 0.3, 0.9))
		fx.puff(floor_pos))
	_party_balls[peer_id] = b




func _pick_freeplay_ball() -> void :
	var here: = player.global_position
	var best: Ball = player.ball
	var best_d: = INF
	if best != null and is_instance_valid(best):
		best_d = here.distance_to(best.global_position) - 0.75
	var cands: Array = [ball]
	for bid in _party_balls:
		var pb: = _party_balls[bid] as Ball
		if pb.visible:
			cands.append(pb)
	for c in cands:
		var cb: = c as Ball
		if cb == best or (cb.frozen and cb != ball):
			continue
		var d: = here.distance_to(cb.global_position)
		if d < best_d:
			best_d = d
			best = cb
	if best != player.ball:
		player.ball = best
		camera_rig.ball = best


func _play_contact_fx(pos: Vector3, power: float, kind: int, vel: Vector3, 
		combo_tier: = 0) -> void :
	if fx == null or sfx == null:
		return
	var strength: = Rules.contact_strength(kind, power)
	var snd: = Rules.contact_sound(kind, power)
	sfx.play(String(snd["n"]), pos, float(snd["db"]), float(snd["pt"]))

	if combo_tier >= 1:
		sfx.play("spike_combo", pos, 0.0, 1.0 + 0.06 * float(combo_tier - 1))
	if kind == Player.TouchKind.SPIKE and power > 0.8:
		fx.big_spike(pos, vel)
	Rules.contact_fx(fx, pos, strength, vel, 0.0, true, kind, combo_tier)

func _on_freeplay_fx(peer_id: int, kind: int, pos: Vector3, power: float, 
		vel: Vector3) -> void :


	if not is_inside_tree() or not Net.party or not _freeplay\
	or peer_id == _my_party_id():
		return
	if kind == -1:

		if fx != null:
			fx.ring(pos, Vector3.UP, 1.15 * power)
			fx.puff(pos)
		if sfx != null:
			sfx.play("hit_soft", pos, -4.0, 1.35)
		return
	if kind == -2:

		if fx != null:
			Rules.contact_fx(fx, pos, power, Vector3.UP, 0.0)
			fx.puff(pos)
		if sfx != null:
			sfx.play("hit_soft", pos, -2.0, 0.55)
		return

	_play_contact_fx(pos, power, kind, vel, 1 if kind == Player.TouchKind.SPIKE else 0)




func _drive_menu_camera(delta: float) -> void :
	if player == null:
		return
	var n: int = _fake_party_n if _fake_party_n > 0\
	else (Net.party_members().size() if Net.party else 1)
	var t: = clampf(float(n - 1) / 5.0, 0.0, 1.0)
	var tgt_pos: Vector3 = HOME_SPOT + Vector3(-0.78, 1.35, 3.7).lerp(
		Vector3(-2.4, 2.5, 6.6), t)
	var tgt_look: Vector3 = HOME_SPOT + Vector3(-1.15, 1.0, 0.0).lerp(
		Vector3(-2.6, 1.1, -0.7), t)
	var tgt_fov: = lerpf(50.0, 55.0, t)
	var k: = clampf(delta * 3.5, 0.0, 1.0)
	menu_cam.global_position = menu_cam.global_position.lerp(tgt_pos, k)
	menu_cam.fov = lerpf(menu_cam.fov, tgt_fov, k)
	_cam_look_now = _cam_look_now.lerp(tgt_look, k)
	menu_cam.look_at(_cam_look_now)

	var to_cam: = menu_cam.global_position - player.global_position
	_base_yaw = atan2(to_cam.x, to_cam.z) - 0.38
	player.visual.rotation.y = _base_yaw + _spin



func _drive_party_lineup(delta: float) -> void :
	var my_id: = _my_party_id()
	var ids: = Net.party_members()
	ids.sort()
	var slot: = 1
	for pid in ids:
		if pid == my_id:
			continue
		_ensure_party_body(pid)
		_ensure_party_ball(pid)
		var body: = _party_bodies[pid] as Player
		body.visible = true
		body.set_name_visible(false)
		var spot: Vector3 = HOME_SPOT\
		+ PARTY_SPOTS[mini(slot, PARTY_SPOTS.size() - 1)]
		body.global_position = spot
		body.velocity = Vector3.ZERO
		var to_cam: = menu_cam.global_position - spot
		body.visual.rotation.y = atan2(to_cam.x, to_cam.z) - 0.38
		body.puppet_tick(delta)
		var b: = _party_balls[pid] as Ball
		b.visible = true
		b.global_position = spot + Vector3(-0.45, 0.4, 0.5)
		slot += 1



func _drive_party_freeplay(delta: float) -> void :
	var now: = float(Time.get_ticks_msec())
	for pid in _party_bodies.keys():

		var live: bool = _party_in_freeplay.get(pid, false) and _drill_active == ""
		var body: = _party_bodies[pid] as Player
		body.visible = live
		body.set_name_visible(live)



		var mine: Ball = _party_balls.get(pid)
		if body.ball != mine:
			body.ball = mine
		if live:
			_party_puppets.drive(int(pid), body, now, delta)


			body.team_side = 1 if body.global_position.z >= 0.0 else -1
		if _party_balls.has(pid):
			var b: = _party_balls[pid] as Ball


			b.visible = live or _drives(int(pid))
			if b.remote_driven and b.visible:

				_party_ball_buf.drive(int(pid), b, now, delta)

	if ball.remote_driven:
		_party_ball_buf.drive(_my_party_id(), ball, now, delta)



func _party_live_bodies() -> Array:
	var out: Array = []
	if Net.party and _freeplay:
		for pid in _party_bodies.keys():
			if _party_in_freeplay.get(pid, false):
				out.append(_party_bodies[pid])
	return out




func _maybe_resume_home_party() -> void :
	if Net.home_party.is_empty():
		return
	if Net.active:
		if Net.party:
			Net.home_party = {}
			return



		if bool(Net.home_party.get("room", false)):
			return




		Net.leave()
	var hp: Dictionary = Net.home_party
	Net.home_party = {}
	_in_party_room = false
	if bool(hp.get("is_leader", false)):

		if Net.host_party(Net.local_display_name()) == OK:
			_refresh_party_strip()
			_flash_notice("party back together")
	else:


		_reform_target = hp
		_reform_left = 8.0



func _drive_reform(delta: float) -> void :
	if Net.party:
		_reform_target = {}
		_refresh_party_strip()
		_flash_notice("party back together")
		return
	_reform_left -= delta
	if _reform_left <= 0.0:
		_reform_target = {}
		if Net.active:
			Net.leave()
		_flash_notice("couldn't rejoin your party")
		return
	if Net.active:
		return
	var sid: = int(_reform_target.get("leader_sid", 0))
	var ip: = String(_reform_target.get("leader_ip", ""))
	if sid != 0 and Net.steam_transport_available():
		Net.join_game_steam(sid, Net.local_display_name())
	elif ip != "":
		Net.join_game(ip, Net.local_display_name())
	else:
		_reform_target = {}

func _start_party() -> void :
	if not OnlineTerms.require(_start_party):
		return

	_cancel_search()

	Net.home_party = {}
	_reform_target = {}
	_invited_ids = {}



	var lan: = Input.is_key_pressed(KEY_SHIFT)\
	or not Net.steam_transport_available()
	var err: = Net.host_party(Net.local_display_name(), lan)
	if err != OK:
		_flash_notice("couldn't start a party (error %d)" % err)
	else:


		_flash_notice("created lan party · direct join by ip" if lan\
		else "created new party · invite friends")
	_refresh_party_strip()

func _on_party_joined() -> void :

	Net.send_party_look(_outfit)
	Net.send_party_ball(_ball_skin)



	_refresh_party_strip()

func _leave_party() -> void :
	_invited_ids = {}
	Net.leave()
	_refresh_party_strip()

func _invite_to_party() -> void :


	if not Net.party:
		_flash_notice("not in a party yet - press create party first")
		return



	if not (multiplayer.multiplayer_peer is ENetMultiplayerPeer):
		Net.steam_invite_overlay()
		return

	var best: = ""
	var alt: = ""
	for a in IP.get_local_addresses():
		if a.begins_with("192.168."):
			best = a
		elif (a.begins_with("10.") or a.begins_with("172.")) and alt == "":
			alt = a
	var ip: = best if best != "" else (alt if alt != "" else "your lan ip")
	_flash_notice("friend joins: online > direct join > %s" % ip)


func _flash_notice(text_in: String) -> void :
	var t: = UiStyle.toast("heads up", text_in, UiStyle.SECONDARY, "information")
	ui.add_child(t)
	t.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	t.position.y = 108
	t.modulate.a = 0.0
	var tw: = t.create_tween()
	tw.tween_property(t, "modulate:a", 1.0, 0.2)
	tw.tween_interval(4.0)
	tw.tween_property(t, "modulate:a", 0.0, 0.4)
	tw.tween_callback(t.queue_free)
	UiStyle.sfx("open")

func _build_browse() -> void :
	var v: = _box(_browse)
	v.custom_minimum_size.x = 730
	v.add_theme_constant_override("separation", 10)
	_hero_head(v, "server browser", true)

	var top: = HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	_bw_search = LineEdit.new()
	_bw_search.placeholder_text = "search by name or code..."
	_bw_search.custom_minimum_size = Vector2(0, 46)
	_bw_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bw_search.clear_button_enabled = true
	UiStyle.style_line_edit(_bw_search)
	_bw_search.text_changed.connect( func(_t): _apply_browse_filters())
	_bw_search.text_submitted.connect( func(_t): _on_join_code(_t))
	top.add_child(_bw_search)


	var create: = Button.new()
	create.text = "create server"
	create.custom_minimum_size = Vector2(170, 46)
	UiStyle.style_button(create, "primary", 20)
	create.pressed.connect( func():
		_cancel_search()
		_show(_host))
	top.add_child(create)
	var refresh: = Button.new()
	refresh.text = "refresh"
	refresh.custom_minimum_size = Vector2(130, 46)
	UiStyle.style_button(refresh, "secondary", 20)
	refresh.pressed.connect(_refresh_browser)
	top.add_child(refresh)
	v.add_child(top)

	var body: = HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll: = ScrollContainer.new()


	scroll.custom_minimum_size = Vector2(486, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UiStyle.style_scroll(scroll.get_v_scroll_bar())
	_browse_list = VBoxContainer.new()
	_browse_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_browse_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_browse_list)
	body.add_child(scroll)
	body.add_child(_build_browse_filters())
	v.add_child(body)
	_browse_hint = _online_status()
	v.add_child(_browse_hint)

	var join_row: = HBoxContainer.new()
	join_row.add_theme_constant_override("separation", 10)
	_bw_code = LineEdit.new()
	_bw_code.placeholder_text = "join by lobby code or lan ip"
	_bw_code.custom_minimum_size = Vector2(0, 46)
	_bw_code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.style_line_edit(_bw_code)
	_bw_code.text_submitted.connect( func(t): _on_join_code(t))
	join_row.add_child(_bw_code)
	var join_btn: = Button.new()
	join_btn.text = "join"
	join_btn.custom_minimum_size = Vector2(120, 46)
	UiStyle.style_button(join_btn, "primary", 22)
	join_btn.pressed.connect( func(): _on_join_code(_bw_code.text))
	join_row.add_child(join_btn)
	v.add_child(join_row)
	v.add_child(_ribbon_btn("back", "back", func(): _show(_online)))


func _build_browse_filters() -> Control:
	var card: = PanelContainer.new()
	UiStyle.style_panel(card, UiStyle.card(), UiStyle.RADIUS_SOFT)
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var pad: = MarginContainer.new()
	for m in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + m, 16)
	card.add_child(pad)
	var col: = VBoxContainer.new()
	col.custom_minimum_size.x = 196
	col.add_theme_constant_override("separation", 10)
	pad.add_child(col)
	var head: = Label.new()
	head.text = "filters"
	UiStyle.style_label(head, "body", UiStyle.SECONDARY)
	col.add_child(head)
	_bw_region = UiSelect.new(BW_REGIONS)




	_bw_region.selected = BW_REGIONS.size() - 1
	_bw_region.picked.connect( func(_i): _apply_browse_filters())
	col.add_child(_labeled("region", _bw_region))
	_bw_sort = UiSelect.new(["lowest ping", "most players", "fewest players"])
	_bw_sort.selected = 0
	_bw_sort.picked.connect( func(_i): _apply_browse_filters())
	col.add_child(_labeled("sort by", _bw_sort))
	_bw_full = _filter_check("show full lobbies", true)
	col.add_child(_bw_full)
	_bw_friends = _filter_check("friends only", false)
	col.add_child(_bw_friends)
	_bw_auto = _filter_check("auto refresh", false)
	col.add_child(_bw_auto)
	return card


func _filter_check(text: String, on: bool) -> CheckBox:
	var cb: = CheckBox.new()
	cb.text = text
	cb.button_pressed = on
	UiStyle.style_check(cb)
	cb.toggled.connect( func(_p): _apply_browse_filters())
	return cb

func _build_host() -> void :
	var v: = _box(_host)
	_hero_head(v, "custom lobby", true)


	_priv_opt = UiSelect.new(["public", "friends only", "private"])
	v.add_child(_labeled("who can join", _priv_opt))


	var player_labels: Array = []
	for n in MAX_PLAYER_CHOICES:
		player_labels.append("%d players" % n)
	_max_players_opt = UiSelect.new(player_labels)
	_max_players_opt.selected = MAX_PLAYER_CHOICES.find(12)
	v.add_child(_labeled("max players", _max_players_opt))
	_pw_edit = LineEdit.new()
	_pw_edit.secret = true
	_pw_edit.placeholder_text = "password"
	_pw_edit.custom_minimum_size = Vector2(0, 44)
	UiStyle.style_line_edit(_pw_edit)
	_pw_edit.visible = false
	_priv_opt.picked.connect( func(i: int):
		_pw_edit.visible = i == Net.Priv.PASSWORD)
	v.add_child(_pw_edit)
	_host_online_card = _card_btn("share1", "host online", 
		"", "primary", _on_host_online)
	v.add_child(_host_online_card)
	_host_steam_card = _card_btn("massiveMultiplayer", "host on steam", 
		"", "info", _on_host_steam)
	v.add_child(_host_steam_card)



	if not LaunchGate.public_beta():
		v.add_child(_card_btn("multiplayer", "host on lan", 
			"", "info", _on_host))
		v.add_child(_card_btn("target", "host an open gym", 
			"", "info", _on_host_gym))
	_host_status = _online_status()
	v.add_child(_host_status)
	_back_row(v, func(): _show(_online))

func _build_direct() -> void :
	var v: = _box(_direct)
	_hero_head(v, "direct join", true)
	var hint: = Label.new()
	hint.text = "join a lan host by address"
	UiStyle.style_label(hint, "small")
	v.add_child(hint)
	var join_row: = HBoxContainer.new()
	join_row.add_theme_constant_override("separation", 10)
	_ip_edit = LineEdit.new()
	_ip_edit.placeholder_text = "127.0.0.1"
	_ip_edit.custom_minimum_size = Vector2(0, 46)
	_ip_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.style_line_edit(_ip_edit)
	join_row.add_child(_ip_edit)
	var join_btn: = Button.new()
	join_btn.text = "join"
	join_btn.custom_minimum_size = Vector2(110, 46)
	UiStyle.style_button(join_btn, "primary", 22)
	join_btn.pressed.connect(_on_join)
	join_row.add_child(join_btn)
	v.add_child(join_row)
	_direct_pw = LineEdit.new()
	_direct_pw.secret = true
	_direct_pw.placeholder_text = "password (if the room has one)"
	_direct_pw.custom_minimum_size = Vector2(0, 44)
	UiStyle.style_line_edit(_direct_pw)
	v.add_child(_direct_pw)
	_direct_status = _online_status()
	v.add_child(_direct_status)
	_back_row(v, func(): _show(_online))

func _build_room() -> void :




	var v: = _box(_room)
	v.add_theme_constant_override("separation", 10)
	_room.add_theme_constant_override("margin_top", 88)
	_room.add_theme_constant_override("margin_bottom", 70)
	_room.position.x = 74
	_room_panel = LobbyPanel.new()
	_room_panel.stage_changed.connect( func(id: String):
		Net.set_stage(id)
		GameConfig.stage = id
		GameConfig.preload_venue(id)
		GameConfig.save_settings())
	_room_panel.rule_changed.connect(_on_room_rule)
	_room_panel.global_cpu_changed.connect( func(d: int): Net.set_cpu_difficulty(d))
	_room_panel.cpu_diff_step.connect( func(id: String, dir: int):
		if Net.is_host:
			_cpu_step(Net.cpu_slots, id, dir, func(): Net.set_cpu_slots(Net.cpu_slots)))
	_room_panel.cpu_reroll.connect( func(id: String):
		if Net.is_host:
			_cpu_reroll(Net.cpu_slots, id, func(): Net.set_cpu_slots(Net.cpu_slots)))
	_room_panel.side_pressed.connect( func(side: int): Net.pick_side(side))
	_room_panel.start_pressed.connect(_on_start_online)
	_room_panel.shuffle_pressed.connect( func(): Net.shuffle_sides())
	_room_panel.invite_pressed.connect( func():
		if Net.online_session() and Net.lobby_code() != "":
			DisplayServer.clipboard_set("https://volleyball.lootline.xyz/?join=" + Net.lobby_code())
			_flash_notice("invite link copied")
		else:
			Net.steam_invite_overlay())
	_room_panel.back_btn.text = "leave"
	_room_panel.back_pressed.connect(_leave_online)
	_room_panel.reset_pressed.connect( func():
		Net.set_rules(Net.RULE_DEFAULTS.pts, Net.RULE_DEFAULTS.sets, 
			Net.RULE_DEFAULTS.wbt, Net.RULE_DEFAULTS.sweat, Net.RULE_DEFAULTS.rate)
		Net.set_stage("nationals")
		GameConfig.stage = "nationals"
		_refresh_room())
	v.add_child(_room_panel)
	_start_btn = _room_panel.start_btn
var _room_panel: LobbyPanel = null


func _on_room_rule(key: String, value: Variant) -> void :
	if not Net.is_host:
		return
	if key == "size":
		Net.set_team_size(clampi(int(value), 1, 6))
		return
	var pts: = Net.rule_points
	var sets: = Net.rule_sets
	var wbt: = Net.rule_wbt
	var sweat: = Net.rule_sweat
	var rate: = Net.rule_rate
	match key:
		"sets":
			sets = clampi(int(value), 1, 3)
		"points":
			pts = clampi(int(value), 3, 25)
		"wbt":
			wbt = bool(value)
		"sweat":
			sweat = bool(value)
		"rate":
			var ri: = clampi(int(value), 0, SWEAT_RATES.size() - 1)
			sweat = ri > 0
			if ri > 0:
				rate = SWEAT_RATES[ri]
	Net.set_rules(pts, sets, wbt, sweat, rate)

func _online_status() -> Label:
	var l: = Label.new()
	l.text = ""
	UiStyle.style_label(l, "small")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l



func _apply_privacy() -> void :
	Net.privacy = _priv_opt.selected if _priv_opt != null else Net.Priv.PUBLIC
	Net.password = _pw_edit.text.strip_edges()\
	if Net.privacy == Net.Priv.PASSWORD and _pw_edit != null else ""
	if Net.privacy == Net.Priv.PASSWORD and Net.password == "":
		Net.privacy = Net.Priv.PUBLIC




func _selected_max_humans() -> int:
	if _max_players_opt == null:
		return 0
	return int(MAX_PLAYER_CHOICES[clampi(_max_players_opt.selected, 0, 
		MAX_PLAYER_CHOICES.size() - 1)])

func _on_host_online() -> void :
	if not OnlineTerms.require(_on_host_online):
		return
	Net.my_name = _online_name()
	_apply_privacy()
	# WebRTC over the Supabase signaling backend: no port forwarding, no Steam,
	# and it works identically in the desktop and browser builds.
	if Net.host_game_web(Net.my_name) == OK:
		Net.custom_lobby = true
		Net.max_humans = _selected_max_humans()
		Net.init_rules_from_config()
		_show_room()
	else:
		_host_status.text = "online hosting unavailable; check your connection and try again"

func _on_host() -> void :
	if not OnlineTerms.require(_on_host):
		return
	Net.my_name = _online_name()
	_apply_privacy()
	var host_err: Error
	if OS.has_feature("web"):
		host_err = Net.host_game_web(Net.my_name)
	else:
		host_err = Net.host_game(Net.my_name)
	if host_err == OK:
		Net.custom_lobby = true
		Net.max_humans = _selected_max_humans()
		Net.init_rules_from_config()
		_show_room()
	else:
		_host_status.text = "online hosting is unavailable; check your connection and try again" if OS.has_feature("web") else "couldn't open the port, are you already hosting?"

func _on_host_steam() -> void :
	if not OnlineTerms.require(_on_host_steam):
		return
	Net.my_name = _online_name()
	_apply_privacy()
	if Net.host_game_steam(Net.my_name) == OK:
		Net.custom_lobby = true
		Net.max_humans = _selected_max_humans()
		Net.init_rules_from_config()
		_show_room()
	else:
		_host_status.text = "steam hosting unavailable"

func _on_host_gym() -> void :
	if not OnlineTerms.require(_on_host_gym):
		return
	Net.my_name = _online_name()
	_apply_privacy()

	if Net.host_gym(Net.my_name, Input.is_key_pressed(KEY_SHIFT)) == OK:
		UiWipe.wipe(get_tree(), func():
			GameConfig.goto_scene("res://game/gym/open_gym.tscn"))
	else:
		_host_status.text = "couldn't open the gym, are you already hosting?"

func _on_join() -> void :
	if not OnlineTerms.require(_on_join):
		return
	Net.my_name = _online_name()
	if _direct_pw != null:
		Net.join_password = _direct_pw.text
	var ip: = _ip_edit.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"
	if Net.join_game(ip, Net.my_name) == OK:
		Net.custom_lobby = true
		_direct_status.text = "connecting to %s..." % ip
		_watch_direct(ip)
	else:
		_direct_status.text = "bad address"

func _watch_direct(ip: String) -> void :

	await get_tree().create_timer(6.0).timeout
	if not Net.party and Net.players.is_empty() and _direct != null\
	and _direct.visible:
		_direct_status.text = \
		"couldn't join %s -- wrong ip, host left, or firewall" % ip






func _on_play_tab() -> void :
	if Net.active and Net.custom_lobby and not Net.party and Net.players.size() > 0 and _room != null:
		_show_room()
	else:
		_show(_home)

func _show_room() -> void :
	_show(_room)
	_refresh_room()


	if _chat != null:
		_chat.unfold()




func _back_to_hub() -> void :
	if Net.active and Net.custom_lobby and not Net.party and Net.players.size() > 0 and _room != null:
		_show_room()
	else:
		_show(_home)

func _leave_online() -> void :





	if Net.active and bool(Net.home_party.get("is_leader", false))\
	and bool(Net.home_party.get("room", false)):
		Net.send_party_home()
		_show(_online)
		get_tree().create_timer(PARTY_RELAY_FLUSH).timeout.connect( func():
			Net.leave()
			_maybe_resume_home_party())
		return
	Net.leave()


	_maybe_resume_home_party()
	_show(_online)




func _on_party_home_called(leader_sid: int) -> void :
	var hp: Dictionary = Net.home_party
	if hp.is_empty() or bool(hp.get("is_leader", false)):
		return
	var mine: = int(hp.get("leader_sid", 0))
	if leader_sid != 0 and mine != 0 and mine != leader_sid:
		return





	_go_home_from_room.call_deferred()

func _go_home_from_room() -> void :
	Net.leave()
	_maybe_resume_home_party()
	if _room.visible or _browse.visible or _host.visible or _direct.visible:
		_show(_online)



func _on_party_travel_to(host_id: int, code: String) -> void :
	_cancel_search()
	Net.my_name = _online_name()
	_party_join_server(host_id, "", code)
	if _browse_hint != null:
		_browse_hint.text = "taking the party to the lobby..."

func _on_session_ended(reason: String) -> void :




	if _member_queuing:
		_member_queuing = false
		_mm_chip.visible = false
		_set_matchmaking(false)


	if _qp != null and _qp.state != QuickPlay.State.IDLE:
		return



	if reason != "" and reason != "left" and reason != "restart":
		_flash_notice(reason)
	_joining_live = false
	_clear_party_bodies()


	if _in_party_room:
		_in_party_room = false
		_maybe_resume_home_party()
	if _room.visible or _browse.visible or _host.visible or _direct.visible:
		_show(_online)
	if _browse.visible and _browse_hint != null:
		_browse_hint.text = reason



func _refresh_browser() -> void :
	for child in _browse_list.get_children():
		child.queue_free()
	# A deep-linked join code can arrive on any platform, not just the browser.
	if not _web_join_consumed and get_tree().root.has_meta("web_join_code"):
		var join_code := String(get_tree().root.get_meta("web_join_code", ""))
		get_tree().root.remove_meta("web_join_code")
		_web_join_consumed = true
		if join_code != "":
			_on_join_code.call_deferred(join_code)
	# Online courts are the primary list everywhere now, so try Supabase first
	# and only fall back to Steam lobbies if the signaling backend is down.
	if SupabaseClient.is_ready:
		_browse_hint.text = "searching online courts..."
		SupabaseClient.list_lobbies()
		return
	if _steam_up:
		_browse_hint.text = "searching..."
		Net.steam_request_lobbies()
		return
	_browse_hint.text = "connecting to online services..."



func _browse_fake(n: int) -> void :
	_show(_browse)
	var names: = ["reg's court", "spike city", "beach bums", "net ninjas", 
		"sunday league", "the pit", "grass stains", "block party", "dig deep", 
		"ace holes", "bump set spike", "sand castle", "the net returns", 
		"volley llamas", "court jesters", "pancake club", "rally cats", 
		"setters gonna set", "kill zone", "over the net"]
	var stages: Array = Stage.ids(false)
	if stages.is_empty():
		stages = ["nationals"]
	var rng: = RandomNumberGenerator.new()
	rng.seed = 1234
	var rows: Array = []
	for i in n:
		var cap: int = [2, 4, 6, 8][rng.randi() % 4]
		var cur: = rng.randi_range(0, cap)
		var in_game: = rng.randf() < 0.35
		var st: String = String(stages[rng.randi() % stages.size()])


		var ping: int = [-1, rng.randi_range(8, 30), rng.randi_range(30, 70), 
			rng.randi_range(75, 130)][rng.randi() % 4]
		var nm: = String(names[i % names.size()])
		if i >= names.size():
			nm += " %d" % (i / names.size() + 1)
		rows.append({
			"name": nm, "steam": true, "host_id": 100000 + i, "lobby_id": 200000 + i, 
			"kind": "", "state": "game" if in_game else "lobby", 
			"mode": "%dv%d" % [cap / 2, cap / 2], "players": cur, "humans": cur, 
			"cap": str(cap), "ping": ping, "map": st, "stage": st, 
			"compatible": true, "priv": "public", "locked": rng.randf() < 0.12, 
		})
	_bw_rows = rows
	_apply_browse_filters()

func _on_steam_lobbies(rows: Array) -> void :
	if not _browse.visible:
		return





	_bw_rows = rows.filter( func(r): return String(r.get("kind", "")) in ["custom", "gym"])
	_apply_browse_filters()

func _on_web_lobbies(rows: Array) -> void:
	if _browse == null or not _browse.visible:
		return
	_bw_rows.clear()
	for row in rows:
		if not row is Dictionary or int(row.get("proto", -1)) != Net.PROTO:
			continue
		if String(row.get("priv", "public")) != "public":
			continue
		_bw_rows.append({
			"name": String(row.get("name", "open court")),
			"steam": false,
			"web": true,
		"room": String(row.get("room", "")),
		"owner": String(row.get("owner", "")),
		"lobby_id": String(row.get("id", "")),
			"host_id": 0,
			"ip": "",
			"players": int(row.get("humans", 1)),
			"humans": int(row.get("humans", 1)),
			"kind": String(row.get("kind", "custom")),
			"mode": String(row.get("mode", "2v2")),
			"state": "game" if String(row.get("state", "lobby")) == "game" else "lobby",
			"stage": String(row.get("stage", "nationals")),
			"map": String(row.get("stage", "nationals")),
			"cap": str(row.get("cap", Net.MAX_PLAYERS)),
			"ping": -1,
			"compatible": true,
			"priv": String(row.get("priv", "public")),
			"locked": bool(row.get("locked", false)),
		})
	_apply_browse_filters()


func _bw_cur(r: Dictionary) -> int:
	return maxi(int(r.get("humans", r.get("players", 0))), 0)

func _bw_cap(r: Dictionary) -> int:




	var c: = int(String(r.get("cap", "0")))
	return c if c > 0 else Net.MAX_PLAYERS


func _apply_browse_filters() -> void :
	if _browse_list == null:
		return
	var rows: Array = _bw_rows.duplicate()










	rows = rows.filter( func(r):
		if String(r.get("priv", "public")) != "friends":
			return true
		if not bool(r.get("steam", false)):
			return true
		var hid: = int(r.get("host_id", 0))
		return hid == Net.my_steam_id() or Net._is_friend(hid))
	var q: = _bw_search.text.strip_edges().to_lower() if _bw_search != null else ""
	if q != "":
		rows = rows.filter( func(r):
			return String(r.get("name", "")).to_lower().contains(q))
	if _bw_region != null:
		var ceil_ms: int = BW_REGION_MS[clampi(_bw_region.selected, 0, 3)]
		rows = rows.filter( func(r):
			var p: = int(r.get("ping", -1))
			return p < 0 or p <= ceil_ms)
	if _bw_friends != null and _bw_friends.button_pressed:
		rows = rows.filter( func(r): return bool(r.get("steam", false))\
		and Net._is_friend(int(r.get("host_id", 0))))
	if _bw_full != null and not _bw_full.button_pressed:
		rows = rows.filter( func(r): return _bw_cur(r) < _bw_cap(r))



	var sort_i: = _bw_sort.selected if _bw_sort != null else 0
	rows.sort_custom( func(a, b): return _bw_less(a, b, sort_i))
	_render_browse_rows(rows)



func _bw_less(a: Dictionary, b: Dictionary, sort_i: int) -> bool:
	if sort_i == 1:
		return _bw_cur(a) > _bw_cur(b)
	if sort_i == 2:
		return _bw_cur(a) < _bw_cur(b)
	var pa: = int(a.get("ping", -1))
	var pb: = int(b.get("ping", -1))
	if pa < 0:
		return false
	if pb < 0:
		return true
	return pa < pb




func _bw_signal_pill(row: Dictionary) -> Control:
	var pill: = PanelContainer.new()
	var box: = UiStyle.card_box(UiStyle.card(), 99)
	box.content_margin_left = 10.0
	box.content_margin_right = 12.0
	box.content_margin_top = 3.0
	box.content_margin_bottom = 3.0
	box.shadow_size = 3
	box.shadow_offset = Vector2(0, 2)
	pill.add_theme_stylebox_override("panel", box)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hb: = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(hb)
	var bars: = StatRow.SignalBars.new()
	bars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(bars)
	var txt: = Label.new()
	txt.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	txt.add_theme_font_size_override("font_size", 13)
	txt.add_theme_color_override("font_color", UiStyle.muted())
	txt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(txt)
	var web_lobby := bool(row.get("web", false))
	var lan: = not bool(row.get("steam", false)) and not web_lobby
	var p: = int(row.get("ping", -1))
	if web_lobby:
		bars.lit = 0
		txt.text = "online"
	elif lan:
		bars.set_ms(0.0)
		txt.text = "lan"
	elif p < 0:
		bars.lit = 0
		txt.text = "?"
	else:
		bars.set_ms(float(p))
		txt.text = "%dms" % p
	return pill

const ROW_ART_SHADER: = "\r\nshader_type canvas_item;\r\nuniform float radius = 14.0;\r\nuniform float fade_from = 0.44;\r\nuniform float fade_to = 0.80;\r\nuniform vec2 rect = vec2(460.0, 78.0);   // the card's size, set from code\r\nvoid fragment() {\r\n\tvec2 px = UV * rect;\r\n\tvec2 sz = rect;\r\n\tvec2 q = abs(px - sz * 0.5) - (sz * 0.5 - vec2(radius));\r\n\tfloat d = length(max(q, 0.0)) - radius;\r\n\tfloat a = 1.0 - smoothstep(-1.0, 1.0, d);\r\n\tfloat f = smoothstep(fade_from, fade_to, UV.x);\r\n\tCOLOR = texture(TEXTURE, UV);\r\n\tCOLOR.a *= a * f;\r\n}\r\n"
















static var _row_art_shader: Shader = null



func _row_stage_art(r: Button, stage_id: String) -> void :
	if stage_id == "" or not Stage.STAGES.has(stage_id):
		return
	var tex: = Stage.thumb(stage_id)
	if tex == null:
		return
	if _row_art_shader == null:
		_row_art_shader = Shader.new()
		_row_art_shader.code = ROW_ART_SHADER
	var art: = TextureRect.new()
	art.texture = tex
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.set_anchors_preset(Control.PRESET_FULL_RECT)



	art.offset_bottom = -8.0
	art.offset_right = -1.0
	art.offset_left = 1.0
	art.offset_top = 1.0
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.modulate = Color(1, 1, 1, 0.9)
	var mat: = ShaderMaterial.new()
	mat.shader = _row_art_shader
	mat.set_shader_parameter("radius", 15.0)
	art.material = mat
	art.resized.connect( func(): mat.set_shader_parameter("rect", art.size))
	r.add_child(art)
	r.move_child(art, 0)



func _render_browse_rows(rows: Array) -> void :
	for child in _browse_list.get_children():
		child.queue_free()
	if rows.is_empty():
		var q: = _bw_search.text.strip_edges() if _bw_search != null else ""
		_browse_hint.text = ("no courts matching \"%s\"" % q) if q != ""\
		else "no courts open right now"
		return
	_browse_hint.text = "%d court%s open" % [rows.size(), 
		"" if rows.size() == 1 else "s"]
	for row in rows:
		var cur: = _bw_cur(row)
		var cap: = _bw_cap(row)
		var full: = cur >= cap
		var kind: = String(row.get("kind", ""))
		var locked: = bool(row.get("locked", false))
		var compatible: = bool(row.get("compatible", true))
		var icon_name: = "menuList"
		var sub: = ""
		if kind == "gym":
			icon_name = "target"
			sub = "open gym hall"
		elif String(row.get("state", "")) == "game":
			icon_name = "massiveMultiplayer"
			sub = "in game     %s" % String(row.get("map", "court"))
		else:
			icon_name = "multiplayer"
			sub = "in lobby     %s" % ("steam" if row.steam else ("online" if bool(row.get("web", false)) else "lan"))

		var trailing: = HBoxContainer.new()
		trailing.add_theme_constant_override("separation", 6)
		var mode: = String(row.get("mode", ""))
		if mode != "":
			trailing.add_child(UiPage.tag(mode, UiStyle.SECONDARY))
		trailing.add_child(_bw_signal_pill(row))
		if not compatible:
			trailing.add_child(UiPage.tag("old version", UiStyle.muted()))
		elif locked:
			trailing.add_child(UiPage.tag("locked", UiStyle.INK))
		elif String(row.get("priv", "public")) == "friends":
			trailing.add_child(UiPage.tag("friends", UiStyle.SECONDARY))
		trailing.add_child(UiPage.tag("%d/%d" % [cur, cap], 
			UiStyle.muted() if full else UiStyle.SUCCESS))
		var r: = UiPage.card_row(icon_name, String(row.name), sub, "info", 
			Callable(), trailing, 460.0, true)


		if String(row.get("state", "")) == "game":
			_row_stage_art(r, String(row.get("stage", "")))
		if not compatible or (full and not locked):
			r.disabled = true
		else:
			r.pressed.connect( func():
				if locked:
					_prompt_password(row)
				else:
					_dial_row(row))
		_browse_list.add_child(r)
	UiPage.reveal(_browse_list)



func _on_join_code(text: String) -> void :
	var s: = text.strip_edges()
	if s == "":
		return
	if not OnlineTerms.require(_on_join_code.bind(text)):
		return


	if Net.party and not Net.is_host:
		_flash_notice("only the party leader can move the party")
		return
	Net.my_name = _online_name()
	if s.contains(".") or s.contains(":"):
		if Net.party:
			_party_join_server(0, s)
			_browse_hint.text = "taking the party to %s..." % s
			return
		if Net.join_game(s, Net.my_name) == OK:
			_browse_hint.text = "joining %s..." % s
			_watch_join(s)
		else:
			_browse_hint.text = "couldn't reach %s" % s
		return



	if s.begins_with("court-"):
		if Net.join_game_web(s, "", Net.my_name) == OK:
			_browse_hint.text = "joining online court..."
			_watch_join(s)
		else:
			_browse_hint.text = "couldn't join online court"
		return
	var has_key: = s.contains("-")
	for row in _bw_rows:
		if not has_key and (str(row.get("lobby_id", "")) == s\
		or String(row.get("name", "")).to_lower() == s.to_lower()):
			_dial_row(row)
			return



	if Net.join_by_code(s):
		_cancel_search()
		_browse_hint.text = "joining lobby..."
		_watch_join("lobby")
		return
	_browse_hint.text = "no lobby with code \"%s\"" % s

func _dial_row(row: Dictionary) -> void :
	if not OnlineTerms.require(_dial_row.bind(row)):
		return


	_cancel_search()
	Net.my_name = _online_name()
	_joining_live = String(row.get("state", "")) == "game"\
	or String(row.get("kind", "")) == "gym"
	if bool(row.steam) and int(row.host_id) == Net.my_steam_id():
		return


	if Net.party:
		if not Net.is_host:
			_flash_notice("only the party leader can move the party")
			return
		_party_join_server(int(row.host_id) if bool(row.steam) else 0, 
			"" if bool(row.steam) else String(row.ip), 
			str(row.lobby_id) if bool(row.steam)\
			and int(row.get("lobby_id", 0)) != 0 else "")
		_browse_hint.text = "taking the party to %s..." % row.name
		return
	var ok: = false
	if bool(row.get("web", false)):
		ok = Net.join_game_web(String(row.get("room", "")), String(row.get("owner", "")), Net.my_name) == OK
	elif row.steam:
		ok = Net.join_game_steam(row.host_id, Net.my_name) == OK
	else:
		ok = Net.join_game(row.ip, Net.my_name) == OK
	if ok:
		Net.custom_lobby = true



		if bool(row.steam) and int(row.get("lobby_id", 0)) != 0:
			Net.remote_lobby_code = str(row.lobby_id)
		_browse_hint.text = "joining %s..." % row.name
		_watch_join(row.name)




func _party_join_server(host_id: int, host_ip: String, code: = "") -> void :
	Net.rehome_party(host_id, host_ip, [], 0)
	Net.home_party = {"is_leader": true, "token": Net.session_token, "room": true}
	_server_join = {"host_id": host_id, "ip": host_ip, "code": code}
	_server_join_t = 0.35

func _drive_server_join() -> void :
	var sj: = _server_join
	_server_join = {}
	var ok: = false
	if int(sj.get("host_id", 0)) != 0:
		ok = Net.join_game_steam(int(sj.host_id), Net.my_name) == OK
	elif String(sj.get("ip", "")) != "":
		ok = Net.join_game(String(sj.ip), Net.my_name) == OK
	if not ok:
		return



	Net.custom_lobby = true
	if String(sj.get("code", "")) != "":
		Net.remote_lobby_code = String(sj.code)

func _prompt_password(row: Dictionary) -> void :
	if _pw_panel != null:
		_pw_panel.queue_free()
	_pw_panel = PanelContainer.new()
	UiStyle.style_panel(_pw_panel, UiStyle._AUTO, UiStyle.RADIUS_SOFT)
	var box: = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	var label: = Label.new()
	label.text = "password?"
	UiStyle.style_label(label, "title")
	box.add_child(label)
	var edit: = LineEdit.new()
	edit.secret = true
	edit.placeholder_text = "password"
	edit.custom_minimum_size = Vector2(260, 44)
	UiStyle.style_line_edit(edit)
	box.add_child(edit)
	var btns: = HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	btns.alignment = BoxContainer.ALIGNMENT_END
	var cancel: = Button.new()
	cancel.text = "cancel"
	UiStyle.style_button(cancel, "tertiary", 16)
	var go: = Button.new()
	go.text = "join"
	UiStyle.style_button(go, "primary", 16)
	btns.add_child(cancel)
	btns.add_child(go)
	box.add_child(btns)
	var pad: = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_%s" % side, 18)
	pad.add_child(box)
	_pw_panel.add_child(pad)
	ui.add_child(_pw_panel)
	_pw_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var submit: = func():
		Net.join_password = edit.text
		_pw_panel.queue_free()
		_pw_panel = null
		_dial_row(row)
	go.pressed.connect(submit)
	edit.text_submitted.connect( func(_t: String): submit.call())
	cancel.pressed.connect( func():
		_pw_panel.queue_free()
		_pw_panel = null)
	edit.grab_focus()

func _watch_join(court_name: String) -> void :
	await get_tree().create_timer(10.0).timeout
	if Net.active and not Net.in_match and Net.players.is_empty():
		Net.leave()
		if _browse.visible:
			_browse_hint.text = "couldn't connect to %s" % court_name

func _refresh_room() -> void :
	if not Net.active:
		return


	if not _room.visible and not Net.is_host and Net.players.size() > 0\
	and (_qp == null or _qp.state == QuickPlay.State.IDLE)\
	and not _joining_live and not Net.party:
		_show_room()
	if not _room.visible or _room_panel == null:
		return
	var me: = _my_party_id()
	var ids: = Net.players.keys()
	ids.sort()
	var humans: = {1: 0, -1: 0}
	var entries: = {1: [], -1: []}
	var specs: Array = []
	var my_side: = 0
	var benched: = false
	for id in ids:
		var side: int = Net.players[id].side
		var name: = String(Net.players[id].name)
		var on_team: bool = side != 0 and int(humans[side]) < Net.team_size
		if id == me:
			my_side = side
			benched = side != 0 and not on_team
		if not on_team:
			specs.append(name)
			continue
		var cfg: Dictionary = Net.players[id].get("cfg", {})
		if id == me and GameConfig.character != null:
			cfg = GameConfig.character.to_dict()
		entries[side].append({"kind": "human", "name": name, 
			"cfg": cfg, "host": id == 1, "you": id == me, 
			"dev": DevBadge.peer_tier(id)})
		humans[side] += 1


	if Net.is_host and CpuSlots.reconcile(Net.cpu_slots, Net.team_size, humans, 
			Net.cpu_difficulty):
		Net.call_deferred("set_cpu_slots", Net.cpu_slots)
	for side in [1, -1]:
		for cpu in CpuSlots.ordered(Net.cpu_slots, side):
			entries[side].append({"kind": "cpu", "name": String(cpu.name), 
				"cfg": cpu.cfg, "diff": int(cpu.diff), 
				"id": CpuSlots.id_for(side, int(cpu.k))})
	var tell: = ""
	if benched:
		tell = "that side is full, join %s to play" % ("away" if my_side == 1 else "home")
	elif my_side == 0 and Net.players.has(me):
		tell = "join home or away to play"
	_room_panel.apply({"title": "lobby", "stage_ids": Stage.ids(), 
		"stage": Net.stage if Stage.STAGES.has(Net.stage) else "nationals", 
		"size": Net.team_size, "home": entries[1], "away": entries[-1], 
		"rules": {"sets": Net.rule_sets, "points": Net.rule_points, 
			"wbt": Net.rule_wbt, "sweat": Net.rule_sweat, 
			"rate": _rate_index(Net.rule_rate, Net.rule_sweat)}, 
		"rate_names": SWEAT_RATE_NAMES, 
		"cpu": CpuSlots.global_diff(Net.cpu_slots), 
		"editable": Net.is_host, "my_side": my_side, "side_mode": "online", 
		"side_editable": true, 
		"can_start": Net.is_host, "invite": Net.steam_transport_available(), 

		"shuffle": Net.is_host and Net.players.size() >= 2, 
		"spectators": specs, 
		"hint": "empty seats are filled with cpus" if Net.is_host\
		else "waiting for the host to start...", "tell": tell})

func _on_start_online() -> void :


	Net.apply_rules_to_config()
	var ids: = Net.players.keys()
	ids.sort()
	var kits: = {1: GameConfig.team_kit(true).map( func(c): return (c as Color).to_html(false)), 
		-1: GameConfig.team_kit(false).map( func(c): return (c as Color).to_html(false))}
	var roster: = Net.build_roster(ids, Net.players, Net.team_size, kits, Net.cpu_slots)
	GameConfig.set_mode(Net.team_size)
	GameConfig.stage = Net.stage
	GameConfig.ranked_match = false
	Net.start_match(roster, randi())







var _fp_toggle_frame: = -1

func _enter_freeplay() -> void :
	_freeplay = true
	_fp_toggle_frame = Engine.get_process_frames()
	# Practice runs inside this scene, so the on-screen pad binds here too.
	TouchControls.bind(camera_rig, _input_collector)
	_dock_chat(false)
	_root.visible = false
	_top_panel.visible = false
	_bottom_panel.visible = false
	_top_strip.visible = false
	_bottom_strip.visible = false
	_logo_rect.visible = false
	if _pc_avatar != null:
		_pc_avatar.visible = false
	if _friends_panel != null:
		_friends_panel.visible = false
	if _friends_scrim != null:
		_friends_scrim.visible = false

	_mm_chip.visible = _member_queuing\
	or (_qp != null and _qp.state != QuickPlay.State.IDLE)

	ui.get_viewport().gui_release_focus()



	_input_collector.swallow_held(["jump", "contact", "serve", "dive", "set"])

	_fp_hint.visible = false
	hud.visible = true
	hud.set_scoreboard_visible(false)
	hud.set_serve_prompt("press r to take the ball in hand")
	player.ball = ball
	player.indicator_enabled = true
	player.charge_ui_enabled = true


	if _sand_deform != null:
		_sand_deform.reset()
	_floor_mat.set_shader_parameter("reflect_on", true)
	camera_rig.mode_locked = false
	camera_rig.mode = clampi(GameConfig.default_camera, 0, 
		CameraRig.Mode.size() - 1) as CameraRig.Mode
	camera_rig.camera.current = true
	camera_rig.apply_mouse_mode()

	if LOCAL_COOP_DROPIN:
		LocalPlayers.watch_joins = true
		if not LocalPlayers.roster_changed.is_connected(_sync_local_guests):
			LocalPlayers.roster_changed.connect(_sync_local_guests)
		_sync_local_guests()
	_update_presence()

func _exit_freeplay() -> void :
	_freeplay = false
	TouchControls.unbind(camera_rig)

	if LOCAL_COOP_DROPIN:
		LocalPlayers.watch_joins = false
		LocalPlayers.reset_to_primary()
		_sync_local_guests()
		_input_collector.set_exclude_pads(PackedInt32Array())
	_fp_toggle_frame = Engine.get_process_frames()
	_dock_chat(true)
	_serving = false
	_clear_party_bodies()
	camera_rig.serve_view = false


	player.clear_action_state()
	player.serve_charge_ui = false
	_spin = 0.0
	reach_marker.reset()

	ball.frozen = false
	player.ball = null
	player.indicator_enabled = false
	player.charge_ui_enabled = false

	if _sand_deform != null:
		_sand_deform.reset()
	hud.visible = false
	aim_indicator.visible = false
	_floor_mat.set_shader_parameter("reflect_on", false)
	_root.visible = true
	_top_panel.visible = true
	_bottom_panel.visible = true
	_top_strip.visible = true
	_bottom_strip.visible = true
	_logo_rect.visible = true
	if _pc_avatar != null:
		_pc_avatar.visible = true
	_mm_chip.visible = false

	if _member_queuing:
		_set_matchmaking(true)
		_mm_cancel.visible = false
	_update_presence()
	_fp_hint.visible = false
	player.global_position = HOME_SPOT
	player.velocity = Vector3.ZERO
	player.team_side = 1
	player.reset_physics_interpolation()
	_face_camera()
	ball.global_position = HOME_SPOT + Vector3(-0.45, 0.4, 0.5)
	ball.vel = Vector3.ZERO
	ball.reset_physics_interpolation()
	menu_cam.current = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	UiStyle.sfx("close")

	call_deferred("_focus_current_page")



func _focus_current_page() -> void :
	for p in [_home, _online, _local, _practice, _drills, _profile, _quick, 
		_settings, _howto, _browse, _host, _room, _direct, _recent]:
		if p != null and p.visible:
			_focus_first(p)
			return



func _restore_focus() -> void :
	if _last_focus != null and is_instance_valid(_last_focus)\
	and _last_focus.is_visible_in_tree()\
	and _last_focus.focus_mode != Control.FOCUS_NONE\
	and not (_last_focus is BaseButton and (_last_focus as BaseButton).disabled):
		_last_focus.grab_focus()
		_scroll_follow(_last_focus)
		return
	_focus_current_page()





func _zone_step(step: int) -> void :
	var foc: = get_viewport().gui_get_focus_owner() as Control
	if foc == null:
		_focus_current_page()
		return
	var items: = _zone_buttons(_zone_of(foc))
	if items.is_empty():
		return
	var idx: = items.find(foc)
	if idx == -1:
		(items[0] as Control).grab_focus()
		return
	var nxt: = items[(idx + step + items.size()) % items.size()] as Control
	nxt.grab_focus()
	_scroll_follow(nxt)
	UiStyle.sfx("hover")



func _zone_buttons(zone: int) -> Array:
	var root: Node = _top_bar if zone == 0 else (_bottom_bar if zone == 2 else _visible_page())
	var out: Array = []
	if root == null:
		return out
	for c in root.find_children("*", "BaseButton", true, false):
		var b: = c as BaseButton
		if b != null and b.is_visible_in_tree() and not b.disabled\
		and b.focus_mode != Control.FOCUS_NONE:
			out.append(b)
	return out


func _zone_of(ctrl: Control) -> int:
	if ctrl != null:
		if _top_bar != null and _top_bar.is_ancestor_of(ctrl):
			return 0
		if _bottom_bar != null and _bottom_bar.is_ancestor_of(ctrl):
			return 2
	return 1





func _grab_zone(zone: int, bottom_edge: = false) -> bool:
	match zone:
		0:
			return _focus_edge_button(_zone_buttons(0), false)
		2:
			return _focus_edge_button(_zone_buttons(2), false)
		_:
			return _focus_edge_button(_zone_buttons(1), bottom_edge)


func _focus_edge_button(items: Array, last: bool) -> bool:
	if items.is_empty():
		return false
	var target: = items[items.size() - 1 if last else 0] as Control
	target.grab_focus()
	_scroll_follow(target)
	UiStyle.sfx("hover")
	return true


const NAV_FIRST_DELAY: = 0.42
const NAV_REPEAT_RATE: = 0.11
const NAV_DEBOUNCE: = 0.07
const ACCEPT_DEBOUNCE: = 0.22
var _nav_dir: = ""
var _nav_repeat: = 0.0
var _nav_cooldown: = 0.0
var _accept_cd: = 0.0
var _cancel_cd: = 0.0




var _last_focus: Control = null





func _menu_nav(delta: float) -> void :
	if _freeplay:
		_nav_dir = ""
		return
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return
	_nav_cooldown = maxf(_nav_cooldown - delta, 0.0)
	_accept_cd = maxf(_accept_cd - delta, 0.0)
	_cancel_cd = maxf(_cancel_cd - delta, 0.0)
	_zone_cd = maxf(_zone_cd - delta, 0.0)

	if UiStyle.dialog_active():
		UiStyle.drive_dialog(delta)
		return

	if _friends_panel != null and _friends_panel.visible:
		_drive_friends(delta)
		return


	if UiSelect.active == null:
		var settled: = get_viewport().gui_get_focus_owner() as Control
		if settled != null:
			_last_focus = settled



	if _zone_cd <= 0.0 and UiSelect.active == null:
		if Input.is_action_just_pressed("menu_zone_next"):
			_zone_cd = ACCEPT_DEBOUNCE
			_zone_step(1)
			return
		elif Input.is_action_just_pressed("menu_zone_prev"):
			_zone_cd = ACCEPT_DEBOUNCE
			_zone_step(-1)
			return


	if Input.is_action_just_pressed("ui_accept") and _accept_cd <= 0.0:
		_accept_cd = ACCEPT_DEBOUNCE
		var foc: = get_viewport().gui_get_focus_owner()
		if foc is UiSelect and not (foc as UiSelect).is_open():
			(foc as UiSelect).open_and_focus()
		elif foc is BaseButton and not (foc as BaseButton).disabled:
			var bb: = foc as BaseButton
			if bb.toggle_mode:
				bb.button_pressed = not bb.button_pressed
				UiStyle.sfx("tick")
			else:
				bb.pressed.emit()
		elif foc == null:
			_restore_focus()




	if Input.is_action_just_pressed("ui_cancel") and _cancel_cd <= 0.0\
	and Engine.get_process_frames() != _fp_toggle_frame:
		_cancel_cd = ACCEPT_DEBOUNCE
		if UiSelect.active != null:
			UiSelect.active.close()
		else:
			_menu_cancel()
		return

	var dir: = ""
	if Input.is_action_pressed("ui_down"): dir = "down"
	elif Input.is_action_pressed("ui_up"): dir = "up"
	elif Input.is_action_pressed("ui_right"): dir = "right"
	elif Input.is_action_pressed("ui_left"): dir = "left"
	if dir == "":
		_nav_dir = ""
		return
	if dir != _nav_dir:
		_nav_dir = dir
		_nav_repeat = NAV_FIRST_DELAY
		if _nav_cooldown <= 0.0:
			_nav_cooldown = NAV_DEBOUNCE
			_nav_move(dir)
	elif _nav_repeat <= 0.0:
		_nav_repeat = NAV_REPEAT_RATE
		_nav_move(dir)
	else:
		_nav_repeat -= delta

func _nav_move(dir: String) -> void :


	if UiSelect.active != null:
		UiSelect.active.step_focus(dir)
		return
	var foc: = get_viewport().gui_get_focus_owner() as Control
	if foc == null:
		_restore_focus()
		return


	if foc is Range and (dir == "left" or dir == "right"):
		var r: = foc as Range


		var st: float = maxf(r.step, (r.max_value - r.min_value) / 10.0)
		r.value += st if dir == "right" else - st
		UiStyle.sfx("tick")
		return
	var zone: = _zone_of(foc)




	match dir:
		"down":
			if zone == 0:
				_grab_zone(1, false)
				return
			if zone == 1:
				if _try_neighbor(foc, "down"):
					return
				_grab_zone(2)
				return
			return
		"up":
			if zone == 2:
				_grab_zone(1, true)
				return
			if zone == 1:
				if _try_neighbor(foc, "up"):
					return
				_grab_zone(0)
				return
			return
		_:
			_try_neighbor(foc, dir)




func _try_neighbor(foc: Control, dir: String) -> bool:
	var side: = SIDE_TOP
	var np: = NodePath()
	match dir:
		"up": np = foc.focus_neighbor_top;side = SIDE_TOP
		"down": np = foc.focus_neighbor_bottom;side = SIDE_BOTTOM
		"left": np = foc.focus_neighbor_left;side = SIDE_LEFT
		"right": np = foc.focus_neighbor_right;side = SIDE_RIGHT
	var next: Control = null
	if not np.is_empty():
		next = foc.get_node_or_null(np) as Control
	if next == null or not next.is_visible_in_tree()\
	or next.focus_mode == Control.FOCUS_NONE:
		next = foc.find_valid_focus_neighbor(side)
	if next != null and next != foc and _zone_of(next) == _zone_of(foc):
		next.grab_focus()
		_scroll_follow(next)
		UiStyle.sfx("hover")
		return true
	return false




func _scroll_follow(ctrl: Control) -> void :
	var p: = ctrl.get_parent()
	while p != null:
		if p is ScrollContainer:
			(p as ScrollContainer).ensure_control_visible(ctrl)
			return
		p = p.get_parent()

func _menu_cancel() -> void :


	if _room != null and _room.visible:
		_leave_online()
		UiStyle.sfx("back")
		return



	if _home != null and not _home.visible and _room != null\
	and Net.active and Net.custom_lobby and not Net.party\
	and Net.players.size() > 0:
		_back_to_hub()
		UiStyle.sfx("back")
		return
	if _home != null and not _home.visible:
		_show(_home)
		UiStyle.sfx("back")
	elif _home != null and _home.visible:

		_enter_freeplay()

func _bubble_demo() -> void :
	await get_tree().create_timer(0.6).timeout
	if player == null:
		return
	var b: = BubbleChat.attach(player)
	b.add_message("nice serve!")
	await get_tree().create_timer(0.9).timeout
	b.add_message("anyone up for a quick game after this one? i have like twenty minutes", true)
	await get_tree().create_timer(0.7).timeout
	b.show_typing()


func _visible_page() -> Control:
	for p in [_home, _online, _local, _practice, _drills, _profile, _quick, 
		_settings, _howto, _browse, _host, _room, _direct, _recent, _achievements]:
		if p != null and p.visible:
			return p
	return null

func _visible_scroll() -> ScrollContainer:
	var page: = _visible_page()
	if page == null:
		return null
	for s in page.find_children("*", "ScrollContainer", true, false):
		var sc: = s as ScrollContainer
		if sc != null and sc.is_visible_in_tree():
			return sc
	return null

func _input(event: InputEvent) -> void :






	if _feedback != null and is_instance_valid(_feedback):
		return
	if _freeplay:
		return
	var _fo: = get_viewport().gui_get_focus_owner()
	if _fo is LineEdit or _fo is TextEdit:
		return



	if event is InputEventMouseButton or (event is InputEventMouseMotion\
	and (event as InputEventMouseMotion).relative.length() > 6.0):
		if get_viewport().gui_get_focus_owner() != null:
			get_viewport().gui_release_focus.call_deferred()
		return
	for a in ["ui_accept", "ui_up", "ui_down", "ui_left", "ui_right"]:
		if event.is_action_pressed(a):
			get_viewport().set_input_as_handled()
			return

func _unhandled_input(event: InputEvent) -> void :
	if _freeplay:
		_input_collector.feed_motion(event)
	else:

		if event is InputEventMouseButton\
		and event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
		elif event is InputEventMouseMotion and _dragging:
			_spin += event.relative.x * 0.012
			player.visual.rotation.y = _base_yaw + _spin





	if _freeplay and event is InputEventKey and event.is_action_pressed("ui_cancel"):
		if _tutorial != null:
			return
		if _drill_active != "":
			_leave_drill()
		else:
			_exit_freeplay()

func _process(_delta: float) -> void :


	if not is_inside_tree():
		return

	if _feedback != null and is_instance_valid(_feedback):
		return





	if LocalPlayers.primary_just_pressed("menu_start"):
		if _freeplay:
			if _tutorial != null:
				pass
			elif _drill_active != "":
				_leave_drill()
			else:
				_exit_freeplay()
		elif not _home.visible:
			_show(_home)
		else:
			_enter_freeplay()




	_menu_nav(_delta)




	if not _freeplay and _home != null and _home.visible and player != null:
		var rs: = Input.get_axis("aim_left", "aim_right")
		if absf(rs) > 0.2:
			_spin += rs * 2.6 * _delta
			player.visual.rotation.y = _base_yaw + _spin





	if not _freeplay and InputPrompts.using_gamepad():
		var sc: = _visible_scroll()
		if sc != null:
			var rv: = Input.get_axis("aim_up", "aim_down")
			if absf(rv) > 0.2:
				sc.scroll_vertical += int(rv * 1400.0 * _delta)
	if not _reform_target.is_empty():
		_drive_reform(_delta)


	if _server_join_t > 0.0:
		_server_join_t -= _delta
		if _server_join_t <= 0.0:
			_drive_server_join()


	if _friends_panel != null and _friends_panel.visible:
		_friends_poll -= _delta
		if _friends_poll <= 0.0:
			_friends_poll = 3.0
			_refresh_friends_panel()

	if _browse != null and _browse.visible\
	and _bw_auto != null and _bw_auto.button_pressed:
		_bw_auto_t -= _delta
		if _bw_auto_t <= 0.0:
			_bw_auto_t = 4.0
			_refresh_browser()
	_place_strips()
	_tilt_cards(_delta)
	_lean_tiles(_delta)

	if not _freeplay:
		_drive_menu_camera(_delta)






	if Net.party:
		if _freeplay:
			_drive_party_freeplay(_delta)
		else:
			_drive_party_lineup(_delta)
	elif not _party_bodies.is_empty() or not _party_balls.is_empty():


		_clear_party_bodies()


	if not _freeplay or hud == null:


		if aim_indicator != null and aim_indicator.visible:
			aim_indicator.visible = false
		TouchControls.set_live(false)
		return
	if _drill_results != null and _drill_results.visible:
		hud.set_aim_cursor(false, Vector2.ZERO)
		TouchControls.set_live(false)
		return
	_input_collector.follow_cursor(camera_rig, true)
	# The pad stays out of the way while the pause menu, the chat box or a drill
	# countdown owns the input.
	TouchControls.set_live(not hud.pause_is_open()\
		and not (_chat != null and _chat.is_typing())\
		and not camera_rig.input_frozen)
	hud.set_aim_cursor(_input_collector.soft_cursor_active(), 
		_input_collector.soft_cursor_pos())
	hud.track_ball_marker(camera_rig.camera, ball, true, player)

func _physics_process(delta: float) -> void :
	if player == null:
		return
	var input: = PlayerInput.new()
	if _freeplay:


		if _chat != null and _chat.is_typing():
			input = PlayerInput.new()
		elif _drill_results != null and _drill_results.visible:
			input = PlayerInput.new()
		elif _drill_runner != null and _drill_runner.counting_down():
			input = PlayerInput.new()
		elif _tutorial != null and _tutorial.blocking_input():
			input = PlayerInput.new()
		else:
			input = _input_collector.collect(camera_rig, player)
		if _tutorial != null:


			camera_rig.input_frozen = _tutorial.blocking_input() or hud.pause_is_open()
		var side: = 1 if player.global_position.z >= 0.0 else -1
		if side != player.team_side:



			player.team_side = side
			_cam_side_target = float(side)


		camera_rig.home_side = lerpf(camera_rig.home_side, 
			_cam_side_target, clampf(delta * 2.2, 0.0, 1.0))
		ball.home_side = camera_rig.home_side




		if _drill_active != "":


			_serving = _drill_runner.serve_wanted()
			player.touch_barred = not _drill_runner.touch_allowed() or _serving
			player.serve_charge_ui = _serving
			ball.serve_held = _serving
			camera_rig.serve_view = _serving
			hud.set_serve_prompt("")
			if _serving:


				ball.frozen = true
				ball.vel = Vector3.ZERO
				ball.global_position = player.serve_cradle_point()
				if input.contact_released:
					_serving = false
					player.serve_charge_ui = false
					ball.frozen = false
					ball.serve_assist = true
					ball.toss(player.serve_cradle_point(), 
						lerpf(6.5, 12.0, player.hold_power()))
					player.present_serve_toss()
					_drill_runner.serve_tossed()
			_drill_timer.text = _drill_time(int(_drill_runner.elapsed * 1000.0))
		else:
			player.touch_barred = _serving
			player.serve_charge_ui = _serving
			camera_rig.serve_view = _serving
			if input.serve_pressed and not _serving:
				_serving = true

				if Net.party:
					_take_party_ball(_my_party_id())
					player.ball = ball
					camera_rig.ball = ball
				ball.frozen = true
				ball.vel = Vector3.ZERO
			ball.serve_held = _serving
			if _serving:
				player.serve_charge_ui = true
				ball.global_position = player.serve_cradle_point()
				hud.set_serve_prompt(
					"hold lmb to charge the toss & release to throw")
				if input.contact_released:
					_serving = false
					player.serve_charge_ui = false
					ball.frozen = false
					ball.serve_assist = true
					ball.toss(player.serve_cradle_point(), 
						lerpf(6.5, 12.0, player.hold_power()))
					player.present_serve_toss()
			else:
				player.serve_charge_ui = false
				hud.set_serve_prompt("press r to take the ball in hand")

		_foley.tick([player] + _party_live_bodies(), delta, sfx, fx)

		var free_cam: = camera_rig.mode == CameraRig.Mode.ACTION\
		or camera_rig.mode == CameraRig.Mode.FIRST_PERSON


		aim_indicator.visible = not free_cam\
		and not (_tutorial != null and _tutorial.blocking_input())
		var maim_ib: = absf(input.aim.x) <= COURT_HW and absf(input.aim.z) <= COURT_HL
		aim_indicator.aim_at(input.aim, float(player.team_side), maim_ib)
		hud.set_crosshair_visible(free_cam)
		hud.set_crosshair_side(input.aim.z, maim_ib)
		hud.set_dive(player.dive_cooldown)
		hud.update_state(player)

		hud.refresh_controls(player, _serving)
		reach_marker.drive(player, ball, 
			GameConfig.reach_marker and not ball.frozen)
	else:
		player.touch_barred = true
		input.aim = _aim_at_cam
		player.aim_point = _aim_at_cam
	player.simulate(input, delta)

	if _freeplay and not _local_guests.is_empty():
		for g in _local_guests:
			var gp: Player = g["player"]
			if gp == null or not is_instance_valid(gp):
				continue
			var gin: PlayerInput = g["slot"].collector.collect(camera_rig, gp)
			gp.simulate(gin, delta)
	if _drill_active != "" and _drill_runner != null:
		_drill_runner.physics_tick(delta, 
			(_chat != null and _chat.is_typing())
			or (_tutorial != null and _tutorial.blocking_input()))
	player.global_position.x = clampf(player.global_position.x, 
		- HALL_X, HALL_X)
	player.global_position.z = clampf(player.global_position.z, 
		- HALL_Z, HALL_Z)



	if _freeplay and _drill_active == "":


		var driven: = _driven_balls() if Net.party else {0: ball}
		for bid in driven:
			var db: = driven[bid] as Ball
			var bp: = db.global_position
			if absf(bp.x) > HALL_X + 2.0 or absf(bp.z) > HALL_Z + 2.0\
			or bp.y < -2.0:
				db.toss(Vector3(0.0, 1.0, 1.5), 4.0)
		if Net.party and SHARED_BALLS and not _serving:
			_pick_freeplay_ball()



	if Net.party and Net.active:
		_fp_send_tick += 1


		var st: = player.net_capture()
		st.append(1.0 if _freeplay else 0.0)
		Net.send_freeplay_pose(st)
		if _fp_send_tick % 3 == 0:

			var driven: = _driven_balls()
			for bid in driven:
				Net.send_ball_pose((driven[bid] as Ball).net_capture(), int(bid))
