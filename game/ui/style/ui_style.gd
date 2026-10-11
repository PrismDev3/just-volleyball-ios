class_name UiStyle


















const PRIMARY: = Color("ffd23f")
const SECONDARY: = Color("2e78ff")
const INK: = Color("232b3b")
const NEUTRAL: = Color("f2f4fb")
const CARD: = Color("ffffff")
const SUCCESS: = Color("4ccb7a")
const HIGHLIGHT: = Color("ff7ea8")
const MUTED: = Color("8b93a7")

const RADIUS: = 14
const RADIUS_SOFT: = 22
const EDGE: = 4

const FONT_BLACK: = "res://game/fonts/Nunito/Nunito-Black.ttf"
const FONT_XBOLD: = "res://game/fonts/Nunito/Nunito-ExtraBold.ttf"
const FONT_SEMI: = "res://game/fonts/Nunito/Nunito-SemiBold.ttf"

static func font(path: String) -> FontFile:
	return load(path) as FontFile






static var dark: = false

static func bg() -> Color:
	return Color("0c0c0e") if dark else NEUTRAL

static func card() -> Color:
	return Color("1a1a1d") if dark else CARD

static func text() -> Color:
	return Color("f4f4f6") if dark else INK

static func muted() -> Color:
	return Color("9b9ba3") if dark else MUTED

const _AUTO: = Color(0, 0, 0, 0)




static func card_box(fill: = _AUTO, radius: = RADIUS) -> StyleBoxFlat:
	var b: = StyleBoxFlat.new()
	b.bg_color = card() if fill == _AUTO else fill
	b.set_corner_radius_all(radius)
	b.shadow_color = Color(0, 0, 0, 0.3) if dark else Color(INK, 0.1)
	b.shadow_size = 8
	b.shadow_offset = Vector2(0, 3)
	b.set_content_margin_all(14)
	return b

static func style_panel(p: Control, fill: = _AUTO, radius: = RADIUS) -> void :
	p.add_theme_stylebox_override("panel", card_box(fill, radius))






static func _slab(fill: Color, edge: Color, pressed: bool, 
		radius: = RADIUS) -> StyleBoxFlat:
	var b: = StyleBoxFlat.new()
	b.bg_color = fill
	b.set_corner_radius_all(radius)
	b.border_width_bottom = 0 if pressed else EDGE
	b.border_color = edge
	b.content_margin_left = 18.0
	b.content_margin_right = 18.0
	b.content_margin_top = 8.0 + (EDGE if pressed else 0)
	b.content_margin_bottom = 8.0 + (0 if pressed else EDGE * 0.25)

	if fill.a > 0.0:
		b.shadow_color = Color(0, 0, 0, 0.28) if dark else Color(INK, 0.14)
		b.shadow_size = 2 if pressed else 5
		b.shadow_offset = Vector2(0, 1 if pressed else 2)
	return b

const RED: = Color("e5484d")








static func round_slab(fill: Color, pressed: bool, radius: float) -> StyleBoxFlat:
	var b: = StyleBoxFlat.new()
	b.bg_color = fill if not pressed else fill.darkened(0.06)
	b.set_corner_radius_all(int(round(radius)))
	b.border_width_bottom = 0 if pressed else EDGE
	b.border_color = fill.darkened(0.22)
	b.content_margin_left = 8.0
	b.content_margin_right = 8.0
	b.content_margin_top = 4.0 + (EDGE if pressed else 0)
	b.content_margin_bottom = 4.0
	b.shadow_color = Color(0, 0, 0, 0.4) if dark else Color(INK, 0.22)
	b.shadow_size = 2 if pressed else 7
	b.shadow_offset = Vector2(0, 1 if pressed else 3)
	return b











