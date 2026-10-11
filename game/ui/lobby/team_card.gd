class_name TeamCard
extends PanelContainer













signal cpu_pressed(id: String)
signal diff_step(id: String, dir: int)
signal reroll(id: String)
signal join_pressed

const CARD: = Vector2(342, 216)

const HOME_C: = Color("4de288")
const AWAY_C: = Color("f859b4")


const ROWS: = {1: [1], 2: [2], 3: [3], 4: [4], 5: [3, 2], 6: [3, 3]}
const TILE: = {1: Vector2(150, 150), 2: Vector2(130, 150), 3: Vector2(100, 150), 
	4: Vector2(78, 122), 5: Vector2(98, 82), 6: Vector2(98, 82)}
const RADIUS: = 16

var side: = 1
var _ink: = Color("2ea86b")
var _fill: = Color("d9f7e6")
var _title: Label
var _count: Label
var _join: Button
var _mine: Label
var _rows: VBoxContainer
var _deco: Deco
var _tiles: Array = []
var _built_size: = 0



class Deco extends Control:
	var col: = Color(1, 1, 1, 0.6)


	var balls: Array = [[0.9, 0.86, 46.0, 0.4, -9.0, -6.0], [0.12, 0.92, 30.0, 2.1, 11.0, -8.0], 
		[0.55, 0.16, 22.0, 1.2, 8.0, 10.0], [0.92, 0.28, 18.0, 3.0, -12.0, 7.0], 
		[0.3, 0.55, 14.0, 0.8, 10.0, -12.0]]
	var _started: = false
	func _process(delta: float) -> void :


		if size.x < 200.0 or size.y < 100.0:
			return
		if not _started:

			_started = true
			for b in balls:
				b[0] = size.x * float(b[0])
				b[1] = size.y * float(b[1])
		for b in balls:
			var r: float = b[2]
			b[0] += float(b[4]) * delta
			b[1] += float(b[5]) * delta
			b[3] += (float(b[4]) / r) * delta * 0.9
			if b[0] < r or b[0] > size.x - r:
				b[4] = - float(b[4])
				b[0] = clampf(b[0], r, size.x - r)
			if b[1] < r or b[1] > size.y - r:
				b[5] = - float(b[5])
				b[1] = clampf(b[1], r, size.y - r)
		queue_redraw()
	func _draw() -> void :
		var tex: Texture2D = UiBackdrop._ball_texture()
		if tex == null or not _started:
			return
		for b in balls:
			var r: float = b[2]
			draw_set_transform(Vector2(float(b[0]), float(b[1])), float(b[3]), Vector2.ONE)


			draw_texture_rect(tex, Rect2( - r, - r, r * 2.0, r * 2.0), false, col)
			draw_texture_rect(tex, Rect2( - r, - r, r * 2.0, r * 2.0), false, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _init() -> void :
	custom_minimum_size = CARD
	clip_contents = true
	_deco = Deco.new()
	_deco.set_anchors_preset(Control.PRESET_FULL_RECT)
	_deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_deco)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	var head: = HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(head)
	var twrap: = Control.new()
	twrap.custom_minimum_size = Vector2(0, 34)
	twrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(twrap)
	_title = Label.new()
	_title.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	_title.add_theme_font_size_override("font_size", 26)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.position = Vector2(2, -2)
	twrap.add_child(_title)
	_count = Label.new()
	_count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(_count)
	var gap: = Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(gap)
	_mine = Label.new()
	_mine.text = "your team"
	_mine.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_mine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(_mine)
	_join = Button.new()
	_join.text = "join"
	_join.custom_minimum_size = Vector2(64, 26)
	_join.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_join.pressed.connect( func(): join_pressed.emit())
	head.add_child(_join)
	var centre: = CenterContainer.new()
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(centre)
	_rows = VBoxContainer.new()
	_rows.alignment = BoxContainer.ALIGNMENT_CENTER
	_rows.add_theme_constant_override("separation", 4)
	_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(_rows)

