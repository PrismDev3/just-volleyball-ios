class_name RulesStrip
extends PanelContainer












signal changed(key: String, value: Variant)
signal reset_pressed

const SETS_NAMES: = ["1 set", "best of 3", "best of 5"]

var rate_names: Array = ["slow", "normal", "fast"]:
	set(v):
		rate_names = v
		if _rate != null and _rate.options != v:
			_rate.options = v.duplicate()
var editable: = true:
	set(v):
		editable = v
		_apply_enabled()

var _size: Label
var _sets: Label
var _points: Label
var _points_edit: LineEdit
var _steps: Array = []
var _cpu: UiSelect
var _rate: UiSelect
var _wbt: CheckBox
var _reset: Button
var _state: = {"size": 2, "sets": 2, "points": 7, "cpu": 1, "rate": 1, 
	"wbt": true, "sweat": true}
var _quiet: = false

func _init() -> void :
	var box: = StyleBoxFlat.new()
	box.bg_color = Color(UiStyle.SECONDARY, 0.07)
	box.set_corner_radius_all(14)
	box.content_margin_left = 14.0
	box.content_margin_right = 14.0
	box.content_margin_top = 6.0
	box.content_margin_bottom = 6.0
	add_theme_stylebox_override("panel", box)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	add_child(v)

	var r1: = HBoxContainer.new()
	r1.add_theme_constant_override("separation", 6)
	v.add_child(r1)
	_size = _value_label(52.0)
	r1.add_child(_cell("multiplayer", "team size", _stepper(_size, "size")))
	r1.add_child(_divider())
	_sets = _value_label(86.0)
	r1.add_child(_cell("trophy", "sets", _stepper(_sets, "sets")))
	r1.add_child(_divider())
	_points = _value_label(84.0)
	r1.add_child(_cell("target", "points", _stepper(_points, "points")))


	_points.mouse_filter = Control.MOUSE_FILTER_STOP
	_points.tooltip_text = "click to type"
	_points.gui_input.connect( func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and editable:
			_edit_points())
	_points_edit = LineEdit.new()
	_points_edit.max_length = 2
	_points_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_points_edit.custom_minimum_size = Vector2(84.0, 0)
	_points_edit.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	_points_edit.add_theme_font_size_override("font_size", 17)
	_points_edit.add_theme_color_override("font_color", UiStyle.SECONDARY)
	for st in ["normal", "focus", "read_only"]:
		var sb: = StyleBoxFlat.new()
		sb.bg_color = Color(UiStyle.SECONDARY, 0.1)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 4.0
		sb.content_margin_right = 4.0
		_points_edit.add_theme_stylebox_override(st, sb)
	_points_edit.visible = false
	_points_edit.text_submitted.connect( func(_t: String): _commit_points())
	_points_edit.focus_exited.connect(_commit_points)
	_points.get_parent().add_child(_points_edit)
	_points.get_parent().move_child(_points_edit, _points.get_index() + 1)

	_cpu = _quiet_select(CpuSlots.DIFF_NAMES, "cpu: ")
	_cpu.picked.connect( func(i: int): _emit("cpu", i))
	_rate = _quiet_select(rate_names, "sweat: ")
	_rate.picked.connect( func(i: int): _emit("rate", i))
	_wbt = _check("deuces")
	_wbt.toggled.connect( func(on: bool): _emit("wbt", on))
	var r2: = HBoxContainer.new()
	r2.add_theme_constant_override("separation", 18)
	r2.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(r2)
	r2.add_child(_cpu)
	r2.add_child(_rate)
	r2.add_child(_wbt)
	_reset = Button.new()
	_reset.text = "reset"
	UiStyle.style_button(_reset, "tertiary", 13)
	_reset.add_theme_color_override("font_color", UiStyle.muted())
	_reset.pressed.connect( func(): reset_pressed.emit())
	r2.add_child(_reset)

func _divider() -> Control:
	var d: = Panel.new()
	d.custom_minimum_size = Vector2(2, 0)
	var sb: = StyleBoxFlat.new()
	sb.bg_color = Color(UiStyle.INK, 0.08)
	d.add_theme_stylebox_override("panel", sb)
	return d


func _quiet_select(opts: Array, prefix: String) -> UiSelect:
	var s: = UiSelect.new(opts.duplicate())
	s.set_meta("prefix", prefix)
	_flatten(s, 14, UiStyle.text(), UiStyle.FONT_XBOLD)
	return s

func _flatten(s: UiSelect, fs: int, col: Color, font: String) -> void :
	s.add_theme_font_override("font", UiStyle.font(font))
	s.add_theme_font_size_override("font_size", fs)
	s.add_theme_constant_override("icon_max_width", 12)
	s.add_theme_constant_override("h_separation", 4)
	s.expand_icon = false
	s.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb: = StyleBoxFlat.new()
		sb.bg_color = Color(UiStyle.SECONDARY, 0.1) if st == "hover" or st == "pressed"\
		else Color(0, 0, 0, 0)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 6.0
		sb.content_margin_right = 6.0
		sb.content_margin_top = 1.0
		sb.content_margin_bottom = 1.0
		if st == "focus":
			sb.set_border_width_all(2)
			sb.border_color = UiStyle.PRIMARY
		s.add_theme_stylebox_override(st, sb)
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", 
			"font_hover_pressed_color"]:
		s.add_theme_color_override(st, col)
	s.add_theme_color_override("font_disabled_color", Color(col, 0.55))

