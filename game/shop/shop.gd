extends Control










const CAM_FOV: = 12.0
const TURNTABLE: = 0.6



const ZOOM_STEP: = 0.76
const ZOOM_MIN: = 4.1
const ZOOM_MAX: = 16.6
const SHIFT_FRAC: = 0.093
const FOCUS_Y: = 1.05
const FOCUS_Y_NEAR: = 1.45
const FOCUS_NEAR_DIST: = 10.2
const PREVIEW_NAMES: = ["showing: home", "showing: away", "showing: gym"]


const TABS: = [
	{"id": "featured", "label": "featured", "cats": ["head", "face", "extra"]}, 
	{"id": "head", "label": "head", "cats": ["head"]}, 
	{"id": "face", "label": "face", "cats": ["face"]}, 
	{"id": "extra", "label": "accessories", "cats": ["extra"]}, 
]

var cfg: CharacterConfig
var _player: Player
var _tab: = "featured"
var _view: = "shop"
var _cart: = {}
var _sel: = ""
var _thumb_cache: = {}
var _thumb_gen: = 0
var _dragging: = false
var _spin: = false
var _preview_kit: = 0
var _cam_dist: = 14.0
var _outfit_btn: Button
var _spin_btn: Button

var _coins_lbl: Label
var _grid: GridContainer
var _tab_btns: = {}
var _sel_name: Label
var _buy_btn: Button
var _add_btn: Button
var _cart_btn: Button
var _cart_view_btn: Button

@onready var world: SubViewport = $Preview / SubViewport

func _ready() -> void :
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MusicManager.set_muffled(true)
	cfg = GameConfig.character if GameConfig.character != null else CharacterConfig.new()
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
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Preview.mouse_filter = Control.MOUSE_FILTER_IGNORE


	var bd: = UiBackdrop.new("balls")
	bd.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bd)
	move_child(bd, 0)
	var wash: = ColorRect.new()
	wash.color = Color(UiStyle.PRIMARY, 0.16)
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)
	move_child(wash, 1)
	_apply_preview("")
	_build_ui()
	_select_tab("featured")

func _process(delta: float) -> void :
	if _player == null:
		return
	if _spin and not _dragging:
		_player.visual.rotation.y += delta * TURNTABLE

	_player.velocity = Vector3.ZERO
	_player.global_position = Vector3.ZERO
	_player.simulate(PlayerInput.new(), delta)
	_player.global_position = Vector3.ZERO
	_player.velocity = Vector3.ZERO

