extends Node






var _settings_path: = "user://settings.json"



signal settings_saved

var master_volume: = 1.0
var sfx_volume: = 1.0
var crowd_volume: = 1.0
var music_volume: = 0.2
var ambient_volume: = 0.7

var character: CharacterConfig = null

func _ready() -> void :



	AppData.init_appdata()
	_settings_path = AppData.migrate("user://settings.json", "settings.json")
	_ensure_bus("sfx")



	_ensure_bus("feedback")
	_ensure_bus("crowd")


	_ensure_bus("music")
	_ensure_bus("ambient")
	_ensure_voice_bus()
	_ensure_announcer_bus()
	_load_settings()
	_apply_volumes()


	apply_display.call_deferred()
	apply_render_scale.call_deferred()
	apply_msaa.call_deferred()
	_hook_window_resize.call_deferred()
	character = CharacterConfig.load_local()





func _hook_window_resize() -> void :
	var tree: = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	if not tree.root.size_changed.is_connected(_on_window_size_changed):
		tree.root.size_changed.connect(_on_window_size_changed)





var _last_applied_size: = Vector2i.ZERO
var _resize_save_pending: = false

func _on_window_size_changed() -> void :


	if window_mode != WindowMode.WINDOWED:
		return
	var now: = DisplayServer.window_get_size()
	if now == _last_applied_size:
		return
	if now.x <= 0 or now.y <= 0:
		return
	window_size = now
	window_user_sized = true

	if _resize_save_pending:
		return
	_resize_save_pending = true
	var tree: = Engine.get_main_loop() as SceneTree
	if tree == null:
		_resize_save_pending = false
		_save_settings()
		return
	tree.create_timer(0.4, true, false, true).timeout.connect( func():
		_resize_save_pending = false
		_save_settings())

var match_seed: = 0


func new_match_seed() -> void :
	match_seed = randi()

func bot_character(side: int, slot: int, salt: = 0) -> CharacterConfig:





	var rng: = RandomNumberGenerator.new()
	rng.seed = hash("cpu:%d:%d:%d:%d" % [side, slot, match_seed, salt])
	return CharacterConfig.random(rng)

func team_gear(is_home: bool) -> Dictionary:



	var cfg: = character if character != null else CharacterConfig.new()
	if is_home:
		return {"socks": cfg.socks, "kneepad": cfg.kneepad}



	var rng: = RandomNumberGenerator.new()
	rng.seed = hash("gear:%d" % match_seed)
	var gear: = Color.from_hsv(rng.randf(), rng.randf_range(0.4, 0.7), 
		rng.randf_range(0.4, 0.6))
	return {"socks": gear, "kneepad": gear}

func dress_in_team_gear(cfg: CharacterConfig, is_home: bool) -> CharacterConfig:

	var gear: = team_gear(is_home)
	cfg.socks = gear["socks"]
	cfg.kneepad = gear["kneepad"]
	return cfg

func team_kit(is_home: bool) -> Array:


	var cfg: = character if character != null else CharacterConfig.new()
	return cfg.kit_home if is_home else cfg.kit_away




func opponent_kit() -> Array:
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash("oppkit:%d" % match_seed)
	var cfg: = character if character != null else CharacterConfig.new()
	var home_hue: float = (cfg.kit_home[0] as Color).h
	var hue: = fposmod(home_hue + rng.randf_range(0.28, 0.72), 1.0)
	var jersey: = Color.from_hsv(hue, rng.randf_range(0.6, 0.85), 
		rng.randf_range(0.72, 0.95))


	var shorts: = Color.from_hsv(hue, rng.randf_range(0.35, 0.6), 
		rng.randf_range(0.32, 0.5))
	return [jersey, shorts, Color.WHITE]

