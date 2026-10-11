class_name SettingsPanel
extends VBoxContainer




















signal retheme_requested(dark: bool)

const WINDOW_NAMES: = ["windowed", "borderless fullscreen", "fullscreen"]

const RES_STEPS: = [Vector2i(1280, 720), Vector2i(1600, 900), 
	Vector2i(1920, 1080), Vector2i(2560, 1440)]
const MSAA_NAMES: = ["off", "2x", "4x", "8x"]


const CAMERA_NAMES: = ["free look", "dynamic", "broadcast", "static"]
const TOUCH_NAMES: = ["auto", "always on", "off"]


const AUDIO_DEFAULTS: = {"master": 1.0, "music": 0.2, "ambient": 0.7, 
	"sfx": 1.0, "crowd": 1.0}



const LATENCY_MS: = [0, 60, 120, 250]
const LATENCY_NAMES: = ["off", "60 ms", "120 ms", "250 ms"]







enum Scope{SYSTEM, PROFILE, ALL}
var scope: int = Scope.SYSTEM

static var _open_tab_by_scope: = {Scope.SYSTEM: 0, Scope.PROFILE: 0, Scope.ALL: 0}
var _tabs: TabContainer = null

func set_scope(s: int) -> void :




	scope = s
	rebuild()




func _is_dev_build() -> bool:
	if LaunchGate.public_beta():
		return false
	return OS.has_feature("editor") or OS.is_debug_build()


func cycle_tab(step: int) -> void :
	if _tabs == null or _tabs.get_tab_count() == 0:
		return
	var n: = _tabs.get_tab_count()
	_tabs.current_tab = (_tabs.current_tab + step + n) % n

func _ready() -> void :

	process_mode = Node.PROCESS_MODE_ALWAYS
	add_theme_constant_override("separation", 12)
	rebuild()




func rebuild() -> void :





	for c in get_children():
		remove_child(c)
		c.queue_free()
	var tabs: = TabContainer.new()
	_tabs = tabs
	tabs.custom_minimum_size = Vector2(620, 380)
	tabs.tab_alignment = TabBar.ALIGNMENT_CENTER
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UiStyle.style_tabs(tabs)
	if scope == Scope.PROFILE:
		_build_profile_tabs(tabs)
	elif scope == Scope.SYSTEM:
		_build_system_tabs(tabs)
	else:
		_build_system_tabs(tabs)
		_build_profile_tabs(tabs)
	var remembered: int = int(_open_tab_by_scope.get(scope, 0))
	if remembered >= 0 and remembered < tabs.get_tab_count():
		tabs.current_tab = remembered
	tabs.tab_changed.connect( func(i: int): _open_tab_by_scope[scope] = i)
	add_child(tabs)



