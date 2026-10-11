extends Control













const PANEL_W: = 486.0
const TOPBAR_H: = 96.0
const BOTTOMBAR_H: = 64.0
const DRAG_SPEED: = 0.012




const CAM_FOV: = 12.0
const ZOOM_STEP: = 0.76
const ZOOM_MIN: = 4.1
const ZOOM_MAX: = 16.6





const CAM_SHIFT_FRAC: = 0.0514


const CAM_FOCUS_Y: = 1.05
const CAM_FOCUS_Y_NEAR: = 1.45
const CAM_FOCUS_NEAR_DIST: = 10.2
const HAIR_THUMB: = Vector2(72, 72)
const PREVIEW_NAMES: = ["showing: home", "showing: away", "showing: gym"]

const VOICE_SAMPLES: = ["dive1", "dive2", "dive3", "jump1", "jump2", "jump3", 
	"recieve1"]

const SECTIONS: = [
	["face", "face"], ["body", "body"], ["voice", "voice"], ["hair", "hair"], 
	["accessories", "accessories"], ["uniforms", "uniforms"], 
	["presets", "presets"], 
]
const FACE_SUBS: = [
	["look", "look"], ["eyes", "eyes"], ["brows", "brows"], 
	["nose", "nose"], ["mouth", "mouth"], 
]



const ACCESSORY_SUBS: = [
	["head", "head"], ["face", "face"], ["extra", "extra"], 
]


const SUBS: = {
	"face": FACE_SUBS, 
	"accessories": ACCESSORY_SUBS, 
}
const EYE_COLORS: Array[Color] = [
	Color(0.15, 0.25, 0.45), Color(0.25, 0.16, 0.1), Color(0.18, 0.38, 0.25), 
	Color(0.1, 0.1, 0.12), Color(0.36, 0.22, 0.52), Color(0.55, 0.45, 0.2), 
]

var cfg: CharacterConfig
var _slots: Array = []

var _player: Player
var _dragging: = false
var _spin: = false
var _preview_kit: = 0
var _cam_dist: = 14.0

var _sub_box: HFlowContainer
var _content: VBoxContainer
var _rail_btns: = {}
var _sub_btns: = {}
var _section: = "face"


var _subsel: = {"face": "look", "accessories": "head"}
var _outfit_btn: Button
var _spin_btn: Button

var _hair_buttons: Array = []
var _hair_thumb_cache: = {}


const THUMB_DEBOUNCE: = 0.35
var _thumb_refresh_token: = 0


var _thumb_generation: = 0


var _slot_thumb_cache: = {}
var _slot_thumb_rects: = {}




var _acc_thumb_cache: = {}
var _acc_buttons: = {}

var _voice_preview: AudioStreamPlayer
var _voice_streams: Array = []

@onready var world: SubViewport = $Preview / SubViewport

func _ready() -> void :
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MusicManager.set_muffled(true)
	# Warm the scene this screen exits to (the lobby on the common path) so
	# the leave wipe swaps from memory.
	GameConfig.preload_scene(_leave_destination())








	cfg = GameConfig.character.clone() if GameConfig.character != null\
	else CharacterConfig.new()
	_slots = ProfileStore.active_slots()
	_player = preload("res://game/player/player.tscn").instantiate()
	_player.enable_reflection = false
	world.add_child(_player)
	_player.charge_ui_enabled = false

	_player.drop_shadow.visible = false



	var cam: Camera3D = $Preview / SubViewport / Camera3D
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.fov = CAM_FOV
	_frame_cam()
	Ink.apply(cam)

	_voice_preview = AudioStreamPlayer.new()
	_voice_preview.bus = "sfx"
	add_child(_voice_preview)
	_load_voice_streams()

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bd: = UiBackdrop.new("balls")


	bd.dark_page = Color("3a3a40")
	bd.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bd)
	move_child(bd, 0)
	_build_top_bar()
	_build_preview_toolbar()
	_build_panel()
	_select_section("face")
	_refresh()



func _process(delta: float) -> void :
	if _spin and not _dragging:
		_player.visual.rotation.y += delta * 0.6

func _physics_process(_delta: float) -> void :
	_player.velocity = Vector3.ZERO
	_player.global_position = Vector3.ZERO
	_player.simulate(PlayerInput.new(), _delta)
	_player.global_position = Vector3.ZERO
	_player.velocity = Vector3.ZERO

func _input(event: InputEvent) -> void :
	if event is InputEventMouseButton:
		var click: = event as InputEventMouseButton

		if click.position.x >= size.x - PANEL_W or click.position.y <= TOPBAR_H:
			return
		if click.button_index == MOUSE_BUTTON_LEFT:
			_dragging = click.pressed
		elif click.button_index == MOUSE_BUTTON_WHEEL_UP and click.pressed:
			_zoom(-1.0)
		elif click.button_index == MOUSE_BUTTON_WHEEL_DOWN and click.pressed:
			_zoom(1.0)
	elif event is InputEventMouseMotion and _dragging:
		_player.visual.rotation.y += (event as InputEventMouseMotion).relative.x\
		* DRAG_SPEED

func _zoom(dir: float) -> void :
	_cam_dist = clampf(_cam_dist + dir * ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
	_frame_cam()
	Ink.apply($Preview / SubViewport / Camera3D)





func _frame_cam() -> void :
	var cam: Camera3D = $Preview / SubViewport / Camera3D
	var t: = clampf(inverse_lerp(ZOOM_MIN, CAM_FOCUS_NEAR_DIST, _cam_dist), 0.0, 1.0)
	var focus_y: = lerpf(CAM_FOCUS_Y_NEAR, CAM_FOCUS_Y, t)
	var shift: = CAM_SHIFT_FRAC * _cam_dist
	cam.position = Vector3(shift, focus_y, _cam_dist)
	cam.look_at(Vector3(shift, focus_y, 0.0))



func _load_voice_streams() -> void :
	_voice_streams.clear()
	var sub: = "" if cfg == null or cfg.voice_pack <= 1 else "%d/" % cfg.voice_pack
	for snd in VOICE_SAMPLES:
		var path: = "res://game/sfx/PlayerSfx/%s%s.wav" % [sub, snd]
		if ResourceLoader.exists(path):
			_voice_streams.append(load(path))

func _preview_voice() -> void :
	if _voice_streams.is_empty():
		return
	_voice_preview.stream = _voice_streams[randi() % _voice_streams.size()]
	_voice_preview.pitch_scale = cfg.voice_pitch()



	_voice_preview.volume_db = -8.0 if cfg.voice_pack >= 2 else 0.0
	_voice_preview.play()



var _voice_soon: SceneTreeTimer = null

func _preview_voice_soon() -> void :
	if _voice_soon != null and _voice_soon.time_left > 0.0:
		_voice_soon.timeout.disconnect(_preview_voice)
	_voice_soon = get_tree().create_timer(0.22)
	_voice_soon.timeout.connect(_preview_voice)

func _refresh() -> void :
	if _preview_kit == 2:
		_player.set_character(cfg.gym_look(), cfg.gym_kit())
	else:
		_player.set_character(cfg, 
			cfg.kit_home if _preview_kit == 0 else cfg.kit_away)

func _changed() -> void :

	_refresh()



	_queue_thumb_refresh()

func _queue_thumb_refresh() -> void :
	if _section != "hair" and _section != "accessories":
		return
	_thumb_refresh_token += 1
	var token: = _thumb_refresh_token
	await get_tree().create_timer(THUMB_DEBOUNCE).timeout

	if not is_instance_valid(self) or token != _thumb_refresh_token:
		return
	if _section == "hair":
		_hair_thumb_cache.clear()
		_render_hair_thumbs.call_deferred()
	elif _section == "accessories":
		_acc_thumb_cache.clear()
		_render_acc_thumbs.call_deferred(_cur_sub())

func _set_preview_kit(k: int) -> void :
	_preview_kit = k
	if _outfit_btn != null and is_instance_valid(_outfit_btn):
		_outfit_btn.text = PREVIEW_NAMES[k]
	_refresh()



func _build_top_bar() -> void :
	var bar: = PanelContainer.new()
	bar.name = "TopBar"
	bar.anchor_right = 1.0
	bar.offset_bottom = TOPBAR_H
	UiStyle.style_panel(bar, UiStyle.card(), 0)
	add_child(bar)
	var pad: = MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 22)
	pad.add_theme_constant_override("margin_right", 22)
	bar.add_child(pad)
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	pad.add_child(row)
	var title: = Label.new()
	title.text = "locker"
	UiStyle.style_label(title, "title", UiStyle.text())
	title.add_theme_font_size_override("font_size", 30)
	title.custom_minimum_size = Vector2(150, 0)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(title)

	var tabs: = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tabs)
	for entry in SECTIONS:
		var id: String = entry[0]
		var b: = Button.new()
		b.text = entry[1]
		b.custom_minimum_size = Vector2(0, 54)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_select_section.bind(id))
		tabs.add_child(b)
		_rail_btns[id] = b