func _ensure_voice_bus() -> void :



	_ensure_bus("voice")
	var idx: = AudioServer.get_bus_index("voice")
	if idx == -1 or AudioServer.get_bus_effect_count(idx) > 0:
		return
	var comp: = AudioEffectCompressor.new()
	comp.threshold = -22.0
	comp.ratio = 8.0
	comp.attack_us = 20.0
	comp.release_ms = 90.0
	comp.gain = 7.0
	AudioServer.add_bus_effect(idx, comp)
	var drive: = AudioEffectDistortion.new()
	drive.mode = AudioEffectDistortion.MODE_CLIP
	drive.drive = 0.22
	drive.pre_gain = 2.0
	drive.post_gain = -4.0
	AudioServer.add_bus_effect(idx, drive)

func _ensure_announcer_bus() -> void :




	_ensure_bus("announcer")
	var idx: = AudioServer.get_bus_index("announcer")
	if idx == -1 or AudioServer.get_bus_effect_count(idx) > 0:
		return
	var comp: = AudioEffectCompressor.new()
	comp.threshold = -18.0
	comp.ratio = 4.0
	comp.attack_us = 15.0
	comp.release_ms = 120.0
	comp.gain = 4.0
	AudioServer.add_bus_effect(idx, comp)

func _ensure_bus(bus_name: String) -> void :
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var idx: = AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")

func set_volume(which: String, value: float) -> void :
	match which:
		"master":
			master_volume = value
		"sfx":
			sfx_volume = value
		"crowd":
			crowd_volume = value
		"music":
			music_volume = value
		"ambient":
			ambient_volume = value
	_apply_volumes()
	_save_settings()

func get_volume(which: String) -> float:
	match which:
		"master":
			return master_volume
		"sfx":
			return sfx_volume
		"music":
			return music_volume
		"ambient":
			return ambient_volume
	return crowd_volume

func _apply_volumes() -> void :
	_set_bus("Master", master_volume)
	_set_bus("sfx", sfx_volume)
	_set_bus("feedback", sfx_volume)
	_set_bus("crowd", crowd_volume)
	_set_bus("music", music_volume)
	_set_bus("ambient", ambient_volume)

func _set_bus(bus_name: String, value: float) -> void :
	var idx: = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, value <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.001)))









const CURSOR_POINT: = "res://game/kny/cursorpack/PNG/Outline/Default/hand_point.png"
const CURSOR_GRAB: = "res://game/kny/cursorpack/PNG/Outline/Default/hand_closed.png"
const CURSOR_AIM: = "res://game/kny/cursorpack/PNG/Outline/Default/line_cross.png"
const CURSOR_SIZE: = 40


const HAND_TIP: = Vector2(0.3, 0.06)

var _cursor_cache: = {}
var _cursor_aiming: = -1
var _cursor_pressed: = false
var _cursor_path: = ""

func _input(event: InputEvent) -> void :

	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var down: = (event as InputEventMouseButton).pressed
		if down != _cursor_pressed:
			_cursor_pressed = down
			if _cursor_aiming == 0:
				_apply_cursor(false)

func use_cursor(aiming: bool) -> void :
	var want: = 1 if aiming else 0
	if _cursor_aiming == want:
		return
	_cursor_aiming = want
	_apply_cursor(aiming)

func _apply_cursor(aiming: bool) -> void :
	var path: = CURSOR_AIM if aiming else (CURSOR_GRAB if _cursor_pressed else CURSOR_POINT)
	if path == _cursor_path:
		return
	_cursor_path = path
	var tex: Texture2D = _cursor_cache.get(path)
	if tex == null:
		var src: Texture2D = load(path)
		if src == null:
			return
		var img: = src.get_image()
		img.resize(CURSOR_SIZE, CURSOR_SIZE, Image.INTERPOLATE_NEAREST)
		tex = ImageTexture.create_from_image(img)
		_cursor_cache[path] = tex

	var hotspot: = HAND_TIP * CURSOR_SIZE
	if aiming:
		hotspot = Vector2(CURSOR_SIZE * 0.5, CURSOR_SIZE * 0.5)
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, hotspot)



