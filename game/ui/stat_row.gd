class_name StatRow
extends PanelContainer






const AVATAR: = 34.0
const ROW_H: = 46.0
const STAT_W: = 40.0
const NET_W: = 88.0
const SEP: = 5.0


const PING_HOST: = -1
const PING_CPU: = -2



const MS_GOOD: = 50.0
const MS_OK: = 90.0

const GOLD: = Color("ffcf3f")
const HOST_TEXT: = Color("c98a00")
const BLUE: = Color("2e78ff")

static var _portrait_cache: = {}

var _side: = 1
var _cfg_hash: = 0
var _portrait: TextureRect
var _frame: PanelContainer
var _name: Label
var _crown: Crown
var _you: PanelContainer
var _stat_labels: Array[Label] = []
var _bars: SignalBars
var _net_text: Label
var _net_crown: Crown



class Crown extends Control:
	var col: = Color("ffcf3f")
	func _init() -> void :
		custom_minimum_size = Vector2(20, 18)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void :
		var w: = size.x
		var h: = size.y
		var pts: = PackedVector2Array([
			Vector2(w * 0.1, h * 0.88), Vector2(w * 0.1, h * 0.3), 
			Vector2(w * 0.32, h * 0.56), Vector2(w * 0.5, h * 0.12), 
			Vector2(w * 0.68, h * 0.56), Vector2(w * 0.9, h * 0.3), 
			Vector2(w * 0.9, h * 0.88)])
		draw_colored_polygon(pts, col)
		var outline: = pts.duplicate()
		outline.append(pts[0])
		draw_polyline(outline, Color(0.62, 0.44, 0.0, 0.9), 1.5, true)


class SignalBars extends Control:
	var lit: = 0
	var col: = Color("4ccb7a")
	func _init() -> void :
		custom_minimum_size = Vector2(24, 18)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func set_ms(ms: float) -> void :
		if ms <= 25.0:
			lit = 4;col = Color("4ccb7a")
		elif ms <= StatRow.MS_GOOD:
			lit = 3;col = Color("4ccb7a")
		elif ms <= StatRow.MS_OK:
			lit = 2;col = Color("f2b636")
		else:
			lit = 1;col = Color("e5484d")
		queue_redraw()
	func _draw() -> void :
		var n: = 4
		var bw: = 4.0
		var gap: = 2.0
		var total: = n * bw + (n - 1) * gap
		var x: = (size.x - total) * 0.5
		for i in n:
			var frac: = float(i + 1) / float(n)
			var bh: = size.y * (0.4 + 0.6 * frac)
			var r: = Rect2(x, size.y - bh, bw, bh)
			var on: = i < lit
			draw_rect(r, col if on else Color(0.55, 0.6, 0.7, 0.28))
			x += bw + gap

func _ready() -> void :
	_build()

func _build() -> void :
	var box: = UiStyle.card_box(Color(UiStyle.card(), 0.98), 12)
	box.set_content_margin_all(4.0)
	box.content_margin_left = 8.0
	box.content_margin_right = 10.0
	box.shadow_size = 3
	box.shadow_offset = Vector2(0, 2)
	add_theme_stylebox_override("panel", box)
	custom_minimum_size.y = ROW_H
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var hb: = HBoxContainer.new()
	hb.add_theme_constant_override("separation", int(SEP))
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hb)



	var identity: = HBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.size_flags_vertical = Control.SIZE_FILL
	identity.add_theme_constant_override("separation", int(SEP))
	identity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(identity)

	_frame = PanelContainer.new()
	_frame.custom_minimum_size = Vector2(AVATAR, AVATAR)
	_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity.add_child(_frame)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_portrait)

	_name = _mk_label("player", 16, UiStyle.text(), UiStyle.FONT_XBOLD)
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_add_name_shadow(_name)
	identity.add_child(_name)

	_crown = Crown.new()
	_crown.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_crown.visible = false
	identity.add_child(_crown)

	_you = _make_you_badge()
	identity.add_child(_you)

	for _i in 6:
		var l: = _mk_label("0", 17, UiStyle.text(), UiStyle.FONT_XBOLD)
		l.custom_minimum_size.x = STAT_W
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hb.add_child(l)
		_stat_labels.append(l)


	var net: = HBoxContainer.new()
	net.custom_minimum_size.x = NET_W
	net.alignment = BoxContainer.ALIGNMENT_END
	net.add_theme_constant_override("separation", 5)
	net.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(net)
	_bars = SignalBars.new()
	_bars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	net.add_child(_bars)
	_net_crown = Crown.new()
	_net_crown.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_net_crown.visible = false
	net.add_child(_net_crown)
	_net_text = _mk_label("", 15, UiStyle.muted(), UiStyle.FONT_XBOLD)
	_net_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	net.add_child(_net_text)