func _build_panel() -> void :
	var panel: = PanelContainer.new()
	panel.name = "Editor"
	panel.anchor_left = 1.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = - PANEL_W
	panel.offset_top = TOPBAR_H + 6.0
	panel.offset_bottom = - BOTTOMBAR_H - 6.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	UiStyle.style_panel(panel, UiStyle._AUTO, UiStyle.RADIUS_SOFT)
	add_child(panel)

	var pad: = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_%s" % side, 18)
	panel.add_child(pad)

	var root_v: = VBoxContainer.new()
	root_v.add_theme_constant_override("separation", 10)
	pad.add_child(root_v)



	_sub_box = HFlowContainer.new()
	_sub_box.add_theme_constant_override("h_separation", 6)
	_sub_box.add_theme_constant_override("v_separation", 6)
	root_v.add_child(_sub_box)

	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_v.add_child(scroll)
	UiStyle.style_scroll(scroll.get_v_scroll_bar())
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 9)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.custom_minimum_size.x = PANEL_W - 52
	scroll.add_child(_content)

	var actions: = VBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	root_v.add_child(actions)


	var done: = Button.new()
	done.text = "save and exit"
	done.custom_minimum_size = Vector2(0, 46)
	done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.style_button(done, "primary", 22)
	done.pressed.connect(_save_and_exit)
	actions.add_child(done)
	var leave: = Button.new()
	leave.text = "exit"
	leave.custom_minimum_size = Vector2(0, 40)
	leave.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.style_button(leave, "exit", 18)
	leave.pressed.connect(_exit_without_saving)
	actions.add_child(leave)





func _build_preview_toolbar() -> void :
	var slab: = PanelContainer.new()
	slab.name = "BottomBar"
	slab.anchor_top = 1.0
	slab.anchor_bottom = 1.0
	slab.anchor_right = 1.0
	slab.offset_top = - BOTTOMBAR_H
	slab.grow_vertical = Control.GROW_DIRECTION_BEGIN
	UiStyle.style_panel(slab, UiStyle.card(), 0)
	add_child(slab)
	var pad: = MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 22)
	pad.add_theme_constant_override("margin_right", 22)
	slab.add_child(pad)
	var bar: = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	pad.add_child(bar)
	_outfit_btn = _bar_btn(bar, PREVIEW_NAMES[_preview_kit], "secondary")
	_outfit_btn.pressed.connect( func():
		_set_preview_kit((_preview_kit + 1) % 3))
	_spin_btn = _bar_btn(bar, "spin: off", "secondary")
	_spin_btn.pressed.connect( func():
		_spin = not _spin
		_spin_btn.text = "spin: on" if _spin else "spin: off")



	var surprise: = _bar_btn(bar, "randomize character", "secondary")
	surprise.pressed.connect( func():
		cfg = CharacterConfig.random(null, true)
		_sync_controls())
	var reset: = _bar_btn(bar, "reset character", "secondary")
	reset.pressed.connect( func():
		cfg = CharacterConfig.new()
		_sync_controls())





	if not GameConfig.onboarding_active and not LaunchGate.public_beta():
		var shop: = _bar_btn(bar, "shop", "secondary")
		shop.pressed.connect(_save_and_shop)


func _bar_btn(bar: HBoxContainer, label: String, kind: String) -> Button:
	var b: = Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(0, 40)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiStyle.style_button(b, kind, 15)
	bar.add_child(b)
	return b

func _select_section(id: String) -> void :
	_section = id
	if id == "accessories":

		_acc_thumb_cache.clear()
	_rebuild_subs()
	_paint_rail()
	_rebuild_content()



func _rebuild_subs() -> void :
	for c in _sub_box.get_children():
		_sub_box.remove_child(c)
		c.queue_free()
	_sub_btns.clear()
	_sub_box.visible = SUBS.has(_section)
	if not _sub_box.visible:
		return
	for entry in SUBS[_section]:
		var id: String = entry[0]
		var b: = Button.new()
		b.text = entry[1]
		b.custom_minimum_size = Vector2(0, 32)
		b.pressed.connect(_select_sub.bind(id))
		_sub_box.add_child(b)
		_sub_btns[id] = b

func _select_sub(id: String) -> void :
	_subsel[_section] = id
	_paint_rail()
	_rebuild_content()

func _cur_sub() -> String:
	return String(_subsel.get(_section, ""))

func _paint_rail() -> void :
	for id in _rail_btns:
		UiStyle.style_button(_rail_btns[id], 
			"primary" if id == _section else "secondary", 18)
	var sub: = _cur_sub()
	for id in _sub_btns:
		UiStyle.style_button(_sub_btns[id], 
			"primary" if id == sub else "tertiary", 14)

func _rebuild_content() -> void :
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()
	if _section == "face":
		match _cur_sub():
			"look": _build_face_look()
			"eyes": _build_face_eyes()
			"brows": _build_face_brows()
			"nose": _build_face_nose()
			"mouth": _build_face_mouth()
	elif _section == "accessories":
		_build_accessories(_cur_sub())
	elif _section == "hair":
		_build_hair()
	elif _section == "body":
		_build_body()
	elif _section == "uniforms":
		_build_uniforms()
	elif _section == "voice":
		_build_voice()
	elif _section == "presets":
		_build_presets()
	UiPage.reveal(_content)

