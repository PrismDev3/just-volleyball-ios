extends Control









const COURT_SCENE: = preload("res://game/court/court.tscn")


const BALL_SCENE: = preload("res://game/ball/ball.tscn")
const PLAYER_SCENE: = preload("res://game/player/player.tscn")
const BASE_HALF_W: = 4.5
const BASE_HALF_L: = 9.0
const SPEEDS: Array[float] = [0.25, 0.5, 1.0, 2.0]
const SPEED_NAMES: Array[String] = ["0.25x", "0.5x", "1x", "2x"]


enum Cam{DYNAMIC, BROADCAST, SPECTATE, FREE}
const CAM_NAMES: = ["dynamic", "broadcast", "spectate", "free"]
const FLY_SPEED: = 9.0
const FLY_FAST: = 22.0
const LOOK_SENS: = 0.0022
const KEY_LOOK_SPEED: = 1.7
const PITCH_LIMIT: = 1.45





const SCRUB_START: = 1.0
const SCRUB_TOP: = 12.0
const SCRUB_RAMP: = 3.5
const FRAME_STEP: = 1.0 / ReplayData.RATE







const HALL_X: = 20.6
const HALL_Z: = 26.6
const HALL_Y_MIN: = 0.8
const HALL_Y_MAX: = 13.0

var _scrub_held: = 0.0


const STEP_REPEAT_DELAY: = 0.35
const STEP_REPEAT_RATE: = 18.0
var _step_held: = 0.0
var _step_accum: = 0.0

var _director: = ReplayDirector.new()
var _data: ReplayData = null
var _bodies: Array = []
var _ball: Ball = null
var _court: Node3D = null
var _venue: Node3D = null



var _sand_deform: SandDeform = null
var _sand_deck: MeshInstance3D = null
var _prev_ball_frozen: = true


var _reflector: FloorReflector = null
var _speed_idx: = 2
var _scrubbing: = false
var _free_cam: = false
var _yaw: = 0.0
var _pitch: = -0.35
var _files: Array = []
var _cue_at: = 0
var _cam_mode: = Cam.DYNAMIC
var _follow: = -1
var _shot_idx: = -1
var _looking: = false
var _ui_hidden: = false


var _show_names: = false
var _show_messages: = true
var _half_w: = BASE_HALF_W
var _half_l: = BASE_HALF_L
var _original_stage: = "nationals"
var _original_barefoot: = false
var _original_reflections: = true
var _base_environment: Environment = null

@onready var _world: Node3D = $World
@onready var _cam: Camera3D = $World / Camera3D
@onready var _list: VBoxContainer = $Browser / Panel / Scroll / List
@onready var _browser: Control = $Browser
@onready var _transport: Control = $Transport
@onready var _transport_card: Panel = $Transport / Card
@onready var _replay_pill: Label = $Transport / ReplayPill
@onready var _scrub: HSlider = $Transport / Bar / Scrub
@onready var _time_label: Label = $Transport / Bar / TimeLabel
@onready var _play_btn: Button = $Transport / Bar / PlayBtn
@onready var _speed_btn: Button = $Transport / Bar / SpeedBtn
@onready var _bar: Control = $Transport / Bar
@onready var _hint: Label = $Transport / Hint
@onready var _title: Label = $Transport / Bar / Title



@onready var _controls: ViewControls = $Transport / Bar / Controls
@onready var _fx: Fx = $World / Fx
@onready var _sfx: Sfx = $World / Sfx
@onready var _crowd: CrowdAudio = $World / Crowd

func _ready() -> void :
	_original_stage = GameConfig.stage
	_original_barefoot = GameConfig.stage_barefoot
	_original_reflections = GameConfig.stage_reflections
	_base_environment = ($World / WorldEnvironment as WorldEnvironment).environment.duplicate()
	GameConfig.use_cursor(false)

	MusicManager.set_muffled(true)


	_crowd.set_active(false)
	Ink.apply($World / Camera3D)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_style_ui()
	_transport.visible = false
	$Browser / Panel / BackBtn.pressed.connect( func():
		UiWipe.wipe(get_tree(), func(): GameConfig.goto_scene("res://game/ui/menu.tscn")))
	_play_btn.pressed.connect(_toggle_play)
	_speed_btn.pressed.connect(_cycle_speed)
	_controls.ui_pressed.connect(_toggle_ui)
	_controls.cam_pressed.connect(_cycle_cam_mode)
	_controls.clean_pressed.connect( func():

		if _show_names and _show_messages:
			_show_names = false
		elif _show_messages:
			_show_messages = false
		else:
			_show_names = true
			_show_messages = true
		_apply_clean()
		_update_buttons())
	_controls.follow_pressed.connect(_cycle_follow)
	if OS.has_feature("web"):
		$Browser / Panel / FolderBtn.visible = false
	$Browser / Panel / FolderBtn.pressed.connect( func():
		DirAccess.make_dir_recursive_absolute(ReplayData.DIR)
		if not OS.has_feature("web"):
			# On web there is no folder to reveal: globalize_path yields a
			# filesystem path and shell_open would try to open a file:/// link
			# ("Security Error: ... may not load or link to file:///"),
			# so the button is hidden above instead.
			OS.shell_open(ProjectSettings.globalize_path(ReplayData.DIR)))
	$Transport / Bar / ExitBtn.pressed.connect(_close_replay)
	_scrub.drag_started.connect( func(): _scrubbing = true)
	_scrub.drag_ended.connect( func(_c: bool):
		_scrubbing = false
		_seek_replay(_director.start_time() + _scrub.value * _director.duration()))
	_scrub.value_changed.connect( func(v: float):
		if _scrubbing:
			_seek_replay(_director.start_time() + v * _director.duration()))
	_update_hint()
	_refresh_list()
	_dev_shot()




