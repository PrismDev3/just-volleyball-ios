class_name StatsDrawer
extends Control







const STAT_ROW: = preload("res://game/ui/stat_row.gd")
const SLIDE_IN: = 0.22
const SLIDE_OUT: = 0.18

var _panel: PanelContainer
var _home_rows: VBoxContainer
var _away_rows: VBoxContainer
var _home_pool: Array[StatRow] = []
var _away_pool: Array[StatRow] = []
var _header_disc: TextureRect
var _title: Label
var _row_h: = 48.0
var _avatar: = 34.0

var _open: = false
var _tween: Tween
var _hidden_x: = 0.0
var _rows_hash: = 0
var _local_peer: = 1
var _networked: = false
var _local_ping: = -1

func _ready() -> void :
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()

	_panel.offset_transform_enabled = true
	visible = false
	get_viewport().size_changed.connect(_apply_metrics)

	_apply_metrics()
	call_deferred("_park_closed")

func _park_closed() -> void :
	_hidden_x = _panel.size.x + 48.0
	if not _open:
		_panel.offset_transform_position.x = _hidden_x



func _resize_to_content() -> void :



	var vh: = get_viewport_rect().size.y
	var top_reserve: = 92.0
	var bot_reserve: = 168.0
	var want: = _panel.get_combined_minimum_size().y
	var hgt: = minf(want, vh - top_reserve - 16.0)
	var band_top: = top_reserve
	var band_bot: = vh - bot_reserve
	var top: = (band_top + band_bot) * 0.5 - hgt * 0.5
	top = maxf(top, top_reserve)
	if top + hgt > vh - 16.0:
		top = vh - 16.0 - hgt
	_panel.offset_top = top
	_panel.offset_bottom = top + hgt
	_park_closed()



func _apply_metrics() -> void :
	var vh: = get_viewport_rect().size.y


	_row_h = clampf((vh - 240.0) / 12.0, 34.0, 42.0)
	_avatar = clampf(_row_h - 10.0, 24.0, 34.0)
	if _header_disc != null:
		var disc: = int(clampf(vh * 0.04, 38.0, 46.0))
		_header_disc.texture = UiStyle.icon_disc("leaderboardsComplex", UiStyle.SECONDARY, disc)
		_header_disc.custom_minimum_size = Vector2(disc, disc)
	if _title != null:
		_title.add_theme_font_size_override("font_size", int(clampf(vh * 0.027, 24.0, 30.0)))
	for r in _home_pool:
		r.set_metrics(_row_h, _avatar)
	for r in _away_pool:
		r.set_metrics(_row_h, _avatar)
	call_deferred("_resize_to_content")

func _build() -> void :
	_panel = PanelContainer.new()
	_panel.name = "RightDrawer"



	_panel.anchor_left = 0.6
	_panel.anchor_top = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 0.0
	_panel.offset_left = 0.0
	_panel.offset_top = 90.0
	_panel.offset_right = -22.0
	_panel.offset_bottom = 490.0
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box: = UiStyle.card_box(UiStyle.card(), UiStyle.RADIUS_SOFT)
	box.shadow_color = Color(0, 0, 0, 0.34)
	box.shadow_size = 14
	box.shadow_offset = Vector2(-4, 8)
	box.set_content_margin_all(0.0)
	_panel.add_theme_stylebox_override("panel", box)
	add_child(_panel)

	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(margin)

	var col: = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)


	col.add_child(_make_column_header())
	col.add_child(_make_section_header(1))
	_home_rows = _make_rows_box()
	col.add_child(_home_rows)
	col.add_child(_make_section_header(-1))
	_away_rows = _make_rows_box()
	col.add_child(_away_rows)

func _make_header() -> Control:
	var hb: = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_disc = TextureRect.new()
	_header_disc.texture = UiStyle.icon_disc("leaderboardsComplex", UiStyle.SECONDARY, 50)
	_header_disc.custom_minimum_size = Vector2(50, 50)
	_header_disc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_header_disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(_header_disc)
	_title = Label.new()
	_title.text = "match stats"
	_title.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", UiStyle.text())
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(_title)
	return hb

func _make_column_header() -> Control:

	var mc: = MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 8)
	mc.add_theme_constant_override("margin_right", 10)
	mc.add_theme_constant_override("margin_top", 2)
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hb: = HBoxContainer.new()
	hb.add_theme_constant_override("separation", int(StatRow.SEP))
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.add_child(hb)
	var player: = _head_label("PLAYER")
	player.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hb.add_child(player)
	for name in ["PTS", "SPK", "BLK", "REC", "SET", "AST"]:
		var l: = _head_label(name)
		l.custom_minimum_size.x = StatRow.STAT_W
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hb.add_child(l)
	var net: = _head_label("NET")
	net.custom_minimum_size.x = StatRow.NET_W
	net.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hb.add_child(net)
	return mc

func _head_label(text: String) -> Label:
	var l: = Label.new()
	l.text = text
	l.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(UiStyle.text(), 0.66))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _make_section_header(side: int) -> Control:
	var pill: = PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b: = StyleBoxFlat.new()
	b.bg_color = Rules.side_color(side)
	b.set_corner_radius_all(10)
	b.content_margin_left = 14.0
	b.content_margin_right = 14.0
	b.content_margin_top = 4.0
	b.content_margin_bottom = 5.0
	b.shadow_color = Color(0, 0, 0, 0.16)
	b.shadow_size = 4
	b.shadow_offset = Vector2(0, 2)
	pill.add_theme_stylebox_override("panel", b)
	var l: = Label.new()
	l.text = Rules.side_name(side)
	l.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	l.add_theme_font_size_override("font_size", 21)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Rules.side_color(side).darkened(0.45))
	l.add_theme_constant_override("outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(l)
	return pill

func _make_rows_box() -> VBoxContainer:
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v


func set_rows(rows: Array, local_peer: int, networked: bool, local_ping: = -1) -> void :
	_local_peer = local_peer
	_networked = networked
	_local_ping = local_ping
	var h: = hash([rows, local_peer, networked, local_ping])
	if h == _rows_hash:
		return
	_rows_hash = h
	var home: Array = []
	var away: Array = []
	for r in rows:
		if int((r as Dictionary).get("side", 1)) > 0:
			home.append(r)
		else:
			away.append(r)


	_fill(_home_rows, _home_pool, home)
	_fill(_away_rows, _away_pool, away)
	call_deferred("_resize_to_content")

func _fill(box: VBoxContainer, pool: Array[StatRow], data: Array) -> void :

	while pool.size() < data.size():
		var r: = STAT_ROW.new() as StatRow
		pool.append(r)
		box.add_child(r)
		r.set_metrics(_row_h, _avatar)
	for i in pool.size():
		var row: = pool[i]
		if i < data.size():
			row.visible = true
			row.update(data[i], _local_peer, _networked, _local_ping)
		else:
			row.visible = false


func open() -> void :
	if _open:
		return
	_open = true
	visible = true
	_slide(0.0, SLIDE_IN, Tween.EASE_OUT)

func close() -> void :
	if not _open:
		return
	_open = false
	_slide(_hidden_x, SLIDE_OUT, Tween.EASE_IN)

func _slide(to_x: float, dur: float, ease: Tween.EaseType) -> void :
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "offset_transform_position:x", to_x, dur)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(ease)
	if not _open:
		_tween.tween_callback( func(): visible = false)