func _build_system_tabs(tabs: TabContainer) -> void :
	var audio: = _tab(tabs, "audio")
	_subheader(audio, "levels")
	_slider(audio, "master", "master")
	_slider(audio, "music", "music")
	_slider(audio, "ambient", "ambient")
	_slider(audio, "sfx", "sfx")
	_slider(audio, "crowd", "crowd")
	_subheader(audio, "sources")
	_check(audio, "audience noises", "", 
		GameConfig.crowd_enabled, func(on: bool): GameConfig.crowd_enabled = on)
	_check(audio, "player voices", "", 
		GameConfig.voice_enabled, func(on: bool): GameConfig.voice_enabled = on)
	_reset_btn(audio, "audio")

	var video: = _tab(tabs, "video")
	_subheader(video, "display")


	_select(video, "window", WINDOW_NAMES, int(GameConfig.window_mode), func(i: int):
		GameConfig.window_mode = i as GameConfig.WindowMode
		GameConfig.apply_display.call_deferred())
	_select(video, "resolution", _res_names(), _res_index(), func(i: int):
		GameConfig.window_size = _res_list()[i]
		GameConfig.apply_display.call_deferred())
	_check(video, "vsync", "", GameConfig.vsync, func(on: bool):
		GameConfig.vsync = on
		GameConfig.apply_display())
	var fps_vals: = [0, 25, 30, 60, 120, 144]
	var fps_names: = ["unlimited", "25", "30", "60", "120", "144"]
	_select(video, "frame rate cap", fps_names, 
		maxi(fps_vals.find(GameConfig.max_fps), 0), func(i: int):
			GameConfig.max_fps = int(fps_vals[i])
			GameConfig.apply_display())
	_subheader(video, "effects")
	_check(video, "floor reflections", "", 
		GameConfig.reflections, func(on: bool): GameConfig.reflections = on)
	_check(video, "half res reflections", "", 
		GameConfig.reflection_half, func(on: bool): GameConfig.reflection_half = on)
	_check(video, "glow", "", 
		GameConfig.bloom, func(on: bool): GameConfig.bloom = on)
	_check(video, "grass", "", 
		GameConfig.grass, func(on: bool): GameConfig.grass = on)
	_check(video, "show fps counter", "", 
		GameConfig.show_fps, func(on: bool): GameConfig.show_fps = on)
	_reset_btn(video, "video")

	var gen: = _tab(tabs, "general")
	_subheader(gen, "theme")





	if scope == Scope.ALL:
		var locked: = CheckBox.new()
		locked.text = "dark theme"
		locked.button_pressed = GameConfig.dark_theme
		locked.disabled = true
		locked.tooltip_text = "change the theme from the main menu, not during a match"
		UiStyle.style_check(locked)
		gen.add_child(locked)
	else:
		_check(gen, "dark theme", "", 
			GameConfig.dark_theme, func(on: bool):
				GameConfig.dark_theme = on
				UiStyle.dark = on
				GameConfig.save_settings()
				retheme_requested.emit(on))
	_subheader(gen, "chat")


	_check(gen, "profanity filter", MenuCopy.sub("chat_filter"), 
		GameConfig.chat_filter, func(on: bool): GameConfig.chat_filter = on)
	_subheader(gen, "recording")
	_check(gen, "save match replays", "", 
		GameConfig.replay_capture, func(on: bool): GameConfig.replay_capture = on)
	_reset_btn(gen, "general")


	if _is_dev_build():
		_build_debug_tab(tabs)



func _build_profile_tabs(tabs: TabContainer) -> void :
	var game: = _tab(tabs, "gameplay")
	_subheader(game, "view")


	_select(game, "camera", CAMERA_NAMES, 
		clampi(GameConfig.default_camera, 0, CAMERA_NAMES.size() - 1), 
		func(i: int): GameConfig.default_camera = i)
	_subheader(game, "hud")
	_check(game, "last-touch outline", MenuCopy.sub("last_touch"), 
		GameConfig.touch_highlight, func(on: bool): GameConfig.touch_highlight = on)
	_check(game, "reach marker", MenuCopy.sub("reach_marker"), 
		GameConfig.reach_marker, func(on: bool): GameConfig.reach_marker = on)
	_check(game, "in-game chat", MenuCopy.sub("in_game_chat"), 
		GameConfig.chat_enabled, func(on: bool): GameConfig.chat_enabled = on)
	_check(game, "chat bubbles", MenuCopy.sub("chat_bubbles"), 
		GameConfig.chat_bubbles, func(on: bool): GameConfig.chat_bubbles = on)
	_check(game, "show your own name", MenuCopy.sub("own_name"), 
		GameConfig.show_own_name, func(on: bool): GameConfig.show_own_name = on)
	_subheader(game, "input")
	_check(game, "hardware cursor", MenuCopy.sub("hardware_cursor"), 
		GameConfig.hardware_cursor, func(on: bool): GameConfig.hardware_cursor = on)
	_range(game, "mouse sensitivity", 0.25, 3.0, 0.05, GameConfig.mouse_sensitivity, 
		func(v: float) -> String: return "%.2fx" % v, 
		func(v: float): GameConfig.mouse_sensitivity = v, 1.0)
	_range(game, "controller sensitivity", 0.25, 3.0, 0.05, GameConfig.stick_sensitivity, 
		func(v: float) -> String: return "%.2fx" % v, 
		func(v: float): GameConfig.stick_sensitivity = v, 1.0)
	_subheader(game, "touch controls")
	_select(game, "on-screen pad", TOUCH_NAMES, 
		clampi(GameConfig.touch_controls, 0, TOUCH_NAMES.size() - 1), 
		_set_touch_mode)
	_reset_btn(game, "gameplay")

	var access: = _tab(tabs, "accessibility")
	_check(access, "aim assist", MenuCopy.sub("aim_assist"), 
		GameConfig.aim_assist, func(on: bool): GameConfig.aim_assist = on)
	_check(access, "camera shake", MenuCopy.sub("camera_shake"), 
		GameConfig.camera_shake, func(on: bool): GameConfig.camera_shake = on)
	_check(access, "rumble", "controller vibration on your hits and impacts", 
		GameConfig.rumble, func(on: bool): GameConfig.rumble = on)
	_check(access, "crosshair colour", 
		"the aim cursor tints green over your side, pink over theirs", 
		GameConfig.aim_color_cue, func(on: bool): GameConfig.aim_color_cue = on)
	_reset_btn(access, "accessibility")

	_build_controls_tab(tabs)