func _dev_shot() -> void :
	var args: = OS.get_cmdline_user_args()
	var at: = args.find("--replay-shot")
	if at == -1:
		return

	get_tree().create_timer(20.0).timeout.connect( func(): get_tree().quit())
	var name: = String(args[at + 1]) if at + 1 < args.size() else ""
	var path: = ReplayData.DIR + "/" + name
	await get_tree().create_timer(0.3).timeout
	_open(path)
	if _data == null:
		push_error("replay shot: could not open " + path)
		get_tree().quit(1)
		return
	var t: = _director.start_time() + minf(6.0, _director.duration() * 0.5)
	if not _moments.is_empty():
		t = maxf(float(_moments[0].t) - 2.0, _director.start_time())
	var ai: = args.find("--at")
	if ai != -1 and ai + 1 < args.size():
		t = _director.start_time() + float(args[ai + 1])
	if "--follow-you" in args:
		for si in _data.slots.size():
			if bool(_data.slots[si].get("is_you", false)):
				_follow = si
	_director.playing = false
	_update_buttons()
	_seek_replay(t)
	_sync_scrub()
	if _markers != null and not _moments.is_empty():
		_markers._hover = 0
		_markers.queue_redraw()
	await get_tree().create_timer(1.5).timeout
	get_viewport().get_texture().get_image()\
	.save_png("res://game/dev/shots/replay_%s.png" % name.get_basename())
	get_tree().quit()

func _style_ui() -> void :
	UiStyle.wash(self)
	($Browser / Dim as ColorRect).color = UiStyle.bg()
	UiStyle.style_panel($Browser / Card, UiStyle.card(), UiStyle.RADIUS_SOFT)
	UiStyle.style_panel($Transport / Card, Color(UiStyle.card(), 0.88), 
		UiStyle.RADIUS_SOFT)
	UiStyle.style_label($Browser / Panel / Title, "shout")
	UiStyle.style_label($Browser / Panel / Hint, "body", UiStyle.muted())
	UiStyle.style_label(_hint, "small", UiStyle.muted())
	UiStyle.style_label(_time_label, "body")
	if _score_label == null:
		_score_label = Label.new()
		_score_label.custom_minimum_size.x = 96.0
		_score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_bar.add_child(_score_label)
		_bar.move_child(_score_label, _time_label.get_index() + 1)


	UiStyle.style_pill(_score_label, Color(0.07, 0.09, 0.13, 0.85), Color.WHITE, 16)
	if _markers == null:
		_markers = Markers.new()
		_markers.viewer = self
		_scrub.add_child(_markers)
	UiStyle.style_button($Browser / Panel / FolderBtn, "secondary", 17)
	UiStyle.style_button($Browser / Panel / BackBtn, "tertiary", 17)
	UiStyle.style_button(_play_btn, "primary", 17)
	UiStyle.style_button(_speed_btn, "secondary", 17)
	UiStyle.style_button($Transport / Bar / ExitBtn, "tertiary", 17)
	UiStyle.style_pill($Transport / ReplayPill, UiStyle.HIGHLIGHT, Color.WHITE, 14)



	var scrub_track: = StyleBoxFlat.new()
	scrub_track.bg_color = Color("111622")
	scrub_track.set_corner_radius_all(99)
	scrub_track.content_margin_top = 3.0
	scrub_track.content_margin_bottom = 3.0
	_scrub.add_theme_stylebox_override("slider", scrub_track)

func _exit_tree() -> void :
	_restore_stage_globals()

func _restore_stage_globals() -> void :
	GameConfig.stage = _original_stage
	GameConfig.stage_barefoot = _original_barefoot
	GameConfig.stage_reflections = _original_reflections