func _input(event: InputEvent) -> void :

	if event is InputEventMouseButton:
		var mb: = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and mb.position.x < size.x * 0.6:
				_dragging = true
			elif not mb.pressed:
				_dragging = false
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed\
		and mb.position.x < size.x * 0.6:
			_zoom(-1.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed\
		and mb.position.x < size.x * 0.6:
			_zoom(1.0)
	elif event is InputEventMouseMotion and _dragging and _player != null:
		_player.visual.rotation.y += (event as InputEventMouseMotion).relative.x * 0.012

func _zoom(dir: float) -> void :
	_cam_dist = clampf(_cam_dist + dir * ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
	_frame_cam()



func _frame_cam() -> void :
	var cam: Camera3D = $Preview / SubViewport / Camera3D
	var t: = clampf(inverse_lerp(ZOOM_MIN, FOCUS_NEAR_DIST, _cam_dist), 0.0, 1.0)
	var focus_y: = lerpf(FOCUS_Y_NEAR, FOCUS_Y, t)
	var shift: = SHIFT_FRAC * _cam_dist
	cam.position = Vector3(shift, focus_y, _cam_dist)
	cam.look_at(Vector3(shift, focus_y, 0.0))




func _shot_with(id: String) -> CharacterConfig:
	var shot: = cfg.clone()
	var item: = AccessoryCatalog.by_id(id)
	if item != null:
		shot.set_acc_id(item.category, id)
		shot.reset_acc_transform(item.category)
		var defs: = item.default_colors()
		for i in defs.size():
			shot.set_acc_color(item.category, i, defs[i])
	return shot



func _apply_preview(id: String) -> void :
	if _player == null:
		return
	var shot: = _shot_with(id)
	if _preview_kit == 2:
		_player.set_character(shot.gym_look(), shot.gym_kit())
	else:
		_player.set_character(shot, shot.kit_home if _preview_kit == 0 else shot.kit_away)

func _set_preview_kit(k: int) -> void :
	_preview_kit = k
	if _outfit_btn != null:
		_outfit_btn.text = PREVIEW_NAMES[k]
	_apply_preview(_sel)



func _build_ui() -> void :

	var top: = PanelContainer.new()
	var tb: = StyleBoxFlat.new()
	tb.bg_color = Color(UiStyle.card(), 0.97)
	tb.content_margin_left = 26
	tb.content_margin_right = 26
	tb.content_margin_top = 12
	tb.content_margin_bottom = 12
	top.add_theme_stylebox_override("panel", tb)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	add_child(top)
	var trow: = HBoxContainer.new()
	trow.add_theme_constant_override("separation", 14)
	top.add_child(trow)
	var title: = Label.new()
	title.text = "shop"
	UiStyle.style_label(title, "hero")
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	trow.add_child(title)
	var sub: = Label.new()
	sub.text = "buy new gear and cosmetics"
	UiStyle.style_label(sub, "small", UiStyle.muted())
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	trow.add_child(sub)
	var sp: = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trow.add_child(sp)
	for t in TABS:
		var b: = _tab_button(String(t["label"]), String(t["id"]), false)
		_tab_btns[String(t["id"])] = b
		trow.add_child(b)
	var sp2: = Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trow.add_child(sp2)
	var coinbox: = HBoxContainer.new()
	coinbox.add_theme_constant_override("separation", 7)
	coinbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coinbox.add_child(_coin_disc(22))
	_coins_lbl = Label.new()
	UiStyle.style_label(_coins_lbl, "title")
	coinbox.add_child(_coins_lbl)
	trow.add_child(coinbox)


	var panel: = PanelContainer.new()
	UiStyle.style_panel(panel, Color(UiStyle.card(), 0.98), UiStyle.RADIUS_SOFT)
	panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -560
	panel.offset_right = -28
	panel.offset_top = 96
	panel.offset_bottom = -104
	add_child(panel)
	var pv: = VBoxContainer.new()
	pv.add_theme_constant_override("separation", 12)
	panel.add_child(pv)
	var scroll: = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pv.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)


	var bot: = PanelContainer.new()
	var bb: = StyleBoxFlat.new()
	bb.bg_color = Color(UiStyle.card(), 0.97)
	bb.content_margin_left = 26
	bb.content_margin_right = 26
	bb.content_margin_top = 10
	bb.content_margin_bottom = 10
	bot.add_theme_stylebox_override("panel", bb)
	bot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bot.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(bot)
	var brow: = HBoxContainer.new()
	brow.add_theme_constant_override("separation", 14)
	bot.add_child(brow)
	var back: = Button.new()
	back.text = "back"
	UiStyle.style_button(back, "secondary", 15)
	back.pressed.connect(_exit)
	brow.add_child(back)

	var locker: = Button.new()
	locker.text = "locker"
	UiStyle.style_button(locker, "secondary", 15)
	locker.pressed.connect( func():
		UiWipe.wipe(get_tree(), func():
			GameConfig.goto_scene("res://game/character/locker.tscn")))
	brow.add_child(locker)

	_outfit_btn = Button.new()
	_outfit_btn.text = PREVIEW_NAMES[_preview_kit]
	UiStyle.style_button(_outfit_btn, "secondary", 15)
	_outfit_btn.pressed.connect( func(): _set_preview_kit((_preview_kit + 1) % 3))
	brow.add_child(_outfit_btn)
	_spin_btn = Button.new()
	_spin_btn.text = "spin: off"
	UiStyle.style_button(_spin_btn, "secondary", 15)
	_spin_btn.pressed.connect( func():
		_spin = not _spin
		_spin_btn.text = "spin: on" if _spin else "spin: off")
	brow.add_child(_spin_btn)
	var bsp: = Control.new()
	bsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brow.add_child(bsp)
	_sel_name = Label.new()
	_sel_name.text = "select an item"
	UiStyle.style_label(_sel_name, "body", UiStyle.muted())
	_sel_name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	brow.add_child(_sel_name)
	_add_btn = Button.new()
	_add_btn.text = "add to cart"
	UiStyle.style_button(_add_btn, "secondary", 15)
	_add_btn.pressed.connect(_add_to_cart)
	_add_btn.disabled = true
	brow.add_child(_add_btn)
	_buy_btn = Button.new()
	_buy_btn.text = "buy"
	UiStyle.style_button(_buy_btn, "primary", 15)
	_buy_btn.pressed.connect(_buy_selected)
	_buy_btn.disabled = true
	brow.add_child(_buy_btn)
	var bsp2: = Control.new()
	bsp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brow.add_child(bsp2)
	_cart_view_btn = Button.new()
	_cart_view_btn.text = "cart"
	UiStyle.style_button(_cart_view_btn, "secondary", 15)
	_cart_view_btn.pressed.connect(_toggle_cart_view)
	brow.add_child(_cart_view_btn)
	_cart_btn = Button.new()
	_cart_btn.text = "checkout"
	UiStyle.style_button(_cart_btn, "primary", 16)
	_cart_btn.pressed.connect(_checkout)
	brow.add_child(_cart_btn)
	_refresh_coins()
	_refresh_cart()

func _tab_button(label: String, id: String, soon: bool) -> Button:
	var b: = Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(84, 44)
	UiStyle.style_button(b, "tertiary", 16)
	b.add_theme_color_override("font_color", UiStyle.muted())
	if soon:
		b.disabled = true
	else:
		b.pressed.connect( func(): _select_tab(id))
	return b

func _select_tab(id: String) -> void :
	_tab = id
	_view = "shop"
	for tid in _tab_btns:
		var b: Button = _tab_btns[tid]
		UiStyle.style_button(b, "primary" if tid == id else "tertiary", 16)
		if tid != id:
			b.add_theme_color_override("font_color", UiStyle.muted())
	_rebuild_panel()

func _tab_items() -> Array:
	var cats: Array = []
	for t in TABS:
		if String(t["id"]) == _tab:
			cats = t["cats"]
			break
	var out: Array = []
	var seen: = {}
	for c in cats:
		for it in AccessoryCatalog.for_category(c):
			if it == null or it.price <= 0 or seen.has(it.id):
				continue
			seen[it.id] = true
			out.append(it)
	return out

func _rebuild_panel() -> void :
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	if _view == "cart":
		_build_cart_view()
		return
	_grid.columns = 3
	var items: = _tab_items()
	if items.is_empty():
		var none: = Label.new()
		none.text = "nothing here yet"
		UiStyle.style_label(none, "body", UiStyle.muted())
		_grid.add_child(none)
		return
	_thumb_gen += 1
	for it in items:
		_grid.add_child(_item_card(it))
	_render_thumbs(items, _thumb_gen)

func _toggle_cart_view() -> void :
	_view = "cart" if _view == "shop" else "shop"
	_rebuild_panel()



func _build_cart_view() -> void :
	_grid.columns = 1
	var head: = Label.new()
	head.text = "your cart"
	UiStyle.style_label(head, "title")
	_grid.add_child(head)
	if _cart.is_empty():
		var e: = Label.new()
		e.text = "nothing in your cart yet"
		UiStyle.style_label(e, "body", UiStyle.muted())
		_grid.add_child(e)
		return
	var total: = 0
	for id in _cart.keys():
		var it: = AccessoryCatalog.by_id(id)
		if it == null:
			continue
		total += int(_cart[id])
		_grid.add_child(_cart_row(it))
	var tot: = HBoxContainer.new()
	tot.add_theme_constant_override("separation", 8)
	var tl: = Label.new()
	tl.text = "total"
	UiStyle.style_label(tl, "title")
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tot.add_child(tl)
	tot.add_child(_coin_disc(20))
	var tv: = Label.new()
	tv.text = _comma(total)
	UiStyle.style_label(tv, "title")
	tot.add_child(tv)
	_grid.add_child(tot)

func _cart_row(it: AccessoryItem) -> Control:
	var row: = PanelContainer.new()
	UiStyle.style_panel(row, Color(UiStyle.bg(), 0.7), 12)
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	row.add_child(h)
	var thumb: = TextureRect.new()
	thumb.custom_minimum_size = Vector2(52, 52)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if _thumb_cache.has(it.id):
		thumb.texture = _thumb_cache[it.id]
	h.add_child(thumb)
	var nm: = Label.new()
	nm.text = it.name_or_id()
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiStyle.style_label(nm, "body")
	h.add_child(nm)
	h.add_child(_coin_disc(16))
	var pl: = Label.new()
	pl.text = _comma(it.price)
	pl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiStyle.style_label(pl, "body")
	h.add_child(pl)
	var rm: = Button.new()
	rm.text = "remove"
	UiStyle.style_button(rm, "tertiary", 13)
	rm.add_theme_color_override("font_color", UiStyle.muted())
	rm.pressed.connect( func(): _remove_from_cart(it.id))
	h.add_child(rm)
	return row

func _remove_from_cart(id: String) -> void :
	_cart.erase(id)
	_refresh_cart()
	_rebuild_panel()

func _item_card(it: AccessoryItem) -> Control:
	var owned: = Progression.owns(it.id, it.price)
	var card: = Button.new()
	card.custom_minimum_size = Vector2(164, 176)
	card.toggle_mode = false
	UiStyle.style_button(card, "secondary", 14)
	card.pressed.connect( func(): _select(it))
	var v: = VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)
	var thumb: = TextureRect.new()
	thumb.custom_minimum_size = Vector2(120, 108)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	thumb.name = "Thumb_" + it.id
	if _thumb_cache.has(it.id):
		thumb.texture = _thumb_cache[it.id]
	v.add_child(thumb)
	var nm: = Label.new()
	nm.text = it.name_or_id()
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.style_label(nm, "small")
	v.add_child(nm)
	if owned:
		var o: = Label.new()
		o.text = "owned"
		o.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiStyle.style_label(o, "small", UiStyle.SUCCESS)
		v.add_child(o)
	else:
		var pr: = HBoxContainer.new()
		pr.alignment = BoxContainer.ALIGNMENT_CENTER
		pr.add_theme_constant_override("separation", 5)
		pr.add_child(_coin_disc(15))
		var pl: = Label.new()
		pl.text = _comma(it.price)
		UiStyle.style_label(pl, "small")
		pr.add_child(pl)
		v.add_child(pr)
	return card

