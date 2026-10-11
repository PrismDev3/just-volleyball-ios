class_name ChatPanel
extends PanelContainer


















const MIN_SIZE: = Vector2(240, 130)
const MAX_SIZE: = Vector2(640, 420)
const SPEC_COLOR: = Color(0.72, 0.72, 0.78)
const TEAM_PREFIX_COLOR: = Color(0.65, 0.85, 1.0)
const DEV_COLOR: = Color(1.0, 0.8, 0.2)
const FRIEND_COLOR: = Color(0.82, 0.86, 0.94)

var _log: RichTextLabel = null
var _input: LineEdit = null
var _team_btn: Button = null
var _all_btn: Button = null
var _fold_btn: Button = null
var _unread_lbl: Label = null
var _body: VBoxContainer = null
var _grip: Control = null
var _channel: = "all"
var _hidden: = false
var _base_left: = 12.0
var _dragging: = false
var _drag_from: = Vector2.ZERO
var _size_from: = Vector2.ZERO
var _slide: Tween = null
var _count_lbl: Label = null
var _typing_lbl: Label = null
var _keys_lbl: Label = null
var _key_sfx: AudioStreamPlayer = null
var _typing_ping: = 0.0




const SPAM_THRESHOLD: = 5
const SPAM_WINDOW: = 2.0
const SPAM_COOLDOWN: = 5.0
const REPEAT_WINDOW: = 10.0
var _sent_times: Array = []
var _cooldown_until: = 0.0
var _last_sent: = ""
var _last_sent_at: = 0.0