func _refresh_list() -> void :
	for c in _list.get_children():
		c.queue_free()
	_files = _find_replays()
	if _files.is_empty():
		var empty: = Label.new()
		empty.text = "finish a match to save your first replay"
		empty.add_theme_font_size_override("font_size", 17)
		_list.add_child(empty)
		return
	for path in _files:
		var meta: = ReplayData.header_of(path)
		var row: = Button.new()
		row.custom_minimum_size = Vector2(560, 64)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var mins: = int(float(meta.get("duration", 0.0)) / 60.0)
		var secs: = int(float(meta.get("duration", 0.0))) % 60
		var home: = "?" if not meta.has("home_score")\
		else str(int(meta.home_score))
		var away: = "?" if not meta.has("away_score")\
		else str(int(meta.away_score))
		var stage_name: = Stage.title(String(meta.get("stage", "nationals")))\
		if meta.has("stage") else "stage unknown"
		var set_result: = ""
		if int(meta.get("sets_to_win", 1)) > 1 and meta.has("home_sets"):
			set_result = "   sets %d:%d" % [int(meta.home_sets), int(meta.away_sets)]



		var badge: = ""
		var compat: = int(meta.get("_compat", ReplayData.Compat.CURRENT))
		var fver: = int(meta.get("_format_version", ReplayData.VERSION))
		if compat == ReplayData.Compat.OUTDATED:
			badge = "   ! outdated version"
			row.tooltip_text = "version is outdated and may play incorrectly"
		elif compat == ReplayData.Compat.INCOMPATIBLE:
			badge = "   ! version mismatch"
			row.tooltip_text = "version mismatch, cannot play"
		row.text = "  home %s   away %s%s   %s   %d:%02d\n  %s%s" % [
			home, away, set_result, stage_name.to_lower(), mins, secs, 
			String(meta.get("title", path.get_file())), badge]
		UiStyle.style_button(row, "secondary", 18)
		row.pressed.connect(_open.bind(path))
		_list.add_child(row)

func _find_replays() -> Array:
	var out: Array = []
	var dir: = DirAccess.open(ReplayData.DIR)
	if dir == null:
		return out
	for f in dir.get_files():
		if f.ends_with(".vbr") and not f.begins_with("_"):
			out.append(ReplayData.DIR + "/" + f)
	out.sort()
	out.reverse()
	return out

func _open(path: String) -> void :
	_data = ReplayData.load_from(path)
	if _data == null:
		return


	if _data.compat == ReplayData.Compat.INCOMPATIBLE or _data.frame_count() == 0:
		_show_version_notice()
		_data = null
		return
	_build_world()
	_director.setup(_data, _bodies, _ball)
	_director.seek(_data.time_at(0))
	_director.playing = true
	_speed_idx = 2
	_director.speed = SPEEDS[_speed_idx]
	_browser.visible = false
	_transport.visible = true
	_title.text = String(_data.meta.get("title", path.get_file()))
	_free_cam = false
	_cam_mode = Cam.DYNAMIC
	_follow = -1
	_shot_idx = -1
	_cue_at = 0
	_build_markers()
	_update_buttons()

func _show_version_notice() -> void :


	var dlg: = AcceptDialog.new()
	dlg.title = "version mismatch"
	dlg.dialog_text = "version mismatch, cannot play"
	add_child(dlg)
	dlg.confirmed.connect(dlg.queue_free)
	dlg.canceled.connect(dlg.queue_free)
	dlg.popup_centered()

func _close_replay() -> void :
	_transport.visible = false
	_browser.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_free_cam = false
	_crowd.set_active(false)
	_tear_down()
	_restore_stage_globals()
	_refresh_list()

func _tear_down() -> void :
	for b in _bodies:
		if is_instance_valid(b):
			(b as Node).queue_free()
	_bodies.clear()
	if _ball != null and is_instance_valid(_ball):
		_ball.queue_free()
	_ball = null
	if _court != null and is_instance_valid(_court):
		_court.queue_free()
	_court = null
	if _venue != null and is_instance_valid(_venue):
		_venue.queue_free()
	_venue = null


	if _sand_deform != null and is_instance_valid(_sand_deform):
		_sand_deform.queue_free()
	_sand_deform = null
	if _sand_deck != null and is_instance_valid(_sand_deck):
		_sand_deck.queue_free()
	_sand_deck = null
	SandDeform.decal_y = 0.0
	SandDeform.decal_y_feet = 0.0


	if _reflector != null and is_instance_valid(_reflector):
		_reflector.queue_free()
	_reflector = null