func _sync_controls() -> void :
	_rebuild_content()
	_changed()




func _group_header(text_in: String) -> Control:
	var col: = VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	var l: = Label.new()
	l.text = text_in
	UiStyle.style_label(l, "title", UiStyle.text())
	l.add_theme_font_size_override("font_size", 18)
	col.add_child(l)
	var rule: = Panel.new()
	rule.custom_minimum_size = Vector2(118, 4)
	var rb: = StyleBoxFlat.new()
	rb.bg_color = UiStyle.PRIMARY
	rb.set_corner_radius_all(2)
	rule.add_theme_stylebox_override("panel", rb)
	col.add_child(rule)
	var wrap: = MarginContainer.new()
	wrap.add_theme_constant_override("margin_top", 6)
	wrap.add_child(col)
	return wrap



func _group_header_show(text_in: String, kit: int) -> HBoxContainer:
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var h: = _group_header(text_in)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(h)
	var b: = Button.new()
	b.text = "show"
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiStyle.style_button(b, "secondary", 13)
	b.pressed.connect( func(): _set_preview_kit(kit))
	row.add_child(b)
	return row

func _labeled(text_in: String, control: Control, label_w: = 92.0) -> HBoxContainer:
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var l: = Label.new()
	l.text = text_in
	l.custom_minimum_size = Vector2(label_w, 0)
	UiStyle.style_label(l, "body", UiStyle.text())
	l.add_theme_font_size_override("font_size", 15)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(control)
	return row



func _reset_btn(on_reset: Callable) -> Button:
	var b: = Button.new()
	b.text = "reset"
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	UiStyle.style_button(b, "tertiary", 13)
	b.pressed.connect( func():
		on_reset.call()
		_sync_controls())
	return b

func _randomize_face_btn(feature: String) -> Button:
	var b: = Button.new()
	b.text = "randomize %s" % feature
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	UiStyle.style_button(b, "secondary", 13)
	b.pressed.connect(_randomize_face_feature.bind(feature))
	return b

func _randomize_face_feature(feature: String) -> void :



	var rolled: = CharacterConfig.random()
	match feature:
		"look":
			cfg.skin = rolled.skin
			cfg.blush = rolled.blush
			cfg.blush_color = rolled.blush_color
			cfg.blush_size = rolled.blush_size
			cfg.blush_width = rolled.blush_width
			cfg.blush_height = rolled.blush_height
			cfg.blush_spacing = rolled.blush_spacing
			cfg.blush_opacity = rolled.blush_opacity
		"eyes":
			cfg.eye_shape = rolled.eye_shape
			cfg.eye_color = rolled.eye_color
			cfg.eye_width = rolled.eye_width
			cfg.eye_size_y = rolled.eye_size_y
			cfg.eye_height = rolled.eye_height
			cfg.eye_spacing = rolled.eye_spacing
			cfg.eye_rot = rolled.eye_rot
			cfg.eye_x = rolled.eye_x
		"brows":
			cfg.brow_shape = rolled.brow_shape
			cfg.brow_height = rolled.brow_height
			cfg.brow_spacing = rolled.brow_spacing
			cfg.brow_width = rolled.brow_width
			cfg.brow_size_y = rolled.brow_size_y
			cfg.brow_rot = rolled.brow_rot
			cfg.brow_x = rolled.brow_x
		"nose":
			cfg.nose_shape = rolled.nose_shape
			cfg.nose_width = rolled.nose_width
			cfg.nose_size_y = rolled.nose_size_y
			cfg.nose_height = rolled.nose_height
			cfg.nose_x = rolled.nose_x
			cfg.nose_flip = rolled.nose_flip
		"mouth":
			cfg.mouth_shape = rolled.mouth_shape
			cfg.mouth_width = rolled.mouth_width
			cfg.mouth_size_y = rolled.mouth_size_y
			cfg.mouth_height = rolled.mouth_height
			cfg.mouth_rot = rolled.mouth_rot
			cfg.mouth_x = rolled.mouth_x
	_sync_controls()

func _slider_row(text_in: String, value: float, on_change: Callable) -> HBoxContainer:
	var s: = HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.02
	s.value = value
	s.custom_minimum_size = Vector2(160, 20)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.style_slider(s)
	s.value_changed.connect(on_change)
	return _labeled(text_in, s)

func _toggle_row(text_in: String, on: bool, on_change: Callable) -> CheckBox:
	var cb: = CheckBox.new()
	cb.text = text_in
	cb.button_pressed = on
	UiStyle.style_check(cb)
	cb.toggled.connect(on_change)
	return cb




func _color_field(color: Color, on_change: Callable) -> ColorPickerButton:
	var p: = ColorPickerButton.new()
	p.custom_minimum_size = Vector2(78, 30)
	p.edit_alpha = false
	p.color = color
	var cp: = p.get_picker()
	cp.edit_alpha = false
	cp.sliders_visible = false
	cp.color_modes_visible = false
	cp.sampler_visible = false
	cp.hex_visible = true
	cp.presets_visible = false
	cp.picker_shape = ColorPicker.SHAPE_HSV_RECTANGLE



	var pop: = p.get_popup()
	var dress: = func():
		if pop != null:
			pop.add_theme_stylebox_override("panel", 
				UiStyle.card_box(UiStyle._AUTO, UiStyle.RADIUS))
		cp.add_theme_color_override("font_color", UiStyle.text())
		for node in _descendants(cp):
			if node is LineEdit:
				UiStyle.style_line_edit(node)
			elif node is Label:
				node.add_theme_color_override("font_color", UiStyle.text())
			elif node is Button:
				UiStyle.style_button(node, "secondary", 14)
	dress.call()
	if pop != null:
		pop.about_to_popup.connect(dress)

	var last: = [0]
	cp.color_changed.connect( func(_c):
		var now: = Time.get_ticks_msec()
		if now - last[0] > 45:
			last[0] = now
			UiStyle.sfx("slide"))

	var face: = Panel.new()
	face.set_anchors_preset(Control.PRESET_FULL_RECT)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fsb: = StyleBoxFlat.new()
	fsb.bg_color = color
	fsb.set_corner_radius_all(7)
	fsb.set_border_width_all(2)
	fsb.border_color = Color(0, 0, 0, 0.22)
	face.add_theme_stylebox_override("panel", fsb)
	p.add_child(face)
	p.color_changed.connect( func(c):
		fsb.bg_color = c
		on_change.call(c))
	return p

func _paint_swatch(b: Button, color: Color, selected: bool) -> void :
	var box: = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(8)
	box.set_border_width_all(3 if selected else 1)
	box.border_color = UiStyle.PRIMARY if selected else Color(0, 0, 0, 0.3)
	for s in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(s, box)