func _ready() -> void :


	visible = _wanted()
	Net.session_ended.connect( func(_r): visible = false)
	_base_left = offset_left




	var style: = StyleBoxEmpty.new()
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 8.0
	add_theme_stylebox_override("panel", style)
	custom_minimum_size = Vector2(
		clampf(GameConfig.chat_w, MIN_SIZE.x, MAX_SIZE.x), 
		clampf(GameConfig.chat_h, MIN_SIZE.y, MAX_SIZE.y))
	var root: = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	add_child(root)

	var head: = HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	root.add_child(head)
	_team_btn = _chip("team")
	_all_btn = _chip("all")
	head.add_child(_team_btn)
	head.add_child(_all_btn)
	_team_btn.pressed.connect( func(): _set_channel("team"))
	_all_btn.pressed.connect( func(): _set_channel("all"))
	_unread_lbl = Label.new()
	UiStyle.style_pill(_unread_lbl, UiStyle.PRIMARY, UiStyle.INK, 11)
	_unread_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_unread_lbl.visible = false
	head.add_child(_unread_lbl)
	var spacer: = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)

	var grip_tex: = TextureRect.new()
	grip_tex.texture = UiStyle.icon("larger", true)
	grip_tex.custom_minimum_size = Vector2(16, 16)
	grip_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grip_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	grip_tex.modulate = Color(1, 1, 1, 0.55)
	grip_tex.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grip_tex.mouse_entered.connect( func(): grip_tex.modulate = Color.WHITE)
	grip_tex.mouse_exited.connect( func(): grip_tex.modulate = Color(1, 1, 1, 0.55))
	_grip = grip_tex
	_grip.tooltip_text = "drag to resize the chat"
	_grip.mouse_filter = Control.MOUSE_FILTER_STOP
	_grip.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	_grip.gui_input.connect(_on_grip)
	head.add_child(_grip)
	_fold_btn = _chip("hide")
	_fold_btn.tooltip_text = "hide the chat (%s)" % _hide_key_name()
	_fold_btn.pressed.connect( func(): _set_hidden(true))
	head.add_child(_fold_btn)

	_body = VBoxContainer.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 4)
	root.add_child(_body)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true



	_log.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log.custom_minimum_size.x = 0
	_log.selection_enabled = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_override("normal_font", UiStyle.font(UiStyle.FONT_SEMI))
	_log.add_theme_font_override("bold_font", UiStyle.font(UiStyle.FONT_XBOLD))
	_log.add_theme_font_size_override("normal_font_size", 15)
	_log.add_theme_font_size_override("bold_font_size", 15)
	_log.add_theme_constant_override("line_separation", 4)
	_log.add_theme_color_override("default_color", Color(1, 1, 1, 0.95))
	_outline_text(_log)
	_body.add_child(_log)



	var lsb: = _log.get_v_scroll_bar()
	if lsb != null:
		lsb.add_theme_stylebox_override("scroll", StyleBoxEmpty.new())
		for st in [["grabber", 0.22], ["grabber_highlight", 0.45], ["grabber_pressed", 0.55]]:
			var g: = StyleBoxFlat.new()
			g.bg_color = Color(1, 1, 1, float(st[1]))
			g.set_corner_radius_all(3)
			lsb.add_theme_stylebox_override(String(st[0]), g)
		lsb.custom_minimum_size.x = 4

	_typing_lbl = Label.new()
	_typing_lbl.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	_typing_lbl.add_theme_font_size_override("font_size", 11)
	_typing_lbl.add_theme_color_override("font_color", Color.BLACK)
	_typing_lbl.visible = false
	_body.add_child(_typing_lbl)


	_keys_lbl = Label.new()
	_keys_lbl.text = "shift + enter switch channel | %s to hide" % _hide_key_name()
	_keys_lbl.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	_keys_lbl.add_theme_font_size_override("font_size", 11)
	_keys_lbl.add_theme_color_override("font_color", Color.BLACK)
	_keys_lbl.clip_text = true
	_body.add_child(_keys_lbl)
	var in_row: = HBoxContainer.new()
	in_row.add_theme_constant_override("separation", 6)
	_body.add_child(in_row)

	_count_lbl = Label.new()
	_count_lbl.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	_count_lbl.add_theme_font_size_override("font_size", 11)
	_count_lbl.add_theme_color_override("font_color", Color.BLACK)
	_count_lbl.visible = false


	_key_sfx = AudioStreamPlayer.new()
	_key_sfx.stream = load("res://game/sfx/Ui/keyboard_click.wav")
	_key_sfx.volume_db = -26.0
	if AudioServer.get_bus_index("sfx") >= 0:
		_key_sfx.bus = "sfx"
	add_child(_key_sfx)
	_input = LineEdit.new()
	_input.placeholder_text = "press enter to chat"
	_input.max_length = Net.CHAT_MAX_LEN
	_input.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_SEMI))
	_input.add_theme_font_size_override("font_size", 14)

	for st in ["normal", "focus", "read_only"]:
		var ib: = StyleBoxFlat.new()
		ib.bg_color = Color(1, 1, 1, 0.22 if st == "focus" else 0.13)
		ib.set_corner_radius_all(99)
		ib.content_margin_left = 12.0
		ib.content_margin_right = 12.0
		ib.content_margin_top = 5.0
		ib.content_margin_bottom = 5.0
		if st == "focus":
			ib.set_border_width_all(2)
			ib.border_color = UiStyle.PRIMARY
		_input.add_theme_stylebox_override(st, ib)
	_input.add_theme_color_override("font_color", Color.WHITE)


	_input.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_input.add_theme_constant_override("outline_size", 4)
	_input.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.5))
	_input.add_theme_color_override("caret_color", UiStyle.PRIMARY)
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.text_submitted.connect(_send)
	_input.gui_input.connect(_on_input_key)
	_input.text_changed.connect( func(t: String):
		_count_lbl.text = "%d/%d" % [t.length(), Net.CHAT_MAX_LEN]


		if t != "" and _key_sfx != null:
			_key_sfx.play())
	_input.focus_entered.connect( func():
		_count_lbl.visible = true
		_count_lbl.text = "%d/%d" % [_input.text.length(), Net.CHAT_MAX_LEN]
		Net.set_typing(true))
	_input.focus_exited.connect( func():
		_count_lbl.visible = false
		Net.set_typing(false))
	in_row.add_child(_input)
	in_row.add_child(_count_lbl)
	Net.typing_changed.connect(_on_typing)
	_set_channel("all")
	if GameConfig.chat_collapsed:
		_set_hidden(true, true)


	Net.chat.connect(_on_chat)


func _hide_key_name() -> String:
	for ev in InputMap.action_get_events("chat_toggle"):
		if ev is InputEventKey:
			var k: = ev as InputEventKey
			var code: = k.physical_keycode if k.physical_keycode != KEY_NONE else k.keycode
			if OS.has_feature("web"):
				# Godot's web display server has no physical->layout keycode mapping;
				# the physical name is the QWERTY label, which is what we want anyway.
				return OS.get_keycode_string(code).to_lower()
			return OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(code)).to_lower()
	return "t"

func _chip(text: String) -> Button:
	var b: = Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	b.add_theme_font_size_override("font_size", 12)
	_chip_style(b, false)
	return b