func _build_controls_tab(tabs: TabContainer) -> void :
	var col: = _tab(tabs, "controls")
	_subheader(col, "rebind")
	var head: = HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var spacer: = Label.new()
	spacer.custom_minimum_size.x = 150
	head.add_child(spacer)
	for name in ["keyboard", "controller"]:
		var h: = Label.new()
		h.text = name
		h.custom_minimum_size.x = BIND_SLOT_W
		UiStyle.style_label(h, "muted")
		head.add_child(h)
	col.add_child(head)
	_bind_buttons.clear()
	var binds: = _active_binds()
	for entry in InputBinds.REBINDABLE:
		var row: = _row(col, String(entry.label))
		row.add_child(_bind_slot(String(entry.action), "kb", bool(entry.kb), binds))
		row.add_child(_bind_slot(String(entry.action), "pad", bool(entry.pad), binds))
	var gap: = Control.new()
	gap.custom_minimum_size.y = 6
	col.add_child(gap)
	var reset: = Button.new()
	reset.text = "reset all controls"
	UiStyle.style_button(reset, "secondary", 14)
	reset.custom_minimum_size = Vector2(0, 40)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	reset.pressed.connect( func():
		_cancel_listen()
		ProfileStore.reset_bindings()
		_refresh_bind_labels())
	col.add_child(reset)

const BIND_BTN_W: = 108
const BIND_SLOT_W: = 138

func _active_binds() -> Dictionary:
	var p: = ProfileStore.active()
	return p.bindings if p != null else {}



func _bind_slot(action: String, slot: String, applies: bool, binds: Dictionary) -> Control:
	if not applies:
		var dash: = Label.new()
		dash.text = "—"
		dash.custom_minimum_size.x = BIND_SLOT_W
		dash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiStyle.style_label(dash, "muted")
		return dash
	var cell: = HBoxContainer.new()
	cell.add_theme_constant_override("separation", 4)
	cell.custom_minimum_size.x = BIND_SLOT_W
	var b: = Button.new()
	b.text = InputBinds.label_for(action, slot, binds)
	UiStyle.style_button(b, "secondary", 14)
	b.custom_minimum_size = Vector2(BIND_BTN_W, 34)
	b.pressed.connect( func(): _begin_listen(action, slot, b))
	_bind_buttons["%s|%s" % [action, slot]] = b
	cell.add_child(b)
	var rst: = Button.new()
	rst.text = "↺"
	rst.tooltip_text = "reset to default"
	UiStyle.style_button(rst, "secondary", 14)
	rst.custom_minimum_size = Vector2(26, 34)
	rst.pressed.connect( func():
		if _listen_action == action and _listen_slot == slot:
			_cancel_listen()
		ProfileStore.reset_binding(action, slot)
		_refresh_bind_labels())
	cell.add_child(rst)
	return cell