func _render_thumbs(items: Array, gen: int) -> void :

	for raw in items:
		var it: = raw as AccessoryItem
		if it == null or _thumb_cache.has(it.id):
			continue
		var shot: = _shot_with(it.id)
		var preset: = it.portrait if it.portrait != "" else "head"
		var tex: = await CharacterPortrait.render(shot, preset, Vector2i.ZERO, self)
		if not is_instance_valid(self) or gen != _thumb_gen:
			return
		if tex == null:
			continue
		_thumb_cache[it.id] = tex
		var t: = _grid.find_child("Thumb_" + it.id, true, false) as TextureRect
		if t != null:
			t.texture = tex

func _select(it: AccessoryItem) -> void :
	_sel = it.id
	_apply_preview(it.id)
	_sel_name.text = it.name_or_id()
	var owned: = Progression.owns(it.id, it.price)
	var in_cart: = _cart.has(it.id)
	_buy_btn.text = "owned" if owned else ("buy  " + _comma(it.price))

	_buy_btn.disabled = owned or in_cart or not Progression.can_afford(it.price)
	_add_btn.disabled = owned or in_cart
	_add_btn.text = "in cart" if in_cart else "add to cart"

func _buy_selected() -> void :
	var it: = AccessoryCatalog.by_id(_sel)
	if it == null:
		return

	if Progression.purchase(it.id, it.price):
		_cart.erase(it.id)
		_refresh_coins()
		_refresh_cart()
		_rebuild_panel()
		_select(it)