func _chip_style(b: Button, on: bool) -> void :
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb: = StyleBoxFlat.new()
		if on:
			sb.bg_color = UiStyle.PRIMARY if st != "hover" else UiStyle.PRIMARY.lightened(0.08)
		else:
			sb.bg_color = Color(1, 1, 1, 0.12 if st != "hover" else 0.2)
		sb.set_corner_radius_all(99)
		sb.content_margin_left = 10.0
		sb.content_margin_right = 10.0
		sb.content_margin_top = 2.0
		sb.content_margin_bottom = 2.0
		b.add_theme_stylebox_override(st, sb)
	var fc: = UiStyle.INK if on else Color.WHITE
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", 
			"font_hover_pressed_color"]:
		b.add_theme_color_override(st, fc)





func _outline_text(c: Control) -> void :
	c.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	c.add_theme_constant_override("outline_size", 5)

func is_typing() -> bool:
	return visible and not _hidden and _input != null and _input.has_focus()

func _on_typing(names: Array) -> void :

	var others: = names.filter( func(n): return String(n) != Net.my_name)
	if others.is_empty():
		_typing_lbl.visible = false
		_keys_lbl.visible = true
	else:
		_typing_lbl.visible = true
		_keys_lbl.visible = false
		_typing_lbl.text = ("%s is typing..." % others[0]) if others.size() == 1\
		else "several people are typing..."



func _wanted() -> bool:



	return Net.active and GameConfig.chat_enabled\
	and not (Net.quick_queue and not Net.in_match and not Net.party)

func _process(_delta: float) -> void :


	var want: = _wanted()
	if visible != want:
		visible = want







	if _hidden and (_slide == null or not _slide.is_valid()):
		var ax: = _away_x()
		if not is_equal_approx(offset_transform_position.x, ax):
			offset_transform_enabled = true
			offset_transform_position.x = ax
		if mouse_filter != Control.MOUSE_FILTER_IGNORE:
			mouse_filter = Control.MOUSE_FILTER_IGNORE


	if is_typing():
		_typing_ping += _delta
		if _typing_ping > 2.0:
			_typing_ping = 0.0
			Net.set_typing(true)

func _set_channel(ch: String) -> void :
	_channel = ch
	_chip_style(_team_btn, ch == "team")
	_chip_style(_all_btn, ch == "all")
	_input.placeholder_text = "to your team..." if ch == "team"\
	else "press enter to chat"


	if _log != null:
		_log.clear()
		_queue.clear()
		_rebuild_gen += 1
		for entry in Net.chat_log:
			if _shows(entry):
				_append(entry)



var _queue: Array = []
var _draining: = false
var _rebuild_gen: = 0

func _drain() -> void :
	if _draining:
		return
	_draining = true
	var gen: = _rebuild_gen
	while not _queue.is_empty():
		var entry: Dictionary = _queue.pop_front()
		var tex: ImageTexture = null
		var cfg: Variant = _sender_cfg(entry)
		if cfg is Dictionary and not (cfg as Dictionary).is_empty():
			tex = await CharacterPortrait.head_cached(cfg, self, "lobby")
		if not is_instance_valid(self) or _log == null:
			return
		if gen != _rebuild_gen:
			break
		if tex != null:
			_log.add_image(tex, 28, 28)
			_log.add_text(" ")
		_log.append_text(format_entry(entry) + "\n")
	_draining = false


func _sender_cfg(entry: Dictionary) -> Variant:
	if not entry.has("p"):
		return null
	var p: = int(entry.p)
	var me: = 1 if Net.is_host else (multiplayer.get_unique_id() if multiplayer != null and multiplayer.multiplayer_peer != null else 0)
	if p == me and GameConfig.character != null:
		return GameConfig.character.to_dict()
	var row: Variant = Net.players.get(p, null)
	if row is Dictionary:
		return (row as Dictionary).get("cfg", null)
	return null

func _shows(entry: Dictionary) -> bool:
	return _channel == "all" or String(entry.get("ch", "all")) == "team"







func _away_x() -> float:
	var vp: = get_viewport_rect().size
	var on_right: = global_position.x + size.x * 0.5 > vp.x * 0.5
	var travel: = maxf(size.x, custom_minimum_size.x) + _base_left + 40.0
	return travel if on_right else - travel






func unfold() -> void :
	_set_hidden(false)

