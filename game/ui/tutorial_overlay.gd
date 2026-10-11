class_name TutorialOverlay
extends Control












const CHARS_PER_SEC: = 28.0
const PLATE: = Vector2i(44, 36)
const PLATE_GLYPH: = 28
const PLATE_INK: = Color("141416")


const TITLE_INK: = Color(0.05, 0.07, 0.12, 1.0)

const SHOW_TIP: = false
const MOVE_ACTIONS: = ["move_forward", "move_left", "move_back", "move_right"]

const BLIP_PATH: = "res://game/sfx/Ui/keyboard_click.wav"
const BLIP_EVERY: = 3
const BLIP_DB: = -26.0

var _slide: Control
var _box: PanelContainer
var _text: RichTextLabel
var _prompt: RichTextLabel
var _hint: RichTextLabel
var _dots: Label
var _pill: Label
var _top: VBoxContainer
var _panel_hint: RichTextLabel
var _panel_info: RichTextLabel
var _checks_row: HBoxContainer
var _checks: Array[PanelContainer] = []
var _fade: ColorRect


var _action_card: PanelContainer
var _action_label: Label
var _action_glyphs: HBoxContainer
var _action_context: Label
var _action_source: Array = ["", "", ""]
var _action_pulse: Tween = null



var _action_pair: HBoxContainer
var _mini_a: Dictionary = {}
var _mini_b: Dictionary = {}


const ACTION_GLYPH_SCALE: = 1.05
var _flash: Label
var _flash_tween: Tween = null
var _hint_tween: Tween = null


var _restart_prompt: HBoxContainer
var _skip_prompt: HBoxContainer
var _restart_glyph: TextureRect
var _skip_glyph: TextureRect
const NAV_GLYPH_SCALE: = 1.15
const FLASH_GOOD: = Color(0.2, 0.78, 0.42)
const FLASH_MISS: = Color(0.93, 0.33, 0.35)
var _playing: = false
var _text_source: = ""
var _prompt_source: = ""
var _hint_source: = ""
var _info_source: = ""
var _type_tween: Tween = null
var _slide_tween: Tween = null
var _plates: = {}
var _blip: AudioStreamPlayer
var _blip_last: = 0

func _ready() -> void :
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	if not InputPrompts.changed.is_connected(_reglyph):
		InputPrompts.changed.connect(_reglyph)