func _refresh_bind_labels() -> void :
	var binds: = _active_binds()
	for key in _bind_buttons:
		var b: = _bind_buttons[key] as Button
		if b == null or not is_instance_valid(b):
			continue
		var parts: = String(key).split("|")
		b.text = InputBinds.label_for(parts[0], parts[1], binds)

var _bind_buttons: = {}

var _listen_action: = ""
var _listen_slot: = ""
var _listen_btn: Button = null
var _listen_since: = 0

func _begin_listen(action: String, slot: String, btn: Button) -> void :
	_cancel_listen()
	_listen_action = action
	_listen_slot = slot
	_listen_btn = btn
	_listen_since = Time.get_ticks_msec()
	btn.text = "press a %s…" % ("key" if slot == "kb" else "button")

func _cancel_listen() -> void :
	if _listen_btn != null and is_instance_valid(_listen_btn):
		_listen_btn.text = InputBinds.label_for(_listen_action, _listen_slot, _active_binds())
	_listen_action = ""
	_listen_slot = ""
	_listen_btn = null

func _input(event: InputEvent) -> void :
	if _listen_btn == null:
		return


	if Time.get_ticks_msec() - _listen_since < 180:
		return

	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		accept_event()
		_cancel_listen()
		return
	var captured: InputEvent = null
	if _listen_slot == "kb":
		if event is InputEventKey and event.pressed and not (event as InputEventKey).echo:
			captured = event
		elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			captured = event
	else:
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed:
			captured = event
		elif event is InputEventJoypadMotion\
		and absf((event as InputEventJoypadMotion).axis_value) > 0.7:
			captured = event
	if captured == null:
		return
	accept_event()
	var a: = _listen_action
	var s: = _listen_slot
	_listen_action = ""
	_listen_slot = ""
	_listen_btn = null
	ProfileStore.set_binding(a, s, InputBinds.event_to_data(captured))


	_refresh_bind_labels()


func _subheader(col: VBoxContainer, text: String) -> void :
	var gap: = Control.new()
	gap.custom_minimum_size.y = 6
	col.add_child(gap)
	var l: = Label.new()
	l.text = text
	UiStyle.style_label(l, "small")
	l.add_theme_color_override("font_color", UiStyle.muted())
	col.add_child(l)
	var rule: = Panel.new()
	rule.custom_minimum_size.y = 2
	var sb: = StyleBoxFlat.new()
	sb.bg_color = Color(UiStyle.muted(), 0.35)
	sb.set_corner_radius_all(1)
	rule.add_theme_stylebox_override("panel", sb)
	col.add_child(rule)




func reset_all() -> void :
	if scope != Scope.PROFILE:
		_reset_category("audio", false)
		_reset_category("video", false)
		_reset_category("general", false)
	if scope != Scope.SYSTEM:
		_reset_category("gameplay", false)
		_reset_category("accessibility", false)
	GameConfig.save_settings()
	rebuild()





