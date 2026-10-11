class_name LobbyPanel
extends VBoxContainer




















signal stage_changed(id: String)
signal rule_changed(key: String, value: Variant)
signal global_cpu_changed(diff: int)
signal cpu_pressed(id: String)
signal cpu_diff_step(id: String, dir: int)
signal cpu_reroll(id: String)
signal side_pressed(side: int)
signal start_pressed
signal shuffle_pressed
signal invite_pressed
signal back_pressed
signal reset_pressed

const WIDTH: = 700.0

var banner: StageBanner
var home: TeamCard
var away: TeamCard
var rules: RulesStrip
var start_btn: Button
var shuffle_btn: Button
var invite_btn: Button
var back_btn: Button
var spectate_btn: Button
var _title: Label
var _code_row: HBoxContainer
var _code_lbl: Label
var _code_eye: Button
var _code_shown: = false
var _tell: Label
var _spec: Label
var _wait: Label
var _state: Dictionary = {}

func _init() -> void :
	custom_minimum_size.x = WIDTH
	add_theme_constant_override("separation", 6)
	_title = Label.new()
	_title.text = "lobby"
	_title.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_color", UiStyle.text())
	_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER


	var header: = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	header.add_child(_title)
	var hspacer: = Control.new()
	hspacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(hspacer)
	_code_row = HBoxContainer.new()
	_code_row.add_theme_constant_override("separation", 8)
	_code_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_code_row.visible = false
	_code_lbl = Label.new()
	_code_lbl.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	_code_lbl.add_theme_font_size_override("font_size", 14)
	_code_lbl.add_theme_color_override("font_color", UiStyle.muted())
	_code_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_code_row.add_child(_code_lbl)


	_code_eye = Button.new()
	_code_eye.text = "show"
	UiStyle.style_button(_code_eye, "tertiary", 12)
	_code_eye.custom_minimum_size.x = 64
	_code_eye.tooltip_text = "show or hide the lobby code"
	_code_eye.pressed.connect( func():
		_code_shown = not _code_shown
		_refresh_code())
	_code_row.add_child(_code_eye)
	var code_copy: = Button.new()
	code_copy.text = "copy"
	UiStyle.style_button(code_copy, "secondary", 12)
	code_copy.custom_minimum_size.x = 92
	code_copy.pressed.connect(_copy_code.bind(code_copy))
	_code_row.add_child(code_copy)
	header.add_child(_code_row)
	add_child(header)
	banner = StageBanner.new()
	banner.changed.connect( func(id: String): stage_changed.emit(id))
	add_child(banner)


	var pair: = PanelContainer.new()
	var pb: = StyleBoxFlat.new()
	pb.bg_color = UiStyle.INK
	pb.set_corner_radius_all(TeamCard.RADIUS + 3)
	pb.set_content_margin_all(3.0)
	pair.add_theme_stylebox_override("panel", pb)
	add_child(pair)
	var teams: = HBoxContainer.new()
	teams.add_theme_constant_override("separation", 0)
	pair.add_child(teams)
	home = TeamCard.new()
	home.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home.setup(1)
	home.cpu_pressed.connect( func(id: String): cpu_pressed.emit(id))
	home.diff_step.connect( func(id: String, dir: int): cpu_diff_step.emit(id, dir))
	home.reroll.connect( func(id: String): cpu_reroll.emit(id))
	home.join_pressed.connect( func(): side_pressed.emit(1))
	teams.add_child(home)
	var bar: = Panel.new()
	bar.custom_minimum_size.x = 4
	var bsb: = StyleBoxFlat.new()
	bsb.bg_color = UiStyle.INK
	bar.add_theme_stylebox_override("panel", bsb)
	teams.add_child(bar)
	away = TeamCard.new()
	away.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	away.setup(-1)
	away.cpu_pressed.connect( func(id: String): cpu_pressed.emit(id))
	away.diff_step.connect( func(id: String, dir: int): cpu_diff_step.emit(id, dir))
	away.reroll.connect( func(id: String): cpu_reroll.emit(id))
	away.join_pressed.connect( func(): side_pressed.emit(-1))
	teams.add_child(away)



	var note: = CenterContainer.new()
	note.custom_minimum_size.y = 22
	add_child(note)
	_spec = Label.new()
	UiStyle.style_label(_spec, "small", UiStyle.muted())
	_spec.visible = false
	note.add_child(_spec)
	_tell = Label.new()
	UiStyle.style_pill(_tell, UiStyle.PRIMARY, UiStyle.INK, 11)
	var tsb: StyleBoxFlat = _tell.get_theme_stylebox("normal")
	tsb.content_margin_top = 1.0
	tsb.content_margin_bottom = 1.0
	tsb.shadow_size = 0
	_tell.visible = false
	note.add_child(_tell)
	rules = RulesStrip.new()
	rules.changed.connect(_on_rule)
	rules.reset_pressed.connect( func(): reset_pressed.emit())
	add_child(rules)

	var acts: = HBoxContainer.new()
	acts.add_theme_constant_override("separation", 10)
	add_child(acts)
	back_btn = Button.new()
	back_btn.text = "back"
	back_btn.custom_minimum_size = Vector2(0, 44)
	UiStyle.style_button(back_btn, "tertiary", 16)
	back_btn.pressed.connect( func(): back_pressed.emit())
	acts.add_child(back_btn)
	spectate_btn = Button.new()
	spectate_btn.text = "spectate"
	spectate_btn.custom_minimum_size = Vector2(0, 44)
	UiStyle.style_button(spectate_btn, "tertiary", 15)
	spectate_btn.pressed.connect( func(): side_pressed.emit(0))
	acts.add_child(spectate_btn)


	shuffle_btn = Button.new()
	shuffle_btn.text = "shuffle"
	shuffle_btn.custom_minimum_size = Vector2(0, 44)
	UiStyle.style_button(shuffle_btn, "tertiary", 15)
	shuffle_btn.tooltip_text = "deal everyone onto the teams again, at random"
	shuffle_btn.pressed.connect( func(): shuffle_pressed.emit())
	acts.add_child(shuffle_btn)
	invite_btn = Button.new()
	invite_btn.text = "invite"
	invite_btn.icon = UiStyle.icon("multiplayer")
	invite_btn.add_theme_constant_override("icon_max_width", 18)
	invite_btn.custom_minimum_size = Vector2(140, 44)
	UiStyle.style_button(invite_btn, "secondary", 16)
	invite_btn.add_theme_color_override("font_color", UiStyle.SECONDARY)
	invite_btn.pressed.connect( func(): invite_pressed.emit())
	var gap: = Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	acts.add_child(gap)
	acts.add_child(invite_btn)
	start_btn = Button.new()
	start_btn.text = "start match"
	start_btn.icon = UiStyle.icon("right")
	start_btn.add_theme_constant_override("icon_max_width", 18)


	start_btn.custom_minimum_size = Vector2(250, 44)
	UiStyle.style_button(start_btn, "primary", 20)
	start_btn.pressed.connect( func(): start_pressed.emit())
	acts.add_child(start_btn)

	_wait = Label.new()
	_wait.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_wait.custom_minimum_size.x = 280
	_wait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiStyle.style_label(_wait, "body", UiStyle.muted())
	_wait.visible = false
	acts.add_child(_wait)