func _build() -> void :

	_slide = Control.new()
	_slide.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_slide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_slide)
	_box = PanelContainer.new()
	_box.anchor_left = 0.5
	_box.anchor_right = 0.5
	_box.anchor_top = 1.0
	_box.anchor_bottom = 1.0
	_box.offset_left = -500
	_box.offset_right = 500
	_box.offset_bottom = -44
	_box.offset_top = -44 - 170
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var bs: = StyleBoxFlat.new()
	bs.bg_color = UiStyle.card()
	bs.set_corner_radius_all(30)

	bs.shadow_size = 28
	bs.shadow_color = Color(0.0, 0.0, 0.0, 0.16)
	bs.shadow_offset = Vector2(0, 6)
	bs.content_margin_left = 36.0
	bs.content_margin_right = 36.0
	bs.content_margin_top = 26.0
	bs.content_margin_bottom = 20.0
	_box.add_theme_stylebox_override("panel", bs)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slide.add_child(_box)
	var bv: = VBoxContainer.new()
	bv.add_theme_constant_override("separation", 10)
	_box.add_child(bv)
	_text = _rich(UiStyle.FONT_XBOLD, 27, UiStyle.text())
	_text.custom_minimum_size = Vector2(0, 40)
	bv.add_child(_text)

	_prompt = _rich(UiStyle.FONT_XBOLD, 21, UiStyle.SECONDARY)
	bv.add_child(_prompt)
	var foot: = HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	bv.add_child(foot)
	_hint = _rich(UiStyle.FONT_SEMI, 16, UiStyle.muted())
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(_hint)
	_dots = Label.new()
	_dots.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	_dots.add_theme_font_size_override("font_size", 18)
	_dots.add_theme_color_override("font_color", UiStyle.SECONDARY)
	_dots.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(_dots)







	_top = VBoxContainer.new()
	_top.anchor_left = 0.0
	_top.anchor_right = 1.0
	_top.anchor_top = 0.0
	_top.anchor_bottom = 0.0
	_top.offset_top = 24
	_top.offset_bottom = 260
	_top.alignment = BoxContainer.ALIGNMENT_BEGIN
	_top.add_theme_constant_override("separation", 10)
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top)
	_pill = Label.new()
	_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pill.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	_pill.add_theme_font_size_override("font_size", 36)
	_pill.add_theme_color_override("font_color", Color.WHITE)
	_pill.add_theme_color_override("font_outline_color", TITLE_INK)
	_pill.add_theme_constant_override("outline_size", 16)
	_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top.add_child(_pill)


	_panel_hint = _rich(UiStyle.FONT_XBOLD, 21, Color.WHITE)


	_panel_hint.custom_minimum_size.x = 640
	_panel_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_panel_hint.add_theme_color_override("font_outline_color", TITLE_INK)
	_panel_hint.add_theme_constant_override("outline_size", 9)
	_top.add_child(_panel_hint)

	_checks_row = HBoxContainer.new()
	_checks_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_checks_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_checks_row.add_theme_constant_override("separation", 8)
	_top.add_child(_checks_row)



	var tipwrap: = HBoxContainer.new()
	tipwrap.anchor_left = 0.0
	tipwrap.anchor_right = 1.0
	tipwrap.anchor_top = 1.0
	tipwrap.anchor_bottom = 1.0
	tipwrap.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tipwrap.offset_top = -168
	tipwrap.offset_bottom = -120
	tipwrap.alignment = BoxContainer.ALIGNMENT_CENTER
	tipwrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tipwrap)
	_panel_info = _rich(UiStyle.FONT_SEMI, 15, Color.WHITE)
	_panel_info.custom_minimum_size.x = 760
	_panel_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_info.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_panel_info.add_theme_color_override("font_outline_color", TITLE_INK)
	_panel_info.add_theme_constant_override("outline_size", 7)
	tipwrap.add_child(_panel_info)
	set_checks(0, 3)




	_flash = Label.new()
	_flash.anchor_left = 0.0
	_flash.anchor_right = 1.0
	_flash.anchor_top = 0.42
	_flash.anchor_bottom = 0.42
	_flash.offset_left = 0.0
	_flash.offset_right = 0.0
	_flash.offset_top = -50.0
	_flash.offset_bottom = 50.0
	_flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flash.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_flash.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	_flash.add_theme_font_size_override("font_size", 58)
	_flash.add_theme_color_override("font_outline_color", Color(0.05, 0.07, 0.12, 1.0))
	_flash.add_theme_constant_override("outline_size", 14)
	_flash.modulate.a = 0.0
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)



	_action_card = PanelContainer.new()
	_action_card.anchor_left = 0.5
	_action_card.anchor_right = 0.5
	_action_card.anchor_top = 1.0
	_action_card.anchor_bottom = 1.0
	_action_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_action_card.grow_vertical = Control.GROW_DIRECTION_BEGIN


	_action_card.offset_bottom = -54
	_action_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var acs: = StyleBoxFlat.new()
	acs.bg_color = UiStyle.card()
	acs.set_corner_radius_all(12)
	acs.shadow_size = 10
	acs.shadow_color = Color(0.0, 0.0, 0.0, 0.16)
	acs.shadow_offset = Vector2(0, 3)
	acs.content_margin_left = 14.0
	acs.content_margin_right = 14.0
	acs.content_margin_top = 6.0
	acs.content_margin_bottom = 6.0
	_action_card.add_theme_stylebox_override("panel", acs)
	add_child(_action_card)
	var av: = VBoxContainer.new()
	av.add_theme_constant_override("separation", 4)
	av.alignment = BoxContainer.ALIGNMENT_CENTER
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_action_card.add_child(av)
	_action_label = Label.new()
	_action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_action_label.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	_action_label.add_theme_font_size_override("font_size", 16)
	_action_label.add_theme_color_override("font_color", UiStyle.SECONDARY)
	_action_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	av.add_child(_action_label)
	_action_glyphs = HBoxContainer.new()
	_action_glyphs.alignment = BoxContainer.ALIGNMENT_CENTER
	_action_glyphs.add_theme_constant_override("separation", 6)
	_action_glyphs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	av.add_child(_action_glyphs)


	_action_context = Label.new()
	_action_context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_action_context.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_SEMI))
	_action_context.add_theme_font_size_override("font_size", 10)
	_action_context.add_theme_color_override("font_color", UiStyle.muted())
	_action_context.mouse_filter = Control.MOUSE_FILTER_IGNORE
	av.add_child(_action_context)
	_action_card.visible = false

	_action_pair = HBoxContainer.new()
	_action_pair.anchor_left = 0.5
	_action_pair.anchor_right = 0.5
	_action_pair.anchor_top = 1.0
	_action_pair.anchor_bottom = 1.0
	_action_pair.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_action_pair.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_action_pair.offset_bottom = -54
	_action_pair.add_theme_constant_override("separation", 10)
	_action_pair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mini_a = _make_mini_action()
	_mini_b = _make_mini_action()
	_action_pair.add_child(_mini_a["card"])
	_action_pair.add_child(_mini_b["card"])
	_action_pair.visible = false
	add_child(_action_pair)

	_fade = ColorRect.new()
	_fade.color = Color.WHITE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)
	_blip = AudioStreamPlayer.new()


	if ResourceLoader.exists(BLIP_PATH):
		_blip.stream = load(BLIP_PATH)
	_blip.bus = "Master"
	_blip.volume_db = BLIP_DB
	add_child(_blip)
	_restart_prompt = _build_nav_prompt("restart", true)
	_restart_glyph = _restart_prompt.get_meta("glyph")
	_skip_prompt = _build_nav_prompt("skip", false)
	_skip_glyph = _skip_prompt.get_meta("glyph")
	_refresh_nav_glyphs()
	hide_box()
	_update_tracker_vis()