static func disc_box(fill: Color, rim: = _AUTO, rim_width: = 0, 
		radius: = 0.0) -> StyleBoxFlat:
	var b: = StyleBoxFlat.new()
	b.bg_color = fill
	b.set_corner_radius_all(int(round(radius)))
	if rim != _AUTO and rim_width > 0:
		b.set_border_width_all(rim_width)
		b.border_color = rim
	return b








static func ink_plate(radius: = 8) -> StyleBoxFlat:
	var b: = StyleBoxFlat.new()
	b.bg_color = Color("141a26") if dark else INK
	b.set_corner_radius_all(radius)
	b.set_content_margin_all(5.0)
	b.border_color = Color(1, 1, 1, 0.08)
	b.set_border_width_all(1)
	return b









static func outlined_label(l: Label, font_size: = 13, 
		color: = Color.WHITE) -> void :
	l.add_theme_font_override("font", font(FONT_XBOLD))
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 5)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))










static func paint_button(btn: Button, fill: Color, held: bool, 
		radius: float, font_size: int = 0) -> void :
	btn.add_theme_stylebox_override("normal", round_slab(fill, held, radius))
	btn.add_theme_stylebox_override("hover", round_slab(fill.lightened(0.08), held, radius))
	btn.add_theme_stylebox_override("pressed", round_slab(fill, true, radius))
	btn.add_theme_stylebox_override("focus", round_slab(fill, held, radius))
	btn.add_theme_stylebox_override("disabled", round_slab(Color(muted(), 0.22), true, radius))
	var text_c: = INK
	if fill.get_luminance() < 0.5:
		text_c = Color.WHITE
	for state in ["font_color", "font_hover_color", "font_pressed_color", 
		"font_hover_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(state, text_c)
	btn.add_theme_font_override("font", font(FONT_BLACK))
	if font_size > 0:
		btn.add_theme_font_size_override("font_size", font_size)











static func button_colors() -> Dictionary:
	return {
		"primary": PRIMARY, 
		"card": card(), 
		"secondary": SECONDARY, 
		"danger": HIGHLIGHT, 
		"exit": RED, 
		"ghost": Color(muted(), 0.55), 
	}





static func style_button(btn: Button, kind: = "primary", 
		font_size: = 20) -> void :
	var fill: = PRIMARY
	var text_c: = INK
	match kind:
		"secondary":
			fill = card()
			text_c = SECONDARY.lightened(0.25) if dark else SECONDARY
		"tertiary":
			fill = Color(0, 0, 0, 0)
			text_c = muted()
		"danger":
			fill = HIGHLIGHT
			text_c = Color.WHITE
		"exit":
			fill = RED
			text_c = Color.WHITE
	var edge: = fill.darkened(0.22)
	if kind == "tertiary":
		edge = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", _slab(fill, edge, false))
	btn.add_theme_stylebox_override("hover", 
		_slab(fill.lightened(0.08), edge, false))
	btn.add_theme_stylebox_override("pressed", 
		_slab(fill.darkened(0.06), edge, true))



	var focus: = _slab(fill.lightened(0.08), edge, false)
	focus.set_border_width_all(4)
	focus.border_color = SECONDARY
	focus.shadow_color = Color(SECONDARY, 0.55)
	focus.shadow_size = 10
	focus.shadow_offset = Vector2.ZERO
	btn.add_theme_stylebox_override("focus", focus)

	var dis: = _slab(Color(muted(), 0.22), Color(0, 0, 0, 0), true)
	dis.shadow_size = 0
	btn.add_theme_stylebox_override("disabled", dis)
	btn.add_theme_color_override("font_disabled_color", Color(muted(), 0.85))
	if kind == "tertiary":
		btn.add_theme_stylebox_override("hover", _slab(
			Color(text(), 0.06), Color(0, 0, 0, 0), false))
	btn.add_theme_font_override("font", font(FONT_XBOLD))
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", text_c)
	btn.add_theme_color_override("font_hover_color", text_c)
	btn.add_theme_color_override("font_pressed_color", text_c.darkened(0.1))
	btn.add_theme_color_override("font_hover_pressed_color", text_c)
	btn.add_theme_color_override("font_focus_color", text_c)
	var bounce: = press_bounce.bind(btn)
	if not btn.pressed.is_connected(bounce):
		btn.pressed.connect(bounce)

	if kind == "primary" or kind == "danger" or kind == "exit":
		var burst: = _burst_self.bind(btn, fill.lightened(0.25))
		if not btn.pressed.is_connected(burst):
			btn.pressed.connect(burst)


	var role: = "confirm" if kind == "primary"\
	else ("back" if kind in ["danger", "exit"] else "press")


	for r in ["press", "confirm", "back"]:
		var old: = sfx.bind(r)
		if r != role and btn.pressed.is_connected(old):
			btn.pressed.disconnect(old)
	var snd: = sfx.bind(role)
	if not btn.pressed.is_connected(snd):
		btn.pressed.connect(snd)
	hover_sound(btn)

static func _burst_self(btn: Button, color: Color) -> void :
	click_burst(btn, color)




static func style_pill(l: Label, bg_c: = PRIMARY, text_c: = _AUTO, 
		font_size: = 14) -> void :
	var b: = StyleBoxFlat.new()
	b.bg_color = bg_c
	b.set_corner_radius_all(99)
	b.content_margin_left = 12.0
	b.content_margin_right = 12.0
	b.content_margin_top = 3.0
	b.content_margin_bottom = 3.0
	b.shadow_color = Color(0, 0, 0, 0.22) if dark else Color(INK, 0.1)
	b.shadow_size = 4
	b.shadow_offset = Vector2(0, 2)
	l.add_theme_stylebox_override("normal", b)
	l.add_theme_font_override("font", font(FONT_XBOLD))
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", 
		INK if text_c == _AUTO else text_c)