func cursor_texture() -> Texture2D:
	if _cursor_aiming == 1:
		return null
	return _cursor_cache.get(_cursor_path)

func cursor_hotspot() -> Vector2:
	return HAND_TIP * CURSOR_SIZE



func aim_cursor_texture() -> Texture2D:
	var tex: Texture2D = _cursor_cache.get(CURSOR_AIM)
	if tex == null:
		var src: Texture2D = load(CURSOR_AIM)
		if src == null:
			return null
		var img: = src.get_image()
		img.resize(CURSOR_SIZE, CURSOR_SIZE, Image.INTERPOLATE_NEAREST)
		tex = ImageTexture.create_from_image(img)
		_cursor_cache[CURSOR_AIM] = tex
	return tex


















enum ArtStyle{CEL_CLASSIC, CEL_INK, WII}
var art_style: = ArtStyle.CEL_CLASSIC



var default_camera: = 1



var ranked_match: = false


var quick_match: = false


var quick_backfill_side: = 0


var migrate_carry: = {}
const ART_STYLE_NAMES: = [
	"classic (cel bands + ink outline)", 
	"screen ink (cel bands + post-process outline)", 
	"wii (no outline, gloss + rim light)", 
]

func style_is(kind: int) -> bool:
	return art_style == kind










var _scene_pending: = ""







var _ts_token: = 0

func slow_time(rate: float, duration: float) -> void :
	Engine.time_scale = rate
	_ts_token += 1
	var tok: = _ts_token
	var tree: = Engine.get_main_loop() as SceneTree
	if tree == null:
		Engine.time_scale = 1.0
		return
	tree.create_timer(duration, true, false, true).timeout.connect( func():
		if _ts_token == tok:
			Engine.time_scale = 1.0)

func goto_scene(path: String) -> void :
	if _scene_pending != "":
		return
	var tree: = Engine.get_main_loop() as SceneTree
	if tree == null:
		return

	Engine.time_scale = 1.0


	SandDeform.decal_y = 0.0
	SandDeform.decal_y_feet = 0.0
	_scene_pending = path



	_do_scene_change.call_deferred(path)

func _do_scene_change(path: String) -> void :
	var tree: = Engine.get_main_loop() as SceneTree
	if tree != null:
		var pre: PackedScene = null
		if _preloaded.has(path):
			pre = _preloaded[path] as PackedScene
			_preloaded.erase(path)
		elif path in _preload_queue:
			# Still loading: block on the running request instead of starting a
			# second load of the same path (same cost as a plain sync load).
			pre = ResourceLoader.load_threaded_get(path) as PackedScene
		_preload_queue.erase(path)
		if pre != null:
			tree.change_scene_to_packed(pre)
		else:
			tree.change_scene_to_file(path)
	_scene_pending = ""

# Scene preloading: kick off loading the next scene while the current screen
# is still interactive (the title waits for input for seconds), so the wipe
# that hides the swap also hides almost none of the load. Loaded resources
# are held here — the resource cache only keeps weak references — which keeps
# the whole dependency tree warm for the swap.
var _preload_queue: Array[String] = []
var _preloaded: Dictionary = {}

func preload_scene(path: String) -> void :
	if path == "" or _preloaded.has(path) or path in _preload_queue:
		return
	if not ResourceLoader.exists(path):
		return
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
		return
	_preload_queue.append(path)
	ResourceLoader.load_threaded_request(path)

func preload_venue(stage_id: String) -> void :
	# The one big dynamic load() in both menu._build_arena and main's arena
	# builder; warming it makes the venue instantiate from memory.
	if Stage.STAGES.has(stage_id):
		preload_scene(String(Stage.info(stage_id).venue))