func _check(text_in: String) -> CheckBox:
	var c: = CheckBox.new()
	c.text = text_in
	UiStyle.style_check(c)
	c.add_theme_font_size_override("font_size", 14)
	c.add_theme_constant_override("icon_max_width", 18)
	return c


func _cell(icon_name: String, caption: String, control: Control) -> Control:
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ic: = TextureRect.new()
	ic.texture = UiStyle.icon(icon_name)
	ic.custom_minimum_size = Vector2(20, 20)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.modulate = Color(1, 1, 1, 0.8)
	var col: = VBoxContainer.new()
	col.add_theme_constant_override("separation", -3)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)

	var top: = HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	top.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	top.add_child(ic)
	top.add_child(control)
	col.add_child(top)
	var cap: = Label.new()
	cap.text = caption
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.style_label(cap, "small", UiStyle.muted())
	cap.add_theme_font_size_override("font_size", 12)
	cap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(cap)
	return row

func _value_label(min_w: float) -> Label:
	var l: = Label.new()
	l.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", UiStyle.SECONDARY)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size.x = min_w
	return l


func _stepper(value: Label, key: String) -> Control:
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.add_child(_step_btn("minus", key, -1))
	row.add_child(value)
	row.add_child(_step_btn("plus", key, 1))
	return row

func _step_btn(icon_name: String, key: String, dir: int) -> Button:
	var b: = Button.new()
	var g: = RosterTile.StepGlyph.new()
	g.plus = icon_name == "plus"
	g.col = UiStyle.SECONDARY
	g.set_anchors_preset(Control.PRESET_FULL_RECT)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(g)
	b.custom_minimum_size = Vector2(22, 22)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb: = StyleBoxFlat.new()
		sb.bg_color = Color(UiStyle.SECONDARY, 0.22 if st == "hover" else 0.12)
		sb.set_corner_radius_all(99)
		if st == "focus":
			sb.set_border_width_all(2)
			sb.border_color = UiStyle.PRIMARY
		b.add_theme_stylebox_override(st, sb)
	RosterTile.hold_repeat(b, func(): _on_step(key, dir))
	_steps.append(b)
	return b

func _on_step(key: String, dir: int) -> void :
	if not editable:
		return
	UiStyle.sfx("tick")
	match key:
		"size":
			_emit("size", clampi(int(_state.size) + dir, 1, 6))
		"sets":
			_emit("sets", clampi(int(_state.sets) + dir, 1, 3))
		"points":
			_emit("points", clampi(int(_state.points) + dir, 3, 25))

func _edit_points() -> void :
	_points_edit.text = str(int(_state.points))
	_points.visible = false
	_points_edit.visible = true
	_points_edit.grab_focus()
	_points_edit.select_all()

func _commit_points() -> void :
	if not _points_edit.visible:
		return
	_points_edit.visible = false
	_points.visible = true
	var txt: = _points_edit.text.strip_edges()
	if txt.is_valid_int():
		var v: = clampi(int(txt), 3, 25)
		if v != int(_state.points):
			_emit("points", v)

func _emit(key: String, value: Variant) -> void :
	if _quiet or not editable:
		return
	changed.emit(key, value)

func set_state(st: Dictionary) -> void :
	for k in st:
		_state[k] = st[k]
	_quiet = true
	_size.text = "%dv%d" % [int(_state.size), int(_state.size)]
	_sets.text = SETS_NAMES[clampi(int(_state.sets) - 1, 0, 2)]
	_points.text = "%d points" % int(_state.points)
	var cpu: = int(_state.cpu)
	if cpu >= 0:
		_cpu.selected = clampi(cpu, 0, CpuSlots.DIFF_NAMES.size() - 1)
	else:
		_cpu.selected = -1
	_cpu.text = "cpu: %s" % CpuSlots.diff_name(cpu)
	_rate.selected = clampi(int(_state.rate), 0, rate_names.size() - 1)
	_rate.text = "sweat: %s" % rate_names[_rate.selected]
	UiStyle.set_check(_wbt, bool(_state.wbt))
	_quiet = false
	_apply_enabled()

func _apply_enabled() -> void :
	if _size == null:
		return
	var none: = int(_state.cpu) == CpuSlots.DIFF_NONE
	for c in [_cpu, _rate, _wbt] + _steps:
		(c as BaseButton).disabled = not editable
	_cpu.disabled = not editable or none
	_cpu.modulate.a = 0.5 if none else 1.0
	_reset.visible = editable



func _process(_delta: float) -> void :
	if _cpu.selected >= 0 and not _cpu.text.begins_with("cpu: "):
		_cpu.text = "cpu: %s" % CpuSlots.diff_name(_cpu.selected)
	if _rate.selected >= 0 and not _rate.text.begins_with("sweat: "):
		_rate.text = "sweat: %s" % rate_names[clampi(_rate.selected, 0, rate_names.size() - 1)]


func open_select(key: String) -> void :
	var s: UiSelect = {"cpu": _cpu, "rate": _rate}.get(key)
	if s != null:
		s.open_and_focus()

func controls() -> Array:
	return _steps + [_cpu, _rate, _wbt]