func _build_world() -> void :
	_tear_down()
	var stage_id: = String(_data.meta.get("stage", "nationals"))
	if not Stage.STAGES.has(stage_id):
		stage_id = "nationals"
	var stage_info: = Stage.info(stage_id)



	GameConfig.stage = stage_id
	GameConfig.stage_barefoot = bool(stage_info.get("barefoot", false))
	GameConfig.stage_reflections = bool(stage_info.get("reflect", true))

	_crowd.set_active(Stage.has_crowd(stage_id))
	var half_w: = float(_data.meta.get("half_w", BASE_HALF_W))
	var half_l: = float(_data.meta.get("half_l", BASE_HALF_L))
	_half_w = half_w
	_half_l = half_l
	_court = COURT_SCENE.instantiate()
	_world.add_child(_court)

	_court.scale = Vector3(half_w / BASE_HALF_W, 1.0, half_l / BASE_HALF_L)
	var net: = _court.get_node_or_null("Net") as MeshInstance3D
	if net != null:
		CourtDress.unique_net(net, _court.scale.x)
	var floor_mat: = CourtDress.unique_floor(_court)



	Stage.apply_reverb(stage_id)
	if bool(Stage.val(stage_id, "owns_floor", false)):
		floor_mat.shader = load("res://game/court/floor_overlay.gdshader")
		var cf: = _court.get_node_or_null("CourtFloor") as MeshInstance3D
		if cf != null:
			cf.position.y += 0.06
	Stage.dress_court(_court, stage_id)
	floor_mat.set_shader_parameter("base_color", stage_info.floor_color)







	_reflector = FloorReflector.new()
	_world.add_child(_reflector)
	_reflector.setup(_cam)
	CourtDress.wire_reflection(floor_mat, _reflector.texture())
	_reflector.floor_mats = [floor_mat]
	_reflector.feet_provider = func(): return _bodies + [_ball]
	_venue = (load(String(stage_info.venue)) as PackedScene).instantiate()
	_world.add_child(_venue)





	_dress_hand_painted(stage_id)




	if Stage.has_crowd(stage_id):
		(preload("res://game/court/gym_crowd.gd") as GDScript).fill(
			_venue, int(_data.meta.get("match_seed", 0)), 
			Stage.val(stage_id, "seat_mats", []), Stage.val(stage_id, "crowd_spacing", 0.0), 
			int(Stage.val(stage_id, "crowd_max", 0)), Stage.val(stage_id, "crowd_fill", 0.0), 
			Stage.val(stage_id, "crowd_lift", 0.15), Stage.val(stage_id, "crowd_push", 0.0), 
			Stage.val(stage_id, "crowd_tint", Color(1, 1, 1)), 
			(Stage.val(stage_id, "haze_color", Color(0.83, 0.87, 0.93)) as Color).darkened(0.62), 
			float(Stage.val(stage_id, "crowd_haze", 
				float(Stage.val(stage_id, "haze_amt", 0.0)) * 2.7)), 
			Stage.val(stage_id, "crowd_shade", {}))



	var backdrop: Dictionary = Stage.val(stage_id, "backdrop", {})
	if not backdrop.is_empty():
		(preload("res://game/stage/stage_backdrop.gd") as GDScript).build(
			_venue, backdrop, half_w, half_l)


	if bool(Stage.val(stage_id, "force_wall", false)):
		var cbox: Vector3 = Stage.val(stage_id, "collision_box", Vector3.ZERO)
		if cbox != Vector3.ZERO:
			var fw: Node3D = (preload("res://game/court/force_dome.gd") as GDScript).new()
			_venue.add_child(fw)
			fw.build(cbox, Stage.val(stage_id, "force_wall_color", Color(0.28, 0.62, 1.0)))
	_ball = BALL_SCENE.instantiate()
	_ball.stage_ball = stage_id
	_world.add_child(_ball)
	_ball.net_puppet = true
	_ball.show_landing_ring = false
	for entry in _data.slots:
		var body: Player = PLAYER_SCENE.instantiate()
		_world.add_child(body)
		body.team_side = int(entry.get("side", 1))
		body.net_puppet = true
		body.is_bot = true






		body.ball = _ball
		body.charge_ui_enabled = false
		body.indicator_enabled = false
		var tint: String = String(entry.get("tint", ""))
		if tint != "":
			body.set_team_color(Color.html(tint))
		var cfg_d: Dictionary = entry.get("cfg", {})
		var kit: Array = (entry.get("kit", []) as Array).map(
			func(c): return Color.html(str(c)))
		var char_cfg: CharacterConfig = CharacterConfig.from_dict(cfg_d)\
		if not cfg_d.is_empty() else CharacterConfig.new()





		char_cfg.casual = bool(Stage.val(stage_id, "casual", false))



		var pinny: = String(entry.get("pinny", ""))
		if pinny == "" and char_cfg.casual\
		and bool(Stage.val(stage_id, "scrimmage_pinny", false))\
		and int(_data.meta.get("team_size", 2)) > 1:
			pinny = String(entry.get("tint", ""))
		if pinny != "":
			char_cfg.wear_pinny = true
			char_cfg.pinny_color = Color.html(pinny)
			char_cfg.pinny_accent = Color.html(String(entry.get("pinny_acc", "f5f5f2")))
		body.set_character(char_cfg, kit)
		body.set_display_name(String(entry.get("name", "player")))
		_bodies.append(body)
	_build_sand(stage_id)



	for piece in _venue.find_children("*", "Node3D", true, false):



		if piece.has_method("configure"):
			piece.call("configure", _half_w, _half_l)
		if piece.has_method("set_feeds"):
			piece.set_feeds( func(): return _bodies, func(): return _ball)


			if piece.has_method("indicator_clearance_y"):
				SandDeform.decal_y = piece.indicator_clearance_y()
				SandDeform.decal_y_feet = piece.indicator_feet_y()
	var world_env: = $World / WorldEnvironment as WorldEnvironment
	var env: = _base_environment.duplicate() as Environment




	if stage_info.has("sky"):
		env.background_mode = Environment.BG_COLOR
		env.background_color = stage_info.sky
	if bool(Stage.val(stage_id, "anime_sky", false)):
		env.background_mode = Environment.BG_SKY
		var sky: = Sky.new()
		var sky_mat: = ShaderMaterial.new()


		var custom_sky: Variant = Stage.val(stage_id, "sky_shader", null)
		sky_mat.shader = custom_sky if custom_sky is Shader\
		else preload("res://game/court/anime_sky.gdshader")
		sky.sky_material = sky_mat
		env.sky = sky


	env.glow_enabled = bool(Stage.val(stage_id, "bloom", false)) and GameConfig.bloom
	if env.glow_enabled:
		env.glow_intensity = 0.6
		env.glow_strength = 0.9
		env.glow_bloom = 0.0
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
		env.glow_hdr_threshold = 1.0



	env.fog_enabled = bool(Stage.val(stage_id, "fog", false))
	if env.fog_enabled:
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_light_color = Stage.val(stage_id, "fog_color", Color(0.02, 0.03, 0.05))
		env.fog_light_energy = 1.0
		env.fog_depth_begin = float(Stage.val(stage_id, "fog_begin", 20.0))
		env.fog_depth_end = float(Stage.val(stage_id, "fog_end", 65.0))
		env.fog_depth_curve = float(Stage.val(stage_id, "fog_curve", 1.0))
		env.fog_density = 1.0
		env.fog_sky_affect = float(Stage.val(stage_id, "fog_sky", 0.0))
		env.fog_aerial_perspective = 0.0
		env.fog_height = float(Stage.val(stage_id, "fog_height", 0.0))
		env.fog_height_density = - float(Stage.val(stage_id, "fog_height_density", 0.0))
	world_env.environment = env
	_apply_clean()

	_cam.global_position = Vector3(0.0, 6.0, half_l + 7.0)


	_yaw = 0.0
	_pitch = -0.42
	_aim_cam()