static func style_label(l: Label, role: = "body", color: = _AUTO) -> void :
	var c: = color
	match role:
		"shout":
			l.add_theme_font_override("font", font(FONT_BLACK))
			l.add_theme_font_size_override("font_size", 34)
		"title":
			l.add_theme_font_override("font", font(FONT_XBOLD))
			l.add_theme_font_size_override("font_size", 24)
		"small":
			l.add_theme_font_override("font", font(FONT_SEMI))
			l.add_theme_font_size_override("font_size", 13)
			if c == _AUTO:
				c = muted()
		_:
			l.add_theme_font_override("font", font(FONT_SEMI))
			l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", text() if c == _AUTO else c)





static func icon(name: String, force_white: = false, force_black: = false) -> Texture2D:
	var shade: = "Black" if force_black else ("White" if (force_white or dark) else "Black")
	return load("res://game/ui_icon/Game Icons/PNG/%s/2x/%s.png"
		%[shade, name]) as Texture2D






static func _disc_tex(size_out: int, fill: Color, ring: = Color(0, 0, 0, 0), 
		ring_frac: = 0.0, hollow: = false, 
		glyph: Texture2D = null) -> Texture2D:


	var size: = size_out * 3
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = (size - 1) * 0.5
	var r_out: = size * 0.5 - 2.0
	var r_in: = r_out * (1.0 - ring_frac)
	for y in size:
		for x in size:
			var d: = Vector2(x - c, y - c).length()
			var a_out: = clampf(r_out - d + 0.5, 0.0, 1.0)
			if a_out <= 0.0:
				continue
			var col: Color
			if ring_frac > 0.0 and d >= r_in:
				col = ring
			elif hollow:
				continue
			else:
				col = fill
				if ring_frac > 0.0:

					var t_in: = clampf(d - r_in + 0.5, 0.0, 1.0)
					col = fill.lerp(ring, t_in)
			col.a *= a_out
			img.set_pixel(x, y, col)
	if glyph != null:
		var g: = glyph.get_image()
		g.convert(Image.FORMAT_RGBA8)
		var gs: = int(size * 0.58)
		g.resize(gs, gs, Image.INTERPOLATE_LANCZOS)
		img.blend_rect(g, Rect2i(0, 0, gs, gs), 
			Vector2i((size - gs) / 2, (size - gs) / 2))
	img.resize(size_out, size_out, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)

