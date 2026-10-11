extends Node

## On-screen controls for phones and tablets.
##
## The pad drives the same [InputMap] actions the keyboard does, so nothing else
## in the game has to know it exists: [DeviceInput], [InputCollector],
## [InputPrompts], rebinding, the tutorial overlays and the HUD control legend
## all keep working unchanged. Held actions go through [method
## Input.action_press] (which keeps [method Input.is_action_just_pressed] correct
## and carries thumbstick strength); taps go through [method
## Input.parse_input_event] as [InputEventAction] because the camera cycle and
## zoom are read from events rather than from action state.
##
## It is drawn with what the rest of the UI already uses: [UiStyle] round slabs,
## the Nunito family, the black glyph set in [code]game/ui_icon[/code]. The
## action buttons take their names from the same [method Hud.update_controls]
## call that drives the desktop legend, and the pad stands in for that legend
## while it is up.
##
## [b]Aim and look do not come from the mouse.[/b] Mobile display servers never
## report [constant Input.MOUSE_MODE_CAPTURED], so both of the game's mouse
## branches are unreachable there; the pad pushes the aim point into
## [member InputCollector.touch_aim] and the look delta into
## [method CameraRig.touch_look] instead.

## Canvas layer: above the HUD (layer 1), below modal dialogs (layer 95).
const LAYER: = 60

## Layout as multiples of viewport height - [code]x[/code] is how far in from the
## right edge a control sits, [code]y[/code] how far up from the bottom. Sizing
## off the short edge keeps the pad right on anything from 16:9 to 21:9 and in
## both orientations.
const STICK_AT: = Vector2(0.250, 0.240)
const STICK_R: = 0.118
const STICK_GRAB: = 1.32
const KNOB_R: = 0.054
const TOP_SAFE: = 0.135
const UTIL_R: = 0.036
const UTIL_GAP: = 0.018

## [code]live[/code] buttons borrow the legend's dynamic name: the HUD renames
## the action tile to whatever the next touch will be (bump / spike / dump /
## toss) and the dive tile to block while the player is airborne.
const BUTTONS: = [
	{"action": "contact", "label": "hit", "at": Vector2(0.155, 0.190), "r": 0.088, "kind": "primary", "live": "action"},
	{"action": "jump", "label": "jump", "at": Vector2(0.350, 0.128), "r": 0.072, "kind": "card", "live": ""},
	{"action": "set", "label": "set", "at": Vector2(0.152, 0.408), "r": 0.070, "kind": "blue", "live": ""},
	{"action": "dive", "label": "dive", "at": Vector2(0.330, 0.352), "r": 0.070, "kind": "pink", "live": "dive"},
	{"action": "strafe", "label": "strafe", "at": Vector2(0.482, 0.220), "r": 0.058, "kind": "ghost", "live": ""},
]

## Top-right strip, drawn with [method UiStyle.icon_button] like every other icon
## button in the game.
const UTILS: = [
	{"icon": "pause", "action": "menu_start", "hint": "pause menu"},
	{"icon": "leaderboardsSimple", "action": "stats", "hint": "scoreboard"},
	{"icon": "video", "action": "camera_toggle", "hint": "camera"},
	{"icon": "zoomIn", "action": "camera_zoom", "hint": "zoom"},
	{"icon": "target", "action": "aim_recenter", "hint": "aim assist"},
]

## Everything the pad can hold down, released together the moment it stops being
## live so a scene change can never leave the player jogging into a wall.
const HELD: = [
	"move_left", "move_right", "move_forward", "move_back", 
	"jump", "contact", "set", "dive", "serve", "strafe", 
]

const MOUSE_ID: = -1


## Auto / on / off, resolved from [member GameConfig.touch_controls] and the
## matching command line switches.
var enabled: = false

var _live: = false
var _layer: CanvasLayer
var _root: Control
var _stick_base: Panel
var _stick_rim: Panel
var _stick_knob: Panel
var _stick_hint: Label
var _stick_center: = Vector2.ZERO
var _stick_travel: = 1.0
var _stick_grab: = 1.0
var _stick_origin: = Vector2.ZERO
var _stick_vector: = Vector2.ZERO
var _buttons: Array = []
var _utils: Array = []
var _utility_rect: = Rect2()
var _size: = Vector2(1920.0, 1080.0)
var _fade: Tween