func _build_sand(stage_id: String) -> void :
	SandDeform.decal_y = 0.0
	SandDeform.decal_y_feet = 0.0
	var court_floor: = _court.get_node_or_null("CourtFloor") as MeshInstance3D
	if String(Stage.val(stage_id, "surface", "court")) != "sand":
		if court_floor != null:
			court_floor.visible = true
		return
	if court_floor != null:
		court_floor.visible = false


	var r: = SandDeform.build(_world, stage_id, _venue, _court, _half_w, _half_l, 
		func(): return _bodies, func(): return _ball)
	_sand_deform = r.get("deform")
	_sand_deck = r.get("deck")

	_prev_ball_frozen = _ball != null and _ball.frozen




func _dress_hand_painted(stage_id: String) -> void :
	if not bool(Stage.val(stage_id, "hand_painted", false)):
		return
	var gym: = _venue.get_node_or_null("Gym")
	if gym == null:
		return

	for node in gym.find_children("*", "MeshInstance3D", true, false):
		if String(node.name).to_lower().contains("cutter"):
			(node as Node3D).visible = false
	var painted: Dictionary = \
	(preload("res://game/court/env_paint.gd") as GDScript).apply(gym)


	var look: = Stage.config(stage_id)
	if look != null and look.has_method("apply"):
		look.apply(painted)


	var acc: = _resolve_accent(stage_id)
	Stage.apply_school_accent(painted, _court, stage_id, acc["accent"], 
		acc["tape"])


	(preload("res://game/court/gym_props.gd") as GDScript).dress(
		_venue, _court, acc["accent"])
	(preload("res://game/stage/stage_collision.gd") as GDScript).build(gym)
	for piece in _venue.get_children():
		if piece.has_method("configure"):
			piece.call("configure", _half_w, _half_l)





func _resolve_accent(stage_id: String) -> Dictionary:
	var seed: = int(_data.meta.get("match_seed", 0))
	if _data.meta.has("school_accent"):
		var has_tape: = bool(_data.meta.get("has_tape", false))
		return {
			"accent": _data.meta["school_accent"], 
			"tape": _data.meta["court_tape"] if has_tape else null, 
			"seed": seed, 
		}
	var accents: Array = Stage.val(stage_id, "accents", [])
	if accents.is_empty() or not _data.meta.has("match_seed"):
		return {"accent": Color(0.85, 0.85, 0.85), "tape": null, "seed": seed}
	var pick: = absi(hash("school_accent:%d" % seed))
	var tapes: Array = Stage.val(stage_id, "tape_by_accent", [])
	return {
		"accent": accents[pick % accents.size()], 
		"tape": tapes[pick % tapes.size()] if not tapes.is_empty() else null, 
		"seed": seed, 
	}

func _apply_clean() -> void :
	for b in _bodies:
		if is_instance_valid(b):


			(b as Player).suppress_names( not _show_names)
			(b as Player).set_labels_visible(_show_names)

func _sync_cues() -> void :


	_cue_at = 0
	var evs: Array = _data.events if _data != null else []
	while _cue_at < evs.size() and float(evs[_cue_at]["t"]) < _director.time:
		_cue_at += 1

