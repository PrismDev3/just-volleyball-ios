class_name UiSelect
extends Button










signal picked(index: int)

const DROP: = 0.16

var options: Array = []
var selected: = -1:
	set(v):
		selected = v
		if v >= 0 and v < options.size():
			text = str(options[v])

var _layer: CanvasLayer = null
var _clip: Control = null
var _list: PanelContainer = null
var _open: = false
var _flip: = false
var _items: Array = []



static var active: UiSelect = null

func _init(opts: = []) -> void :
	options = opts
	UiStyle.style_button(self, "secondary", 16)
	icon = UiStyle.icon("arrowDown")
	icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	expand_icon = true
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	if not options.is_empty():
		selected = 0
	pressed.connect(_toggle)


	focus_exited.connect(_on_focus_exited)

func _toggle() -> void :
	if _open:
		_collapse()
	else:
		_expand()

func _expand() -> void :
	_open = true
	active = self
	UiStyle.sfx("open")
	icon = UiStyle.icon("arrowUp")


	_layer = CanvasLayer.new()


	var lay: = 90
	var up: Node = get_parent()
	while up != null:
		if up is CanvasLayer:
			lay = maxi(lay, (up as CanvasLayer).layer + 1)
		up = up.get_parent()
	_layer.layer = lay
	add_child(_layer)




	var scrim: = Control.new()



	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.gui_input.connect( func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_collapse())
	_layer.add_child(scrim)
	_clip = Control.new()
	_clip.clip_contents = true
	_layer.add_child(_clip)
	_list = PanelContainer.new()
	UiStyle.style_panel(_list)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	_items = []

	var fs: = get_theme_font_size("font_size")
	var compact: = fs > 0 and fs <= 14
	for i in options.size():
		var item: = Button.new()
		item.text = str(options[i])
		UiStyle.style_button(item, "tertiary", fs if fs > 0 else 16)
		if compact:
			item.custom_minimum_size.y = 30.0
			for st in ["normal", "hover", "pressed", "focus", "disabled"]:
				var sb: = item.get_theme_stylebox(st)
				if sb is StyleBoxFlat:
					var c: = (sb as StyleBoxFlat).duplicate() as StyleBoxFlat
					c.content_margin_top = 4.0
					c.content_margin_bottom = 4.0
					item.add_theme_stylebox_override(st, c)
		item.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_items.append(item)
		if i == selected:


			for state in ["font_color", "font_hover_color", 
				"font_pressed_color", "font_hover_pressed_color", 
				"font_focus_color"]:
				item.add_theme_color_override(state, UiStyle.SECONDARY)
		item.pressed.connect( func():
			selected = i
			picked.emit(i)
			_collapse())
		v.add_child(item)
	_list.add_child(v)
	_clip.add_child(_list)

	await get_tree().process_frame


	if not _open or _list == null:
		return
	var h: = _list.size.y


	var w: = maxf(size.x, _list.size.x)



	var vp: = get_viewport().get_visible_rect()
	var below_y: = global_position.y + size.y + 4
	_flip = false
	var y: = minf(below_y, vp.end.y - h - 4)
	y = maxf(y, vp.position.y)
	_clip.global_position = Vector2(global_position.x, y)

	if _clip.global_position.x + w > vp.end.x:
		_clip.global_position.x = maxf(vp.position.x, vp.end.x - w)
	_clip.size = Vector2(w, h)
	_list.size = Vector2(w, h)
	_list.position = Vector2(0, h if _flip else - h)
	var t: = create_tween()
	t.tween_property(_list, "position:y", 0.0, DROP)\
	.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func _collapse() -> void :
	if not _open:
		return
	_open = false
	if active == self:
		active = null
	_items = []


	if InputPrompts.using_gamepad():
		grab_focus()
	UiStyle.sfx("close")
	icon = UiStyle.icon("arrowDown")
	var layer: = _layer
	var list: = _list
	_layer = null
	_clip = null
	_list = null
	var t: = list.create_tween()
	t.tween_property(list, "position:y", list.size.y if _flip else - list.size.y, DROP)\
	.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	t.tween_callback(layer.queue_free)


func is_open() -> bool:
	return _open

func close() -> void :
	_collapse()


func open_and_focus() -> void :
	if not _open:
		_expand()
	focus_selected_item()

func focus_selected_item() -> void :
	if _items.is_empty():
		return
	var idx: = selected if selected >= 0 and selected < _items.size() else 0
	(_items[idx] as Control).grab_focus()


func step_focus(dir: String) -> void :
	if not _open or _items.is_empty() or (dir != "up" and dir != "down"):
		return
	var foc: = get_viewport().gui_get_focus_owner()
	var cur: = _items.find(foc)
	if cur == -1:
		cur = maxi(selected, 0)
	var step: = 1 if dir == "down" else -1
	(_items[(cur + step + _items.size()) % _items.size()] as Control).grab_focus()
	UiStyle.sfx("hover")

func _on_focus_exited() -> void :
	if not _open:
		return

	call_deferred("_collapse_if_focus_left")

func _collapse_if_focus_left() -> void :
	if not _open:
		return



	if not InputPrompts.using_gamepad():
		return
	var foc: = get_viewport().gui_get_focus_owner()
	if foc == self or _items.has(foc):
		return
	_collapse()

func _exit_tree() -> void :
	if active == self:
		active = null
	if _layer != null:
		_layer.queue_free()