var _rig: CameraRig = null
var _collector: InputCollector = null

## Touch ids (the mouse uses [constant MOUSE_ID]) mapped to what they grabbed.
var _pointers: = {}
## Action name -> the action actually pressed, which differs from the button's
## own action while the hit button is doubling as the serve button.
var _held: = {}
var _look_last: = Vector2.INF

## Kept in step with the HUD legend so the two never disagree on screen.
var _legend_action: = "hit"
var _legend_dive: = "dive"
var _legend_on: = {"action": true, "dive": true, "jump": true, "set": true}


func _ready() -> void :
	_build()
	get_viewport().size_changed.connect(_layout)
	_refresh_enabled()
	call_deferred("_layout")


## Called by [Main] and [OpenGym] once their rig and collector exist.
func bind(rig: CameraRig, collector: InputCollector) -> void :
	_refresh_enabled()
	_rig = rig
	_collector = collector
	_look_last = Vector2.INF
	if enabled and _collector != null and _collector.touch_aim == Vector2.INF:
		_aim_to_center()
	_layout()

func unbind(rig: CameraRig) -> void :
	if rig != null and rig != _rig:
		return
	_release_all()
	if _collector != null:
		_collector.touch_aim = Vector2.INF
	_rig = null
	_collector = null
	set_live(false)


## True while the pad is up and claiming touches. The HUD asks so it can drop its
## own legend, which only shows keyboard and controller glyphs.
func active() -> bool:
	return _live


## [param live] is false in menus, cinematics, replays, spectator mode, with the
## pause menu open and while the chat box has the keyboard - everywhere a touch
## belongs to the interface instead of the player.
func set_live(on: bool) -> void :
	var want: = on and enabled and _rig != null
	if want == _live:
		if not want:
			_clear_holds()
		return
	_live = want
	_release_all()
	if _fade != null and _fade.is_valid():
		_fade.kill()
	if _live:
		if _collector != null and _collector.touch_aim == Vector2.INF:
			_aim_to_center()
		_root.modulate.a = 0.0
		_layer.visible = true
		_fade = create_tween()
		_fade.tween_property(_root, "modulate:a", 1.0, 0.20)
	else:
		_fade = create_tween()
		_fade.tween_property(_root, "modulate:a", 0.0, 0.14)
		_fade.tween_callback(_drop_layer)


func _drop_layer() -> void :
	if not _live:
		_layer.visible = false


## Mirrors [method Hud.update_controls] so a round button reads "bump" or "block"
## the same moment the desktop legend does, and dims to the same 35% when the
## action is unavailable.
func sync_legend(action_text: String, action_on: bool, dive_on: bool, 
		jump_on: bool, set_on: bool, m2_text: String) -> void :
	_legend_action = action_text
	_legend_dive = m2_text
	_legend_on.action = action_on
	_legend_on.dive = dive_on
	_legend_on.jump = jump_on
	_legend_on.set = set_on
	if not enabled:
		return
	for spec in _buttons:
		var btn: Button = spec.node
		var key: = String(spec.live)
		var label: = String(spec.label)
		if key == "action":
			label = action_text
		elif key == "dive":
			label = m2_text
		if btn.text != label:
			btn.text = label
		var on: bool = bool(_legend_on.get(key, true)) if key != "" else true
		btn.modulate.a = 1.0 if on else 0.35


## Re-resolves the auto / on / off setting, for the settings panel to call when
## the player changes it.
func refresh_mode() -> void :
	_refresh_enabled()


func _refresh_enabled() -> void :
	var mode: = 0
	if GameConfig != null:
		mode = int(GameConfig.touch_controls)
	var args: = OS.get_cmdline_user_args()
	if args.has("--touch"):
		mode = 1
	elif args.has("--no-touch"):
		mode = 2
	if mode == 0:
		mode = 1 if (DisplayServer.is_touchscreen_available() 
			or OS.has_feature("mobile")) else 2
	enabled = mode == 1
	if enabled:
		_layer.visible = _live
	else:
		set_live(false)


