class_name PauseMenu
extends Control









signal opened
signal closed


signal seat_requested(side: int)

@export var pauses_tree: = true


func set_teams_available(on: bool) -> void :
	$PausePanel / PauseBox / TeamsBtn.visible = on



func set_seat_options(blue_free: int, red_free: int, playing: bool) -> void :
	var box: = $TeamsPopup / TeamsBox
	var blue: Button = box.get_node("BlueBtn")
	var red: Button = box.get_node("RedBtn")
	var watch: Button = box.get_node("WatchBtn")
	blue.disabled = blue_free <= 0
	red.disabled = red_free <= 0
	blue.text = "join home" if blue_free > 0 else "home is full"
	red.text = "join away" if red_free > 0 else "away is full"
	blue.add_theme_color_override("font_color", Rules.HOME_COLOR)
	red.add_theme_color_override("font_color", Rules.AWAY_COLOR)
	watch.disabled = not playing

var _open: = false
var _prev_mouse_mode: = Input.MOUSE_MODE_VISIBLE


var _code_panel: PanelContainer = null
var _code_val: Label = null
var _code_btn: Button = null
var _code_eye: Button = null
var _code_shown: = false


var leave_override: = Callable()
var _tutorial_skip: = Callable()


func set_tutorial_skip(cb: Callable) -> void :
	_tutorial_skip = cb
	var how: = $PausePanel / PauseBox / HowToBtn as Button
	if cb.is_valid():
		_style_pause_card(how, "arrowRight", "skip tutorial", "jump to the end", false)
	else:
		_style_pause_card(how, "question", "how to play", "controls & rules", false)




var _opened_frame: = -1

func _ready() -> void :

	process_mode = Node.PROCESS_MODE_ALWAYS
	$PausePanel / PauseBox / ResumeBtn.pressed.connect( func(): set_open(false))
	$PausePanel / PauseBox / SettingsBtn.pressed.connect( func():
		$PausePanel.visible = false
		$SettingsPopup.visible = true)
	$SettingsPopup / SettingsBox / SettingsBackBtn.pressed.connect( func():
		$SettingsPopup.visible = false
		$PausePanel.visible = true)




	var settings_panel: = $SettingsPopup / SettingsBox / Panel as SettingsPanel

	settings_panel.set_scope(SettingsPanel.Scope.ALL)
	settings_panel.retheme_requested.connect( func(_dark: bool):
		UiStyle.wash(self)
		settings_panel.rebuild())


	$PausePanel / PauseBox / TeamsBtn.pressed.connect( func():
		$PausePanel.visible = false
		$TeamsPopup.visible = true)
	for pair in [["BlueBtn", 1], ["RedBtn", -1], ["WatchBtn", 0]]:
		var side: int = pair[1]
		($TeamsPopup / TeamsBox).get_node(String(pair[0])).pressed.connect( func():
			seat_requested.emit(side)
			set_open(false))
	$TeamsPopup / TeamsBox / TeamsBackBtn.pressed.connect( func():
		$TeamsPopup.visible = false
		$PausePanel.visible = true)
	$PausePanel / PauseBox / HowToBtn.pressed.connect( func():


		if _tutorial_skip.is_valid():
			set_open(false)
			_tutorial_skip.call()
			return
		$PausePanel.visible = false
		$HowToPopup.visible = true)
	$HowToPopup / HowToBox / HowToBackBtn.pressed.connect( func():
		$HowToPopup.visible = false
		$PausePanel.visible = true)
	$PausePanel / PauseBox / MenuBtn.pressed.connect( func():
		if leave_override.is_valid():
			set_open(false)
			leave_override.call()
			return




		_set_paused(false)



		var local_match: = not Net.active and not Net.party\
		and not GameConfig.tutorial_finale\
		and get_tree().current_scene != null\
		and get_tree().current_scene.scene_file_path == "res://game/main/main.tscn"

		if Net.party:





			if Net.is_host:
				Net.send_event("regroup" if Net.gym_session else "to_lobby", {})
			Net.end_match()
		elif Net.active and Net.custom_lobby and Net.is_host:


			Net.send_event("to_lobby", {})
			Net.end_match()
		elif Net.active:


			Net.leave()
		if local_match:
			GameConfig.menu_return_local = true
		GameConfig.goto_scene("res://game/ui/menu.tscn"))
	$PausePanel / PauseBox / ExitBtn.pressed.connect( func():


		_set_paused(false)
		if Net.active:
			Net.leave()
		# quit_app, not get_tree().quit(): on a phone the latter only stops the
		# main loop and leaves the last frame frozen on screen.
		GameConfig.quit_app())


	UiStyle.wash(self)



	for panel in [$PausePanel, $SettingsPopup, $HowToPopup, $TeamsPopup]:
		panel.visibility_changed.connect(_on_panel_shown.bind(panel))
	_restyle_pause_menu()