func _set_hidden(h: bool, instant: = false) -> void :
	if h == _hidden:
		return
	_hidden = h
	if _input.has_focus():
		_input.release_focus()




	var to: = _away_x() if h else 0.0
	offset_transform_enabled = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE if h else Control.MOUSE_FILTER_STOP
	if _slide != null and _slide.is_valid():
		_slide.kill()
	if instant:
		offset_transform_position.x = to
	else:
		_slide = create_tween()
		_slide.set_ignore_time_scale(true)
		_slide.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_slide.tween_property(self, "offset_transform_position:x", to, 0.22)
	GameConfig.chat_collapsed = _hidden
	GameConfig.save_settings()

func _on_grip(event: InputEvent) -> void :

	if event is InputEventMouseButton\
	and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_dragging = (event as InputEventMouseButton).pressed
		_drag_from = get_global_mouse_position()
		_size_from = custom_minimum_size
		if not _dragging:
			GameConfig.chat_w = custom_minimum_size.x
			GameConfig.chat_h = custom_minimum_size.y
			GameConfig.save_settings()
	elif _dragging and event is InputEventMouseMotion:
		var d: = get_global_mouse_position() - _drag_from
		custom_minimum_size = Vector2(
			clampf(_size_from.x + d.x, MIN_SIZE.x, MAX_SIZE.x), 
			clampf(_size_from.y - d.y, MIN_SIZE.y, MAX_SIZE.y))

func _unhandled_key_input(event: InputEvent) -> void :







	var k: = event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if not visible or is_typing():
		return
	if event.is_action_pressed("chat_toggle"):
		_set_hidden( not _hidden)
		get_viewport().set_input_as_handled()
		return
	if _hidden:
		return
	if k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
		if k.shift_pressed:
			_set_channel("team" if _channel == "all" else "all")
		_input.grab_focus()
		get_viewport().set_input_as_handled()
	elif k.keycode == KEY_SLASH:
		_input.grab_focus()
		get_viewport().set_input_as_handled()

func _on_input_key(event: InputEvent) -> void :
	var k: = event as InputEventKey
	if k == null or not k.pressed:
		return

	if k.keycode == KEY_ESCAPE:
		_input.release_focus()
		_input.accept_event()

	elif (k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER) and k.shift_pressed:
		_set_channel("team" if _channel == "all" else "all")
		_input.accept_event()

func _send(text: String) -> void :
	_input.clear()

	_input.release_focus()
	Net.set_typing(false)
	var now: = Time.get_ticks_msec() / 1000.0
	var clean: = text.strip_edges()
	if clean == "":
		return
	if now < _cooldown_until:
		_system("slow down, %d seconds" % int(ceil(_cooldown_until - now)))
		return
	if clean == _last_sent and now - _last_sent_at < REPEAT_WINDOW:
		_system("you just said that")
		return
	_sent_times = _sent_times.filter( func(t): return now - float(t) < SPAM_WINDOW)
	_sent_times.append(now)
	if _sent_times.size() >= SPAM_THRESHOLD:
		_cooldown_until = now + SPAM_COOLDOWN
		_sent_times.clear()
		_system("sending too fast, chat paused for %d seconds" % int(SPAM_COOLDOWN))
		return
	_last_sent = clean
	_last_sent_at = now
	Net.send_chat(_channel, text)


func _system(text: String) -> void :
	_log.append_text("[color=#%s][i]%s[/i][/color]\n" % [SPEC_COLOR.to_html(false), text])

func _on_chat(entry: Dictionary) -> void :
	_append(entry)

func _append(entry: Dictionary) -> void :
	if _shows(entry):
		_queue.append(entry)
		_drain()



static func format_entry(entry: Dictionary) -> String:
	var side: = int(entry.get("s", 0))
	var color: Color = Rules.side_color(side) if side != 0 else SPEC_COLOR

	var tier: = int(entry.get("d", 0))
	if tier == DevBadge.Tier.GOLD:
		color = DEV_COLOR
	elif tier == DevBadge.Tier.SILVER:
		color = FRIEND_COLOR
	var name: = String(entry.get("n", "player"))
	var msg: = String(entry.get("m", ""))


	if GameConfig.chat_filter:
		msg = ChatFilter.clean(msg)
	var line: = ""
	if String(entry.get("ch", "all")) == "team":
		line += "[color=#%s](team)[/color] " % TEAM_PREFIX_COLOR.to_html(false)
	line += "[color=#%s][b]%s[/b][/color]: %s" % [color.to_html(false), name, msg]
	return line