func _build_debug_tab(tabs: TabContainer) -> void :
	var col: = _tab(tabs, "debug")
	var master: = _named_check("DebugCheck", 
		"developer optionsdev tools and readouts", GameConfig.debug_menu)
	col.add_child(master)
	var drawer: = VBoxContainer.new()
	drawer.name = "DebugBox"
	drawer.add_theme_constant_override("separation", 12)
	drawer.visible = GameConfig.debug_menu
	col.add_child(drawer)
	master.toggled.connect( func(on: bool):
		GameConfig.debug_menu = on
		drawer.visible = on


		if not on:
			Net.fake_latency_ms = 0
			Net.fake_jitter_ms = 0
			Net.fake_loss_pct = 0
		GameConfig.save_settings())
	var cam: = _named_check("CamDebugCheck", 
		"camera readoutposition + mode overlay", GameConfig.show_cam_debug)
	cam.toggled.connect( func(on: bool):
		GameConfig.show_cam_debug = on
		GameConfig.save_settings())
	drawer.add_child(cam)

	var nocd: = _named_check("NoCooldownCheck", 
		"no cooldownsdive and block recover instantly", GameConfig.no_cooldowns)
	nocd.toggled.connect( func(on: bool):
		GameConfig.no_cooldowns = on)
	drawer.add_child(nocd)
	var hitstop: = _named_check("HitstopCheck", 
		"spike hitstopearned spikes hang for a beat at contact", 
		GameConfig.spike_hitstop)
	hitstop.toggled.connect( func(on: bool):
		GameConfig.spike_hitstop = on)
	drawer.add_child(hitstop)
	var zones: = _named_check("ServeZonesCheck", 
		"all serve zonespaint every server's zone, not just yours", 
		GameConfig.debug_serve_zones)
	zones.toggled.connect( func(on: bool):
		GameConfig.debug_serve_zones = on)
	drawer.add_child(zones)
	var netlog: = _named_check("NetLogCheck", 
		"net logprint the netcode trace", GameConfig.debug_net_log)
	netlog.toggled.connect( func(on: bool):
		GameConfig.debug_net_log = on
		GameConfig.save_settings())
	drawer.add_child(netlog)
	var predict: = _named_check("PredictCheck", 
		"predict contactsclient-side contact prediction", 
		GameConfig.predict_contacts)
	predict.toggled.connect( func(on: bool):
		GameConfig.predict_contacts = on
		GameConfig.save_settings())
	drawer.add_child(predict)
	var row: = _row(drawer, "simulated latency")
	var sel: = UiSelect.new(LATENCY_NAMES)
	sel.name = "LatencyOption"
	sel.selected = maxi(LATENCY_MS.find(Net.fake_latency_ms), 0)
	sel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sel.picked.connect( func(i: int): Net.fake_latency_ms = LATENCY_MS[i])
	row.add_child(sel)



	if GameConfig.dev_tools:
		var gap: = Control.new()
		gap.custom_minimum_size.y = 6
		drawer.add_child(gap)
		var lab: = Button.new()
		lab.name = "StageLabBtn"
		lab.text = "stage lab"
		UiStyle.style_button(lab, "secondary", 14)
		lab.custom_minimum_size = Vector2(0, 40)
		lab.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		lab.pressed.connect( func():
			GameConfig.goto_scene.call_deferred("res://game/dev/stage_lab.tscn"))
		drawer.add_child(lab)

func _named_check(node_name: String, label: String, on: bool) -> CheckBox:
	var cb: = CheckBox.new()
	cb.name = node_name
	cb.text = label
	cb.button_pressed = on
	UiStyle.style_check(cb)
	return cb

func _set_touch_mode(i: int) -> void :
	GameConfig.touch_controls = i
	TouchControls.refresh_mode()

func _reset_btn(col: VBoxContainer, cat: String) -> void :
	var gap: = Control.new()
	gap.custom_minimum_size.y = 6
	col.add_child(gap)
	var b: = Button.new()
	b.text = "reset %s" % cat
	UiStyle.style_button(b, "secondary", 14)
	b.custom_minimum_size = Vector2(0, 40)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect( func():
		_reset_category(cat, true)
		rebuild())
	col.add_child(b)

func _reset_category(cat: String, save: = true) -> void :
	match cat:
		"audio":
			for bus in AUDIO_DEFAULTS:
				GameConfig.set_volume(bus, float(AUDIO_DEFAULTS[bus]))
			GameConfig.crowd_enabled = false
			GameConfig.voice_enabled = true
		"gameplay":
			GameConfig.default_camera = 1
			GameConfig.touch_highlight = true
			GameConfig.reach_marker = true
			GameConfig.chat_enabled = true
			GameConfig.chat_bubbles = true
			GameConfig.show_own_name = false
			GameConfig.hardware_cursor = false
			GameConfig.touch_controls = 0
			GameConfig.mouse_sensitivity = 1.0
			GameConfig.stick_sensitivity = 1.0
		"accessibility":
			GameConfig.aim_assist = false
			GameConfig.camera_shake = true
			GameConfig.rumble = true
			GameConfig.aim_color_cue = true
		"video":
			GameConfig.window_mode = GameConfig.WindowMode.WINDOWED
			GameConfig.window_size = GameConfig.WINDOWED_SIZE
			GameConfig.render_scale = 1.0
			GameConfig.reflection_half = true
			GameConfig.msaa = 0
			GameConfig.vsync = true
			GameConfig.reflections = true
			GameConfig.bloom = true
			GameConfig.max_fps = 60
			GameConfig.show_fps = false
			GameConfig.apply_display()
			GameConfig.apply_render_scale()
			GameConfig.apply_msaa()
		"general":


			GameConfig.replay_capture = true
			GameConfig.chat_filter = true
	if save:
		GameConfig.save_settings()
		UiStyle.sfx("confirm")