func _restyle_pause_menu() -> void :
	var p: = $PausePanel as PanelContainer
	p.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	p.anchor_left = 0.0
	p.anchor_right = 0.0
	p.anchor_top = 0.5
	p.anchor_bottom = 0.5
	p.offset_left = 48.0
	p.offset_right = 540.0
	p.offset_top = -250.0
	p.offset_bottom = 250.0
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	var box: = $PausePanel / PauseBox as VBoxContainer
	box.add_theme_constant_override("separation", 14)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var title: = $PausePanel / PauseBox / PauseTitle as Label
	title.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_style_pause_card($PausePanel / PauseBox / ResumeBtn, "arrowRight", 
		"resume", "back to the match", true)
	_style_pause_card($PausePanel / PauseBox / SettingsBtn, "gear", 
		"settings", "audio, video, display", false)
	_style_pause_card($PausePanel / PauseBox / TeamsBtn, "multiplayer", 
		"teams", "switch sides", false)
	_style_pause_card($PausePanel / PauseBox / HowToBtn, "question", 
		"how to play", "controls & rules", false)

	var m_title: = "back to menu"
	var m_sub: = "leave the match"
	if Net.party:
		m_title = "back to party"
		m_sub = "return to your squad"
	elif Net.active and Net.custom_lobby and Net.is_host:


		m_title = "back to lobby"
		m_sub = "return to the room"
	elif Net.active and not Net.party:
		m_sub = "leave the match and the room"
	_style_pause_card($PausePanel / PauseBox / MenuBtn, "home", m_title, m_sub, false)


	_style_pause_card($PausePanel / PauseBox / ExitBtn, "exit", "exit game", 
		"close the game", false)



func _style_pause_card(b: Button, icon_name: String, title: String, 
		sub: String, primary: bool) -> void :
	b.text = ""
	b.custom_minimum_size = Vector2(452, 76)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.clip_contents = false
	var fill: = UiStyle.PRIMARY if primary else UiStyle.card()
	for state in [["normal", fill, 9], ["hover", fill.lightened(0.06), 9], 
			["pressed", fill.darkened(0.05), 3], 
			["focus", fill.lightened(0.06), 9], 
			["disabled", Color(UiStyle.muted(), 0.3), 3]]:
		var boxs: = StyleBoxFlat.new()
		boxs.bg_color = state[1]
		boxs.set_corner_radius_all(18)
		boxs.border_width_bottom = int(state[2])
		boxs.border_color = (state[1] as Color).darkened(0.3)
		boxs.shadow_color = Color(0, 0, 0, 0.42)
		boxs.shadow_size = 12
		boxs.shadow_offset = Vector2(4, 8)
		b.add_theme_stylebox_override(String(state[0]), boxs)

	for c in b.get_children():
		c.queue_free()
	var pad: = MarginContainer.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_left", 16)
	pad.add_theme_constant_override("margin_right", 16)
	b.add_child(pad)
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(row)
	var disc: = TextureRect.new()
	disc.texture = UiStyle.icon_disc(icon_name, 
		UiStyle.INK if primary else UiStyle.SECONDARY, 54, true)
	disc.custom_minimum_size = Vector2(54, 54)
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
	UiStyle.style_label(t, "title", UiStyle.INK if primary else UiStyle.text())
	t.add_theme_font_size_override("font_size", 25)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(t)
	var s: = Label.new()
	s.text = sub
	UiStyle.style_label(s, "small", 
		Color(UiStyle.INK, 0.66) if primary else UiStyle.muted())
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(s)
	if b not in _tilt:
		_tilt.append(b)




var _tilt: Array = []
func _tilt_cards(delta: float) -> void :
	if _tilt.is_empty():
		return
	var vp: = get_viewport().get_visible_rect().size
	if vp.x <= 0.0:
		return
	var mouse: = get_viewport().get_mouse_position()
	var off: = (mouse / vp) - Vector2(0.5, 0.5)
	var k: = clampf(delta * 9.0, 0.0, 1.0)
	var depth: = 0
	for c in _tilt:
		var card: = c as Button
		if not is_instance_valid(card) or not card.is_visible_in_tree():
			continue
		card.offset_transform_enabled = true
		card.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
		var hovered: = card.has_focus() or card.get_global_rect().has_point(mouse)
		var recede: = 1.0 - 0.026 * float(depth)
		var fan: = 0.028 - 0.016 * float(depth)
		var want_rot: = 0.0 if hovered else fan - off.x * 0.06
		var want_scale: = 1.07 if hovered else recede - absf(off.x) * 0.012
		var want_x: = (52.0 if hovered else 8.0 * float(depth))\
		- off.x * (26.0 + 8.0 * float(depth))
		card.offset_transform_rotation = lerpf(
			card.offset_transform_rotation, want_rot, k)
		card.offset_transform_scale = card.offset_transform_scale.lerp(
			Vector2.ONE * want_scale, k)
		card.offset_transform_position.x = lerpf(
			card.offset_transform_position.x, want_x, k)
		card.z_index = 2 if hovered else 0
		depth += 1