func _build_nav_prompt(text: String, top_left: bool) -> HBoxContainer:
	var box: = HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.anchor_top = 0.0
	box.anchor_bottom = 0.0
	box.offset_top = 26
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if top_left:
		box.anchor_left = 0.0
		box.anchor_right = 0.0
		box.offset_left = 28
		box.grow_horizontal = Control.GROW_DIRECTION_END
	else:
		box.anchor_left = 1.0
		box.anchor_right = 1.0
		box.offset_right = -28
		box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(box)
	var g: = TextureRect.new()
	g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	g.custom_minimum_size = Vector2(PLATE.x, PLATE.y) * NAV_GLYPH_SCALE
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl: = Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	lbl.add_theme_font_size_override("font_size", 19)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_outline_color", TITLE_INK)
	lbl.add_theme_constant_override("outline_size", 8)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if top_left:
		box.add_child(g)
		box.add_child(lbl)
	else:
		box.add_child(lbl)
		box.add_child(g)
	box.set_meta("glyph", g)
	box.visible = false
	return box

func _refresh_nav_glyphs() -> void :
	if _restart_glyph != null:
		_restart_glyph.texture = _plated("tut_restart", NAV_GLYPH_SCALE)
	if _skip_glyph != null:
		_skip_glyph.texture = _plated("tut_skip", NAV_GLYPH_SCALE)

func _process(_delta: float) -> void :

	if not typing():
		return
	var shown: = _text.visible_characters
	if shown < 0:
		shown = _text.get_total_character_count()
	if _blip.stream != null and shown / BLIP_EVERY != _blip_last / BLIP_EVERY:
		_blip.pitch_scale = randf_range(0.95, 1.06)
		_blip.play()
	_blip_last = shown

func _rich(font: String, size: int, color: Color) -> RichTextLabel:
	var rt: = RichTextLabel.new()
	rt.bbcode_enabled = false
	rt.fit_content = true
	rt.scroll_active = false
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rt.add_theme_font_override("normal_font", UiStyle.font(font))
	rt.add_theme_font_size_override("normal_font_size", size)
	rt.add_theme_color_override("default_color", color)
	return rt