func _add_to_cart() -> void :
	var it: = AccessoryCatalog.by_id(_sel)
	if it == null or Progression.owns(it.id, it.price):
		return
	_cart[it.id] = it.price
	_refresh_cart()
	_select(it)

func _checkout() -> void :
	var total: = 0
	for id in _cart:
		total += int(_cart[id])

	if _cart.is_empty() or not Progression.can_afford(total):
		return
	for id in _cart.keys():
		Progression.purchase(id, int(_cart[id]))
	_cart.clear()
	_refresh_coins()
	_refresh_cart()
	_rebuild_panel()
	if _sel != "":
		var it: = AccessoryCatalog.by_id(_sel)
		if it != null:
			_select(it)

func _refresh_coins() -> void :
	var p: = ProfileStore.active()
	_coins_lbl.text = _comma(p.coins if p != null else 0)

func _refresh_cart() -> void :
	var n: = _cart.size()
	var total: = 0
	for id in _cart:
		total += int(_cart[id])
	_cart_view_btn.text = ("cart  %d" % n) if n > 0 else "cart"

	_cart_btn.disabled = n == 0 or not Progression.can_afford(total)

func _exit() -> void :
	UiWipe.wipe(get_tree(), func(): GameConfig.goto_scene("res://game/ui/menu.tscn"))



func _coin_disc(px: = 20) -> Panel:
	var coin: = Panel.new()
	coin.custom_minimum_size = Vector2(px, px)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var cs: = StyleBoxFlat.new()
	cs.bg_color = Color(0.96, 0.78, 0.16)
	cs.set_corner_radius_all(99)
	cs.set_border_width_all(2)
	cs.border_color = Color(0.74, 0.55, 0.05)
	coin.add_theme_stylebox_override("panel", cs)
	return coin

func _comma(n: int) -> String:
	var s: = str(absi(n))
	var out: = ""
	var c: = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out