static func _dot(color: Color, size: = 26) -> Texture2D:
	return _disc_tex(size, color)


static func _knob(size: = 26) -> Texture2D:
	var core: = card() if dark else Color.WHITE
	var ring: = Color("121214") if dark else INK
	return _disc_tex(size, core, ring, 0.22)

static func _track(color: Color) -> StyleBoxFlat:
	var b: = StyleBoxFlat.new()
	b.bg_color = color
	b.set_corner_radius_all(99)
	return b

static func style_slider(s: Slider) -> void :
	var track: = _track(Color(muted(), 0.3))
	track.content_margin_top = 3.0
	track.content_margin_bottom = 3.0
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", _track(SECONDARY))
	s.add_theme_stylebox_override("grabber_area_highlight", 
		_track(SECONDARY.lightened(0.12)))
	s.add_theme_icon_override("grabber", _knob())
	s.add_theme_icon_override("grabber_highlight", _knob(30))
	s.add_theme_icon_override("grabber_disabled", 
		_dot(Color(muted(), 0.5)))
	var tick: = _drag_tick
	if not s.drag_ended.is_connected(tick):
		s.drag_ended.connect(tick)

	var slide: = _slide_sfx
	if not s.value_changed.is_connected(slide):
		s.value_changed.connect(slide)

static func _drag_tick(_changed: bool) -> void :
	sfx("tick")

static var _slide_ms: = 0

static func _slide_sfx(_v: float) -> void :
	var now: = Time.get_ticks_msec()
	if now - _slide_ms < 45:
		return
	_slide_ms = now
	sfx("slide")

static func style_check(cb: CheckBox) -> void :




	var blank: = _disc_tex(2, Color(0, 0, 0, 0))
	for n in ["checked", "unchecked", "checked_disabled", 
		"unchecked_disabled", "radio_checked", "radio_unchecked"]:
		cb.add_theme_icon_override(n, blank)
	cb.icon = _check_disc(cb.button_pressed)
	cb.add_theme_constant_override("icon_max_width", 24)
	cb.add_theme_font_override("font", font(FONT_SEMI))
	cb.add_theme_font_size_override("font_size", 16)



	for state in ["font_color", "font_hover_color", "font_pressed_color", 
		"font_hover_pressed_color", "font_focus_color"]:
		cb.add_theme_color_override(state, text())


	var focus: = StyleBoxFlat.new()
	focus.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	focus.set_border_width_all(2)
	focus.border_color = HIGHLIGHT
	focus.set_corner_radius_all(RADIUS_SOFT)
	focus.set_content_margin_all(4.0)
	cb.add_theme_stylebox_override("focus", focus)
	var bounce: = press_bounce.bind(cb)
	if not cb.pressed.is_connected(bounce):
		cb.pressed.connect(bounce)
	var ts: = _check_swap.bind(cb)
	if not cb.toggled.is_connected(ts):
		cb.toggled.connect(ts)

static func _check_swap(on: bool, cb: CheckBox) -> void :
	cb.icon = _check_disc(on)
	sfx("toggle_on" if on else "toggle_off")







static func set_check(cb: CheckBox, on: bool) -> void :
	cb.set_pressed_no_signal(on)
	cb.icon = _check_disc(on)

static func _check_disc(on: bool) -> Texture2D:

	if on:

		return _disc_tex(72, SUCCESS, SUCCESS.darkened(0.25), 0.14, 
			false, icon("checkmark", true))
	return _disc_tex(72, Color(0, 0, 0, 0), Color(muted(), 0.9), 0.16, true)