func set_metrics(row_h: float, avatar: float) -> void :
	if _frame == null:
		_build()
	custom_minimum_size.y = row_h
	_frame.custom_minimum_size = Vector2(avatar, avatar)



func update(row: Dictionary, local_peer: int, networked: bool, local_ping: = -1) -> void :
	if _name == null:
		_build()
	_side = int(row.get("side", 1))
	var team: = Rules.side_color(_side)
	var peer: = int(row.get("peer", 0))
	var is_host: = networked and peer == 1
	var is_you: = peer == local_peer
	var is_cpu: = peer == 0

	_name.text = String(row.get("name", "player"))


	var name_col: = team.darkened(0.28) if not UiStyle.dark else team.lightened(0.15)
	_name.add_theme_color_override("font_color", name_col)
	var frame: = StyleBoxFlat.new()
	frame.bg_color = Color(UiStyle.muted(), 0.12)
	frame.border_color = Color(team, 0.75)
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(99)
	frame.set_content_margin_all(2.0)
	_frame.add_theme_stylebox_override("panel", frame)

	_crown.visible = is_host
	_you.visible = is_you

	var keys: = ["pts", "spk", "blk", "rcv", "set", "ast"]
	for i in 6:
		_stat_labels[i].text = str(int(row.get(keys[i], 0)))



	var ping: = local_ping if (networked and is_you) else int(row.get("ping", PING_CPU))
	if is_cpu:
		_bars.visible = false
		_net_crown.visible = false
		_net_text.text = "CPU"
		_net_text.add_theme_color_override("font_color", UiStyle.muted())
	elif is_host and ping <= 0:

		_bars.visible = false
		_net_crown.visible = true
		_net_text.text = "HOST"
		_net_text.add_theme_color_override("font_color", HOST_TEXT)
	elif ping <= 0:

		_bars.visible = false
		_net_crown.visible = false
		_net_text.text = "—"
		_net_text.add_theme_color_override("font_color", UiStyle.muted())
	else:


		_bars.visible = true
		_net_crown.visible = false
		_bars.set_ms(float(ping))
		_net_text.text = "%dms" % ping
		_net_text.add_theme_color_override("font_color", _bars.col.darkened(0.28))

	_apply_portrait(row.get("cfg", {}))

func _apply_portrait(cfg_data: Variant) -> void :
	if not (cfg_data is Dictionary) or (cfg_data as Dictionary).is_empty():
		return
	var key: = hash(cfg_data)
	if key == _cfg_hash:
		return
	_cfg_hash = key
	if _portrait_cache.has(key):
		_portrait.texture = _portrait_cache[key]
		return
	_load_portrait(cfg_data, key)

func _load_portrait(cfg_data: Dictionary, key: int) -> void :


	var tex: = await CharacterPortrait.render(
		CharacterConfig.from_dict(cfg_data), "head", Vector2i(80, 80), 
		get_tree().root)
	if tex == null:
		return
	_portrait_cache[key] = tex
	if is_instance_valid(_portrait) and key == _cfg_hash:
		_portrait.texture = tex

func _make_you_badge() -> PanelContainer:
	var p: = PanelContainer.new()
	p.visible = false
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b: = StyleBoxFlat.new()
	b.bg_color = BLUE
	b.set_corner_radius_all(7)
	b.content_margin_left = 6.0
	b.content_margin_right = 6.0
	b.content_margin_top = 1.0
	b.content_margin_bottom = 1.0
	p.add_theme_stylebox_override("panel", b)
	var l: = _mk_label("YOU", 11, Color.WHITE, UiStyle.FONT_XBOLD)
	p.add_child(l)
	return p

func _mk_label(text: String, sz: int, col: Color, font_path: String) -> Label:
	var l: = Label.new()
	l.text = text
	l.add_theme_font_override("font", UiStyle.font(font_path))
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _add_name_shadow(label: Label) -> void :
	label.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.09, 0.9))
	label.add_theme_constant_override("outline_size", 2)