func _seek_replay(t: float) -> void :
	_director.seek(t)




	if not _director.playing:
		for b in _bodies:
			(b as Player).set_anim_time_scale(0.0)



	_director.apply( not _director.playing)



	if not _free_cam and _ball != null:
		_drive_camera(0.0, true)
	_rebuild_scrub_vfx()
	_sync_cues()

func _rebuild_scrub_vfx() -> void :



	_fx.clear_transients()
	for body in _bodies:
		if is_instance_valid(body):
			(body as Player).hide_callout()
	var edge: = 0.55 / ReplayData.RATE
	for cue in (_data.events if _data != null else []):
		var cue_t: = float(cue.get("t", - INF))
		if cue_t > _director.time + edge:
			break
		if cue_t >= _director.time - edge and ReplayCues.is_visual(cue):
			ReplayCues.play(cue, null, _fx, null, _ball, _bodies, 
				_show_messages)

func _fire_cues() -> void :


	var evs: Array = _data.events if _data != null else []
	while _cue_at < evs.size() and float(evs[_cue_at]["t"]) <= _director.time:
		ReplayCues.play(evs[_cue_at], _sfx, _fx, _crowd, _ball, _bodies, 
			_show_messages)
		_cue_at += 1

func _cycle_cam_mode() -> void :
	_set_cam_mode(((_cam_mode + 1) % Cam.size()) as Cam)

func _set_cam_mode(m: Cam) -> void :
	_cam_mode = m
	var was_free: = _free_cam
	_free_cam = _cam_mode == Cam.FREE
	if _free_cam and not was_free:


		var e: = _cam.global_transform.basis.get_euler()
		_yaw = e.y
		_pitch = clampf(e.x, - PITCH_LIMIT, PITCH_LIMIT)
		_aim_cam()
	if not _free_cam:
		_looking = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_hint()
	_update_buttons()

func _toggle_ui() -> void :

	_ui_hidden = not _ui_hidden
	_bar.visible = not _ui_hidden


	_transport_card.visible = false
	_replay_pill.visible = not _ui_hidden
	_hint.visible = false
	_update_buttons()

func _update_hint() -> void :
	if _free_cam:
		_hint.text = "free cam   wasd to fly   q and e for height   hold right mouse to look   arrows to scrub"
	else:
		_hint.text = "c changes camera   f opens free cam   space pauses   arrows scrub   h hides the ui"

func _cycle_follow() -> void :
	_follow += 1
	if _follow >= _bodies.size():
		_follow = -1
	_update_buttons()

func _follow_point() -> Vector3:
	if _follow >= 0 and _follow < _bodies.size() and is_instance_valid(_bodies[_follow]):
		return (_bodies[_follow] as Player).global_position + Vector3(0, 1.0, 0)
	if _ball != null:
		return _ball.global_position
	return Vector3.ZERO

func _drive_camera(delta: float, force_snap: = false) -> void :

	var focus: = _follow_point()
	match _cam_mode:
		Cam.BROADCAST:
			var want: = Vector3(_half_w + 13.0, 9.0, focus.z * 0.3)
			_cam.global_position = _in_hall(want if force_snap else
				_cam.global_position.lerp(want, 1.0 - exp(-3.0 * delta)))
			_look_at_safe(Vector3(0.0, 1.2, 0.0).lerp(focus, 0.4))
		Cam.SPECTATE:

			var side: float = signf(focus.z)
			if side == 0.0:
				side = 1.0
			var want2: = focus + Vector3(1.4, 1.9, side * 4.0)
			_cam.global_position = _in_hall(want2 if force_snap else
				_cam.global_position.lerp(want2, 1.0 - exp(-6.0 * delta)))
			_look_at_safe(focus)
		Cam.DYNAMIC:

			var elapsed: = _director.time - _director.start_time()
			var shot: = int(elapsed / 3.0) % 4
			var s2: float = signf(focus.z)
			if s2 == 0.0:
				s2 = 1.0
			var eye: = Vector3.ZERO
			match shot:
				0: eye = Vector3(_half_w + 3.2, 1.3, focus.z + s2 * 1.5)
				1: eye = focus + Vector3(-1.8, 2.0, s2 * 3.6)
				2: eye = Vector3( - _half_w - 3.0, 1.0, focus.z - s2 * 1.2)
				_: eye = Vector3(2.2, 5.2, s2 * (_half_l + 3.0))
			var snap: = force_snap or shot != _shot_idx
			_shot_idx = shot
			_cam.global_position = _in_hall(eye if snap else
				_cam.global_position.lerp(eye, 1.0 - exp(-7.0 * delta)))
			_look_at_safe(focus)

func _aim_cam() -> void :
	_cam.global_transform.basis = Basis.from_euler(Vector3(_pitch, _yaw, 0.0))





func _look_at_safe(target: Vector3) -> void :
	var to: = target - _cam.global_position
	if to.length_squared() < 0.04:
		return

	if absf(to.normalized().dot(Vector3.UP)) > 0.999:
		return
	_cam.look_at(target)