static func style_line_edit(le: LineEdit) -> void :
	var box: = StyleBoxFlat.new()


	box.bg_color = Color("1d2434") if dark else Color(MUTED, 0.14)
	box.border_color = Color(muted(), 0.45)
	box.set_border_width_all(1)
	box.set_corner_radius_all(RADIUS)
	box.set_content_margin_all(10)
	box.content_margin_left = 14.0
	box.content_margin_right = 14.0
	le.add_theme_stylebox_override("normal", box)
	var focused: StyleBoxFlat = box.duplicate()
	focused.border_width_bottom = 2
	focused.border_width_top = 2
	focused.border_width_left = 2
	focused.border_width_right = 2
	focused.border_color = SECONDARY
	le.add_theme_stylebox_override("focus", focused)
	le.add_theme_font_override("font", font(FONT_SEMI))
	le.add_theme_font_size_override("font_size", 16)
	le.add_theme_color_override("font_color", text())
	le.add_theme_color_override("font_placeholder_color", muted())
	le.add_theme_color_override("caret_color", SECONDARY)



static func style_option(ob: OptionButton) -> void :
	style_button(ob, "secondary", 16)
	var pop: = ob.get_popup()
	pop.transparent_bg = true
	pop.add_theme_stylebox_override("panel", card_box())
	var hover: = StyleBoxFlat.new()
	hover.bg_color = Color(SECONDARY, 0.3 if dark else 0.14)
	hover.set_corner_radius_all(10)
	hover.content_margin_left = 10.0
	hover.content_margin_right = 10.0
	pop.add_theme_stylebox_override("hover", hover)
	pop.add_theme_font_override("font", font(FONT_SEMI))
	pop.add_theme_font_size_override("font_size", 16)
	pop.add_theme_color_override("font_color", text())
	pop.add_theme_color_override("font_hover_color", text())
	pop.add_theme_constant_override("v_separation", 6)


	var blank: = _disc_tex(2, Color(0, 0, 0, 0))
	for n in ["radio_checked", "radio_unchecked", "checked", "unchecked"]:
		pop.add_theme_icon_override(n, blank)

static func style_spin(sb: SpinBox) -> void :
	style_line_edit(sb.get_line_edit())



	var arrow_up: = _sized_icon("arrowUp", 18)
	var arrow_down: = _sized_icon("arrowDown", 18)
	for state in ["", "_hover", "_pressed", "_disabled"]:
		sb.add_theme_icon_override("up%s" % state, arrow_up)
		sb.add_theme_icon_override("down%s" % state, arrow_down)
	var quiet: = StyleBoxEmpty.new()
	var hov: = _track(Color(SECONDARY, 0.3 if dark else 0.14))
	hov.set_corner_radius_all(8)
	var prs: = _track(Color(SECONDARY, 0.45 if dark else 0.25))
	prs.set_corner_radius_all(8)
	for side in ["up", "down"]:
		sb.add_theme_stylebox_override("%s_background" % side, quiet)
		sb.add_theme_stylebox_override("%s_background_disabled" % side, quiet)
		sb.add_theme_stylebox_override("%s_background_hovered" % side, hov)
		sb.add_theme_stylebox_override("%s_background_pressed" % side, prs)


static func _sized_icon(name: String, px: int) -> Texture2D:
	var img: = icon(name).get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(px, px, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)

static func style_progress(pb: ProgressBar) -> void :
	pb.add_theme_stylebox_override("background", 
		_track(Color(muted(), 0.3)))
	pb.add_theme_stylebox_override("fill", _track(PRIMARY))
	pb.show_percentage = false
	pb.custom_minimum_size.y = 14

static func style_scroll(sb: ScrollBar) -> void :
	var rail: = StyleBoxEmpty.new()
	sb.add_theme_stylebox_override("scroll", rail)


	sb.add_theme_stylebox_override("grabber", _track(Color(SECONDARY, 0.65)))
	sb.add_theme_stylebox_override("grabber_highlight", _track(SECONDARY))
	sb.add_theme_stylebox_override("grabber_pressed", _track(SECONDARY))
	sb.custom_minimum_size.x = 8









