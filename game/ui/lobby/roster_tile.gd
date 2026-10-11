class_name RosterTile
extends Control













signal cpu_pressed(id: String)
signal diff_step(id: String, dir: int)
signal reroll(id: String)



const MASK_SHADER: = "\nshader_type canvas_item;\nuniform float zoom = 1.12;\nuniform vec2 shift = vec2(0.0, -0.03);\nvoid fragment() {\n\tvec2 d = UV - vec2(0.5);\n\tif (dot(d, d) > 0.25) { discard; }\n\tvec2 uv = d / zoom + vec2(0.5) + shift;\n\tCOLOR = texture(TEXTURE, uv);\n}\n"










static var _mask: Shader = null

var data: Dictionary = {}
var ring_color: = Color("2ea86b")
var _disc: Panel
var _face: TextureRect
var _ring: Panel
var _empty: EmptyDisc
var _crown: Control
var _hit: Button
var _plate: Label
var _status: Label
var _step: HBoxContainer
var _minus: Button
var _diff: Label
var _plus: Button
var _reroll: Button
var _cfg_key: = 0



class StepGlyph extends Control:
	var plus: = false
	var col: = Color("232b3b")
	func _draw() -> void :
		var c: = size * 0.5
		var k: = minf(size.x, size.y) * 0.24
		draw_line(c - Vector2(k, 0), c + Vector2(k, 0), col, 2.0)
		if plus:
			draw_line(c - Vector2(0, k), c + Vector2(0, k), col, 2.0)


class ShuffleGlyph extends Control:
	var col: = Color("232b3b")
	func _draw() -> void :
		var c: = size * 0.5
		var r: = minf(size.x, size.y) * 0.19
		draw_arc(c, r, deg_to_rad(-30.0), deg_to_rad(230.0), 16, col, 1.6, true)
		var tip: = c + Vector2(cos(deg_to_rad(-30.0)), sin(deg_to_rad(-30.0))) * r
		var k: = r * 0.6
		draw_colored_polygon(PackedVector2Array([tip + Vector2( - k * 0.2, - k), 
			tip + Vector2(k * 0.75, k * 0.1), tip + Vector2( - k * 0.55, k * 0.35)]), col)



class HostMark extends Control:
	var col: = Color("ffcf3f")
	func _draw() -> void :
		draw_circle(size * 0.5, minf(size.x, size.y) * 0.5, col)


const NAME_MAX_SMALL: = 9
const NAME_MAX_BIG: = 12


class EmptyDisc extends Control:
	var col: = Color(0.55, 0.6, 0.7, 0.6)
	func _draw() -> void :
		var c: = size * 0.5
		var r: = minf(size.x, size.y) * 0.5 - 2.0
		var n: = 24
		for i in n:
			if i % 2 == 1:
				continue
			var a0: = TAU * float(i) / float(n)
			var a1: = TAU * float(i + 1) / float(n)
			draw_arc(c, r, a0, a1, 6, col, 2.5, true)
		var k: = r * 0.32
		draw_line(c - Vector2(k, 0), c + Vector2(k, 0), col, 3.0)
		draw_line(c - Vector2(0, k), c + Vector2(0, k), col, 3.0)

func _init() -> void :
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _mask == null:
		_mask = Shader.new()
		_mask.code = MASK_SHADER
	_disc = Panel.new()
	var db: = StyleBoxFlat.new()
	db.bg_color = Color("e9eefb")
	db.set_corner_radius_all(999)
	db.shadow_color = Color(0, 0, 0, 0.16)
	db.shadow_size = 6
	db.shadow_offset = Vector2(0, 3)
	_disc.add_theme_stylebox_override("panel", db)
	_disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_disc)
	_face = TextureRect.new()
	_face.set_anchors_preset(Control.PRESET_FULL_RECT)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_SCALE
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat: = ShaderMaterial.new()
	mat.shader = _mask
	_face.material = mat
	_disc.add_child(_face)
	_ring = Panel.new()
	_ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_disc.add_child(_ring)
	_empty = EmptyDisc.new()
	_empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_empty.visible = false
	add_child(_empty)

	_hit = Button.new()
	_hit.flat = true
	_hit.focus_mode = Control.FOCUS_ALL
	for st in ["normal", "hover", "pressed", "disabled"]:
		_hit.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var fb: = StyleBoxFlat.new()
	fb.bg_color = Color(0, 0, 0, 0)
	fb.set_corner_radius_all(999)
	fb.set_border_width_all(3)
	fb.border_color = UiStyle.PRIMARY
	_hit.add_theme_stylebox_override("focus", fb)
	_hit.pressed.connect( func(): cpu_pressed.emit(String(data.get("id", ""))))
	add_child(_hit)
	_crown = HostMark.new()
	_crown.visible = false
	add_child(_crown)
	_reroll = Button.new()
	_reroll.tooltip_text = "shuffle appearance"
	_reroll.focus_mode = Control.FOCUS_ALL
	var sg: = ShuffleGlyph.new()
	sg.set_anchors_preset(Control.PRESET_FULL_RECT)
	sg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reroll.add_child(sg)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb: = StyleBoxFlat.new()
		sb.bg_color = Color.WHITE if st != "hover" else Color("fff3c4")
		sb.set_corner_radius_all(999)
		sb.set_border_width_all(2)
		sb.border_color = Color(UiStyle.INK, 0.15) if st != "focus" else UiStyle.PRIMARY
		sb.shadow_color = Color(0, 0, 0, 0.15)
		sb.shadow_size = 3
		sb.shadow_offset = Vector2(0, 1)
		_reroll.add_theme_stylebox_override(st, sb)
	_reroll.pressed.connect( func():
		UiStyle.sfx("press")
		reroll.emit(String(data.get("id", ""))))
	_reroll.visible = false
	add_child(_reroll)
	_plate = Label.new()
	_plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_plate)
	_status = Label.new()
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status.visible = false
	add_child(_status)
	_step = HBoxContainer.new()
	_step.add_theme_constant_override("separation", 2)
	_step.alignment = BoxContainer.ALIGNMENT_CENTER
	_step.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_step.visible = false
	add_child(_step)
	_minus = _step_btn("minus", -1)
	_step.add_child(_minus)
	_diff = Label.new()
	_diff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_diff.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_step.add_child(_diff)
	_plus = _step_btn("plus", 1)
	_step.add_child(_plus)