func show_page(text: String, page: int, pages: int, last: bool, prompt: = "", last_label: = "next", can_back: = false) -> void :
	_text_source = text
	_prompt_source = prompt
	_fill_rich(_text, text)
	_fill_rich(_prompt, prompt)
	_prompt.visible = prompt != ""
	var dots: = ""
	for i in pages:
		dots += "●" if i == page else "○"
		if i < pages - 1:
			dots += " "
	_dots.text = dots



	_hint_source = "{jump}  " + (last_label if last else "next")
	if can_back:
		_hint_source += "        {dive}  back"
	_fill_rich(_hint, _hint_source)
	_slide.visible = true

	if _type_tween != null:
		_type_tween.kill()


	_text.visible_ratio = 0.0
	_blip_last = 0
	_type_tween = create_tween()
	_type_tween.tween_property(_text, "visible_ratio", 1.0, 
		maxf(float(text.length()) / CHARS_PER_SEC, 0.05))

	if _slide_tween != null:
		_slide_tween.kill()
	_slide.position = Vector2(0, 34)
	_slide.modulate.a = 0.0
	_slide_tween = create_tween().set_parallel(true)
	_slide_tween.tween_property(_slide, "position", Vector2.ZERO, 0.26)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_slide_tween.tween_property(_slide, "modulate:a", 1.0, 0.2)


func typing() -> bool:
	return _type_tween != null and _type_tween.is_running()

func reveal_all() -> void :
	if _type_tween != null:
		_type_tween.kill()
	_text.visible_ratio = 1.0

func hide_box() -> void :
	_slide.visible = false

func box_visible() -> bool:
	return _slide.visible



func set_section(name: String, _inputs_unused: Array, info: String) -> void :
	_pill.text = name
	_pill.visible = name != ""
	_info_source = info
	_fill_rich(_panel_info, info, true)
	_update_tracker_vis()


func set_playing(on: bool) -> void :
	_playing = on
	_update_tracker_vis()
	var is_pair: = _action_source.size() >= 6
	_action_card.visible = on and not is_pair and String(_action_source[0]) != ""
	if _action_pair != null:
		_action_pair.visible = on and is_pair and String(_action_source[0]) != ""



func set_nav_visible(on: bool) -> void :
	if _restart_prompt != null:
		_restart_prompt.visible = on
	if _skip_prompt != null:
		_skip_prompt.visible = on



func _update_tracker_vis() -> void :
	var show: = _playing and _pill.visible
	_panel_hint.visible = show
	_checks_row.visible = show


	_panel_info.visible = SHOW_TIP and _playing and _info_source != ""





func set_action_prompt(label: String, action: String, context: = "") -> void :
	_action_source = [label, action, context]
	_action_label.text = label
	for c in _action_glyphs.get_children():
		c.queue_free()
	if label != "":
		for tex in _plates_for(action, ACTION_GLYPH_SCALE):
			var tr: = TextureRect.new()
			tr.texture = tex
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.custom_minimum_size = Vector2(PLATE.x, PLATE.y) * ACTION_GLYPH_SCALE
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_action_glyphs.add_child(tr)
	_action_context.text = context
	_action_context.visible = context != ""
	_action_card.visible = _playing and label != ""
	if _action_pair != null:
		_action_pair.visible = false



func set_action_pair(la: String, aa: String, ca: String, lb: String, ab: String, cb: String) -> void :
	_action_source = [la, aa, ca, lb, ab, cb]
	_fill_mini(_mini_a, la, aa, ca)
	_fill_mini(_mini_b, lb, ab, cb)
	_action_card.visible = false
	_action_pair.visible = _playing and la != ""