const DEFAULT_PACK: = "res://game/ui/style/default_ui_sfx.tres"
static var pack: UiSfxPack = null
static var _sfx_pool: Array = []
static var _sfx_next: = 0
static var _sfx_last: = {}

static func sfx(role: String) -> void :
	var tree: = Engine.get_main_loop() as SceneTree
	if tree == null:
		return



	var now: = Time.get_ticks_msec()
	var min_gap: = 45 if role == "hover" else 80
	if now - int(_sfx_last.get(role, -9999)) < min_gap:
		return
	_sfx_last[role] = now
	if pack == null:
		if not ResourceLoader.exists(DEFAULT_PACK):
			return
		pack = load(DEFAULT_PACK) as UiSfxPack
		if pack == null:
			return
	var streams: = pack.streams(role)
	if streams.is_empty():
		return
	if _sfx_pool.is_empty() or not is_instance_valid(_sfx_pool[0]):
		_sfx_pool = []
		for i in 5:
			var p: = AudioStreamPlayer.new()
			p.bus = "Master"
			tree.root.add_child(p)
			_sfx_pool.append(p)
	var player: AudioStreamPlayer = _sfx_pool[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_pool.size()
	player.stream = streams[randi() % streams.size()]
	player.volume_db = pack.volume(role)
	player.pitch_scale = randf_range(0.97, 1.03)
	player.play()


static func hover_sound(c: Control) -> void :
	var h: = sfx.bind("hover")
	if not c.mouse_entered.is_connected(h):
		c.mouse_entered.connect(h)








static func style_tabs(tc: TabContainer) -> void :
	tc.add_theme_stylebox_override("panel", card_box())
	var sel: = StyleBoxFlat.new()
	sel.bg_color = PRIMARY
	sel.corner_radius_top_left = 10
	sel.corner_radius_top_right = 10
	sel.content_margin_left = 16.0
	sel.content_margin_right = 16.0
	sel.content_margin_top = 6.0
	sel.content_margin_bottom = 6.0
	tc.add_theme_stylebox_override("tab_selected", sel)
	var uns: StyleBoxFlat = sel.duplicate()
	uns.bg_color = Color(muted(), 0.16)
	tc.add_theme_stylebox_override("tab_unselected", uns)
	var hov: StyleBoxFlat = sel.duplicate()
	hov.bg_color = Color(muted(), 0.3)
	tc.add_theme_stylebox_override("tab_hovered", hov)
	tc.add_theme_font_override("font", font(FONT_XBOLD))
	tc.add_theme_font_size_override("font_size", 15)
	tc.add_theme_color_override("font_selected_color", INK)
	tc.add_theme_color_override("font_unselected_color", muted())
	tc.add_theme_color_override("font_hovered_color", text())

static func wash(root: Node) -> void :
	for c in root.find_children("*", "Control", true, false):
		if c is TabContainer:
			style_tabs(c)
		elif c is PanelContainer:
			style_panel(c)
		elif c is OptionButton:
			style_option(c)
		elif c is CheckBox:
			style_check(c)
		elif c is SpinBox:
			style_spin(c)
		elif c is Button:
			var b: = c as Button
			if b.has_meta("icon_button"):
				continue
			var size: = b.get_theme_font_size("font_size")
			style_button(b, "secondary", clampi(size, 14, 22))
		elif c is LineEdit:
			style_line_edit(c)
		elif c is HSlider or c is VSlider:
			style_slider(c)
		elif c is ProgressBar:
			style_progress(c)
		elif c is ScrollContainer:
			style_scroll((c as ScrollContainer).get_v_scroll_bar())
		elif c is Label:
			var l: = c as Label
			var keep: = l.get_theme_font_size("font_size")
			var col: Color = l.get_theme_color("font_color")
			l.add_theme_font_override("font", 
				font(FONT_XBOLD if keep >= 22 else FONT_SEMI))


			if col.is_equal_approx(Color.WHITE) or col.is_equal_approx(
				Color(0.875, 0.875, 0.875)):
				l.add_theme_color_override("font_color", text())





static func pop_in(c: Control, delay: = 0.0) -> void :
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2.ONE * 0.85
	c.modulate.a = 0.0
	var t: = c.create_tween().set_parallel(true)
	t.tween_property(c, "scale", Vector2.ONE, 0.28)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
	t.tween_property(c, "modulate:a", 1.0, 0.16).set_delay(delay)




static func stagger_reveal(box: Node, step: = 0.05, skip: = 0) -> void :
	var i: = 0
	for child in box.get_children():
		var c: = child as Control
		if c == null:
			continue
		if i < skip:
			i += 1
			continue
		c.offset_transform_enabled = true
		c.offset_transform_position.y = 30.0
		c.modulate.a = 0.0
		var d: = step * float(i - skip)
		var t: = c.create_tween().set_parallel(true)
		t.tween_property(c, "modulate:a", 1.0, 0.16).set_delay(d)
		t.tween_property(c, "offset_transform_position:y", 0.0, 0.32)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(d)

		t.tween_callback(sfx.bind("hover")).set_delay(d)
		i += 1

static func press_bounce(c: Control) -> void :



	c.offset_transform_enabled = true
	c.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
	var t: = c.create_tween()
	t.tween_property(c, "offset_transform_scale", Vector2(0.9, 0.85), 0.06)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "offset_transform_scale", Vector2.ONE, 0.24)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)