func _step_btn(icon_name: String, dir: int) -> Button:
	var b: = Button.new()
	b.focus_mode = Control.FOCUS_ALL
	var g: = StepGlyph.new()
	g.plus = icon_name == "plus"
	g.set_anchors_preset(Control.PRESET_FULL_RECT)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(g)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb: = StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.9) if st != "hover" else Color.WHITE
		sb.set_corner_radius_all(999)
		sb.set_content_margin_all(0.0)
		if st == "focus":
			sb.set_border_width_all(2)
			sb.border_color = UiStyle.PRIMARY
		b.add_theme_stylebox_override(st, sb)
	hold_repeat(b, func():
		UiStyle.sfx("tick")
		diff_step.emit(String(data.get("id", "")), dir))
	return b



static func hold_repeat(b: Button, fn: Callable) -> void :
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.pressed.connect(fn)
	var t: = Timer.new()
	t.one_shot = false
	b.add_child(t)
	var ticks: = [0]
	t.timeout.connect( func():
		ticks[0] += 1
		t.wait_time = maxf(0.16 - 0.02 * ticks[0], 0.05)
		fn.call())
	b.button_down.connect( func():
		ticks[0] = 0
		t.wait_time = 0.42
		t.start())
	b.button_up.connect( func(): t.stop())
	b.mouse_exited.connect( func():
		if not b.button_pressed:
			t.stop())







var _editable: = true

func _ready() -> void :
	if not data.is_empty():
		setup(data, custom_minimum_size, _editable, ring_color)