func _swatch_grid(colors: Array, selected: int, on_pick: Callable, 
		swatch: = Vector2(40, 40)) -> HFlowContainer:
	var row: = HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	var btns: Array = []
	for i in colors.size():
		var b: = Button.new()
		b.custom_minimum_size = swatch
		_paint_swatch(b, colors[i], i == selected)
		var idx: = i
		b.pressed.connect( func():
			for j in btns.size():
				_paint_swatch(btns[j], colors[j], j == idx)
			on_pick.call(idx))
		row.add_child(b)
		btns.append(b)
	return row

func _choice_grid(labels: Array, selected: int, on_pick: Callable) -> HFlowContainer:
	var row: = HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 6)
	var btns: Array = []
	for i in labels.size():
		var b: = Button.new()
		b.text = str(labels[i])
		b.custom_minimum_size = Vector2(0, 32)
		UiStyle.style_button(b, "primary" if i == selected else "secondary", 14)
		var idx: = i
		b.pressed.connect( func():
			for j in btns.size():
				UiStyle.style_button(btns[j], 
					"primary" if j == idx else "secondary", 14)
			on_pick.call(idx))
		row.add_child(b)
		btns.append(b)
	return row

func _descendants(n: Node) -> Array:
	var out: Array = [n]
	for c in n.get_children():
		out.append_array(_descendants(c))
	return out

func _nearest(colors: Array, c: Color) -> int:
	var best: = 0
	var bd: = 1000000000.0
	for i in colors.size():
		var col: Color = colors[i]
		var d: = Vector3(col.r - c.r, col.g - c.g, col.b - c.b).length_squared()
		if d < bd:
			bd = d
			best = i
	return best



func _thumb_choice_grid(feature: String, selected: int, on_pick: Callable, 
		allow_none: = false) -> HFlowContainer:
	var row: = HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	var entries: Array = []
	var repaint: = func(sel: int):
		for e in entries:
			_paint_thumb_btn(e[0], int(e[1]) == sel)
	if allow_none:
		var nb: = Button.new()
		nb.text = "none"
		nb.custom_minimum_size = Vector2(74, 62)
		nb.add_theme_font_size_override("font_size", 14)
		row.add_child(nb)
		entries.append([nb, -1])
		nb.pressed.connect( func():
			repaint.call(-1)
			on_pick.call(-1))
	for i in FaceParts.count(feature):
		var b: = Button.new()
		b.custom_minimum_size = Vector2(74, 62)
		b.expand_icon = true
		b.icon = FaceParts.thumb(feature, i)
		row.add_child(b)
		entries.append([b, i])
		var idx: = i
		b.pressed.connect( func():
			repaint.call(idx)
			on_pick.call(idx))
	repaint.call(selected)
	return row

func _paint_thumb_btn(b: Button, selected: bool) -> void :
	var box: = StyleBoxFlat.new()
	box.bg_color = UiStyle.card()
	box.set_corner_radius_all(10)
	box.set_border_width_all(3 if selected else 1)
	box.border_color = UiStyle.PRIMARY if selected else Color(UiStyle.muted(), 0.4)
	box.content_margin_left = 6
	box.content_margin_right = 6
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	for s in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(s, box)



func _blush_thumb_grid(selected: int, on_pick: Callable) -> HFlowContainer:
	var row: = HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	var btns: Array = []
	for i in CharacterConfig.BLUSH_SHAPES.size():
		var b: = Button.new()
		b.custom_minimum_size = Vector2(74, 62)
		b.expand_icon = true
		b.tooltip_text = CharacterConfig.BLUSH_SHAPE_NAMES[i]
		var tex: = _blush_thumb_tex(CharacterConfig.blush_shape_key(i))
		if tex != null:
			b.icon = tex

			for s in ["normal", "hover", "pressed", "focus", "disabled"]:
				b.add_theme_color_override("icon_%s_color" % s, cfg.blush_color)
		else:
			b.text = CharacterConfig.BLUSH_SHAPE_NAMES[i]
		var idx: = i
		b.pressed.connect( func():
			for j in btns.size():
				_paint_thumb_btn(btns[j], j == idx)
			on_pick.call(idx))
		row.add_child(b)
		btns.append(b)
	for j in btns.size():
		_paint_thumb_btn(btns[j], j == selected)
	return row



static var _blush_thumb_cache: = {}
static func _blush_thumb_tex(key: String) -> Texture2D:
	if _blush_thumb_cache.has(key):
		return _blush_thumb_cache[key]
	var t: Texture2D = null


	var path: = "res://game/character/faces/blush/%s.png" % key
	if ResourceLoader.exists(path):
		var base: = load(path) as Texture2D
		if base != null:
			var img: = base.get_image()
			img.convert(Image.FORMAT_RGBA8)
			var u: = img.get_used_rect()
			if u.size.x > 0 and u.size.y > 0:
				img = img.get_region(u)
			t = ImageTexture.create_from_image(img)
	if t == null and key == "circle":
		t = _circle_thumb_tex()
	_blush_thumb_cache[key] = t
	return t

static func _circle_thumb_tex() -> Texture2D:


	var n: = 96
	var img: = Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rw: = n * 0.24
	var rh: = n * 0.17
	for cx in [n * 0.32, n * 0.68]:
		for y in n:
			for x in n:
				var d: = Vector2((x - cx) / rw, (y - n * 0.5) / rh).length()
				var a: = pow(1.0 - clampf(d, 0.0, 1.0), 1.4)
				if a > 0.0:
					var cur: = img.get_pixel(x, y)
					img.set_pixel(x, y, Color(1, 1, 1, maxf(cur.a, a)))
	return ImageTexture.create_from_image(img)



func _build_face_look() -> void :
	_content.add_child(_group_header("skin"))
	_content.add_child(_swatch_grid(CharacterConfig.SKIN_TONES, cfg.skin, 
		func(i): cfg.skin = i;_changed()))
	_content.add_child(_group_header("blush"))
	var brow: = HBoxContainer.new()
	brow.add_theme_constant_override("separation", 12)
	brow.add_child(_toggle_row("blush", cfg.blush, 
		func(on): cfg.blush = on;_changed()))
	brow.add_child(_color_field(cfg.blush_color, 
		func(c): cfg.blush_color = c;_changed()))
	_content.add_child(brow)


	_content.add_child(_blush_thumb_grid(cfg.blush_shape, 
		func(i): cfg.blush_shape = i;_changed()))
	_content.add_child(_slider_row("scale x", cfg.blush_width, 
		func(v): cfg.blush_width = v;_changed()))
	_content.add_child(_slider_row("scale y", cfg.blush_size, 
		func(v): cfg.blush_size = v;_changed()))
	_content.add_child(_slider_row("vertical", cfg.blush_height, 
		func(v): cfg.blush_height = v;_changed()))
	_content.add_child(_slider_row("spacing", cfg.blush_spacing, 
		func(v): cfg.blush_spacing = v;_changed()))
	_content.add_child(_slider_row("opacity", cfg.blush_opacity, 
		func(v): cfg.blush_opacity = v;_changed()))
	_content.add_child(_reset_btn( func():
		cfg.blush_size = 0.5
		cfg.blush_width = 0.5
		cfg.blush_height = 0.5
		cfg.blush_spacing = 0.5
		cfg.blush_opacity = 0.5))
	_content.add_child(_randomize_face_btn("look"))