func _in_hall(pos: Vector3) -> Vector3:
	return Vector3(
		clampf(pos.x, - HALL_X, HALL_X), 
		clampf(pos.y, HALL_Y_MIN, HALL_Y_MAX), 
		clampf(pos.z, - HALL_Z, HALL_Z))


func _step_frames(n: int) -> void :
	if _data == null:
		return
	_director.playing = false
	_update_buttons()
	_director.seek(clampf(_director.time + float(n) * FRAME_STEP, 
		_director.start_time(), _director.end_time()))
	_sync_scrub()


func _step_tick(delta: float) -> void :
	if _data == null:
		return
	var dir: = 0
	if Input.is_key_pressed(KEY_COMMA):
		dir = -1
	elif Input.is_key_pressed(KEY_PERIOD):
		dir = 1
	if dir == 0:
		_step_held = 0.0
		_step_accum = 0.0
		return
	_step_held += delta
	if _step_held < STEP_REPEAT_DELAY:
		return
	_step_accum += delta * STEP_REPEAT_RATE
	while _step_accum >= 1.0:
		_step_accum -= 1.0
		_step_frames(dir)


func _scrub_tick(delta: float) -> void :
	if _data == null or _scrubbing:
		return
	var dir: = Input.get_axis("ui_left", "ui_right")
	if absf(dir) < 0.5:
		_scrub_held = 0.0
		return
	_scrub_held += delta
	var rate: = lerpf(SCRUB_START, SCRUB_TOP, 
		clampf(_scrub_held / SCRUB_RAMP, 0.0, 1.0))
	_director.playing = false
	_update_buttons()
	_director.seek(clampf(_director.time + dir * rate * delta, 
		_director.start_time(), _director.end_time()))
	_sync_scrub()






const MARKER_PREROLL: = 5.0

var _score_label: Label = null
var _markers: Markers = null
var _moments: Array = []

func _build_markers() -> void :
	_moments.clear()
	if _data != null:
		for cue in _data.events:
			if String(cue.get("k", "")) == "point":
				var d: Dictionary = cue.get("d", {})
				_moments.append({"t": float(cue.get("t", 0.0)), 
					"w": int(d.get("w", 1)), "h": int(d.get("h", 0)), 
					"a": int(d.get("a", 0)), "set": int(d.get("set", 1))})
	if _markers != null:
		_markers.queue_redraw()


func _score_at(t: float) -> Dictionary:
	var out: = {"h": 0, "a": 0, "set": 1}
	for m in _moments:
		if float(m.t) <= t:
			out = {"h": int(m.h), "a": int(m.a), "set": int(m.set)}
		else:
			break
	return out

func _update_score_readout() -> void :
	if _score_label == null:
		return
	if _moments.is_empty():
		_score_label.visible = false
		return
	_score_label.visible = true
	var s: = _score_at(_director.time)
	_score_label.text = "%d - %d" % [int(s.h), int(s.a)]

func _jump_to_moment(m: Dictionary) -> void :
	_seek_replay(maxf(float(m.t) - MARKER_PREROLL, _director.start_time()))
	_sync_scrub()

class Markers extends Control:
	var viewer: Node = null
	var _hover: = -1
	func _init() -> void :
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_PASS
	func _x_of(t: float) -> float:
		var start: float = viewer._director.start_time()
		var span: float = maxf(viewer._director.duration(), 0.001)
		return clampf((t - start) / span, 0.0, 1.0) * size.x
	func _near(pos: Vector2) -> int:
		var best: = -1
		var best_d: = 10.0
		for i in viewer._moments.size():
			var d: = absf(pos.x - _x_of(float(viewer._moments[i].t)))
			if d < best_d:
				best_d = d
				best = i
		return best
	func _gui_input(event: InputEvent) -> void :
		if viewer == null or viewer._data == null:
			return
		if event is InputEventMouseMotion:
			var h: = _near(event.position)
			if h != _hover:
				_hover = h
				queue_redraw()
		elif event is InputEventMouseButton and event.pressed\
		and event.button_index == MOUSE_BUTTON_LEFT:
			var h: = _near(event.position)
			if h >= 0:
				viewer._jump_to_moment(viewer._moments[h])
				accept_event()
	func _notification(what: int) -> void :
		if what == NOTIFICATION_MOUSE_EXIT and _hover != -1:
			_hover = -1
			queue_redraw()
	func _draw() -> void :
		if viewer == null:
			return
		var cy: = size.y * 0.5



		for i in viewer._moments.size():
			var m: Dictionary = viewer._moments[i]
			var x: = _x_of(float(m.t))
			var hovered: bool = i == _hover
			var col: Color = Rules.side_color(int(m.w))
			if not hovered:
				col = col.lerp(Color("111622"), 0.28)
			var r: = 5.5 if hovered else 3.6

			draw_circle(Vector2(x, cy), r + 1.4, Color(0.03, 0.05, 0.09, 0.7))
			draw_circle(Vector2(x, cy), r, col)
			if hovered:
				draw_arc(Vector2(x, cy), r + 2.2, 0.0, TAU, 20, Color(1, 1, 1, 0.9), 1.5, true)
		if _hover >= 0 and _hover < viewer._moments.size():
			var m: Dictionary = viewer._moments[_hover]
			var x: = _x_of(float(m.t))
			var text: = "%d - %d" % [int(m.h), int(m.a)]
			var font: = UiStyle.font(UiStyle.FONT_XBOLD)
			var fs: = 13
			var tw: = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
			var tx: = clampf(x - tw * 0.5, 2.0, maxf(size.x - tw - 2.0, 2.0))
			var box: = Rect2(tx - 8.0, cy - 32.0, tw + 16.0, 21.0)

			draw_style_box(UiStyle.card_box(Color(0.07, 0.09, 0.13, 0.94), 8), box)
			draw_string(font, Vector2(tx, cy - 17.5), text, 
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)

