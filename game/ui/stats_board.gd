class_name StatsBoard
extends VBoxContainer




const HEADERS: = ["player", "points", "spikes", "blocks", "receives", "sets", "assists"]
const STAT_KEYS: = ["pts", "spk", "blk", "rcv", "set", "ast"]
const PLAYER_WIDTH: = 210.0
const STAT_WIDTH: = 68.0
const ROW_HEIGHT: = 50.0

var _rows: Array = []
var _rows_hash: = 0
var _render_generation: = 0
var _dark: = false
var _presented: = false
var _portrait_cache: = {}


var name_labels: = {}

func _ready() -> void :
	add_theme_constant_override("separation", 5)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dark = UiStyle.dark
	_rebuild()

func _process(_delta: float) -> void :
	if _dark != UiStyle.dark:
		_dark = UiStyle.dark
		_rebuild()

func set_rows(rows: Array) -> void :
	var next_hash: = hash(rows)
	if next_hash == _rows_hash:
		return
	_rows_hash = next_hash
	_rows = rows.duplicate(true)
	_rebuild()

func _rebuild() -> void :
	_render_generation += 1
	var generation: = _render_generation



	var previous_scroll: = 0.0
	var old_scroll: = get_node_or_null("RowsScroll") as ScrollContainer
	if old_scroll != null:
		previous_scroll = old_scroll.get_v_scroll_bar().value
	name_labels.clear()
	for child in get_children():
		child.queue_free()
	var header: = _make_grid()
	for i in HEADERS.size():
		var label: = _label(HEADERS[i], 12, UiStyle.muted())
		label.custom_minimum_size.x = PLAYER_WIDTH if i == 0 else STAT_WIDTH
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT\
		if i == 0 else HORIZONTAL_ALIGNMENT_CENTER
		header.add_child(label)
	add_child(header)
	var scroll: = ScrollContainer.new()
	scroll.name = "RowsScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UiStyle.style_scroll(scroll.get_v_scroll_bar())
	add_child(scroll)
	var list: = VBoxContainer.new()
	list.name = "PlayerRows"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)
	_restore_scroll(scroll, previous_scroll, generation)


	for side in [1, -1]:
		var side_rows: = _rows.filter(
			func(row): return int(row.get("side", 1)) == side)
		if side_rows.is_empty():
			continue
		side_rows.sort_custom( func(a, b): return int(a.pts) > int(b.pts))
		list.add_child(_team_heading(side))
		for row in side_rows:
			list.add_child(_player_row(row, generation))
	if not _presented and not _rows.is_empty():
		_presented = true
		UiStyle.stagger_reveal(list, 0.025)

func _restore_scroll(scroll: ScrollContainer, value: float, 
		generation: int) -> void :
	await get_tree().process_frame
	if generation == _render_generation and is_instance_valid(scroll):
		scroll.get_v_scroll_bar().value = value

func _team_heading(side: int) -> Control:
	var bar: = HBoxContainer.new()
	bar.custom_minimum_size.y = 24.0
	bar.add_theme_constant_override("separation", 8)
	var title: = _label(Rules.side_name(side), 13, Rules.side_color(side))
	_add_team_text_shadow(title)
	title.custom_minimum_size.x = 54.0
	bar.add_child(title)
	var line: = ColorRect.new()
	line.color = Color(Rules.side_color(side), 0.55)
	line.custom_minimum_size.y = 2.0
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(line)
	return bar

func _player_row(row: Dictionary, generation: int) -> Control:
	var card: = PanelContainer.new()
	var box: = UiStyle.card_box(Color(UiStyle.card(), 0.96), 12)
	box.set_content_margin_all(5.0)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 2)
	card.add_theme_stylebox_override("panel", box)
	card.custom_minimum_size.y = ROW_HEIGHT
	var grid: = _make_grid()
	card.add_child(grid)
	var identity: = HBoxContainer.new()
	identity.custom_minimum_size = Vector2(PLAYER_WIDTH, 40)
	identity.add_theme_constant_override("separation", 8)
	var portrait_frame: = PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(40, 40)
	var frame: = StyleBoxFlat.new()
	frame.bg_color = Color(UiStyle.muted(), 0.12)
	frame.border_color = Color(Rules.side_color(int(row.get("side", 1))), 0.7)
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(10)
	frame.set_content_margin_all(2.0)
	portrait_frame.add_theme_stylebox_override("panel", frame)
	var portrait: = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_frame.add_child(portrait)
	identity.add_child(portrait_frame)
	var player_name: = String(row.get("name", "player"))
	var name_label: = _label(player_name, 16, 
		Rules.side_color(int(row.get("side", 1))))
	_add_team_text_shadow(name_label)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	identity.add_child(name_label)
	name_labels[String(row.get("ready_name", player_name))] = name_label
	grid.add_child(identity)
	for key in STAT_KEYS:
		var value: = _label(str(int(row.get(key, 0))), 17, UiStyle.text())
		value.custom_minimum_size.x = STAT_WIDTH
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		grid.add_child(value)
	var cfg_data: Variant = row.get("cfg", {})
	if cfg_data is Dictionary and not (cfg_data as Dictionary).is_empty():
		var portrait_key: = hash(cfg_data)
		if _portrait_cache.has(portrait_key):
			portrait.texture = _portrait_cache[portrait_key]
		else:
			_load_portrait(portrait, cfg_data, portrait_key, generation)
	return card

func _load_portrait(target: TextureRect, cfg_data: Dictionary, 
		portrait_key: int, generation: int) -> void :




	var texture: = await CharacterPortrait.render(
		CharacterConfig.from_dict(cfg_data), "head", Vector2i(80, 80), 
		get_tree().root)



	if texture == null:
		return
	_portrait_cache[portrait_key] = texture
	if generation == _render_generation and is_instance_valid(target):
		target.texture = texture

func _make_grid() -> GridContainer:
	var grid: = GridContainer.new()
	grid.columns = HEADERS.size()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 7)
	return grid

func _label(value: String, size: int, color: Color) -> Label:
	var label: = Label.new()
	label.text = value
	label.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD\
	if size >= 16 else UiStyle.FONT_SEMI))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _add_team_text_shadow(label: Label) -> void :


	label.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.09, 0.9))
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.05, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_constant_override("shadow_outline_size", 1)