func _build_face_eyes() -> void :
	_content.add_child(_group_header("style"))
	_content.add_child(_thumb_choice_grid("eyes", cfg.eye_shape, 
		func(i): cfg.eye_shape = i;_changed()))
	_content.add_child(_group_header("position"))
	_content.add_child(_slider_row("scale x", cfg.eye_width, 
		func(v): cfg.eye_width = v;_changed()))
	_content.add_child(_slider_row("scale y", cfg.eye_size_y, 
		func(v): cfg.eye_size_y = v;_changed()))
	_content.add_child(_slider_row("vertical", cfg.eye_height, 
		func(v): cfg.eye_height = v;_changed()))
	_content.add_child(_slider_row("horizontal", cfg.eye_x, 
		func(v): cfg.eye_x = v;_changed()))
	_content.add_child(_slider_row("spacing", cfg.eye_spacing, 
		func(v): cfg.eye_spacing = v;_changed()))
	_content.add_child(_slider_row("tilt", cfg.eye_rot, 
		func(v): cfg.eye_rot = v;_changed()))
	_content.add_child(_reset_btn( func():
		cfg.eye_width = 0.5
		cfg.eye_size_y = 0.5
		cfg.eye_height = 0.5
		cfg.eye_x = 0.5
		cfg.eye_spacing = 0.5
		cfg.eye_rot = 0.5))
	if FaceParts.has_tint("eyes"):
		_content.add_child(_group_header("color"))
		_content.add_child(_swatch_grid(EYE_COLORS, 
			_nearest(EYE_COLORS, cfg.eye_color), 
			func(i): cfg.eye_color = EYE_COLORS[i];_changed(), Vector2(34, 34)))
	_content.add_child(_randomize_face_btn("eyes"))

func _build_face_brows() -> void :
	_content.add_child(_group_header("style"))
	_content.add_child(_thumb_choice_grid("brows", cfg.brow_shape, 
		func(i): cfg.brow_shape = i;_changed(), true))
	_content.add_child(_group_header("position"))
	_content.add_child(_slider_row("scale x", cfg.brow_width, 
		func(v): cfg.brow_width = v;_changed()))
	_content.add_child(_slider_row("scale y", cfg.brow_size_y, 
		func(v): cfg.brow_size_y = v;_changed()))
	_content.add_child(_slider_row("vertical", cfg.brow_height, 
		func(v): cfg.brow_height = v;_changed()))
	_content.add_child(_slider_row("horizontal", cfg.brow_x, 
		func(v): cfg.brow_x = v;_changed()))
	_content.add_child(_slider_row("spacing", cfg.brow_spacing, 
		func(v): cfg.brow_spacing = v;_changed()))
	_content.add_child(_slider_row("tilt", cfg.brow_rot, 
		func(v): cfg.brow_rot = v;_changed()))
	_content.add_child(_reset_btn( func():
		cfg.brow_height = 0.5
		cfg.brow_spacing = 0.5
		cfg.brow_width = 0.5
		cfg.brow_size_y = 0.5
		cfg.brow_x = 0.5
		cfg.brow_rot = 0.5))
	_content.add_child(_randomize_face_btn("brows"))

func _build_face_nose() -> void :
	_content.add_child(_group_header("style"))
	_content.add_child(_thumb_choice_grid("nose", cfg.nose_shape, 
		func(i): cfg.nose_shape = i;_changed(), true))
	_content.add_child(_group_header("position"))
	_content.add_child(_slider_row("scale x", cfg.nose_width, 
		func(v): cfg.nose_width = v;_changed()))
	_content.add_child(_slider_row("scale y", cfg.nose_size_y, 
		func(v): cfg.nose_size_y = v;_changed()))
	_content.add_child(_slider_row("vertical", cfg.nose_height, 
		func(v): cfg.nose_height = v;_changed()))
	_content.add_child(_slider_row("horizontal", cfg.nose_x, 
		func(v): cfg.nose_x = v;_changed()))
	_content.add_child(_toggle_row("flip", cfg.nose_flip, 
		func(v): cfg.nose_flip = v;_changed()))
	_content.add_child(_reset_btn( func():
		cfg.nose_width = 0.5
		cfg.nose_size_y = 0.5
		cfg.nose_height = 0.5
		cfg.nose_x = 0.5
		cfg.nose_flip = false))
	_content.add_child(_randomize_face_btn("nose"))

func _build_face_mouth() -> void :
	_content.add_child(_group_header("style"))
	_content.add_child(_thumb_choice_grid("mouth", cfg.mouth_shape, 
		func(i): cfg.mouth_shape = i;_changed()))
	_content.add_child(_group_header("position"))
	_content.add_child(_slider_row("scale x", cfg.mouth_width, 
		func(v): cfg.mouth_width = v;_changed()))
	_content.add_child(_slider_row("scale y", cfg.mouth_size_y, 
		func(v): cfg.mouth_size_y = v;_changed()))
	_content.add_child(_slider_row("vertical", cfg.mouth_height, 
		func(v): cfg.mouth_height = v;_changed()))
	_content.add_child(_slider_row("horizontal", cfg.mouth_x, 
		func(v): cfg.mouth_x = v;_changed()))
	_content.add_child(_slider_row("tilt", cfg.mouth_rot, 
		func(v): cfg.mouth_rot = v;_changed()))
	_content.add_child(_reset_btn( func():
		cfg.mouth_width = 0.5
		cfg.mouth_size_y = 0.5
		cfg.mouth_height = 0.5
		cfg.mouth_x = 0.5
		cfg.mouth_rot = 0.5))
	_content.add_child(_randomize_face_btn("mouth"))

func _build_hair() -> void :
	_hair_buttons.clear()


	_hair_thumb_cache.clear()
	_content.add_child(_group_header("style"))
	var grid: = HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for i in CharacterConfig.hair_meshes().size():
		var b: = Button.new()
		b.custom_minimum_size = HAIR_THUMB
		b.expand_icon = true
		b.tooltip_text = CharacterConfig.hair_names()[i]
		if _hair_thumb_cache.has(i):
			b.icon = _hair_thumb_cache[i]
		var idx: = i
		b.pressed.connect( func():
			cfg.hair = idx
			_mark_hair_selected()
			_changed()


			_rebuild_content.call_deferred())
		grid.add_child(b)
		_hair_buttons.append(b)
	_content.add_child(grid)

	_content.add_child(_toggle_row("flip", cfg.hair_flip, 
		func(v): cfg.hair_flip = v;_changed()))



	var defaults: = CharacterConfig.hair_slot_defaults(cfg.hair)
	if defaults.is_empty():


		_content.add_child(_group_header("color"))
		_build_hair_slot(0, cfg.hair_color())
	else:
		_content.add_child(_group_header("color" if defaults.size() == 1 else "colors"))
		for si in defaults.size():
			_build_hair_slot(si, defaults[si])
	_mark_hair_selected()


	_render_hair_thumbs.call_deferred()