func _on_panel_shown(panel: Control) -> void :




	if _open and panel.visible and InputPrompts.using_gamepad():
		_focus_first_visible.call_deferred()

func _set_paused(value: bool) -> void :

	if not is_inside_tree():
		return
	get_tree().paused = value

func is_open() -> bool:
	return _open

func toggle() -> void :
	set_open( not _open)

func set_open(value: bool) -> void :
	_open = value
	if pauses_tree:
		_set_paused(value)
	_refresh_code_panel(value)
	$PausePanel.visible = value


	if not value:
		$SettingsPopup.visible = false
		$HowToPopup.visible = false
		$TeamsPopup.visible = false
	if value:



		UiStyle.pop_in($PausePanel)
		UiStyle.stagger_reveal($PausePanel / PauseBox, 0.05, 1)
		_opened_frame = Engine.get_process_frames()
		_prev_mouse_mode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Haptics.stop()
		opened.emit()
	else:
		Input.mouse_mode = _prev_mouse_mode
		closed.emit()




func _refresh_code_panel(opening: bool) -> void :



	var code: = Net.lobby_code()
	var want: = opening and code != ""
	if not want:
		if _code_panel != null:
			_code_panel.visible = false
		return
	_ensure_code_panel()
	_code_shown = false
	_refresh_code_text()
	_code_btn.text = "copy"
	_code_panel.visible = true

func _refresh_code_text() -> void :
	var code: = Net.lobby_code()
	_code_val.text = code if _code_shown else "•".repeat(code.length())
	_code_eye.text = "hide" if _code_shown else "show"

func _ensure_code_panel() -> void :
	if _code_panel != null:
		return
	_code_panel = PanelContainer.new()
	UiStyle.style_panel(_code_panel, UiStyle._AUTO, UiStyle.RADIUS)
	_code_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_code_panel.offset_top = 24.0
	_code_panel.offset_right = -24.0
	_code_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_code_panel.grow_vertical = Control.GROW_DIRECTION_END
	_code_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_code_panel)
	var pad: = MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + s, 12)
	_code_panel.add_child(pad)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pad.add_child(v)
	var head: = Label.new()
	head.text = "lobby code:"
	head.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	head.add_theme_font_size_override("font_size", 14)
	head.add_theme_color_override("font_color", UiStyle.muted())
	v.add_child(head)


	var val_row: = HBoxContainer.new()
	val_row.add_theme_constant_override("separation", 8)
	v.add_child(val_row)
	_code_val = Label.new()
	_code_val.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	_code_val.add_theme_font_size_override("font_size", 18)
	_code_val.add_theme_color_override("font_color", UiStyle.text())
	_code_val.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	val_row.add_child(_code_val)
	_code_eye = Button.new()
	_code_eye.text = "show"
	UiStyle.style_button(_code_eye, "tertiary", 12)
	_code_eye.custom_minimum_size.x = 64
	_code_eye.tooltip_text = "show or hide the lobby code"
	_code_eye.pressed.connect( func():
		_code_shown = not _code_shown
		_refresh_code_text())
	val_row.add_child(_code_eye)
	_code_btn = Button.new()
	_code_btn.text = "copy"
	UiStyle.style_button(_code_btn, "primary", 14)
	_code_btn.pressed.connect(_copy_code)
	v.add_child(_code_btn)

func _copy_code() -> void :
	var code: = Net.lobby_code()
	if code == "":
		return
	DisplayServer.clipboard_set(code)
	UiStyle.sfx("confirm")
	if _code_btn != null:
		_code_btn.text = "copied!"
		var tw: = create_tween()
		tw.tween_interval(1.2)
		tw.tween_callback( func(): if is_instance_valid(_code_btn): _code_btn.text = "copy")





const _NAV_FIRST: = 0.42
const _NAV_REPEAT: = 0.11
const _NAV_DEBOUNCE: = 0.07
const _BTN_DEBOUNCE: = 0.22
var _nav_dir: = ""
var _nav_repeat: = 0.0
var _nav_cd: = 0.0
var _acc_cd: = 0.0
var _can_cd: = 0.0
var _tab_cd: = 0.0

func _process(delta: float) -> void :
	if _open:
		_poll_nav(delta)
		_tilt_cards(delta)