func _tab(tabs: TabContainer, tab_name: String) -> VBoxContainer:
	var scroll: = ScrollContainer.new()
	scroll.name = tab_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UiStyle.style_scroll(scroll.get_v_scroll_bar())
	var col: = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 12)
	var pad: = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_%s" % side, 14)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(col)
	scroll.add_child(pad)
	tabs.add_child(scroll)
	return col

func _row(col: VBoxContainer, label: String) -> HBoxContainer:
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var l: = Label.new()
	l.text = label
	UiStyle.style_label(l, "body")
	l.custom_minimum_size.x = 150
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	col.add_child(row)
	return row

func _slider(col: VBoxContainer, label: String, bus: String) -> void :
	var row: = _row(col, label)
	var s: = HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.01
	s.value = GameConfig.get_volume(bus)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiStyle.style_slider(s)
	s.value_changed.connect( func(vv: float): GameConfig.set_volume(bus, vv))
	row.add_child(s)

	if AUDIO_DEFAULTS.has(bus):
		row.add_child(_slider_reset(s, float(AUDIO_DEFAULTS[bus])))



func _slider_reset(s: HSlider, default: float) -> Button:
	var b: = UiStyle.reset_button( func(): s.value = default)
	b.tooltip_text = "reset to default"
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return b

func _check(col: VBoxContainer, label: String, desc: String, 
		on: bool, apply: Callable) -> void :
	var cb: = CheckBox.new()



	cb.text = label
	if desc != "":
		cb.tooltip_text = desc
	cb.button_pressed = on
	UiStyle.style_check(cb)
	cb.toggled.connect( func(v: bool):
		apply.call(v)
		GameConfig.save_settings())
	col.add_child(cb)

func _select(col: VBoxContainer, label: String, options: Array, 
		current: int, apply: Callable) -> void :
	var row: = _row(col, label)
	var sel: = UiSelect.new(options)
	sel.selected = current
	sel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sel.picked.connect( func(i: int):
		apply.call(i)
		GameConfig.save_settings())
	row.add_child(sel)




func _range(col: VBoxContainer, label: String, mn: float, mx: float, 
		step: float, val: float, fmt: Callable, apply: Callable, 
		default: = NAN) -> void :
	var row: = _row(col, label)
	var s: = HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = step
	s.value = val
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiStyle.style_slider(s)
	var readout: = Label.new()
	readout.custom_minimum_size.x = 52
	readout.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiStyle.style_label(readout, "body")
	readout.text = fmt.call(val)
	s.value_changed.connect( func(vv: float):
		readout.text = fmt.call(vv)
		apply.call(vv)
		GameConfig.save_settings())
	row.add_child(s)
	row.add_child(readout)
	if not is_nan(default):
		row.add_child(_slider_reset(s, default))



func _res_list() -> Array:
	var native: = DisplayServer.screen_get_size(
		DisplayServer.window_get_current_screen())
	var out: Array = []
	for r in RES_STEPS:
		if r.x <= native.x and r.y <= native.y:
			out.append(r)
	if not out.has(native):
		out.append(native)
	return out

func _res_names() -> Array:
	var native: = DisplayServer.screen_get_size(
		DisplayServer.window_get_current_screen())
	var names: Array = []
	for r in _res_list():
		names.append("%d x %d%s" % [r.x, r.y, 
			"   native" if r == native else ""])
	return names

func _res_index() -> int:
	var list: = _res_list()
	for i in list.size():
		if list[i] == GameConfig.window_size:
			return i
	return list.size() - 1