func setup(team_side: int) -> void :
	side = team_side


	var base: Color = HOME_C if side > 0 else AWAY_C
	_ink = base.darkened(0.22) if side > 0 else base.darkened(0.06)
	_fill = base
	_deco.col = Color(1, 1, 1, 0.45)
	_title.text = "home" if side > 0 else "away"

	_title.add_theme_color_override("font_color", Color.WHITE)
	_title.add_theme_color_override("font_outline_color", UiStyle.INK)
	_title.add_theme_constant_override("outline_size", 7)
	UiStyle.style_pill(_count, Color(1, 1, 1, 0.85), _ink, 12)
	UiStyle.style_pill(_mine, Color.WHITE, _ink, 11)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb: = StyleBoxFlat.new()
		sb.bg_color = Color.WHITE if st != "hover" else Color(1, 1, 1, 0.85)
		sb.set_corner_radius_all(99)
		sb.set_border_width_all(2)
		sb.border_color = _ink if st != "focus" else UiStyle.PRIMARY
		sb.content_margin_left = 12.0
		sb.content_margin_right = 12.0
		_join.add_theme_stylebox_override(st, sb)
	_join.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	_join.add_theme_font_size_override("font_size", 12)
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", 
			"font_hover_pressed_color"]:
		_join.add_theme_color_override(st, _ink)
	UiStyle.press_bounce(_join)
	set_selected(false, true)



func set_selected(on: bool, can_join: bool) -> void :
	var base: Color = HOME_C if side > 0 else AWAY_C
	var box: = StyleBoxFlat.new()


	box.bg_color = base if on else Color.WHITE.lerp(base, 0.82)
	box.corner_radius_top_left = RADIUS if side > 0 else 0
	box.corner_radius_bottom_left = RADIUS if side > 0 else 0
	box.corner_radius_top_right = 0 if side > 0 else RADIUS
	box.corner_radius_bottom_right = 0 if side > 0 else RADIUS
	box.content_margin_left = 10.0
	box.content_margin_right = 10.0
	box.content_margin_top = 4.0
	box.content_margin_bottom = 8.0
	add_theme_stylebox_override("panel", box)
	_mine.visible = on
	_join.visible = not on and can_join



func set_roster(entries: Array, team_size: int, editable: bool) -> void :
	team_size = clampi(team_size, 1, 6)
	var seats: Array = entries.slice(0, team_size)
	while seats.size() < team_size:
		seats.append({"kind": "empty"})
	var filled: = 0
	for e in seats:
		if String((e as Dictionary).get("kind", "empty")) != "empty":
			filled += 1
	_count.text = "%d/%d" % [filled, team_size]
	_count.visible = filled < team_size
	var px: Vector2 = TILE[team_size]



	if _tiles.size() == team_size and _built_size == team_size:
		for k in team_size:
			(_tiles[k] as RosterTile).setup(seats[k], px, editable, _ink)
		return
	for c in _rows.get_children():
		_rows.remove_child(c)
		c.queue_free()
	_tiles = []
	_built_size = team_size
	var i: = 0
	var r: = 0
	for n in ROWS[team_size]:
		var row: = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 3 if team_size == 4 else 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rows.add_child(row)
		for _j in n:
			var tile: = RosterTile.new()
			tile.setup(seats[i], px, editable, _ink)
			tile.cpu_pressed.connect( func(id: String): cpu_pressed.emit(id))
			tile.diff_step.connect( func(id: String, dir: int): diff_step.emit(id, dir))
			tile.reroll.connect( func(id: String): reroll.emit(id))
			row.add_child(tile)
			_tiles.append(tile)

			tile.pivot_offset = px * 0.5
			UiStyle.pop_in(tile, 0.04 * float(i))
			i += 1
		r += 1

func tiles() -> Array:
	return _tiles

func join_button() -> Button:
	return _join