func _poll_nav(delta: float) -> void :
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return
	_nav_cd = maxf(_nav_cd - delta, 0.0)
	_acc_cd = maxf(_acc_cd - delta, 0.0)
	_can_cd = maxf(_can_cd - delta, 0.0)
	_tab_cd = maxf(_tab_cd - delta, 0.0)

	if UiStyle.dialog_active():
		UiStyle.drive_dialog(delta)
		return

	if _tab_cd <= 0.0 and UiSelect.active == null and $SettingsPopup.visible:
		var panel: = $SettingsPopup / SettingsBox / Panel as SettingsPanel
		if Input.is_action_just_pressed("menu_zone_next"):
			_tab_cd = _BTN_DEBOUNCE
			panel.cycle_tab(1)
			return
		elif Input.is_action_just_pressed("menu_zone_prev"):
			_tab_cd = _BTN_DEBOUNCE
			panel.cycle_tab(-1)
			return

	if Input.is_action_just_pressed("ui_accept") and _acc_cd <= 0.0:
		_acc_cd = _BTN_DEBOUNCE
		_activate(get_viewport().gui_get_focus_owner() as Control)


	if Input.is_action_just_pressed("ui_cancel") and _can_cd <= 0.0\
	and Engine.get_process_frames() != _opened_frame:
		_can_cd = _BTN_DEBOUNCE
		_nav_back()
		return

	var dir: = ""
	if Input.is_action_pressed("ui_down"): dir = "down"
	elif Input.is_action_pressed("ui_up"): dir = "up"
	elif Input.is_action_pressed("ui_right"): dir = "right"
	elif Input.is_action_pressed("ui_left"): dir = "left"
	if dir == "":
		_nav_dir = ""
		return
	if dir != _nav_dir:
		_nav_dir = dir
		_nav_repeat = _NAV_FIRST
		if _nav_cd <= 0.0:
			_nav_cd = _NAV_DEBOUNCE
			_nav_step(dir)
	elif _nav_repeat <= 0.0:
		_nav_repeat = _NAV_REPEAT
		_nav_step(dir)
	else:
		_nav_repeat -= delta

func _activate(foc: Control) -> void :
	if foc is UiSelect and not (foc as UiSelect).is_open():
		(foc as UiSelect).open_and_focus()
	elif foc is BaseButton and not (foc as BaseButton).disabled:
		var b: = foc as BaseButton
		if b.toggle_mode:
			b.button_pressed = not b.button_pressed
			UiStyle.sfx("tick")
		else:
			b.pressed.emit()
	elif foc == null:
		_focus_first_visible()

func _nav_step(dir: String) -> void :
	if UiSelect.active != null:
		UiSelect.active.step_focus(dir)
		return
	var foc: = get_viewport().gui_get_focus_owner() as Control
	if foc == null or not foc.is_visible_in_tree():
		_focus_first_visible()
		return

	if foc is Range and (dir == "left" or dir == "right"):
		var r: = foc as Range

		var st: float = maxf(r.step, (r.max_value - r.min_value) / 10.0)
		r.value += st if dir == "right" else - st
		UiStyle.sfx("tick")
		return
	var side: = SIDE_TOP
	match dir:
		"down": side = SIDE_BOTTOM
		"left": side = SIDE_LEFT
		"right": side = SIDE_RIGHT
	var nxt: = foc.find_valid_focus_neighbor(side)
	if nxt != null and nxt != foc:
		nxt.grab_focus()
		UiStyle.sfx("hover")

func _nav_back() -> void :
	if UiSelect.active != null:
		UiSelect.active.close()
		return

	for popup in [$SettingsPopup, $HowToPopup, $TeamsPopup]:
		if (popup as Control).visible:
			(popup as Control).visible = false
			$PausePanel.visible = true
			return
	set_open(false)

func _focus_first_visible() -> void :
	var root: Control = null
	for c in [$PausePanel, $SettingsPopup, $HowToPopup, $TeamsPopup]:
		if (c as Control).visible:
			root = c
			break
	if root == null:
		return
	for b in root.find_children("*", "BaseButton", true, false):
		var btn: = b as BaseButton
		if btn != null and btn.is_visible_in_tree() and not btn.disabled\
		and btn.focus_mode != Control.FOCUS_NONE:
			btn.grab_focus()
			return

func _input(event: InputEvent) -> void :



	if not _open:
		return
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return

	if event is InputEventMouseButton or (event is InputEventMouseMotion\
	and (event as InputEventMouseMotion).relative.length() > 6.0):
		if get_viewport().gui_get_focus_owner() != null:
			get_viewport().gui_release_focus.call_deferred()
		return
	for a in ["ui_accept", "ui_up", "ui_down", "ui_left", "ui_right", "ui_cancel"]:
		if event.is_action_pressed(a):
			get_viewport().set_input_as_handled()
			return