func _build_hair_slot(slot: int, fallback: Color) -> void :
	var label: = "color %d" % (slot + 1)
	_content.add_child(_labeled(label, _color_field(cfg.hair_color_at(slot, fallback), 
		func(c): cfg.set_hair_color_at(slot, c);_changed())))
	_content.add_child(_toggle_row("gradient", cfg.hair_gradient_on(slot), 
		func(on):
			cfg.set_hair_gradient_on(slot, on)
			_changed()
			_rebuild_content.call_deferred()))
	if cfg.hair_gradient_on(slot):
		var top: Color = cfg.hair_color_at(slot, fallback)
		_content.add_child(_labeled("  bottom", 
			_color_field(cfg.hair_gradient_bottom(slot, top.darkened(0.4)), 
				func(c): cfg.set_hair_gradient_bottom(slot, c);_changed())))

		var fade: Vector2 = cfg.hair_gradient_fade(slot)
		var mid: = (fade.x + fade.y) * 0.5
		var band: = maxf(fade.y - fade.x, 0.02)
		_content.add_child(_slider_row("  position", mid, 
			func(v): _set_hair_fade(slot, v, band)))
		_content.add_child(_slider_row("  softness", band, 
			func(v): _set_hair_fade(slot, (cfg.hair_gradient_fade(slot).x
				+ cfg.hair_gradient_fade(slot).y) * 0.5, v)))


func _set_hair_fade(slot: int, mid: float, band: float) -> void :
	var half: = maxf(band, 0.02) * 0.5
	cfg.set_hair_gradient_fade(slot, mid - half, mid + half)
	_changed()


func _set_acc_fade(slot: String, i: int, mid: float, band: float) -> void :
	var half: = maxf(band, 0.02) * 0.5
	cfg.set_acc_gradient_fade(slot, i, mid - half, mid + half)
	_changed()

func _mark_hair_selected() -> void :
	for i in _hair_buttons.size():
		var b: Button = _hair_buttons[i]
		var box: = StyleBoxFlat.new()
		box.bg_color = UiStyle.card()
		box.set_corner_radius_all(10)
		box.set_border_width_all(3 if i == cfg.hair else 1)
		box.border_color = UiStyle.PRIMARY if i == cfg.hair\
		else Color(UiStyle.muted(), 0.4)
		for s in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(s, box)




func _build_accessories(slot: String) -> void :
	var items: = AccessoryCatalog.for_category(slot)
	_content.add_child(_group_header("%s item" % slot))
	if items.is_empty():
		var note: = Label.new()
		note.text = "no %s items yet" % slot
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiStyle.style_label(note, "body", UiStyle.muted())
		_content.add_child(note)
		return
	var cur: = cfg.acc_id(slot)


	_acc_buttons = {}
	var grid: = HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.add_child(_acc_thumb_btn(slot, "", "none", cur == ""))
	for it in items:
		grid.add_child(_acc_thumb_btn(slot, it.id, it.name_or_id(), cur == it.id))
	_content.add_child(grid)
	_render_acc_thumbs.call_deferred(slot)
	if cur == "":
		return
	var item: = AccessoryCatalog.by_id(cur)
	if item == null:
		return

	var count: = item.color_count()
	if count > 0:
		var header_added: = false
		var shown: = 0
		for i in count:
			if item.is_color_locked(i):
				continue
			if not header_added:
				_content.add_child(_group_header("colors"))
				header_added = true
			shown += 1
			var idx: = i
			_content.add_child(_labeled("color %d" % shown, 
				_color_field(cfg.acc_color(slot, i, item.default_color(i)), 
					func(c): cfg.set_acc_color(slot, idx, c);_changed())))

			_content.add_child(_toggle_row("  gradient", cfg.acc_gradient_on(slot, i), 
				func(on):
					cfg.set_acc_gradient_on(slot, idx, on)
					_changed()
					_rebuild_content.call_deferred()))
			if cfg.acc_gradient_on(slot, i):
				var top: Color = cfg.acc_color(slot, i, item.default_color(i))
				_content.add_child(_labeled("  bottom", 
					_color_field(cfg.acc_gradient_bottom(slot, i, top.darkened(0.4)), 
						func(c): cfg.set_acc_gradient_bottom(slot, idx, c);_changed())))
				var fade: Vector2 = cfg.acc_gradient_fade(slot, i)
				var mid: = (fade.x + fade.y) * 0.5
				var band: = maxf(fade.y - fade.x, 0.02)
				_content.add_child(_slider_row("  position", mid, 
					func(v): _set_acc_fade(slot, idx, v, band)))
				_content.add_child(_slider_row("  softness", band, 
					func(v): _set_acc_fade(slot, idx, 
						(cfg.acc_gradient_fade(slot, idx).x
							+ cfg.acc_gradient_fade(slot, idx).y) * 0.5, v)))

	_content.add_child(_group_header("position"))
	_content.add_child(_slider_row("horizontal", cfg.acc_val(slot, "px"), 
		func(v): cfg.set_acc(slot, "px", v);_changed()))
	_content.add_child(_slider_row("vertical", cfg.acc_val(slot, "py"), 
		func(v): cfg.set_acc(slot, "py", v);_changed()))
	_content.add_child(_slider_row("depth", cfg.acc_val(slot, "pz"), 
		func(v): cfg.set_acc(slot, "pz", v);_changed()))
	_content.add_child(_group_header("rotation"))
	_content.add_child(_slider_row("tilt", cfg.acc_val(slot, "rx"), 
		func(v): cfg.set_acc(slot, "rx", v);_changed()))
	_content.add_child(_slider_row("turn", cfg.acc_val(slot, "ry"), 
		func(v): cfg.set_acc(slot, "ry", v);_changed()))
	_content.add_child(_slider_row("roll", cfg.acc_val(slot, "rz"), 
		func(v): cfg.set_acc(slot, "rz", v);_changed()))
	_content.add_child(_group_header("size"))
	_content.add_child(_slider_row("scale", cfg.acc_val(slot, "sc"), 
		func(v): cfg.set_acc(slot, "sc", v);_changed()))

	_content.add_child(_slider_row("scale x", cfg.acc_val(slot, "sx"), 
		func(v): cfg.set_acc(slot, "sx", v);_changed()))
	_content.add_child(_slider_row("scale y", cfg.acc_val(slot, "sy"), 
		func(v): cfg.set_acc(slot, "sy", v);_changed()))
	_content.add_child(_slider_row("scale z", cfg.acc_val(slot, "sz"), 
		func(v): cfg.set_acc(slot, "sz", v);_changed()))
	_content.add_child(_reset_btn( func(): cfg.reset_acc_transform(slot)))