static func toast(title: String, body: String, accent: = SUCCESS, 
		icon_name: = "information") -> Control:
	var panel: = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", card_box())
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var disc: = TextureRect.new()
	disc.texture = _disc_tex(88, accent, accent.darkened(0.2), 0.1, 
		false, icon(icon_name, true))
	disc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	disc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	disc.custom_minimum_size = Vector2(44, 44)
	h.add_child(disc)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var t: = Label.new()
	t.text = title
	style_label(t, "title")
	t.add_theme_font_size_override("font_size", 17)
	var d: = Label.new()
	d.text = body
	style_label(d, "small")
	v.add_child(t)
	v.add_child(d)
	h.add_child(v)
	panel.add_child(h)
	return panel







static var active_dialog: CanvasLayer = null
static var _dialog_btns: Array = []
static var _dialog_cd: = 0.0

static func dialog_active() -> bool:
	return active_dialog != null and is_instance_valid(active_dialog)



static func drive_dialog(delta: float) -> void :
	_dialog_cd = maxf(_dialog_cd - delta, 0.0)
	var tree: = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	var vp: = tree.root
	if Input.is_action_just_pressed("ui_cancel"):
		sfx("close")
		active_dialog.queue_free()
		return
	if Input.is_action_just_pressed("ui_accept"):
		var foc: = vp.gui_get_focus_owner()
		if foc is BaseButton and not (foc as BaseButton).disabled:
			(foc as BaseButton).pressed.emit()
		return
	if _dialog_cd <= 0.0 and (Input.is_action_just_pressed("ui_left")\
	or Input.is_action_just_pressed("ui_right")):
		_dialog_cd = 0.18
		var foc: = vp.gui_get_focus_owner()
		var i: = _dialog_btns.find(foc)
		if i == -1:
			i = 0
		var other: Control = _dialog_btns[(i + 1) % _dialog_btns.size()]
		other.grab_focus()
		sfx("hover")