## A desktop has no touch screen, so there the pointer drives the pad - that is
## what makes it testable without a device.
func _pointer_drives_pad() -> bool:
	return not (DisplayServer.is_touchscreen_available() or OS.has_feature("mobile"))


# Build and lay out


func _build() -> void :
	_layer = CanvasLayer.new()
	_layer.name = "TouchLayer"
	_layer.layer = LAYER
	_layer.visible = false
	add_child(_layer)

	_root = Control.new()
	_root.name = "Pad"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_root)

	_stick_base = Panel.new()
	_stick_base.name = "StickBase"
	_stick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_stick_base)

	_stick_rim = Panel.new()
	_stick_rim.name = "StickRim"
	_stick_rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_stick_rim)

	_stick_knob = Panel.new()
	_stick_knob.name = "StickKnob"
	_stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_stick_knob)

	_stick_hint = Label.new()
	_stick_hint.name = "StickHint"
	_stick_hint.text = "move"
	_stick_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.outlined_label(_stick_hint, 13)
	_root.add_child(_stick_hint)

	for spec in BUTTONS:
		var btn: = Button.new()
		btn.name = "T_" + String(spec.action)
		btn.text = String(spec.label)
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.clip_text = true
		_root.add_child(btn)
		_buttons.append({
			"node": btn, 
			"action": String(spec.action), 
			"label": String(spec.label), 
			"kind": String(spec.kind), 
			"at": spec.at, 
			"r": float(spec.r), 
			"live": String(spec.live), 
			"center": Vector2.ZERO, 
			"radius": 0.0, 
		})

	for spec in UTILS:
		var ub: = UiStyle.icon_button(String(spec.icon), "secondary", 52)
		ub.name = "U_" + String(spec.action)
		ub.tooltip_text = String(spec.hint)
		ub.mouse_filter = Control.MOUSE_FILTER_STOP
		ub.pressed.connect(_tap.bind(String(spec.action)))
		_root.add_child(ub)
		_utils.append(ub)


func _layout() -> void :
	_size = get_viewport().get_visible_rect().size
	if _size.y <= 1.0:
		return
	var h: = _size.y
	var w: = _size.x

	var base_r: = STICK_R * h
	var knob_r: = KNOB_R * h
	_stick_center = Vector2(STICK_AT.x * h, h - STICK_AT.y * h)
	_stick_travel = maxf(base_r - knob_r, 1.0)
	_stick_grab = base_r * STICK_GRAB
	_place(_stick_base, _stick_center, base_r)
	_place(_stick_rim, _stick_center, base_r)
	_place(_stick_knob, _stick_center, knob_r)
	_style(_stick_base, UiStyle.disc_box(Color(UiStyle.INK, 0.20)))
	_style(_stick_rim, UiStyle.disc_box(Color(0, 0, 0, 0), 
		Color(1, 1, 1, 0.42), 3, base_r))
	_style(_stick_knob, UiStyle.disc_box(Color.WHITE, UiStyle.INK, 3, knob_r))
	_stick_hint.size = Vector2(base_r * 2.8, 20.0)
	_stick_hint.position = Vector2(_stick_center.x - base_r * 1.4, 
		_stick_center.y + base_r + 2.0)
	_stick_knob.position = _stick_center - _stick_knob.size * 0.5

	for spec in _buttons:
		var center: = Vector2(w - float(spec.at.x) * h, h - float(spec.at.y) * h)
		spec.center = center
		spec.radius = float(spec.r) * h
		_place(spec.node, center, float(spec.radius))
		var size: = float(spec.radius) * 0.52
		if String(spec.action) == "strafe":
			size = float(spec.radius) * 0.42
		spec.node.add_theme_font_size_override("font_size", maxi(int(round(size)), 12))
		_paint(spec.node, String(spec.kind), false, float(spec.radius))

	var u: = UTIL_R * h
	var pitch: = u * 2.0 + UTIL_GAP * h
	var right: = 0.028 * h
	var top: = 0.028 * h
	var x: = w - right - u * 2.0
	var left: = x
	for ub in _utils:
		ub.size = Vector2(u * 2.0, u * 2.0)
		ub.position = Vector2(x, top)
		left = minf(left, x)
		x -= pitch
	_utility_rect = Rect2(left - 8.0, top - 8.0, 
		(w - right - left) + u * 2.0 + 16.0, u * 2.0 + 16.0)