func _process(_delta: float) -> void :
	# Drains finished preloads (on single-threaded builds polling is also what
	# advances the load). Held in _preloaded until _do_scene_change uses it.
	if _preload_queue.is_empty():
		return
	for i in range(_preload_queue.size() - 1, - 1, - 1):
		var p: String = _preload_queue[i]
		var st: = ResourceLoader.load_threaded_get_status(p)
		if st == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		_preload_queue.remove_at(i)
		if st == ResourceLoader.THREAD_LOAD_LOADED:
			_preloaded[p] = ResourceLoader.load_threaded_get(p)

func save_settings() -> void :
	_save_settings()



func has_accepted_online_terms() -> bool:
	return online_terms_accepted and online_terms_version >= ONLINE_TERMS_VERSION

func accept_online_terms() -> void :
	online_terms_accepted = true
	online_terms_version = ONLINE_TERMS_VERSION
	_save_settings()




func flush_saves() -> void :
	_save_settings()
	if has_node("/root/ProfileStore"):
		get_node("/root/ProfileStore").capture_character()
	if has_node("/root/Career"):
		get_node("/root/Career").save_now()

func _notification(what: int) -> void :
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		flush_saves()





func _save_settings() -> void :
	var data: = {
		"audio": {
			"master": master_volume, "sfx": sfx_volume, "crowd": crowd_volume, 
			"music": music_volume, "ambient": ambient_volume, 
		}, 
		"game": {
			"crowd_enabled": crowd_enabled, "voice_enabled": voice_enabled, 
			"dark_theme": dark_theme, "tutorial_seen": tutorial_seen, 
			"online_terms_accepted": online_terms_accepted, 
			"online_terms_version": online_terms_version, 
			"aim_assist": aim_assist, "hardware_cursor": hardware_cursor, 
			"touch_controls": touch_controls, 
			"show_own_name": show_own_name, "touch_highlight": touch_highlight, 
			"camera_shake": camera_shake, "rumble": rumble, 
			"aim_color_cue": aim_color_cue, 
			"mouse_sensitivity": mouse_sensitivity, 
			"stick_sensitivity": stick_sensitivity, "stage": stage, 
			"chat_enabled": chat_enabled, "chat_w": chat_w, "chat_h": chat_h, 
			"chat_filter": chat_filter, "chat_bubbles": chat_bubbles, 
			"chat_collapsed": chat_collapsed, "reach_marker": reach_marker, 
			"replay_capture": replay_capture, "art_style": int(art_style), 
			"default_camera": default_camera, "difficulty": difficulty, 
			"menu_outfit": menu_outfit, "menu_ball": menu_ball, 
			"freeplay_stage": freeplay_stage, 
		}, 
		"video": {
			"window_mode": int(window_mode), "vsync": vsync, 
			"max_fps": max_fps, "show_fps": show_fps, "render_scale": render_scale, 
			"reflections": reflections, "reflection_half": reflection_half, 
			"bloom": bloom, "grass": grass, 
			"window_w": window_size.x, "window_h": window_size.y, "msaa": msaa, 
			"window_user_sized": window_user_sized, 
			"gpu_notice_dismissed": gpu_notice_dismissed, 
		}, 
		"debug": {
			"menu": debug_menu, 


			"net_log": debug_net_log, "predict_contacts": predict_contacts, 
		}, 
	}
	var f: = FileAccess.open(_settings_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()
	settings_saved.emit()

func _load_settings() -> void :
	if not FileAccess.file_exists(_settings_path):
		_migrate_settings_cfg()
		return
	var f: = FileAccess.open(_settings_path, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	var audio: Dictionary = data.get("audio", {})
	var game: Dictionary = data.get("game", {})
	var video: Dictionary = data.get("video", {})
	var dbg: Dictionary = data.get("debug", {})
	master_volume = float(audio.get("master", 1.0))
	sfx_volume = float(audio.get("sfx", 1.0))
	crowd_volume = float(audio.get("crowd", 1.0))
	music_volume = float(audio.get("music", 0.2))
	ambient_volume = float(audio.get("ambient", 0.7))
	crowd_enabled = bool(game.get("crowd_enabled", true))
	voice_enabled = bool(game.get("voice_enabled", true))
	dark_theme = bool(game.get("dark_theme", false))
	UiStyle.dark = dark_theme
	tutorial_seen = bool(game.get("tutorial_seen", false))


	if AppData.did_wipe:
		tutorial_seen = false
	online_terms_accepted = bool(game.get("online_terms_accepted", false))
	online_terms_version = int(game.get("online_terms_version", 0))
	aim_assist = bool(game.get("aim_assist", false))
	hardware_cursor = bool(game.get("hardware_cursor", false))
	touch_controls = clampi(int(game.get("touch_controls", 0)), 0, 2)
	show_own_name = bool(game.get("show_own_name", false))
	touch_highlight = bool(game.get("touch_highlight", true))
	camera_shake = bool(game.get("camera_shake", true))
	rumble = bool(game.get("rumble", true))
	aim_color_cue = bool(game.get("aim_color_cue", true))
	mouse_sensitivity = clampf(float(game.get("mouse_sensitivity", 1.0)), 0.25, 3.0)
	stick_sensitivity = clampf(float(game.get("stick_sensitivity", 1.0)), 0.25, 3.0)
	stage = String(game.get("stage", "nationals"))
	chat_enabled = bool(game.get("chat_enabled", true))
	chat_filter = bool(game.get("chat_filter", true))
	chat_bubbles = bool(game.get("chat_bubbles", true))
	chat_w = float(game.get("chat_w", 300.0))
	chat_h = float(game.get("chat_h", 160.0))
	chat_collapsed = bool(game.get("chat_collapsed", false))
	reach_marker = bool(game.get("reach_marker", true))
	replay_capture = bool(game.get("replay_capture", true))
	art_style = int(game.get("art_style", ArtStyle.CEL_CLASSIC))


	default_camera = clampi(int(game.get("default_camera", 1)), 0, 3)
	difficulty = int(game.get("difficulty", 1))
	menu_outfit = String(game.get("menu_outfit", "gym"))
	menu_ball = String(game.get("menu_ball", "nationals"))
	freeplay_stage = String(game.get("freeplay_stage", "nationals"))
	window_mode = int(video.get("window_mode", WindowMode.WINDOWED)) as WindowMode
	vsync = bool(video.get("vsync", true))
	max_fps = int(video.get("max_fps", 60))
	show_fps = bool(video.get("show_fps", false))
	render_scale = float(video.get("render_scale", 1.0))
	reflections = bool(video.get("reflections", true))
	reflection_half = bool(video.get("reflection_half", true))
	bloom = bool(video.get("bloom", true))
	grass = bool(video.get("grass", true))
	window_size = Vector2i(int(video.get("window_w", WINDOWED_SIZE.x)), 
		int(video.get("window_h", WINDOWED_SIZE.y)))
	window_user_sized = bool(video.get("window_user_sized", false))
	gpu_notice_dismissed = bool(video.get("gpu_notice_dismissed", false))
	msaa = int(video.get("msaa", 0))
	debug_menu = bool(dbg.get("menu", false))
	show_cam_debug = false
	debug_net_log = bool(dbg.get("net_log", false))
	predict_contacts = bool(dbg.get("predict_contacts", true))



	if LaunchGate.public_beta():
		debug_menu = false
		show_cam_debug = false
		debug_net_log = false



func _migrate_settings_cfg() -> void :
	var cfg: = ConfigFile.new()
	if cfg.load("user://settings.cfg") != OK:
		return
	master_volume = cfg.get_value("audio", "master", 1.0)
	sfx_volume = cfg.get_value("audio", "sfx", 1.0)
	crowd_volume = cfg.get_value("audio", "crowd", 1.0)
	music_volume = cfg.get_value("audio", "music", 0.2)
	ambient_volume = cfg.get_value("audio", "ambient", 0.7)
	crowd_enabled = cfg.get_value("game", "crowd_enabled", true)
	voice_enabled = cfg.get_value("game", "voice_enabled", true)
	tutorial_seen = bool(cfg.get_value("game", "tutorial_seen", false))
	aim_assist = cfg.get_value("game", "aim_assist", false)
	hardware_cursor = cfg.get_value("game", "hardware_cursor", false)
	touch_controls = clampi(int(cfg.get_value("game", "touch_controls", 0)), 0, 2)
	show_own_name = cfg.get_value("game", "show_own_name", false)
	touch_highlight = cfg.get_value("game", "touch_highlight", true)
	camera_shake = cfg.get_value("game", "camera_shake", true)
	aim_color_cue = bool(cfg.get_value("game", "aim_color_cue", true))
	stage = cfg.get_value("game", "stage", "nationals")
	chat_enabled = bool(cfg.get_value("game", "chat_enabled", true))
	chat_filter = bool(cfg.get_value("game", "chat_filter", true))
	chat_bubbles = bool(cfg.get_value("game", "chat_bubbles", true))
	chat_w = float(cfg.get_value("game", "chat_w", 300.0))
	chat_h = float(cfg.get_value("game", "chat_h", 160.0))
	chat_collapsed = bool(cfg.get_value("game", "chat_collapsed", false))
	reach_marker = cfg.get_value("game", "reach_marker", true)
	replay_capture = cfg.get_value("game", "replay_capture", true)
	art_style = cfg.get_value("game", "art_style", ArtStyle.CEL_CLASSIC)
	default_camera = clampi(int(cfg.get_value("game", "default_camera", 1)), 0, 3)
	difficulty = cfg.get_value("game", "difficulty", 1)
	window_mode = int(cfg.get_value("video", "window_mode", WindowMode.WINDOWED)) as WindowMode
	vsync = cfg.get_value("video", "vsync", true)
	show_fps = cfg.get_value("video", "show_fps", false)
	render_scale = cfg.get_value("video", "render_scale", 1.0)
	reflections = cfg.get_value("video", "reflections", true)
	reflection_half = cfg.get_value("video", "reflection_half", true)
	bloom = cfg.get_value("video", "bloom", true)
	grass = bool(cfg.get_value("video", "grass", true))
	debug_menu = cfg.get_value("debug", "menu", false)
	show_cam_debug = false
	debug_net_log = cfg.get_value("debug", "net_log", false)
	predict_contacts = cfg.get_value("debug", "predict_contacts", true)
	_save_settings()
	DirAccess.remove_absolute("user://settings.cfg")

var team_size: = 2



var pre_tutorial_settings: = {}
var court_half_width: = 4.5
var court_half_length: = 9.0
var set_points: = 7
var sets_to_win: = 2
var win_by_two: = true





var sweat_enabled: = false
var sweat_rate: = 1.0



var sweat_small: = false


var local_side: = 1
var crowd_enabled: = true
var voice_enabled: = true


var dark_theme: = false




var debug_menu: = false




var dev_tools: = OS.has_feature("editor")


var debug_net_log: = false


var predict_contacts: = true


var lobby_notice: = ""



var menu_return_local: = false


var lobby_page: = ""


var menu_outfit: = "gym"


var menu_ball: = "nationals"
var freeplay_stage: = "nationals"


const VERSION: = "0.77.1"


var show_cam_debug: = false



var no_cooldowns: = false


var spike_hitstop: = true



var simple_bot_serves: = false


var tutorial_finale: = false



var debug_serve_zones: = false








var onboarding_active: = false
var onboarding_seen: = false



var tutorial_seen: = false




const ONLINE_TERMS_VERSION: = 2
var online_terms_accepted: = false
var online_terms_version: = 0




var gpu_notice_dismissed: = false
var aim_assist: = false






var hardware_cursor: = false


# On-screen controls: 0 = auto (on wherever there is a touch screen), 1 = on,
# 2 = off. Auto is resolved by TouchControls, which owns the pad itself.
var touch_controls: = 0


var show_own_name: = false



var touch_highlight: = true
var camera_shake: = true
var rumble: = true
var aim_color_cue: = true



var mouse_sensitivity: = 1.0
var stick_sensitivity: = 1.0

var chat_enabled: = true
var chat_filter: = true
var chat_bubbles: = true
var chat_w: = 300.0
var chat_h: = 160.0
var chat_collapsed: = false


var stage: = "nationals"



var stage_barefoot: = false



var stage_reflections: = true

func reflections_live() -> bool:
	return reflections and stage_reflections




var reach_marker: = true
var replay_capture: = true







enum WindowMode{WINDOWED, BORDERLESS, FULLSCREEN}
var window_mode: = WindowMode.WINDOWED
var vsync: = true
var bloom: = true
var net_see_through: = true


var grass: = true
var max_fps: = 60
var show_fps: = false


var render_scale: = 1.0
var reflections: = true
var reflection_half: = true



var msaa: = 0






const WINDOWED_SIZE: = Vector2i(1600, 900)



var window_size: = WINDOWED_SIZE




var window_user_sized: = false

func apply_display() -> void :

	match window_mode:
		WindowMode.WINDOWED:






			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var screen: = DisplayServer.window_get_current_screen()
			var usable: = DisplayServer.screen_get_usable_rect(screen)



			var want: = window_size if window_user_sized else usable.size
			var size: = Vector2i(
				mini(want.x, usable.size.x - 80), 
				mini(want.y, usable.size.y - 80))



			_last_applied_size = size
			DisplayServer.window_set_size(size)
			DisplayServer.window_set_position(
				usable.position + (usable.size - size) / 2)


			window_size = size



			window_user_sized = true
		WindowMode.BORDERLESS:


			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			var screen: = DisplayServer.window_get_current_screen()
			DisplayServer.window_set_position(
				DisplayServer.screen_get_position(screen))
			DisplayServer.window_set_size(DisplayServer.screen_get_size(screen))
		WindowMode.FULLSCREEN:








			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync
		else DisplayServer.VSYNC_DISABLED)


	Engine.max_fps = max_fps

## True on the two targets that cannot afford the desktop render budget: the web
## build, which 4.7 pins to the Compatibility renderer, and phones.
func low_end_renderer() -> bool:
	return OS.has_feature("web") or OS.has_feature("mobile")

func apply_render_scale() -> void :
	var tree: = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	# Render at a smaller internal resolution to reduce GPU fragment work while
	# keeping the UI crisp. FSR2 below picks the cost back up when available.
	var effective_scale: = minf(render_scale, 0.75) if low_end_renderer() else render_scale
	tree.root.scaling_3d_scale = effective_scale




	var can_fsr: = RenderingServer.get_rendering_device() != null
	tree.root.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2\
	if (effective_scale < 0.999 and can_fsr) else Viewport.SCALING_3D_MODE_BILINEAR





var _compat: = -1
func is_compatibility() -> bool:
	if _compat < 0:
		_compat = 1 if RenderingServer.get_rendering_device() == null else 0
	return _compat == 1

func apply_msaa() -> void :


	var tree: = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	tree.root.msaa_3d = clampi(msaa, 0, 3) as Viewport.MSAA
var difficulty: = 1


var local_cpus: Dictionary = {}
var net_roster: Array = []

func difficulty_aim_mult(level: = -1) -> float:
	return [1.7, 1.0, 0.55][difficulty if level < 0 else level]

func difficulty_think_mult(level: = -1) -> float:
	return [1.5, 1.0, 0.7][difficulty if level < 0 else level]

func set_mode(size: int) -> void :











	team_size = size
	if size >= 6:

		court_half_width = 7.6
		court_half_length = 13.6
	elif size >= 4:
		court_half_width = 7.0
		court_half_length = 12.8
	elif size <= 1:



		court_half_width = 4.0
		court_half_length = 8.4
	else:
		court_half_width = 5.1
		court_half_length = 10.2