func _sync_scrub() -> void :
	var span: = _director.duration()
	if span > 0.0:
		_scrub.set_value_no_signal(
			(_director.time - _director.start_time()) / span)
	_seek_replay(_director.time)

func _toggle_play() -> void :
	_director.playing = not _director.playing
	_update_buttons()

func _cycle_speed() -> void :
	_speed_idx = (_speed_idx + 1) % SPEEDS.size()
	_director.speed = SPEEDS[_speed_idx]
	_update_buttons()

func _update_buttons() -> void :
	_play_btn.text = "pause" if _director.playing else "play"
	_speed_btn.text = SPEED_NAMES[_speed_idx]
	var clean: = "off"
	if not _show_names and not _show_messages:
		clean = "on"
	elif not _show_names:
		clean = "no names"
	var follow: = "ball"
	if _follow >= 0 and _follow < _bodies.size():
		follow = String(_data.slots[_follow].get("name", "player")) if _data != null else "player"
	_controls.set_labels(CAM_NAMES[_cam_mode], follow, clean, _ui_hidden)

func _unhandled_input(event: InputEvent) -> void :
	if not _transport.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if _ui_hidden:
			_toggle_ui()
		elif _free_cam:
			_set_cam_mode(Cam.DYNAMIC)
		else:
			_close_replay()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_H:
				_toggle_ui()
				return
			KEY_F:
				_set_cam_mode(Cam.DYNAMIC if _free_cam else Cam.FREE)
				return
			KEY_C:
				_cycle_cam_mode()
				return
			KEY_SPACE:
				_toggle_play()
				return
			KEY_COMMA, KEY_PERIOD:


				_step_frames(-1 if (event as InputEventKey).keycode == KEY_COMMA
					else 1)
				_step_held = 0.0
				_step_accum = 0.0
				return




	if not _free_cam:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
		_looking = (event as InputEventMouseButton).pressed
	elif _looking and event is InputEventMouseMotion:
		var rel: = (event as InputEventMouseMotion).relative
		_yaw -= rel.x * LOOK_SENS
		_pitch = clampf(_pitch - rel.y * LOOK_SENS, - PITCH_LIMIT, PITCH_LIMIT)
		_aim_cam()

func _process(delta: float) -> void :
	if not _transport.visible or _data == null:
		return
	_scrub_tick(delta)
	_step_tick(delta)
	if _free_cam:
		var dir: = Vector3.ZERO
		var basis: = _cam.global_transform.basis
		dir -= basis.z * Input.get_axis("move_back", "move_forward")
		dir += basis.x * Input.get_axis("move_left", "move_right")



		if Input.is_key_pressed(KEY_E):
			dir.y += 1.0
		if Input.is_key_pressed(KEY_Q):
			dir.y -= 1.0
		if dir.length() > 0.01:
			var fast: = Input.is_key_pressed(KEY_SHIFT)
			_cam.global_position += dir.normalized()\
			* (FLY_FAST if fast else FLY_SPEED) * delta
	if not _scrubbing:
		_director.advance(delta)
		if _director.finished():
			_director.playing = false
			_update_buttons()



	var anim_scale: = _director.speed if _director.playing else 0.0
	for b in _bodies:
		if is_instance_valid(b):
			(b as Player).set_anim_time_scale(anim_scale)
	_director.apply( not _director.playing)





	if _sand_deform != null and _ball != null:
		var f: = _ball.frozen
		if f and not _prev_ball_frozen:
			_sand_deform.reset()
		_prev_ball_frozen = f
	_fire_cues()



	if _ball != null:
		_ball.set_replay_time_scale(anim_scale)
	_director.pose_tick(delta * (_director.speed if _director.playing else 0.0))
	if _free_cam:
		_aim_cam()
	else:
		_drive_camera(delta)
	var span: = maxf(_director.duration(), 0.001)
	if not _scrubbing:
		_scrub.set_value_no_signal(
			(_director.time - _director.start_time()) / span)
	var now: = _director.time - _director.start_time()
	_time_label.text = "%d:%02d / %d:%02d" % [
		int(now / 60.0), int(now) % 60, 
		int(span / 60.0), int(span) % 60]
	_update_score_readout()
