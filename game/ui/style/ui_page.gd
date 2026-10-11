class_name UiPage














static func backdrop(host: Control, style: = "balls") -> UiBackdrop:
	var bd: = UiBackdrop.new(style)
	bd.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(bd)
	host.move_child(bd, 0)
	return bd




static func page(parent: Control, min_w: = 460.0) -> Control:
	var holder: = CenterContainer.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(holder)
	var panel: = PanelContainer.new()
	panel.name = "Panel"
	UiStyle.style_panel(panel, UiStyle._AUTO, UiStyle.RADIUS_SOFT)
	holder.add_child(panel)
	var pad: = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_%s" % side, 30)
	panel.add_child(pad)
	var v: = VBoxContainer.new()
	v.name = "Box"
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size.x = min_w
	pad.add_child(v)
	return holder

static func box(holder: Control) -> VBoxContainer:
	return holder.find_child("Box", true, false) as VBoxContainer




static func hero(v: VBoxContainer, text_in: String, on_card: = true) -> void :
	var col: = VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	var l: = Label.new()
	l.text = text_in
	l.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	l.add_theme_font_size_override("font_size", 38)
	if on_card:
		l.add_theme_color_override("font_color", UiStyle.text())
	else:
		l.add_theme_color_override("font_color", Color.WHITE)
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
		l.add_theme_constant_override("shadow_offset_x", 2)
		l.add_theme_constant_override("shadow_offset_y", 3)
		l.add_theme_constant_override("shadow_outline_size", 2)
	col.add_child(l)
	var rule: = Panel.new()
	rule.custom_minimum_size = Vector2(150, 6)
	var rb: = StyleBoxFlat.new()
	rb.bg_color = UiStyle.PRIMARY
	rb.set_corner_radius_all(3)
	rule.add_theme_stylebox_override("panel", rb)
	col.add_child(rule)
	var wrap_box: = MarginContainer.new()
	wrap_box.add_theme_constant_override("margin_bottom", 8)
	wrap_box.add_child(col)
	v.add_child(wrap_box)











static func card_row(icon_name: String, title: String, sub: String, 
		kind: = "info", on_press: = Callable(), 
		trailing: Control = null, min_w: = 430.0, compact: = false) -> Button:
	var yellow: = kind == "primary"
	var disc_c: = UiStyle.INK if yellow\
	else (UiStyle.muted() if kind == "quiet" else UiStyle.SECONDARY)
	var b: = Button.new()
	b.custom_minimum_size = Vector2(min_w, 50 if compact else 74)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fill: = UiStyle.PRIMARY if yellow else UiStyle.card()
	for state in [["normal", fill, 8], ["hover", fill.lightened(0.06), 8], 
		["pressed", fill.darkened(0.05), 3], 
		["focus", fill.lightened(0.06), 8], 
		["disabled", Color(UiStyle.muted(), 0.28), 3]]:
		var box_s: = StyleBoxFlat.new()
		box_s.bg_color = state[1]
		box_s.set_corner_radius_all(12 if compact else 16)
		box_s.border_width_bottom = mini(int(state[2]), 5) if compact else int(state[2])
		box_s.border_color = (state[1] as Color).darkened(0.3)
		box_s.shadow_color = Color(0, 0, 0, 0.34)
		box_s.shadow_size = 6 if compact else 10
		box_s.shadow_offset = Vector2(2, 4) if compact else Vector2(3, 6)
		b.add_theme_stylebox_override(String(state[0]), box_s)
	var pad: = MarginContainer.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_left", 12 if compact else 16)
	pad.add_theme_constant_override("margin_right", 12 if compact else 16)
	b.add_child(pad)
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10 if compact else 15)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(row)
	var disc_px: = 34 if compact else 54
	var disc: = TextureRect.new()
	disc.texture = UiStyle.icon_disc(icon_name, disc_c, disc_px, true)
	disc.custom_minimum_size = Vector2(disc_px, disc_px)
	disc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	disc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(disc)
	var col: = VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	var t: = Label.new()
	t.text = title
	UiStyle.style_label(t, "title", UiStyle.INK if yellow else UiStyle.text())
	t.add_theme_font_size_override("font_size", 18 if compact else 25)


	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.clip_text = true
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(t)
	if sub != "":
		var s: = Label.new()
		s.text = sub
		UiStyle.style_label(s, "small", 
			Color(UiStyle.INK, 0.66) if yellow else UiStyle.muted())
		if compact:
			s.add_theme_font_size_override("font_size", 12)
		s.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		s.clip_text = true
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(s)
	if trailing != null:
		trailing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		trailing.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(trailing)
	else:
		var chev: = TextureRect.new()
		chev.texture = UiStyle.icon("right", yellow and not UiStyle.dark)
		chev.modulate = Color(UiStyle.INK, 0.5) if yellow\
		else Color(UiStyle.muted(), 0.9)
		chev.custom_minimum_size = Vector2(20, 20)
		chev.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		chev.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		chev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chev.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(chev)
	b.pressed.connect(UiStyle.press_bounce.bind(b))
	b.pressed.connect(UiStyle.sfx.bind("confirm" if yellow else "press"))
	UiStyle.hover_sound(b)
	if on_press.is_valid():
		b.pressed.connect(on_press)
	return b


static func tag(text_in: String, bg_c: = UiStyle.SECONDARY) -> Label:
	var l: = Label.new()
	l.text = text_in
	UiStyle.style_pill(l, bg_c, Color.WHITE, 13)
	return l


static func back(text_in: String, on_press: Callable) -> Button:
	var b: = Button.new()
	b.text = text_in
	UiStyle.style_button(b, "tertiary", 20)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if on_press.is_valid():
		b.pressed.connect(on_press)
	return b


static func reveal(v: Node, skip: = 0) -> void :
	if v != null:
		UiStyle.stagger_reveal(v, 0.05, skip)