func _place(c: Control, center: Vector2, radius: float) -> void :
	c.size = Vector2.ONE * radius * 2.0
	c.position = center - Vector2.ONE * radius
	c.pivot_offset = Vector2.ONE * radius


func _style(c: Control, skin: StyleBoxFlat) -> void :
	if c is Panel:
		(c as Panel).add_theme_stylebox_override("panel", skin)


func _palette(kind: String) -> Dictionary:
	match kind:
		"card":
			return {"fill": UiStyle.card(), "text": UiStyle.SECONDARY}
		"blue":
			return {"fill": UiStyle.SECONDARY, "text": Color.WHITE}
		"pink":
			return {"fill": UiStyle.HIGHLIGHT, "text": Color.WHITE}
		"ghost":
			return {"fill": Color(UiStyle.MUTED, 0.62), "text": Color.WHITE}
		_:
			return {"fill": UiStyle.PRIMARY, "text": UiStyle.INK}


func _paint(btn: Button, kind: String, held: bool, radius: float) -> void :
	var pal: = _palette(kind)
	var text: Color = pal.text
	var skin: = UiStyle.round_slab(pal.fill, held, radius)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(state, skin)
	for state in ["font_color", "font_hover_color", "font_pressed_color", 
		"font_hover_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(state, text)
	if text == Color.WHITE:
		btn.add_theme_constant_override("outline_size", 4)
		btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
	btn.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))


# Input


func _input(event: InputEvent) -> void :
	# The tree is paused behind the pause menu, and the menu owns every touch
	# while it is up. [method set_live] normally catches that first; this is the
	# belt to its braces, because a paused tree stops [method Main._process] too.
	if not _live or get_tree().paused:
		return
	if event is InputEventScreenTouch:
		var st: = event as InputEventScreenTouch
		if st.pressed:
			_pointer_down(st.index, st.position)
		else:
			_pointer_up(st.index)
		return
	if event is InputEventScreenDrag:
		var sd: = event as InputEventScreenDrag
		_pointer_move(sd.index, sd.position)
		return
	if not _pointer_drives_pad():
		return
	if event is InputEventMouseButton:
		var mb: = event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_pointer_down(MOUSE_ID, mb.position)
		else:
			_pointer_up(MOUSE_ID)
	elif event is InputEventMouseMotion and _pointers.has(MOUSE_ID):
		_pointer_move(MOUSE_ID, (event as InputEventMouseMotion).position)


func _pointer_down(id: int, pos: Vector2) -> void :
	if _pointers.has(id):
		return
	var zone: = _zone_at(pos)
	if zone == "":
		return
	_pointers[id] = zone
	match zone:
		"stick":
			_stick_origin = pos
			_stick_drag(pos)
		"look":
			_look_last = pos
			_aim(pos)
		_:
			_button_press(zone.trim_prefix("btn:"))
	get_viewport().set_input_as_handled()


func _pointer_move(id: int, pos: Vector2) -> void :
	if not _pointers.has(id):
		return
	var zone: = String(_pointers[id])
	if zone == "stick":
		_stick_drag(pos)
	elif zone == "look":
		_look_drag(pos)
	else:
		_button_slide(id, zone.trim_prefix("btn:"), pos)
	get_viewport().set_input_as_handled()


func _pointer_up(id: int) -> void :
	if not _pointers.has(id):
		return
	var zone: = String(_pointers[id])
	_pointers.erase(id)
	if zone == "stick":
		_stick_release()
	elif zone == "look":
		_look_last = Vector2.INF
	else:
		_button_release(zone.trim_prefix("btn:"))
	get_viewport().set_input_as_handled()