func _make_mini_action() -> Dictionary:
	var card: = PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s: = StyleBoxFlat.new()
	s.bg_color = UiStyle.card()
	s.set_corner_radius_all(12)
	s.shadow_size = 10
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.16)
	s.shadow_offset = Vector2(0, 3)
	s.content_margin_left = 14.0
	s.content_margin_right = 14.0
	s.content_margin_top = 6.0
	s.content_margin_bottom = 6.0
	card.add_theme_stylebox_override("panel", s)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)
	var lbl: = Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", UiStyle.SECONDARY)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(lbl)
	var gl: = HBoxContainer.new()
	gl.alignment = BoxContainer.ALIGNMENT_CENTER
	gl.add_theme_constant_override("separation", 6)
	gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(gl)
	var ctx: = Label.new()
	ctx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ctx.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_SEMI))
	ctx.add_theme_font_size_override("font_size", 10)
	ctx.add_theme_color_override("font_color", UiStyle.muted())
	ctx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(ctx)
	return {"card": card, "label": lbl, "glyphs": gl, "context": ctx}

func _fill_mini(mini: Dictionary, label: String, action: String, context: String) -> void :
	if mini.is_empty():
		return
	mini["label"].text = label
	for c in mini["glyphs"].get_children():
		c.queue_free()
	for tex in _plates_for(action, ACTION_GLYPH_SCALE):
		var tr: = TextureRect.new()
		tr.texture = tex
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(PLATE.x, PLATE.y) * ACTION_GLYPH_SCALE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mini["glyphs"].add_child(tr)
	mini["context"].text = context
	mini["context"].visible = context != ""



func pulse_action() -> void :
	if _action_card == null or not _action_card.visible:
		return
	_action_card.pivot_offset = _action_card.size * 0.5
	if _action_pulse != null and _action_pulse.is_valid():
		_action_pulse.kill()
	_action_card.scale = Vector2(1.16, 1.16)
	_action_pulse = create_tween()
	_action_pulse.tween_property(_action_card, "scale", Vector2.ONE, 0.28)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func set_hint(text: String) -> void :
	_panel_hint.add_theme_color_override("default_color", Color.WHITE)
	_fill_rich(_panel_hint, text, true)
	_panel_hint.visible = text != "" and _playing




func flash(text: String, positive: bool) -> void :
	if _flash == null or text == "":
		return
	_flash.text = text
	_flash.add_theme_color_override("font_color", FLASH_GOOD if positive else FLASH_MISS)
	if _flash_tween != null:
		_flash_tween.kill()


	_flash.modulate.a = 0.0
	_flash.pivot_offset = _flash.size * 0.5
	_flash.scale = Vector2(0.86, 0.86)
	_flash_tween = create_tween()
	_flash_tween.set_parallel(true)
	_flash_tween.tween_property(_flash, "modulate:a", 1.0, 0.12)
	_flash_tween.tween_property(_flash, "scale", Vector2.ONE, 0.22)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_flash_tween.set_parallel(false)
	_flash_tween.tween_interval(0.9)
	_flash_tween.tween_property(_flash, "modulate:a", 0.0, 0.45)



func emphasize_hint() -> void :
	if _panel_hint == null:
		return
	_panel_hint.add_theme_color_override("default_color", FLASH_MISS)
	if _hint_tween != null:
		_hint_tween.kill()
	_panel_hint.pivot_offset = Vector2.ZERO
	_panel_hint.scale = Vector2(1.14, 1.14)
	_hint_tween = create_tween()
	_hint_tween.tween_property(_panel_hint, "scale", Vector2.ONE, 0.26)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func set_checks(done: int, required: = -1) -> void :
	if required > 0 and required != _checks.size():
		for c in _checks:
			c.queue_free()
		_checks.clear()
		var px: = 30 if required <= 6 else 22
		for i in required:
			var disc: = PanelContainer.new()
			disc.custom_minimum_size = Vector2(px, px)
			var icon: = TextureRect.new()
			icon.texture = UiStyle.icon("checkmark", true)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(px * 0.55, px * 0.55)
			icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			disc.add_child(icon)
			_checks_row.add_child(disc)
			_checks.append(disc)
	for i in _checks.size():
		var got: = i < done
		var sb: = StyleBoxFlat.new()
		sb.set_corner_radius_all(int(_checks[i].custom_minimum_size.x / 2.0))


		sb.bg_color = UiStyle.SUCCESS if got else Color(0.28, 0.31, 0.38, 0.72)
		sb.shadow_size = 4
		sb.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
		_checks[i].add_theme_stylebox_override("panel", sb)


		var ic: Node = _checks[i].get_child(0)
		if ic is TextureRect:
			(ic as TextureRect).visible = got