func _on_rule(key: String, value: Variant) -> void :
	if key == "cpu":
		global_cpu_changed.emit(int(value))
	else:
		rule_changed.emit(key, value)






func _refresh_code() -> void :
	var code: = Net.lobby_code()
	_code_row.visible = code != ""
	if code == "":
		_code_shown = false
		return
	_code_lbl.text = "lobby code: %s" % (code if _code_shown else "•".repeat(code.length()))
	_code_eye.text = "hide" if _code_shown else "show"

func _copy_code(btn: Button) -> void :
	var code: = Net.lobby_code()
	if code == "":
		return
	DisplayServer.clipboard_set(code)
	UiStyle.sfx("confirm")
	btn.text = "copied!"
	var tw: = create_tween()
	tw.tween_interval(1.2)
	tw.tween_callback( func(): if is_instance_valid(btn): btn.text = "copy")

func apply(st: Dictionary) -> void :
	_state = st
	_title.text = String(st.get("title", "lobby"))
	_refresh_code()
	var editable: = bool(st.get("editable", true))
	banner.set_ids(st.get("stage_ids", Stage.ids()))


	var stage_id: = String(st.get("stage", "nationals"))
	banner.set_stage(stage_id, 1 if banner.current != "" and banner.current != stage_id else 0)
	banner.editable = editable
	var size: = int(st.get("size", 2))
	var my_side: = int(st.get("my_side", 1))
	var online: = String(st.get("side_mode", "local")) == "online"
	var can_join: = bool(st.get("side_editable", true))
	home.set_roster(st.get("home", []), size, editable)
	away.set_roster(st.get("away", []), size, editable)
	home.set_selected(my_side == 1, can_join)
	away.set_selected(my_side == -1, can_join)
	var r: Dictionary = st.get("rules", {})
	rules.rate_names = st.get("rate_names", rules.rate_names)
	rules.set_state({"size": size, "sets": int(r.get("sets", 2)), 
		"points": int(r.get("points", 7)), "rate": int(r.get("rate", 1)), 
		"wbt": bool(r.get("wbt", true)), "sweat": bool(r.get("sweat", true)), 
		"cpu": int(st.get("cpu", 1))})
	rules.editable = editable
	var tell: = String(st.get("tell", ""))
	_tell.text = tell
	_tell.visible = tell != ""
	spectate_btn.visible = online and can_join and my_side != 0
	shuffle_btn.visible = bool(st.get("shuffle", false))
	invite_btn.visible = bool(st.get("invite", false))
	var can_start: = bool(st.get("can_start", true))
	start_btn.visible = can_start
	var specs: Array = st.get("spectators", [])
	_spec.text = "spectating: " + ", ".join(specs)
	_spec.visible = online and not specs.is_empty() and tell == ""
	var hint: = String(st.get("hint", ""))
	_wait.text = hint
	_wait.visible = hint != "" and not can_start