func setup(d: Dictionary, px: Vector2, editable: bool, ring: Color) -> void :
	data = d
	ring_color = ring
	_editable = editable
	custom_minimum_size = px
	size = px
	var small: = px.y < 100.0
	var narrow: = px.x < 90.0
	var disc: float = minf(px.y * (0.62 if small else 0.66), px.x * 0.9)
	var kind: = String(d.get("kind", "empty"))
	var you: = bool(d.get("you", false))
	var host: = bool(d.get("host", false))

	var dx: = (px.x - disc) * 0.5
	_disc.position = Vector2(dx, 0)
	_disc.size = Vector2(disc, disc)
	_empty.position = _disc.position
	_empty.size = _disc.size
	_hit.position = _disc.position
	_hit.size = _disc.size
	var rb: = StyleBoxFlat.new()
	rb.bg_color = Color(0, 0, 0, 0)
	rb.set_corner_radius_all(999)
	rb.set_border_width_all(4 if not small else 3)


	rb.border_color = UiStyle.SECONDARY if you else Color.WHITE
	_ring.add_theme_stylebox_override("panel", rb)

	var plate_h: = 16.0 if (small or narrow) else 20.0
	var full_name: = String(d.get("name", "")) if kind != "empty" else "open"
	var limit: = NAME_MAX_SMALL if small else NAME_MAX_BIG
	_plate.text = full_name if full_name.length() <= limit else full_name.left(limit - 1) + "..."
	tooltip_text = full_name if full_name.length() > limit else ""

	var tier: = int(d.get("dev", 0)) if kind == "human" else 0
	var plate_bg: = Color.WHITE
	if tier == DevBadge.Tier.GOLD:
		plate_bg = DevTag.GOLD_DEEP
	elif tier == DevBadge.Tier.SILVER:
		plate_bg = DevTag.SILVER_DEEP
	UiStyle.style_pill(_plate, plate_bg, UiStyle.INK, 10 if (small or narrow) else 13)
	var psb: StyleBoxFlat = _plate.get_theme_stylebox("normal")
	psb.content_margin_left = 8.0
	psb.content_margin_right = 8.0
	psb.content_margin_top = 0.0
	psb.content_margin_bottom = 1.0
	psb.shadow_size = 3
	psb.shadow_offset = Vector2(0, 2)




	_plate.custom_minimum_size = Vector2(0, plate_h)
	var pw: = clampf(_plate.get_minimum_size().x, disc * 0.8, px.x + 6.0)
	_plate.size = Vector2(pw, plate_h)
	_plate.position = Vector2((px.x - _plate.size.x) * 0.5, disc - plate_h * 0.55)
	_plate.modulate.a = 0.75 if kind == "empty" else 1.0

	var status_y: = _plate.position.y + plate_h + 2.0
	_status.visible = false
	_step.visible = false
	_reroll.visible = false
	_crown.visible = false
	_disc.visible = kind != "empty"
	_empty.visible = kind == "empty"
	_hit.visible = kind == "cpu"
	_hit.mouse_filter = Control.MOUSE_FILTER_STOP if kind == "cpu" and editable else Control.MOUSE_FILTER_IGNORE
	_hit.focus_mode = Control.FOCUS_ALL if kind == "cpu" and editable else Control.FOCUS_NONE
	match kind:
		"human":
			if you:
				_status.text = "you"
				UiStyle.style_pill(_status, UiStyle.SECONDARY, Color.WHITE, 9 if small else 11)
				_slim(_status)
				_status.visible = true
			if host:
				var cs: = 16.0 if small else 20.0
				_crown.size = Vector2(cs, cs)
				_crown.position = _disc.position + Vector2(disc - cs * 0.85, -2.0)
				_crown.visible = true
		"cpu":
			var lvl: = int(d.get("diff", 1))
			_diff.text = CpuSlots.diff_name(lvl)



			var pc: Color = [Color("3fb872"), Color("e9bd3a"), Color("d9534f")][clampi(lvl, 0, 2)]
			var compact: = small or narrow
			UiStyle.style_pill(_diff, pc, Color.WHITE, 9 if compact else 11)
			var dsb: StyleBoxFlat = _diff.get_theme_stylebox("normal")
			dsb.content_margin_top = 0.0
			dsb.content_margin_bottom = 0.0
			dsb.content_margin_left = 5.0 if compact else 8.0
			dsb.content_margin_right = 5.0 if compact else 8.0
			dsb.shadow_size = 0
			_diff.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
			_diff.add_theme_color_override("font_outline_color", UiStyle.INK)
			_diff.add_theme_constant_override("outline_size", 3 if compact else 5)
			var bs: = 14.0 if compact else 18.0


			_diff.custom_minimum_size.x = clampf(px.x - bs * 2.0 - 8.0, 34.0, 60.0)
			for b in [_minus, _plus]:
				(b as Control).custom_minimum_size = Vector2(bs, bs)
				(b as Button).visible = editable
				(b as Button).disabled = not editable
			_step.visible = true
			_step.size = Vector2(px.x, bs)
			_step.position = Vector2(0, status_y)
			if editable:
				var rs: = 16.0 if small else 20.0
				_reroll.custom_minimum_size = Vector2(rs, rs)
				_reroll.size = Vector2(rs, rs)
				_reroll.position = _disc.position + Vector2(-2.0, -2.0)
				_reroll.visible = true
		_:
			pass
	if _status.visible:
		_status.size = _status.get_combined_minimum_size()
		_status.position = Vector2((px.x - _status.size.x) * 0.5, status_y)
	_load_face(d.get("cfg", {}))

func _slim(l: Label) -> void :
	var sb: StyleBoxFlat = l.get_theme_stylebox("normal")
	sb.content_margin_left = 7.0
	sb.content_margin_right = 7.0
	sb.content_margin_top = 0.0
	sb.content_margin_bottom = 0.0
	sb.shadow_size = 0

func focus_target() -> Control:
	if _hit.visible and _hit.focus_mode != Control.FOCUS_NONE:
		return _hit
	return null

func _load_face(cfg: Variant) -> void :
	if not (cfg is Dictionary) or (cfg as Dictionary).is_empty():
		_face.texture = null
		_cfg_key = 0
		return
	var key: = hash(cfg)
	if key == _cfg_key and _face.texture != null:
		return
	_cfg_key = key
	var tex: ImageTexture = await CharacterPortrait.head_cached(cfg, self, "lobby")

	if not is_instance_valid(self) or key != _cfg_key:
		return
	_face.texture = tex