static func confirm(parent: Node, title: String, body: String, 
		on_yes: Callable, yes_text: = "yes", no_text: = "cancel", 
		yes_kind: = "danger", hold_seconds: = 0.0) -> void :



	var layer: = CanvasLayer.new()
	layer.layer = 95
	parent.add_child(layer)
	var scrim: = ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.45)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(scrim)
	var card: = PanelContainer.new()
	style_panel(card, _AUTO, RADIUS_SOFT)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	var t: = Label.new()
	t.text = title
	style_label(t, "title")
	v.add_child(t)
	if body != "":
		var d: = Label.new()
		d.text = body
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size.x = 300
		style_label(d, "body")
		v.add_child(d)
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var no: = Button.new()
	no.text = no_text
	style_button(no, "tertiary", 16)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(layer.queue_free)
	row.add_child(no)
	var yes: = Button.new()
	yes.text = yes_text
	style_button(yes, yes_kind, 16)
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect( func():
		layer.queue_free()
		on_yes.call())
	row.add_child(yes)
	if hold_seconds > 0.0:


		yes.disabled = true
		var start: = int(ceil(hold_seconds))
		yes.text = "%s (%d)" % [yes_text, start]
		var timer: = Timer.new()
		timer.wait_time = 1.0
		timer.set_meta("remain", start)
		layer.add_child(timer)
		timer.timeout.connect( func():
			var r: = int(timer.get_meta("remain")) - 1
			timer.set_meta("remain", r)
			if r <= 0:
				yes.disabled = false
				yes.text = yes_text
				timer.stop()
			else:
				yes.text = "%s (%d)" % [yes_text, r])
		timer.start()
	v.add_child(row)
	card.add_child(v)
	layer.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	scrim.gui_input.connect( func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			sfx("close")
			layer.queue_free())


	active_dialog = layer
	_dialog_btns = [no, yes]
	layer.tree_exiting.connect( func():
		if active_dialog == layer:
			active_dialog = null
			_dialog_btns = [])
	no.focus_neighbor_right = no.get_path_to(yes)
	yes.focus_neighbor_left = yes.get_path_to(no)
	no.grab_focus.call_deferred()
	sfx("open")

	(Engine.get_main_loop() as SceneTree).process_frame.connect(
		func(): pop_in(card), CONNECT_ONE_SHOT)



static func icon_disc(icon_name: String, fill: Color, px: = 52, 
		glyph_white: = true) -> Texture2D:
	return _disc_tex(px * 2, fill, fill.darkened(0.12), 0.06, false, 
		icon(icon_name, glyph_white))




static func icon_button(icon_name: String, kind: = "secondary", 
		px: = 42) -> Button:
	var b: = Button.new()
	style_button(b, kind, 16)
	b.icon = icon(icon_name, kind == "danger")
	b.expand_icon = true
	b.custom_minimum_size = Vector2(px, px)



	b.set_meta("icon_button", true)

	for state in ["normal", "hover", "pressed", "focus"]:
		var sb: = b.get_theme_stylebox(state) as StyleBoxFlat
		if sb != null:
			sb.content_margin_left = 9.0
			sb.content_margin_right = 9.0
	return b



static func reset_button(on_reset: Callable) -> Button:
	var b: = icon_button("return", "tertiary", 36)
	b.pressed.connect( func():
		click_burst(b, SECONDARY)
		on_reset.call())
	return b





static func click_burst(c: Control, color: = PRIMARY) -> void :
	var p: = CPUParticles2D.new()
	p.one_shot = true
	p.amount = 9
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.spread = 180.0
	p.direction = Vector2(0, -1)
	p.gravity = Vector2(0, 640)
	p.initial_velocity_min = 130.0
	p.initial_velocity_max = 240.0
	p.texture = _disc_tex(10, Color.WHITE)
	p.color = color
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.1
	c.add_child(p)
	p.position = c.get_local_mouse_position()\
	if Rect2(Vector2.ZERO, c.size).has_point(c.get_local_mouse_position())\
	else c.size * 0.5
	p.emitting = true
	p.finished.connect(p.queue_free)