func _acc_thumb_btn(slot: String, id: String, label: String, 
		selected: bool) -> Button:
	var b: = Button.new()
	b.custom_minimum_size = Vector2(78, 78)
	b.expand_icon = true
	b.tooltip_text = label
	if id == "":
		b.text = "none"
	var key: = "%s:%s" % [slot, id]
	if _acc_thumb_cache.has(key):
		b.icon = _acc_thumb_cache[key]
		b.text = ""
	_paint_thumb_btn(b, selected)


	var item: = AccessoryCatalog.by_id(id)
	var locked: = id != "" and item != null and item.price > 0\
	and not Progression.owns(id, item.price)
	b.pressed.connect( func():
		if locked:
			return
		cfg.set_acc_id(slot, id)
		_sync_controls())
	if locked:
		b.modulate = Color(1.0, 1.0, 1.0, 0.55)
		b.tooltip_text = "%s  (buy in the shop)" % label
		var tag: = Label.new()
		tag.text = str(item.price)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		tag.add_theme_font_size_override("font_size", 13)
		tag.add_theme_color_override("font_color", Color(0.82, 0.6, 0.04))
		tag.set_anchors_preset(Control.PRESET_FULL_RECT)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(tag)
	_acc_buttons[id] = b
	return b

func _render_acc_thumbs(slot: String) -> void :



	_thumb_generation += 1
	var gen: = _thumb_generation
	var base: = cfg.clone()
	var ids: Array = [""]
	for it in AccessoryCatalog.for_category(slot):
		ids.append(it.id)
	for id in ids:
		var key: = "%s:%s" % [slot, id]
		if _acc_thumb_cache.has(key):
			continue
		var shot: = base.clone()
		shot.set_acc_id(slot, id)

		var item: = AccessoryCatalog.by_id(id)
		var preset: = item.portrait if item != null else "head"
		var tex: = await CharacterPortrait.render(shot, preset, Vector2i.ZERO, self)
		if not is_instance_valid(self) or gen != _thumb_generation:
			return
		if tex == null:
			continue
		_acc_thumb_cache[key] = tex
		if _acc_buttons.has(id) and is_instance_valid(_acc_buttons[id]):
			var btn: Button = _acc_buttons[id]
			btn.icon = tex
			btn.text = ""

func _build_body() -> void :
	_content.add_child(_group_header("size"))
	_content.add_child(_slider_row("height", cfg.height, 
		func(v): cfg.height = v;_changed()))
	_content.add_child(_slider_row("build", cfg.weight, 
		func(v): cfg.weight = v;_changed()))
	_content.add_child(_group_header("head shape"))
	_content.add_child(_choice_grid(CharacterConfig.HEAD_SHAPE_NAMES, cfg.head_shape, 
		func(i): cfg.head_shape = i;_changed()))
	_content.add_child(_group_header("preferred hand"))
	_content.add_child(_choice_grid(["right handed", "left handed"], 
		1 if cfg.left_handed else 0, 
		func(i): cfg.left_handed = i == 1;_changed()))

func _build_uniforms() -> void :
	_content.add_child(_group_header("number"))
	var sb: = SpinBox.new()
	sb.min_value = 0
	sb.max_value = 99
	sb.value = cfg.number
	UiStyle.style_spin(sb)
	sb.value_changed.connect( func(v): cfg.number = int(v);_changed())
	_content.add_child(_labeled("number", sb))

	_content.add_child(_group_header_show("home", 0))
	_kit_pickers(true)
	_content.add_child(_group_header_show("away", 1))
	_kit_pickers(false)

	var swap: = Button.new()
	swap.text = "swap home and away"
	UiStyle.style_button(swap, "secondary", 14)
	swap.pressed.connect( func():
		var tmp: Array = cfg.kit_home
		cfg.kit_home = cfg.kit_away
		cfg.kit_away = tmp
		_refresh()
		_rebuild_content())
	_content.add_child(swap)

	_content.add_child(_group_header_show("gym", 2))
	_content.add_child(_labeled("tee", _color_field(cfg.gym_tee, 
		func(c): cfg.gym_tee = c;_set_preview_kit(2))))
	_content.add_child(_labeled("shorts", _color_field(cfg.gym_shorts, 
		func(c): cfg.gym_shorts = c;_set_preview_kit(2))))
	var shirt_sel: = UiSelect.new(CharacterConfig.SHIRT_SHAPE_NAMES)
	shirt_sel.custom_minimum_size = Vector2(150, 0)
	shirt_sel.selected = clampi(cfg.gym_shirt, 0, 
		CharacterConfig.SHIRT_SHAPE_NAMES.size() - 1)
	shirt_sel.picked.connect( func(i): cfg.gym_shirt = i;_set_preview_kit(2))
	_content.add_child(_labeled("shirt cut", shirt_sel, 74.0))

	_content.add_child(_group_header("fit"))
	var shorts_sel: = UiSelect.new(CharacterConfig.SHORTS_SHAPE_NAMES)
	shorts_sel.custom_minimum_size = Vector2(150, 0)
	shorts_sel.selected = clampi(cfg.shorts_len, 0, 
		CharacterConfig.SHORTS_SHAPE_NAMES.size() - 1)
	shorts_sel.picked.connect( func(i): cfg.shorts_len = i;_changed())
	_content.add_child(_labeled("shorts", shorts_sel, 74.0))
	var socks_sel: = UiSelect.new(CharacterConfig.SOCKS_SHAPE_NAMES)
	socks_sel.custom_minimum_size = Vector2(150, 0)
	socks_sel.selected = clampi(cfg.socks_len, 0, 
		CharacterConfig.SOCKS_SHAPE_NAMES.size() - 1)
	socks_sel.picked.connect( func(i): cfg.socks_len = i;_changed())
	_content.add_child(_labeled("socks", socks_sel, 74.0))

	_content.add_child(_group_header("gear"))
	_content.add_child(_labeled("kneepads", _color_field(cfg.kneepad, 
		func(c): cfg.kneepad = c;_changed())))
	_content.add_child(_labeled("socks", _color_field(cfg.socks, 
		func(c): cfg.socks = c;_changed())))
	_content.add_child(_labeled("shoes", _color_field(cfg.shoe_color, 
		func(c): cfg.shoe_color = c;_changed())))
	_content.add_child(_toggle_row("wear socks", cfg.wear_socks, 
		func(on): cfg.wear_socks = on;_changed()))
	_content.add_child(_toggle_row("wear kneepads", cfg.wear_kneepads, 
		func(on): cfg.wear_kneepads = on;_changed()))

func _kit_pickers(home: bool) -> void :
	var names: = ["jersey", "shorts", "accent"]
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for i in 3:
		var col: = VBoxContainer.new()
		col.add_theme_constant_override("separation", 3)
		var l: = Label.new()
		l.text = names[i]
		UiStyle.style_label(l, "small", UiStyle.muted())
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
		var idx: = i
		var p: = _color_field((cfg.kit_home if home else cfg.kit_away)[i], 
			func(c):
				(cfg.kit_home if home else cfg.kit_away)[idx] = c
				_set_preview_kit(0 if home else 1))
		col.add_child(p)
		row.add_child(col)
	_content.add_child(row)

