class_name LaunchGate
extends RefCounted

























const PLAYTEST_EXPIRES: = "2026-09-28T03:59:00Z"

const VERDICT_OK: = "ok"
const VERDICT_RESTART: = "restart"
const VERDICT_NO_STEAM: = "no_steam"
const VERDICT_NOT_OWNED: = "not_owned"
const VERDICT_EXPIRED: = "expired"

static func _args() -> PackedStringArray:
	return OS.get_cmdline_user_args()

static func _arg_after(flag: String) -> String:
	var a: = _args()
	var i: = a.find(flag)
	return String(a[i + 1]) if i >= 0 and i + 1 < a.size() else ""

static func _editor() -> bool:
	return OS.has_feature("editor")

static func is_playtest() -> bool:
	return OS.has_feature("playtest")



const STEAM_CHECK_DISABLED: = true







static func public_beta() -> bool:
	return is_playtest() or _args().has("--beta")


static func enforced() -> bool:
	if _arg_after("--gate-test") != "":
		return true
	if not _editor():


		return OS.has_feature("pc")
	return _args().has("--gate") and not _args().has("--no-gate")


static func check() -> Dictionary:
	if not enforced():
		return _v(VERDICT_OK, "not enforced (editor)")
	var fake: = _arg_after("--gate-test")
	if fake != "":
		if fake in [VERDICT_NO_STEAM, VERDICT_NOT_OWNED, VERDICT_EXPIRED]:
			return _v(fake, "faked by --gate-test")
		push_warning("[gate] unknown --gate-test verdict '%s' (no_steam | not_owned | expired)" % fake)
	var app_id: = Net.steam_app_id()
	var s: Object = Engine.get_singleton("Steam") if Engine.has_singleton("Steam") else null



	if STEAM_CHECK_DISABLED:



		var up: = s != null and Net.steam_init()
		return _v(VERDICT_OK, "steam check DISABLED (steam_ok=%s) app %d" % [str(up), app_id])\
		if not _expired(s) else _v(VERDICT_EXPIRED, "expired (steam check disabled)")
	if s != null and not _editor() and s.has_method("restartAppIfNecessary"):
		if bool(s.restartAppIfNecessary(app_id)):
			return _v(VERDICT_RESTART, "steam is relaunching app %d" % app_id)
	var steam_ok: = s != null and Net.steam_init()






	if steam_ok:
		if s.has_method("isSubscribedApp"):
			if not bool(s.isSubscribedApp(app_id)):
				return _v(VERDICT_NOT_OWNED, "isSubscribedApp(%d) false" % app_id)
		elif s.has_method("isSubscribed"):
			if not bool(s.isSubscribed()):
				return _v(VERDICT_NOT_OWNED, "isSubscribed false")
	else:
		push_warning("[gate] steam unavailable for app %d; allowing play, expiry still enforced" % app_id)

	if _expired(s):
		return _v(VERDICT_EXPIRED, "past PLAYTEST_EXPIRES (%s)" % _time_source)
	return _v(VERDICT_OK, "gate ok (steam_ok=%s) app %d" % [str(steam_ok), app_id])



static func _expired(s: Object) -> bool:
	if not (is_playtest() or _arg_after("--gate-expiry") != ""):
		return false
	var expires: = _expiry_unix()
	var now: = _now_unix(s)


	if expires <= 0:
		push_error("[gate] PLAYTEST_EXPIRES '%s' did not parse" % PLAYTEST_EXPIRES)
	return now >= expires

static var _time_source: = "local clock"

static func _expiry_unix() -> int:
	var iso: = PLAYTEST_EXPIRES
	if _editor():
		var o: = _arg_after("--gate-expiry")
		if o != "":
			iso = o
	return int(Time.get_unix_time_from_datetime_string(iso))



static func _now_unix(s: Object) -> int:
	_time_source = "local clock"
	if s != null and s.has_method("getServerRealTime"):
		var t: = int(s.getServerRealTime())
		if t > 0:
			_time_source = "steam server time"
			return t
	return int(Time.get_unix_time_from_system())

static func _v(verdict: String, detail: String) -> Dictionary:
	print("[gate] %s: %s" % [verdict, detail])
	return {"verdict": verdict, "detail": detail}




static func show_block(host: Node, result: Dictionary) -> void :
	var verdict: String = result.get("verdict", VERDICT_NO_STEAM)
	if verdict == VERDICT_RESTART:
		host.get_tree().quit()
		return
	var app_id: = Net.steam_app_id()
	var title: = ""
	var body: = ""
	var store: = false
	match verdict:
		VERDICT_NO_STEAM:
			title = "steam needed"
			body = "please launch the game through steam's client"
		VERDICT_NOT_OWNED:
			if is_playtest():
				title = "playtest over"
				body = "this steam account no longer has playtest access. thanks for playing!"
			else:
				title = "not on this account"
				body = "the steam account that's signed in doesn't own the game"
				store = true
		VERDICT_EXPIRED:
			title = "playtest over"
			body = "thanks for playing!"
		_:
			title = "can't start"
			body = String(result.get("detail", ""))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MusicManager.stop(0.0)
	var overlay: = CanvasLayer.new()
	overlay.layer = 125
	host.add_child(overlay)
	var bg: = ColorRect.new()
	bg.color = UiStyle.bg()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)
	var center: = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var card: = PanelContainer.new()
	UiStyle.style_panel(card, UiStyle.card(), UiStyle.RADIUS_SOFT)
	center.add_child(card)
	var m: = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 24)
	card.add_child(m)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size.x = 440
	m.add_child(v)
	var t: = Label.new()
	t.text = title
	UiStyle.style_label(t, "title")
	v.add_child(t)
	var d: = Label.new()
	d.text = body
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.style_label(d, "body")
	v.add_child(d)
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(row)
	if store:
		var shop: = Button.new()
		shop.text = "open store page"
		UiStyle.style_button(shop, "secondary", 16)
		shop.pressed.connect( func():
			if OS.has_feature("web"):
				# steam:// is a desktop scheme; in a browser it is a dead click.
				OS.shell_open("https://store.steampowered.com/app/%d/" % app_id)
			else:
				OS.shell_open("steam://store/%d" % app_id))
		row.add_child(shop)
	var quit: = Button.new()
	quit.text = "quit"
	UiStyle.style_button(quit, "primary", 16)
	quit.pressed.connect( func(): host.get_tree().quit())
	row.add_child(quit)
	quit.grab_focus()
	var shot: = _arg_after("--gate-shot")
	if shot != "":
		_shoot(host, shot)

static func _shoot(host: Node, path: String) -> void :
	await host.get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	host.get_viewport().get_texture().get_image().save_png(path)
	print("gate shot -> ", path)
	host.get_tree().quit()