func checks_count() -> int:
	return _checks.size()



func fade(mid: Callable, hold: = 0.12) -> void :
	var tw: = create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.28)
	tw.tween_interval(hold)
	tw.tween_callback(mid)
	tw.tween_property(_fade, "modulate:a", 0.0, 0.4)




func _plates_for(action: String, scale: = 1.0) -> Array:
	var out: = []
	if action == "move" and not InputPrompts.using_gamepad():
		for a in MOVE_ACTIONS:
			var p: = _plated(a, scale)
			if p != null:
				out.append(p)
		return out
	var p: = _plated(action, scale)
	if p != null:
		out.append(p)
	return out



func _plated(action: String, scale: = 1.0) -> Texture2D:


	var key: = "%s|%d|%d|%.2f" % [action, InputPrompts.device_kind(), InputPrompts.active_style(), scale]
	if _plates.has(key):
		return _plates[key]
	var tex: = InputPrompts.glyph(action)
	if tex == null:
		return null
	var glyph: = tex.get_image()
	if glyph == null:
		return null
	if glyph.is_compressed():
		glyph.decompress()
	glyph.convert(Image.FORMAT_RGBA8)
	var gsz: = int(round(PLATE_GLYPH * scale))
	glyph.resize(gsz, gsz, Image.INTERPOLATE_LANCZOS)
	var pw: = int(round(PLATE.x * scale))
	var ph: = int(round(PLATE.y * scale))
	var img: = Image.create(pw, ph, false, Image.FORMAT_RGBA8)
	var r: = 9.0 * scale
	for y in ph:
		for x in pw:

			var cx: = clampf(x + 0.5, r, pw - r)
			var cy: = clampf(y + 0.5, r, ph - r)
			var d: = Vector2(x + 0.5 - cx, y + 0.5 - cy).length()
			var a: = clampf(r - d + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(PLATE_INK.r, PLATE_INK.g, PLATE_INK.b, a))
	img.blend_rect(glyph, Rect2i(0, 0, gsz, gsz), 
		Vector2i((pw - gsz) / 2, (ph - gsz) / 2))
	var out: = ImageTexture.create_from_image(img)
	_plates[key] = out
	return out


func _fill_rich(rt: RichTextLabel, text: String, center: = false) -> void :
	rt.clear()
	if center:
		rt.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	var rest: = text
	while true:
		var a: = rest.find("{")
		var b: = rest.find("}", a + 1) if a != -1 else -1
		if a == -1 or b == -1:
			rt.add_text(rest)
			break
		rt.add_text(rest.substr(0, a))
		var action: = rest.substr(a + 1, b - a - 1)
		var plates: = _plates_for(action)
		if plates.is_empty():
			rt.add_text(action)
		for i in plates.size():
			rt.add_image(plates[i], PLATE.x, PLATE.y)
			if i < plates.size() - 1:
				rt.add_text(" ")
		rest = rest.substr(b + 1)

func _reglyph() -> void :
	_plates.clear()
	if _slide.visible:
		_fill_rich(_text, _text_source)
		_text.visible_ratio = 1.0
		_fill_rich(_prompt, _prompt_source)
		_fill_rich(_hint, _hint_source)
	if _action_source.size() >= 6:
		set_action_pair(String(_action_source[0]), String(_action_source[1]), String(_action_source[2]), 
			String(_action_source[3]), String(_action_source[4]), String(_action_source[5]))
	else:
		set_action_prompt(String(_action_source[0]), String(_action_source[1]), String(_action_source[2]))
	_fill_rich(_panel_info, _info_source, true)
	_refresh_nav_glyphs()