func _build_voice() -> void :
	_content.add_child(_group_header("voice"))



	if CharacterConfig.VOICE_PACK_COUNT > 1:
		var vlabels: Array = []
		for i in CharacterConfig.VOICE_PACK_COUNT:
			vlabels.append("voice %d" % (i + 1))
		_content.add_child(_choice_grid(vlabels, 
			clampi(cfg.voice_pack - 1, 0, CharacterConfig.VOICE_PACK_COUNT - 1), 
			func(i):
				cfg.voice_pack = i + 1
				_load_voice_streams()
				_preview_voice()))


	_content.add_child(_slider_row("pitch", cfg.v_pitch, 
		func(v): cfg.v_pitch = v;_preview_voice_soon()))
	_content.add_child(_slider_row("speed", cfg.v_speed, 
		func(v): cfg.v_speed = v;_preview_voice_soon()))
	var play: = Button.new()
	play.text = "hear it"
	play.custom_minimum_size = Vector2(0, 34)
	UiStyle.style_button(play, "secondary", 15)
	play.pressed.connect(_preview_voice)
	_content.add_child(play)

func _build_presets() -> void :
	_content.add_child(_group_header("save slots"))
	var hint: = Label.new()
	hint.text = "load & save custom characters"
	UiStyle.style_label(hint, "small", UiStyle.muted())
	_content.add_child(hint)
	_slot_thumb_rects.clear()
	for i in CharacterConfig.SLOT_COUNT:
		_content.add_child(_slot_card(i))
	_render_slot_thumbs.call_deferred()

func _slot_card(i: int) -> PanelContainer:
	var card: = PanelContainer.new()
	UiStyle.style_panel(card, UiStyle.bg(), 12)
	var pad: = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_%s" % side, 10)
	card.add_child(pad)
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	pad.add_child(row)

	var slot: CharacterConfig = _slots[i] if i < _slots.size() else null


	var thumb: = Panel.new()
	thumb.custom_minimum_size = Vector2(120, 152)
	var tsb: = StyleBoxFlat.new()
	tsb.bg_color = UiStyle.card()
	tsb.set_corner_radius_all(9)
	tsb.set_border_width_all(1)
	tsb.border_color = Color(UiStyle.muted(), 0.4)
	thumb.add_theme_stylebox_override("panel", tsb)
	row.add_child(thumb)
	if slot != null:
		var tr: = TextureRect.new()
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _slot_thumb_cache.has(i):
			tr.texture = _slot_thumb_cache[i]
		thumb.add_child(tr)
		_slot_thumb_rects[i] = tr

	var name_col: = VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_col.add_theme_constant_override("separation", 0)
	row.add_child(name_col)
	var title: = Label.new()
	title.text = "slot %d" % (i + 1)
	UiStyle.style_label(title, "body", UiStyle.text())
	title.add_theme_font_size_override("font_size", 16)
	name_col.add_child(title)
	var sub: = Label.new()
	sub.text = "empty" if slot == null else ""
	UiStyle.style_label(sub, "small", UiStyle.muted())
	name_col.add_child(sub)

	var btns: = HBoxContainer.new()
	btns.add_theme_constant_override("separation", 5)
	btns.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(btns)
	if slot == null:
		var save: = Button.new()
		save.text = "save here"
		UiStyle.style_button(save, "secondary", 14)
		save.pressed.connect(_save_to_slot.bind(i))
		btns.add_child(save)
	else:
		var wear: = Button.new()
		wear.text = "wear"
		UiStyle.style_button(wear, "primary", 14)
		wear.pressed.connect( func():
			cfg = slot.clone()
			_sync_controls())
		btns.add_child(wear)
		var over: = Button.new()
		over.text = "save"
		UiStyle.style_button(over, "secondary", 14)
		over.pressed.connect(_save_to_slot.bind(i))
		btns.add_child(over)
		var clear: = Button.new()
		clear.text = "clear"
		UiStyle.style_button(clear, "tertiary", 14)
		clear.pressed.connect( func():
			_slots[i] = null
			_slot_thumb_cache.erase(i)
			ProfileStore.set_slots(_slots)
			_rebuild_content())
		btns.add_child(clear)
	return card

func _save_to_slot(i: int) -> void :
	_slots[i] = cfg.clone()
	_slot_thumb_cache.erase(i)
	ProfileStore.set_slots(_slots)
	_rebuild_content()



func _render_hair_thumbs() -> void :




	_thumb_generation += 1
	var gen: = _thumb_generation


	var base: = cfg.clone()
	for i in CharacterConfig.hair_meshes().size():
		var shot: = base.clone()
		shot.hair = i
		var tex: = await CharacterPortrait.render(shot, "head", Vector2i(220, 220), self)
		if not is_instance_valid(self) or gen != _thumb_generation:
			return
		if tex == null:
			continue
		_hair_thumb_cache[i] = tex
		if i < _hair_buttons.size() and is_instance_valid(_hair_buttons[i]):
			(_hair_buttons[i] as Button).icon = tex



func _render_slot_thumbs() -> void :


	for i in _slots.size():
		if _slots[i] == null or _slot_thumb_cache.has(i):
			continue
		var tex: = await CharacterPortrait.render(_slots[i], "full", 
			Vector2i(240, 300), self)
		if not is_instance_valid(self):
			return
		if tex == null:
			continue
		_slot_thumb_cache[i] = tex
		if _slot_thumb_rects.has(i) and is_instance_valid(_slot_thumb_rects[i]):
			(_slot_thumb_rects[i] as TextureRect).texture = tex

func _visual_bounds(n: Node) -> AABB:
	var out: = AABB()
	var first: = true
	for m in _meshes_of(n):
		var mi: = m as MeshInstance3D
		if not mi.visible or mi.mesh == null:
			continue
		var world_aabb: = mi.global_transform * mi.mesh.get_aabb()
		if first:
			out = world_aabb
			first = false
		else:
			out = out.merge(world_aabb)
	return out

func _meshes_of(n: Node) -> Array:
	var out: Array = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_meshes_of(c))
	return out





func _exit_without_saving() -> void :
	var live: = GameConfig.character
	var dirty: = live == null or live.to_dict() != cfg.to_dict()
	if not dirty:
		_leave()
		return
	UiStyle.confirm(self, "exit without saving?", 
		"your changes to this look will be lost", 
		_leave, "exit", "cancel", "exit", 0.0)

func _leave() -> void :
	UiWipe.wipe(get_tree(), func(): GameConfig.goto_scene(_leave_destination()))

func _save_and_exit() -> void :
	await _save_look()
	UiWipe.wipe(get_tree(), func(): GameConfig.goto_scene(_leave_destination()))


func _save_and_shop() -> void :
	await _save_look()
	UiWipe.wipe(get_tree(), func(): GameConfig.goto_scene("res://game/shop/shop.tscn"))

func _save_look() -> void :
	cfg.save_local()
	GameConfig.character = cfg
	ProfileStore.capture_character()
	Achievements.notify("avatar")


	await CharacterPortrait.generate_and_save(cfg, self)





func _leave_destination() -> String:
	if GameConfig.onboarding_active:
		GameConfig.onboarding_active = false




		ProfileStore.seeded_fresh = false




		MusicManager.set_muffled(false)
		return "res://game/ui/boot/boot_intro.tscn"
	return "res://game/ui/menu.tscn"