## What a touch at [param pos] grabs: the stick, a held action, or the aim and
## look area. Anything left unclaimed still belongs to the interface, which is
## what keeps the menus, the scoreboard panel and the pause button usable.
func _zone_at(pos: Vector2) -> String:
	if pos.y < TOP_SAFE * _size.y:
		return ""
	if _utility_rect.has_point(pos):
		return ""
	for spec in _buttons:
		if pos.distance_to(spec.center) <= float(spec.radius) * 1.08:
			return "btn:" + String(spec.action)
	if pos.distance_to(_stick_center) <= _stick_grab:
		return "stick"
	return "look"


func _stick_drag(pos: Vector2) -> void :
	_stick_vector = ((pos - _stick_origin) / _stick_travel).limit_length(1.0)
	_stick_apply()


func _stick_release() -> void :
	_stick_vector = Vector2.ZERO
	_stick_apply()


func _stick_apply() -> void :
	var v: = _stick_vector
	_hold("move_right", maxf(v.x, 0.0))
	_hold("move_left", maxf( - v.x, 0.0))
	_hold("move_back", maxf(v.y, 0.0))
	_hold("move_forward", maxf( - v.y, 0.0))
	_stick_knob.position = _stick_center + v * _stick_travel\
		- _stick_knob.size * 0.5
	_stick_knob.modulate = Color.WHITE if v != Vector2.ZERO else Color(1, 1, 1, 0.8)


## The right thumb aims: on a phone that is the same ray the desktop builds from
## the mouse cursor, just placed with a finger.
func _aim(pos: Vector2) -> void :
	if _collector != null:
		_collector.touch_aim = pos


func _look_drag(pos: Vector2) -> void :
	_aim(pos)
	if _rig != null and _look_last != Vector2.INF:
		_rig.touch_look(pos - _look_last)
	_look_last = pos


func _hold(action: String, value: float) -> void :
	if value > 0.004:
		Input.action_press(action, clampf(value, 0.0, 1.0))
	else:
		Input.action_release(action)


func _button_press(action: String) -> void :
	if _held.has(action):
		return
	var send: = "serve" if (action == "contact" and _legend_action == "toss") else action
	_held[action] = send
	Input.action_press(send)
	_press_skin(action, true)
	_feedback(action)


func _button_release(action: String) -> void :
	if not _held.has(action):
		return
	Input.action_release(String(_held[action]))
	_held.erase(action)
	_press_skin(action, false)


## A thumb rolling from one button onto the next swaps the held action instead of
## leaving the first one stuck down.
func _button_slide(id: int, current: String, pos: Vector2) -> void :
	for spec in _buttons:
		if pos.distance_to(spec.center) > float(spec.radius) * 1.08:
			continue
		var next: = String(spec.action)
		if next == current:
			return
		_button_release(current)
		_pointers[id] = "btn:" + next
		_button_press(next)
		return


func _press_skin(action: String, down: bool) -> void :
	for spec in _buttons:
		if String(spec.action) == action:
			_paint(spec.node, String(spec.kind), down, float(spec.radius))
			return


func _feedback(action: String) -> void :
	for spec in _buttons:
		if String(spec.action) != action:
			continue
		UiStyle.press_bounce(spec.node)
		break
	UiStyle.sfx("confirm" if action == "contact" else "press")


## One-frame action tap, delivered as an [InputEventAction] so the handlers that
## read events - the camera cycle and zoom in [CameraRig], the pause toggle in
## [Hud] - see it exactly as they would a key press.
func _tap(action: String) -> void :
	var down: = InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	var up: = InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	UiStyle.sfx("press")


func _release_all() -> void :
	for action in _held.values():
		Input.action_release(String(action))
	_held.clear()
	for action in HELD:
		if InputMap.has_action(action):
			Input.action_release(action)
	_pointers.clear()
	_stick_vector = Vector2.ZERO
	_stick_apply()
	_look_last = Vector2.INF


## Cheap guard so the pad does not re-release ten actions every frame while it
## sits hidden through a menu or a cinematic.
func _clear_holds() -> void :
	if _held.is_empty() and _stick_vector == Vector2.ZERO and _pointers.is_empty():
		return
	_release_all()


func _aim_to_center() -> void :
	if _collector != null:
		_collector.touch_aim = _size * 0.5
