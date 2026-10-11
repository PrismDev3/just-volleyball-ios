class_name Hud
extends Control




const TOUCH_NAMES: = {
	Player.TouchKind.NONE: "--", 
	Player.TouchKind.BUMP: "bump", 
	Player.TouchKind.SET: "set", 
	Player.TouchKind.SPIKE: "spike", 
	Player.TouchKind.DUMP: "dump", 
	Player.TouchKind.BLOCK: "block", 
}
const STATS_BOARD: = preload("res://game/ui/stats_board.tscn")
const STATS_DRAWER: = preload("res://game/ui/stats_drawer.gd")




const CONTROL_FLASH_TIME: = 0.11
const CONTROL_FLASH_GREY: = 0.58
const CONTROL_ACTIONS: = {
	"Action": "contact", 
	"Set": "set", 
	"Dive": "dive", 
	"Jump": "jump", 
	"Strafe": "strafe", 
}
var _control_flash_left: Dictionary = {}


var _control_icons: Dictionary = {}
var _extra_actions: Dictionary = {}
var _gamepad_only_rows: Array = []

@onready var action_label: Label = $Readout / Box / ActionLabel
@onready var power_bar: ProgressBar = $Readout / Box / PowerBar
@onready var crosshair: Label = $Crosshair
@onready var touch_label: Label = $Readout / Box / TouchLabel
@onready var dive_label: Label = $Readout / Box / DiveLabel




var you_score: Label
var opp_score: Label
var _you_chip: Control
var _opp_chip: Control
var _you_name: Label
var _opp_name: Label
var _sb_set_you: Label
var _sb_set_opp: Label
var _sb_sub: Label
var _set_dots_you: Array = []
var _set_dots_opp: Array = []
var _sets_you: = 0
var _sets_opp: = 0
var _touch_pips: Array = []
var _touch_row: HBoxContainer
var _touch_box: Panel
var _touch_fade: Tween
var _touch_above: = false
var _point_tag: Label
var _roll_lock_you: = false
var _roll_lock_opp: = false
@onready var serve_label: Label = $ServeLabel
@onready var banner_label: Label = $BannerLabel
@onready var stats_panel: PanelContainer = $StatsPanel
@onready var chat: ChatPanel = get_node_or_null("Chat")
@onready var stats_grid: GridContainer = $StatsPanel / Box / Grid
var _stats_drawer: StatsDrawer
var _post_stats_board: StatsBoard
var _stats_dark: = false




func refresh_controls(p: Player, serving: bool) -> void :
	var action_text: = "touch"
	var action_on: = not p.touch_barred
	if serving:
		action_text = "toss"
		action_on = true
	else:
		match p.resolved_touch():
			Player.TouchKind.BUMP:
				action_text = "bump"
			Player.TouchKind.SET:
				action_text = "set"
			Player.TouchKind.SPIKE:
				action_text = "spike"
			Player.TouchKind.DUMP:
				action_text = "dump"
			Player.TouchKind.BLOCK:
				action_text = "block"
			_:
				action_on = false


	var airborne: = not p.is_on_floor()
	var m2_text: = "block" if airborne else "dive"
	var m2_on: = airborne or p.dive_cooldown <= 0.0
	update_controls(action_text, action_on, m2_on, p.is_on_floor(), 
		p.set_opportunity_available(), m2_text)


	var strafe_nm: = get_node_or_null("Controls/Strafe/Name") as Label
	if strafe_nm != null:
		strafe_nm.text = "block" if airborne and InputPrompts.using_gamepad()\
		else "strafe"

func update_state(_player: Player) -> void :


	power_bar.visible = false
	action_label.visible = false

var _sight: TextureRect

func set_crosshair_visible(value: bool) -> void :
	crosshair.visible = value






func set_crosshair_side(point_z: float, in_bounds: = true) -> void :



	var c: = Color.WHITE
	if GameConfig.aim_color_cue and in_bounds:

		c = Rules.half_color(point_z)
	if _sight != null:
		_sight.modulate = c
	if _aim_cursor != null:
		_aim_cursor.modulate = c



var _ball_marker: OffscreenBall = null

func track_ball_marker(camera: Camera3D, ball: Node3D, active: bool, 
		near_to: Node3D = null) -> void :
	if _ball_marker == null:
		if not active:
			return
		_ball_marker = OffscreenBall.new()
		add_child(_ball_marker)



	if ball != null:
		var skin: = ""
		if "stage_ball" in ball:
			skin = String(ball.stage_ball)
		_ball_marker.ball_tex = PointWipe.ball_image_for(skin)
	var dist: = -1.0
	if ball != null and near_to != null:
		dist = ball.global_position.distance_to(near_to.global_position)
	_ball_marker.track(camera, 
		ball.global_position if ball != null else Vector3.ZERO, 
		active and ball != null, dist)






var _aim_cursor: TextureRect = null

func set_aim_cursor(on: bool, pos: Vector2) -> void :
	if not on:
		if _aim_cursor != null:
			_aim_cursor.visible = false
		return
	if _aim_cursor == null:
		_aim_cursor = TextureRect.new()
		_aim_cursor.texture = GameConfig.aim_cursor_texture()
		_aim_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_aim_cursor.z_index = 100
		add_child(_aim_cursor)
	_aim_cursor.visible = true



	var k: = _pixel_scale()
	_aim_cursor.scale = Vector2(k, k)
	var half: Vector2 = _aim_cursor.texture.get_size() * 0.5 * k\
	if _aim_cursor.texture != null else Vector2.ZERO
	_aim_cursor.position = pos - half





func _build_crosshair() -> void :
	var src: Texture2D = load(GameConfig.CURSOR_AIM)
	if src == null:
		return
	var img: = src.get_image()
	var s: = GameConfig.CURSOR_SIZE
	img.resize(s, s, Image.INTERPOLATE_NEAREST)
	var rect: = TextureRect.new()
	rect.name = "Sight"
	rect.texture = ImageTexture.create_from_image(img)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	rect.anchor_left = 0.5
	rect.anchor_top = 0.5
	rect.anchor_right = 0.5
	rect.anchor_bottom = 0.5
	rect.offset_left = - s * 0.5
	rect.offset_top = - s * 0.5
	rect.offset_right = s * 0.5
	rect.offset_bottom = s * 0.5
	crosshair.add_child(rect)
	_sight = rect
	crosshair.text = ""



	rect.pivot_offset = Vector2(s, s) * 0.5
	_fit_sight(rect)
	get_viewport().size_changed.connect(_fit_sight.bind(rect))

func _fit_sight(rect: TextureRect) -> void :
	var k: = _pixel_scale()
	rect.scale = Vector2(k, k)

func _pixel_scale() -> float:
	var st: = get_viewport().get_screen_transform().get_scale()
	return 1.0 / st.x if st.x > 0.001 else 1.0




func chat_typing() -> bool:
	return chat != null and chat.is_typing()

func set_scoreboard_visible(value: bool) -> void :
	$Scoreboard.visible = value




var _replay_ui_hidden: = false
func _set_match_ui_hidden(hidden: bool) -> void :
	if hidden == _replay_ui_hidden:
		return
	_replay_ui_hidden = hidden
	var to: = 0.0 if hidden else 1.0
	var t: = create_tween().set_ignore_time_scale(true).set_parallel(true)
	t.tween_property($Scoreboard, "modulate:a", to, 0.22)
	if has_node("SweatBox"):
		t.tween_property($SweatBox, "modulate:a", to, 0.22)



	t.tween_property($SpectateBar, "modulate:a", to, 0.22)
	if _seat_tell != null:
		t.tween_property(_seat_tell, "modulate:a", to, 0.22)




var _score_side: = 0

func set_score_colors(my_side: int) -> void :
	if my_side == _score_side or my_side == 0:
		return
	_score_side = my_side
	_refresh_set_dots()

func set_play_hud_visible(value: bool) -> void :

	$Readout.visible = value
	$Controls.visible = value

var _sweat: = 0.0
var _sweat_base: = Vector2.ZERO
var _sweat_base_set: = false
var _sweat_ticks: Array = []
var _sweat_tick_boxes: Array = []
var _sweat_drop: Polygon2D

var pause_pauses_tree: = true
var _net_stat_rows: Array = []

func _ready() -> void :
	_build_crosshair()
	_build_presentation()
	_build_stats_boards()
	_build_beta_watermark()
	_ready_post()





func _build_beta_watermark() -> void :
	if not LaunchGate.public_beta():
		return
	var wm: = Label.new()
	wm.name = "BetaWatermark"
	wm.text = "pre beta build - content not final"
	wm.anchor_left = 0.0
	wm.anchor_right = 1.0
	wm.anchor_top = 1.0
	wm.anchor_bottom = 1.0
	wm.offset_top = -46.0
	wm.offset_bottom = -14.0
	wm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wm.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	wm.add_theme_font_size_override("font_size", 22)
	wm.add_theme_color_override("font_color", Color(0, 0, 0, 0.45))
	wm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wm)


	apply_pause_mode()
	($PauseMenu as PauseMenu).seat_requested.connect(
		func(side: int): seat_requested.emit(side))
	($PauseMenu as PauseMenu).opened.connect( func():


		set_aim_cursor(false, Vector2.ZERO)
		pause_opened.emit())
	($PauseMenu as PauseMenu).closed.connect( func(): pause_closed.emit())










func _build_presentation() -> void :
	_build_scoreboard()
	_build_sweat()
	_build_control_cards()
	_build_banner_card()


	_announcer = ANNOUNCER_SCRIPT.new()
	_announcer.name = "Announcer"
	add_child(_announcer)
	_build_loading_bar()
	_style_transient_labels()



	move_child($Loading, get_child_count() - 1)




func _build_loading_bar() -> void :
	var loading: ColorRect = $Loading
	loading.color = Color.BLACK
	var lbl: = loading.get_node("LoadingLabel") as Label
	lbl.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	var track: = Panel.new()
	track.name = "LoadBar"
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.anchor_left = 0.5
	track.anchor_right = 0.5
	track.anchor_top = 0.5
	track.anchor_bottom = 0.5
	track.offset_left = -160.0
	track.offset_right = 160.0
	track.offset_top = 46.0
	track.offset_bottom = 55.0
	var tb: = StyleBoxFlat.new()
	tb.bg_color = Color(0.14, 0.15, 0.19)
	tb.set_corner_radius_all(5)
	track.add_theme_stylebox_override("panel", tb)
	loading.add_child(track)
	var fill: = Panel.new()
	fill.name = "Fill"
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.size = Vector2(96, 9)
	var fb: = StyleBoxFlat.new()
	fb.bg_color = Color(0.35, 1.0, 0.55)
	fb.set_corner_radius_all(5)
	fill.add_theme_stylebox_override("panel", fb)
	track.add_child(fill)

	var t: = fill.create_tween().set_loops().set_ignore_time_scale(true)
	t.tween_property(fill, "position:x", 320.0 - 96.0, 0.85)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(fill, "position:x", 0.0, 0.85)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)





func _build_control_cards() -> void :


	var old: Control = $Controls
	var controls: = VBoxContainer.new()
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls.anchor_left = old.anchor_left
	controls.anchor_right = old.anchor_right
	controls.anchor_top = old.anchor_top
	controls.anchor_bottom = old.anchor_bottom
	controls.offset_left = old.offset_left
	controls.offset_right = old.offset_right
	controls.offset_top = old.offset_top
	controls.offset_bottom = old.offset_bottom
	controls.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	controls.grow_vertical = Control.GROW_DIRECTION_BEGIN
	controls.alignment = BoxContainer.ALIGNMENT_END
	controls.add_theme_constant_override("separation", 5)
	for tile_name in ["Action", "Set", "Dive", "Jump", "Strafe"]:
		var tile: = old.get_node_or_null(tile_name) as VBoxContainer
		if tile == null:
			continue
		var idx: = tile.get_index()
		old.remove_child(tile)
		var row: = HBoxContainer.new()
		row.name = tile_name
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.alignment = BoxContainer.ALIGNMENT_END
		row.add_theme_constant_override("separation", 7)

		for l in tile.find_children("*", "Label", true, false):
			var lbl: = l as Label
			lbl.get_parent().remove_child(lbl)
			lbl.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.add_theme_color_override("font_color", Color.WHITE)
			lbl.add_theme_constant_override("outline_size", 5)
			lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row.add_child(lbl)



		for ic in tile.find_children("*", "TextureRect", true, false):
			var icon: = ic as TextureRect
			icon.get_parent().remove_child(icon)

			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(26, 20)
			row.add_child(icon)
			_plate_icon(icon)
			_control_icons[tile_name] = icon
		tile.queue_free()
		controls.add_child(row)
		controls.move_child(row, idx)



	_add_hint_row(controls, "Camera", "camera", "camera_toggle", false, "")
	_add_hint_row(controls, "Zoom", "zoom", "camera_zoom", true, "")
	_add_hint_row(controls, "AimAssist", "aim assist", "aim_recenter", true, "x2")
	controls.move_child(controls.get_node("Camera"), 0)
	controls.move_child(controls.get_node("Zoom"), 1)
	controls.move_child(controls.get_node("AimAssist"), 2)
	var parent: = old.get_parent()
	parent.add_child(controls)
	old.name = "ControlsRetired"
	controls.name = "Controls"
	parent.remove_child(old)
	old.queue_free()


	if not InputPrompts.changed.is_connected(_refresh_control_glyphs):
		InputPrompts.changed.connect(_refresh_control_glyphs)
	_refresh_control_glyphs()




func _refresh_control_glyphs() -> void :
	for id in _control_icons:
		var icon: = _control_icons[id] as TextureRect
		if icon == null or not is_instance_valid(icon):
			continue
		var action: = String(CONTROL_ACTIONS.get(id, _extra_actions.get(id, "")))
		var tex: = InputPrompts.glyph(action)
		if tex != null:
			icon.texture = tex

	var pad: = InputPrompts.using_gamepad()
	for row in _gamepad_only_rows:
		if is_instance_valid(row):
			row.visible = pad



func _add_hint_row(parent: VBoxContainer, id: String, label_text: String, 
		action: String, gamepad_only: bool, badge: String) -> void :
	var row: = HBoxContainer.new()
	row.name = id
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 7)
	var lbl: = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	lbl.add_theme_font_size_override("font_size", 13)




	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)
	var icon: = TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(26, 20)
	row.add_child(icon)
	_plate_icon(icon)
	if badge != "":
		var b: = Label.new()
		b.text = badge
		b.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
		b.add_theme_font_size_override("font_size", 11)
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_constant_override("outline_size", 4)
		b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))
		b.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(b)
	parent.add_child(row)
	_control_icons[id] = icon
	_extra_actions[id] = action
	if gamepad_only:
		_gamepad_only_rows.append(row)



func _plate_icon(ic: TextureRect) -> void :
	var box: = ic.get_parent()
	var i: = ic.get_index()
	box.remove_child(ic)
	var plate: = PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var pb: = StyleBoxFlat.new()
	pb.bg_color = Color("141a26") if UiStyle.dark else UiStyle.INK
	pb.set_corner_radius_all(8)
	pb.set_content_margin_all(5.0)
	pb.border_color = Color(1, 1, 1, 0.08)
	pb.set_border_width_all(1)
	plate.add_theme_stylebox_override("panel", pb)
	plate.add_child(ic)
	box.add_child(plate)
	box.move_child(plate, i)


var _banner_card: PanelContainer

func _build_banner_card() -> void :
	var parent: = banner_label.get_parent()
	_banner_card = PanelContainer.new()
	_banner_card.name = "BannerCard"
	_banner_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b: = StyleBoxFlat.new()
	b.bg_color = UiStyle.card()
	b.set_corner_radius_all(UiStyle.RADIUS_SOFT)
	b.content_margin_left = 26.0
	b.content_margin_right = 26.0
	b.content_margin_top = 8.0
	b.content_margin_bottom = 10.0
	b.shadow_color = Color(0, 0, 0, 0.35) if UiStyle.dark else Color(UiStyle.INK, 0.16)
	b.shadow_size = 9
	b.shadow_offset = Vector2(0, 4)
	_banner_card.add_theme_stylebox_override("panel", b)
	_banner_card.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner_card.anchor_left = 0.5
	_banner_card.anchor_right = 0.5
	_banner_card.offset_top = 150.0
	_banner_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner_card.visible = false


	banner_label.visible = false
	var lbl: = Label.new()
	lbl.name = "BannerText"
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", UiStyle.text())
	_banner_card.add_child(lbl)
	banner_label = lbl
	parent.add_child(_banner_card)







const SB_HOME: = Color(0.35, 1.0, 0.55)
const SB_AWAY: = Color(1.0, 0.25, 0.72)
const SB_NAVY: = Color(0, 0, 0, 1)
const SB_MUTED: = Color(0.4, 0.45, 0.58)


const SB_SCALE: = 0.7
var _sb_col: Control = null
var _sb_punch: Tween = null
const ANNOUNCER_SCRIPT: = preload("res://game/audio/announcer.gd")
var _announcer: Node = null

var _announce_tween: Tween = null
var _announced_state: = ""

var _big_board: Control = null
var _big_home_num: Label = null
var _big_away_num: Label = null
var _big_home_bar: Control = null
var _big_away_bar: Control = null
var _big_cine: Tween = null
var _cine_tweens: Array = []
var _big_home_sb: StyleBoxFlat = null
var _big_away_sb: StyleBoxFlat = null
const BIG_HOME_X: = 0.0
const BIG_AWAY_X: = 110.0
const BIG_W: = 200.0

func _build_scoreboard() -> void :
	var host: Control = $Scoreboard
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE


	var col: = VBoxContainer.new()
	col.name = "CenterColumn"
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 7)
	col.set_anchors_preset(Control.PRESET_CENTER_TOP)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.offset_top = 22.0
	host.add_child(col)


	_sb_col = col
	col.pivot_offset = Vector2(195, 0)
	col.scale = Vector2(SB_SCALE, SB_SCALE)


	var main: = PanelContainer.new()
	main.name = "MainScoreboard"
	main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.custom_minimum_size = Vector2(390, 56)
	var mb: = StyleBoxFlat.new()
	mb.bg_color = UiStyle.card()
	mb.set_corner_radius_all(28)
	mb.content_margin_left = 3
	mb.content_margin_right = 3
	mb.content_margin_top = 3
	mb.content_margin_bottom = 3
	mb.shadow_color = Color(0.1, 0.13, 0.28, 0.3)
	mb.shadow_size = 6
	mb.shadow_offset = Vector2(0, 4)
	main.add_theme_stylebox_override("panel", mb)
	col.add_child(main)

	var row: = HBoxContainer.new()
	row.name = "ScoreRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 0)
	main.add_child(row)


	_you_name = _cap_label("home")
	_you_chip = _cap(SB_HOME, _you_name, true)
	row.add_child(_you_chip)


	you_score = _sb_num()
	you_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	you_score.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(you_score)
	var dash: = Label.new()
	dash.name = "Divider"
	dash.text = "—"
	dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dash.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dash.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	dash.add_theme_font_size_override("font_size", 28)
	dash.add_theme_color_override("font_color", Color.WHITE)
	dash.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	dash.add_theme_constant_override("outline_size", 8)
	dash.custom_minimum_size = Vector2(56, 0)
	dash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(dash)
	opp_score = _sb_num()
	opp_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	opp_score.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(opp_score)
	_opp_name = _cap_label("away")
	_opp_chip = _cap(SB_AWAY, _opp_name, false)
	row.add_child(_opp_chip)


	var setcap: = PanelContainer.new()
	setcap.name = "SetCapsule"
	setcap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	setcap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	setcap.custom_minimum_size = Vector2(210, 28)
	var sb: = StyleBoxFlat.new()
	sb.bg_color = UiStyle.card()
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0.3, 0.34, 0.45, 0.22)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(0, 2)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	setcap.add_theme_stylebox_override("panel", sb)
	col.add_child(setcap)

	var setrow: = HBoxContainer.new()
	setrow.name = "SetRow"
	setrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	setrow.alignment = BoxContainer.ALIGNMENT_CENTER
	setrow.add_theme_constant_override("separation", 8)
	setcap.add_child(setrow)
	var need: = maxi(1, GameConfig.sets_to_win)
	_set_dots_you = _set_dot_group(setrow, need)
	_sb_sub = Label.new()
	_sb_sub.name = "SetLabel"
	_sb_sub.text = "set 1"
	_sb_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sb_sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sb_sub.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	_sb_sub.add_theme_font_size_override("font_size", 13)
	_sb_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_sb_sub.add_theme_color_override("font_color", SB_MUTED)
	setrow.add_child(_sb_sub)
	_set_dots_opp = _set_dot_group(setrow, need)
	_refresh_set_dots()



	_build_touch_counter(col)

	_point_tag = Label.new()
	_point_tag.name = "PointTag"
	_point_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_point_tag.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	_point_tag.add_theme_font_size_override("font_size", 26)
	_point_tag.add_theme_constant_override("outline_size", 7)
	_point_tag.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	_point_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_point_tag.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_point_tag.custom_minimum_size = Vector2(200, 0)
	_point_tag.position = Vector2(-100, 100)
	_point_tag.visible = false
	add_child(_point_tag)
	_build_big_board()


func _cap(fill: Color, label: Label, home: bool) -> PanelContainer:
	var p: = PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.custom_minimum_size = Vector2(84, 50)
	var b: = StyleBoxFlat.new()
	b.bg_color = fill
	if home:
		b.corner_radius_top_left = 25
		b.corner_radius_bottom_left = 25
		b.corner_radius_top_right = 5
		b.corner_radius_bottom_right = 5
	else:
		b.corner_radius_top_right = 25
		b.corner_radius_bottom_right = 25
		b.corner_radius_top_left = 5
		b.corner_radius_bottom_left = 5
	p.add_theme_stylebox_override("panel", b)
	p.add_child(label)
	return p

func _cap_label(text: String) -> Label:
	var l: = Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	l.add_theme_constant_override("outline_size", 7)
	return l


func _dot_solid(color: Color) -> StyleBoxFlat:
	var b: = StyleBoxFlat.new()
	b.bg_color = color
	b.set_corner_radius_all(99)
	b.corner_detail = 12
	return b

func _dot_ring() -> StyleBoxFlat:
	var b: = StyleBoxFlat.new()
	b.bg_color = UiStyle.card()
	b.set_corner_radius_all(99)
	b.corner_detail = 12
	b.set_border_width_all(2)
	b.border_color = SB_MUTED
	return b


func _set_dot_group(parent: HBoxContainer, n: int) -> Array:
	var group: = HBoxContainer.new()
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_theme_constant_override("separation", 5)
	parent.add_child(group)
	var out: Array = []
	for i in n:
		var dot: = Panel.new()
		dot.custom_minimum_size = Vector2(12, 12)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		group.add_child(dot)
		out.append(dot)
	return out



func _build_touch_counter(col: VBoxContainer) -> void :
	var box: = Panel.new()
	box.name = "TouchCounter"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.custom_minimum_size = Vector2(66, 24)
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bb: = StyleBoxFlat.new()

	bb.bg_color = UiStyle.card()
	bb.set_corner_radius_all(12)
	bb.shadow_color = Color(0.3, 0.34, 0.45, 0.22)
	bb.shadow_size = 3
	bb.shadow_offset = Vector2(0, 2)
	bb.content_margin_left = 10
	bb.content_margin_right = 10
	box.add_theme_stylebox_override("panel", bb)
	box.visible = false
	col.add_child(box)
	_touch_box = box
	var pips: = HBoxContainer.new()
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pips.set_anchors_preset(Control.PRESET_FULL_RECT)
	pips.alignment = BoxContainer.ALIGNMENT_CENTER
	pips.add_theme_constant_override("separation", 7)
	box.add_child(pips)
	_touch_row = pips
	_touch_pips = []
	for i in 3:
		var dot: = Panel.new()
		dot.custom_minimum_size = Vector2(9, 9)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pips.add_child(dot)
		_touch_pips.append(dot)
	_paint_touch(0)

func set_touch_placement(_above: bool) -> void :
	pass

func _sb_num() -> Label:
	var l: = Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.text = "00"
	l.custom_minimum_size = Vector2(40, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	l.add_theme_font_size_override("font_size", 33)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	l.add_theme_constant_override("outline_size", 8)
	return l



func _sb_set_num() -> Label:
	var l: = Label.new()
	l.text = "0"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	l.add_theme_font_size_override("font_size", 16)
	return l

func _sb_name(text: String) -> Label:
	var l: = Label.new()
	l.text = text
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", UiStyle.text())
	return l



func _score_row(name: Label, score: Label) -> HBoxContainer:
	var row: = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size = Vector2(134, 0)
	row.add_theme_constant_override("separation", 9)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name)
	row.add_child(score)
	return row


func _stripe(fill: Color, top: bool) -> Panel:
	var p: = Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size = Vector2(7, 38)
	p.set_meta("top_tab", top)
	_paint_stripe(p, fill)
	return p

func _paint_stripe(p: Panel, fill: Color) -> void :
	var b: = StyleBoxFlat.new()
	b.bg_color = fill
	if bool(p.get_meta("top_tab", true)):
		b.corner_radius_top_left = 2
	else:
		b.corner_radius_bottom_left = 2
	p.add_theme_stylebox_override("panel", b)

func _pip_box(fill: Color) -> StyleBoxFlat:
	var b: = StyleBoxFlat.new()
	b.bg_color = fill
	b.set_corner_radius_all(99)
	return b

func _score_info_muted() -> Color:


	return Color(1.0, 1.0, 1.0, 0.62)




const _TOUCH_LIGHT: = [UiStyle.SUCCESS, UiStyle.PRIMARY, UiStyle.RED]

func _paint_touch(count: int) -> void :
	for i in _touch_pips.size():
		var dot: Panel = _touch_pips[i]
		if i < count:
			dot.add_theme_stylebox_override("panel", _dot_solid(_TOUCH_LIGHT[i]))
		else:
			dot.add_theme_stylebox_override("panel", _dot_ring())



func _paint_set_score_colors() -> void :
	_refresh_set_dots()


func _refresh_set_dots() -> void :
	for i in _set_dots_you.size():
		(_set_dots_you[i] as Panel).add_theme_stylebox_override("panel", 
			_dot_solid(SB_HOME) if i < _sets_you else _dot_ring())
	for i in _set_dots_opp.size():
		(_set_dots_opp[i] as Panel).add_theme_stylebox_override("panel", 
			_dot_solid(SB_AWAY) if i < _sets_opp else _dot_ring())






const SWEAT_TICKS: = 7

func _build_sweat() -> void :
	var box: Control = $SweatBox
	box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row: = HBoxContainer.new()
	row.name = "Ticks"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 3)
	box.add_child(row)


	var drop_host: = Control.new()
	drop_host.custom_minimum_size = Vector2(11, 11)
	drop_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sweat_drop = Polygon2D.new()
	var pts: = PackedVector2Array()
	pts.append(Vector2(7.5, 0.0))
	for i in 13:

		var a: = deg_to_rad(-50.0 + 260.0 * float(i) / 12.0)
		pts.append(Vector2(7.5, 9.2) + Vector2(cos(a), sin(a)) * 5.4)
	_sweat_drop.polygon = pts
	_sweat_drop.color = Color(0.35, 0.7, 1.0)
	drop_host.add_child(_sweat_drop)
	row.add_child(drop_host)
	for i in SWEAT_TICKS:
		var tick: = Panel.new()
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tick.custom_minimum_size = Vector2(9, 8)
		var b: = StyleBoxFlat.new()
		b.set_corner_radius_all(4)
		b.bg_color = Color(0.08, 0.1, 0.16, 0.38)
		tick.add_theme_stylebox_override("panel", b)
		row.add_child(tick)
		_sweat_ticks.append(tick)
		_sweat_tick_boxes.append(b)



func _place_sweat() -> void :
	var box: Control = $SweatBox
	var row: = box.get_node_or_null("Ticks") as Control
	var w: = row.size.x if row != null and row.size.x > 1.0 else 150.0
	box.size.x = w
	_sweat_base = Vector2($Scoreboard.size.x * 0.5 - w * 0.5, 122.0)
	_sweat_base_set = true
	box.position = _sweat_base

func _style_transient_labels() -> void :



	serve_label.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	serve_label.add_theme_font_size_override("font_size", 17)
	serve_label.add_theme_constant_override("outline_size", 6)
	serve_label.add_theme_color_override("font_color", Color.WHITE)
	serve_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))

	banner_label.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))










func _big_center_x() -> float:
	return $Scoreboard.size.x * 0.5 - BIG_W * 0.5

func _build_big_board() -> void :
	var b: = Control.new()
	b.name = "BigBoard"
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.set_anchors_preset(Control.PRESET_TOP_LEFT)
	b.custom_minimum_size = Vector2(BIG_W, 72)
	b.size = b.custom_minimum_size
	b.pivot_offset = Vector2(BIG_W * 0.5, 0)
	b.position = Vector2(_big_center_x(), 44)
	b.modulate.a = 0.0
	b.visible = false
	$Scoreboard.add_child(b)
	_big_board = b

	_big_home_bar = _big_bar(SB_HOME, true)
	_big_home_bar.position = Vector2(BIG_HOME_X, 4)
	b.add_child(_big_home_bar)
	_big_away_bar = _big_bar(SB_AWAY, false)
	_big_away_bar.position = Vector2(BIG_AWAY_X, 4)
	b.add_child(_big_away_bar)


	var dash: = Panel.new()
	dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dash.size = Vector2(18, 8)
	dash.position = Vector2(BIG_W * 0.5 - 9, 30)
	var db: = StyleBoxFlat.new()
	db.bg_color = UiStyle.card()
	db.set_corner_radius_all(4)
	dash.add_theme_stylebox_override("panel", db)
	b.add_child(dash)



func _big_bar(fill: Color, home: bool) -> Control:
	var bar: = Control.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.custom_minimum_size = Vector2(90, 60)
	bar.size = bar.custom_minimum_size
	bar.pivot_offset = Vector2(45, 30)
	var cap: = Panel.new()
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.size = Vector2(90, 60)
	var cb: = StyleBoxFlat.new()
	cb.bg_color = fill
	cb.set_corner_radius_all(30)
	cb.shadow_color = Color(0.1, 0.13, 0.28, 0.3)
	cb.shadow_size = 6
	cb.shadow_offset = Vector2(0, 3)
	cap.add_theme_stylebox_override("panel", cb)
	bar.add_child(cap)
	if home:
		_big_home_sb = cb
	else:
		_big_away_sb = cb

	var num: = Label.new()
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	num.text = "0"
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	num.add_theme_font_size_override("font_size", 50)
	num.add_theme_color_override("font_color", Color.WHITE)
	num.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	num.add_theme_constant_override("outline_size", 12)
	num.size = Vector2(90, 60)
	num.pivot_offset = Vector2(45, 30)
	num.position = Vector2(0, 0)
	bar.add_child(num)
	if home:
		_big_home_num = num
	else:
		_big_away_num = num
	return bar







func _cine_reset() -> void :
	for t in _cine_tweens:
		if t != null and t.is_valid():
			t.kill()
	_cine_tweens.clear()
	if _big_board == null:
		return
	_big_board.scale = Vector2.ONE
	_big_home_bar.scale = Vector2.ONE
	_big_away_bar.scale = Vector2.ONE
	_big_home_num.scale = Vector2.ONE
	_big_away_num.scale = Vector2.ONE
	if _big_home_sb != null:
		_big_home_sb.bg_color = SB_HOME
		_big_away_sb.bg_color = SB_AWAY
	$SweatBox.modulate.a = 1.0
	for c in _big_board.get_children():
		if String(c.name).begins_with("clashfx"):
			c.queue_free()

func point_cinematic(winner_side: int, home_score: int, away_score: int) -> void :
	if _big_board == null:
		return
	_cine_reset()
	var winner_home: = winner_side >= 0
	_big_home_num.text = str(home_score - (1 if winner_home else 0))
	_big_away_num.text = str(away_score - (0 if winner_home else 1))
	_big_board.pivot_offset = Vector2(BIG_W * 0.5, 36.0)

	_big_board.visible = true
	var bx: = _big_center_x()
	_big_board.position = Vector2(bx, 44)
	_big_home_bar.position.x = - (bx + 320.0)
	_big_away_bar.position.x = $Scoreboard.size.x - bx


	_big_cine = create_tween().set_ignore_time_scale(true).set_parallel(true)
	_cine_tweens.append(_big_cine)
	_big_cine.tween_property(_big_board, "modulate:a", 1.0, 0.12)
	if _sb_col != null:
		_big_cine.tween_property(_sb_col, "modulate:a", 0.0, 0.12)
	_big_cine.tween_property($SweatBox, "modulate:a", 0.0, 0.12)
	_big_cine.tween_property(_big_home_bar, "position:x", BIG_HOME_X, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_big_cine.tween_property(_big_away_bar, "position:x", BIG_AWAY_X, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	var wb: Control = _big_home_bar if winner_home else _big_away_bar
	var lb: Control = _big_away_bar if winner_home else _big_home_bar
	var wn: Label = _big_home_num if winner_home else _big_away_num
	var final_val: = home_score if winner_home else away_score

	wb.pivot_offset = Vector2(90.0 if winner_home else 0.0, 30.0)
	lb.pivot_offset = Vector2(0.0 if winner_home else 90.0, 30.0)


	var clash: = create_tween().set_ignore_time_scale(true)
	_cine_tweens.append(clash)
	clash.tween_interval(0.24)
	clash.tween_callback( func():
		_flash_caps()
		_shake_board())
	clash.tween_property(_big_board, "scale", Vector2(0.82, 1.22), 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	clash.tween_property(_big_board, "scale", Vector2(1.12, 0.9), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	clash.tween_property(_big_board, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


	var grow: = create_tween().set_ignore_time_scale(true).set_parallel(true)
	_cine_tweens.append(grow)
	grow.tween_interval(0.3)
	grow.chain().tween_property(wb, "scale", Vector2(1.12, 1.12), 0.55).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


	var num: = create_tween().set_ignore_time_scale(true)
	_cine_tweens.append(num)
	num.tween_interval(0.3)
	num.tween_callback( func(): wn.text = str(final_val))
	num.tween_property(wn, "scale", Vector2(1.18, 1.18), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	num.tween_property(wn, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)






	var outro: = create_tween().set_ignore_time_scale(true)
	_cine_tweens.append(outro)
	outro.tween_interval(1.8)
	outro.tween_property(_big_board, "modulate:a", 0.0, 0.22)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	outro.parallel().tween_property(_big_board, "scale", Vector2(0.72, 0.72), 0.22)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	outro.chain().tween_callback( func(): _big_board.visible = false)
	if _sb_col != null:
		outro.tween_property(_sb_col, "modulate:a", 1.0, 0.2)
	outro.parallel().tween_property($SweatBox, "modulate:a", 1.0, 0.2)
	UiStyle.sfx("open")


func _flash_caps() -> void :
	if _big_home_sb == null:
		return
	_big_home_sb.bg_color = Color.WHITE
	_big_away_sb.bg_color = Color.WHITE
	var t: = create_tween().set_ignore_time_scale(true).set_parallel(true)
	_cine_tweens.append(t)
	t.tween_property(_big_home_sb, "bg_color", SB_HOME, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(_big_away_sb, "bg_color", SB_AWAY, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _shake_board() -> void :
	if _big_board == null:
		return
	var base: = Vector2(_big_center_x(), 44)
	var sh: = _big_board.create_tween().set_ignore_time_scale(true)
	_cine_tweens.append(sh)
	for i in 6:
		var k: = 1.0 - float(i) / 6.0
		sh.tween_property(_big_board, "position", 
			base + Vector2(randf_range(-9, 9), randf_range(-5, 5)) * k, 0.04)
	sh.tween_property(_big_board, "position", base, 0.04)


func _spawn_flash(local_pos: Vector2) -> void :
	if _big_board == null:
		return
	var f: = Panel.new()
	f.name = "clashfx_flash"
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.size = Vector2(84, 84)
	f.position = local_pos - f.size * 0.5
	f.pivot_offset = f.size * 0.5
	var fb: = StyleBoxFlat.new()
	fb.bg_color = Color(1, 1, 1, 0.9)
	fb.set_corner_radius_all(99)
	fb.corner_detail = 16
	f.add_theme_stylebox_override("panel", fb)
	f.scale = Vector2(0.3, 0.3)
	_big_board.add_child(f)
	var t: = f.create_tween().set_ignore_time_scale(true).set_parallel(true)
	t.tween_property(f, "scale", Vector2(3.0, 3.0), 0.34)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(f, "modulate:a", 0.0, 0.34)
	t.chain().tween_callback(f.queue_free)

	for i in 8:
		var ang: = TAU * float(i) / 8.0 + 0.2
		var line: = Panel.new()
		line.name = "clashfx_line"
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.size = Vector2(16, 5)
		line.pivot_offset = line.size * 0.5
		line.rotation = ang
		line.position = local_pos - line.size * 0.5
		var lb2: = StyleBoxFlat.new()
		lb2.bg_color = Color(1, 1, 1, 0.95)
		lb2.set_corner_radius_all(3)
		line.add_theme_stylebox_override("panel", lb2)
		_big_board.add_child(line)
		var dir: = Vector2(cos(ang), sin(ang))
		var lt: = line.create_tween().set_ignore_time_scale(true).set_parallel(true)
		lt.tween_property(line, "position", 
			local_pos - line.size * 0.5 + dir * 54.0, 0.34)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		lt.tween_property(line, "modulate:a", 0.0, 0.34)
		lt.chain().tween_callback(line.queue_free)

func point_moment(winner_side: int, my_side: int, _reason: String, 
		home_score: int, away_score: int) -> void :
	if you_score == null:
		return
	var mine: = winner_side == my_side
	var you: = home_score if my_side > 0 else away_score
	var opp: = away_score if my_side > 0 else home_score
	var new_val: = you if mine else opp
	var l: Label = you_score if mine else opp_score


	if mine:
		_roll_lock_you = true
	else:
		_roll_lock_opp = true
	l.text = "%d" % maxi(new_val - 1, 0)
	l.offset_transform_enabled = true
	l.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
	var t: = l.create_tween()
	t.set_ignore_time_scale(true)
	t.tween_interval(0.12)
	t.tween_callback( func():
		l.text = "%d" % new_val


		UiStyle.click_burst(l, SB_HOME if mine else SB_AWAY))
	t.tween_property(l, "offset_transform_scale", Vector2(1.5, 1.5), 0.12)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "offset_transform_scale", Vector2.ONE, 0.3)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_callback( func():
		_roll_lock_you = false
		_roll_lock_opp = false)





	point_cinematic(1 if mine else -1, you, opp)

func _flash_point_tag(color: Color) -> void :
	if _point_tag == null:
		return
	_point_tag.text = "point!"
	_point_tag.add_theme_color_override("font_color", color)
	_point_tag.visible = true
	UiStyle.pop_in(_point_tag)
	var t: = create_tween()
	t.set_ignore_time_scale(true)
	t.tween_interval(1.4)
	t.tween_property(_point_tag, "modulate:a", 0.0, 0.4)
	t.tween_callback( func(): _point_tag.visible = false)

func hide_point_moment() -> void :
	if _point_tag != null:
		_point_tag.visible = false

func spectate_controls() -> ViewControls:
	return $SpectateBar / Controls as ViewControls

func set_spectating(on: bool) -> void :
	$SpectateBar.visible = on




func set_play_ui_visible(on: bool) -> void :
	$Readout.visible = on
	if has_node("Controls"):
		get_node("Controls").visible = on


func set_watch_ui_visible(on: bool) -> void :
	$SpectateBar.visible = on
	$Scoreboard.visible = on


	if has_node("SweatBox"):
		$SweatBox.visible = on


signal seat_requested(side: int)

signal pause_opened
signal pause_closed

func set_teams_available(on: bool) -> void :
	($PauseMenu as PauseMenu).set_teams_available(on)

func set_seat_options(blue_free: int, red_free: int, playing: bool) -> void :
	($PauseMenu as PauseMenu).set_seat_options(blue_free, red_free, playing)


	if _seat_tell == null:
		_seat_tell = Label.new()
		_seat_tell.name = "SeatTell"
		UiStyle.style_pill(_seat_tell, UiStyle.PRIMARY, UiStyle.INK, 15)
		_seat_tell.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		_seat_tell.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_seat_tell.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_seat_tell.offset_bottom = -88.0
		_seat_tell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_seat_tell)
	var seat_open: = blue_free > 0 or red_free > 0
	var want: bool = ( not playing) and seat_open and $SpectateBar.visible
	if playing and _seat_tell.visible:

		_seat_tell.visible = false
	if want and not _seat_tell_shown:


		_seat_tell_shown = true
		_seat_tell.text = "to join the match, select a team from the pause menu"
		_seat_tell.modulate.a = 1.0
		_seat_tell.visible = true
		var t: = _seat_tell.create_tween()
		t.tween_interval(SEAT_TELL_SECS)
		t.tween_property(_seat_tell, "modulate:a", 0.0, 0.6)
		t.tween_callback( func(): _seat_tell.visible = false)
	elif not want and _seat_tell.visible and not _seat_tell_shown:
		_seat_tell.visible = false

const SEAT_TELL_SECS: = 30.0

func hide_seat_tell() -> void :
	if _seat_tell != null:
		_seat_tell.visible = false
var _seat_tell: Label = null
var _seat_tell_shown: = false

func pause_is_open() -> bool:
	return ($PauseMenu as PauseMenu).is_open()

func apply_pause_mode() -> void :
	$PauseMenu.pauses_tree = pause_pauses_tree
	if not pause_pauses_tree and is_inside_tree():

		get_tree().paused = false



var pause_enabled: = true
var _pause_toggle_frame: = -1

func _unhandled_input(event: InputEvent) -> void :
	if not pause_enabled:
		return



	if $PostStats.visible:
		return
	var pm: = $PauseMenu as PauseMenu




	var wants_toggle: bool
	if pm.is_open():
		wants_toggle = event.is_action_pressed("ui_cancel")\
		or event.is_action_pressed("menu_start")
	else:
		wants_toggle = event.is_action_pressed("menu_start")\
		or (event is InputEventKey and event.is_action_pressed("ui_cancel"))
	if not wants_toggle:
		return



	var f: = Engine.get_process_frames()
	if f != _pause_toggle_frame:
		_pause_toggle_frame = f
		pm.set_open( not pm.is_open())
	get_viewport().set_input_as_handled()

func pause_open() -> bool:
	return $PauseMenu.is_open()

func update_controls(action_text: String, action_on: bool, dive_on: bool, 
		jump_on: bool, set_on: bool = true, m2_text: String = "dive") -> void :



	var nm: = get_node_or_null("Controls/Action/Name") as Label
	if nm != null:
		nm.text = action_text


	var dive_nm: = get_node_or_null("Controls/Dive/Name") as Label
	if dive_nm != null:
		dive_nm.text = m2_text
	$Controls / Action.modulate.a = 1.0 if action_on else 0.35
	$Controls / Set.modulate.a = 1.0 if set_on else 0.35
	$Controls / Dive.modulate.a = 1.0 if dive_on else 0.35
	$Controls / Jump.modulate.a = 1.0 if jump_on else 0.35

	# The on-screen pad shows these same five names, so on a touch build it
	# takes the legend's place instead of sitting next to it.
	var legend: = get_node_or_null("Controls") as Control
	if legend != null:
		legend.visible = not TouchControls.active()
	TouchControls.sync_legend(action_text, action_on, dive_on, jump_on, 
		set_on, m2_text)

func set_net_info(text: String) -> void :
	$NetLabel.visible = text != ""
	$NetLabel.text = text

func store_stat_rows(rows: Array) -> void :
	_net_stat_rows = rows

func stored_stat_rows() -> Array:
	return _net_stat_rows

func set_sweat(value: float) -> void :
	_sweat = value
	var box: Control = $SweatBox
	box.visible = value > 0.01
	if not box.visible:
		return
	_place_sweat()
	var lit: = int(ceilf(value * float(SWEAT_TICKS) - 0.001))


	for i in _sweat_tick_boxes.size():
		var b: StyleBoxFlat = _sweat_tick_boxes[i]
		b.bg_color = _tier_color(i) if i < lit else Color(0.08, 0.1, 0.16, 0.38)
	if _sweat_drop != null:
		_sweat_drop.color = _tier_color(maxi(lit - 1, 0))


func _tier_color(i: int) -> Color:
	if i <= 2:
		return Color(0.28, 0.62, 1.0)
	elif i <= 4:
		return Color(1.0, 0.82, 0.15)
	return Color(1.0, 0.22, 0.16)

func _process(_delta: float) -> void :


	_tick_cam_label(_delta)
	_tick_control_feedback(_delta)
	if _stats_dark != UiStyle.dark:
		_style_stats_surfaces()
	if $PostStats.visible and not _pa_states.is_empty():
		_pa_spin += _delta
		_render_pa_marks()

	var box: Control = $SweatBox
	if not box.visible or not _sweat_base_set:
		return
	if _sweat > 0.55:
		var shake: = (_sweat - 0.55) / 0.45 * 3.0
		box.position = _sweat_base + Vector2(
			randf_range( - shake, shake), randf_range( - shake, shake))
	else:
		box.position = _sweat_base

func _tick_control_feedback(delta: float) -> void :
	var controls: = get_node_or_null("Controls") as Control
	if controls != null and controls.visible:
		for tile_name in CONTROL_ACTIONS:
			var action: String = CONTROL_ACTIONS[tile_name]
			if Input.is_action_just_pressed(action):
				_control_flash_left[tile_name] = CONTROL_FLASH_TIME

	for tile_name in _control_flash_left.keys():
		var left: = float(_control_flash_left[tile_name]) - delta
		var card: = get_node_or_null("Controls/" + str(tile_name)) as Control
		if card == null:
			_control_flash_left.erase(tile_name)
			continue
		if left <= 0.0:
			card.self_modulate = Color.WHITE
			_control_flash_left.erase(tile_name)
			continue
		_control_flash_left[tile_name] = left


		var amount: = clampf(left / CONTROL_FLASH_TIME, 0.0, 1.0)
		var shade: = lerpf(CONTROL_FLASH_GREY, 1.0, amount)
		card.self_modulate = Color(shade, shade, shade, 1.0)

func set_touches(count: int) -> void :




	_paint_touch(count)
	touch_label.text = ""
	if _touch_box == null:
		return
	if count > 0:
		if _touch_fade != null and _touch_fade.is_valid():
			_touch_fade.kill()
		_touch_box.visible = true
		_touch_box.modulate.a = 1.0
	elif _touch_box.visible and (_touch_fade == null or not _touch_fade.is_valid()):
		_touch_fade = create_tween()
		_touch_fade.set_ignore_time_scale(true)
		_touch_fade.tween_property(_touch_box, "modulate:a", 0.0, 0.22)
		_touch_fade.tween_callback( func(): _touch_box.visible = false)




const CAM_LABEL_HOLD: = 1.4
const CAM_LABEL_FADE: = 0.5
var _cam_label_left: = 0.0

func show_camera_name(name: String) -> void :
	($CamLabel as Label).text = "cam: " + name
	_cam_label_left = CAM_LABEL_HOLD + CAM_LABEL_FADE

func _tick_cam_label(delta: float) -> void :
	if _cam_label_left <= 0.0:
		return
	_cam_label_left -= delta
	($CamLabel as Label).modulate.a = clampf(
		_cam_label_left / CAM_LABEL_FADE, 0.0, 1.0)

var _dive_count: Label = null
var _dive_icon: Control = null

func set_dive(cooldown: float) -> void :




	dive_label.visible = false
	if _dive_count == null:




		var dive_tile: = get_node_or_null("Controls/Dive") as Control
		if dive_tile == null:
			return
		var host: = dive_tile.find_child("Icon", true, false) as Control
		if host == null:
			host = dive_tile
		_dive_count = Label.new()
		_dive_count.add_theme_font_size_override("font_size", 26)
		_dive_count.add_theme_color_override("font_color", Color(1, 1, 1))
		_dive_count.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		_dive_count.add_theme_constant_override("outline_size", 6)
		_dive_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_dive_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_dive_count.mouse_filter = Control.MOUSE_FILTER_IGNORE


		host.add_child(_dive_count)
		_dive_count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_dive_icon = host
	var charging: = cooldown > 0.0
	_dive_count.visible = charging
	if charging:
		_dive_count.text = "%d" % ceili(cooldown)


	if _dive_icon != null:
		_dive_icon.self_modulate.a = 0.4 if charging else 1.0



var _dive_deny_tween: Tween = null

func dive_denied() -> void :
	var tile: = get_node_or_null("Controls/Dive") as Control
	if tile == null:
		return
	if _dive_deny_tween != null and _dive_deny_tween.is_valid():
		_dive_deny_tween.kill()
		tile.position = _dive_tile_rest
	else:
		_dive_tile_rest = tile.position
	var rest: = _dive_tile_rest
	var red: = Color(1.0, 0.3, 0.3)
	if _dive_count != null:
		_dive_count.add_theme_color_override("font_color", red)
	if _dive_icon != null:
		_dive_icon.self_modulate = Color(red, _dive_icon.self_modulate.a)
	_dive_deny_tween = create_tween()
	_dive_deny_tween.set_ignore_time_scale(true)
	for i in 5:
		var off: = Vector2((-1.0 if i % 2 == 0 else 1.0) * (7.0 - float(i)), 0.0)
		_dive_deny_tween.tween_property(tile, "position", rest + off, 0.035)
	_dive_deny_tween.tween_property(tile, "position", rest, 0.04)
	_dive_deny_tween.tween_callback( func():
		if _dive_count != null:
			_dive_count.add_theme_color_override("font_color", Color(1, 1, 1))
		if _dive_icon != null:
			_dive_icon.self_modulate = Color(1.0, 1.0, 1.0, _dive_icon.self_modulate.a))

var _dive_tile_rest: = Vector2.ZERO

func set_score(you: int, opp: int, sets_you: int, sets_opp: int, set_number: int) -> void :

	if not _roll_lock_you:
		you_score.text = "%d" % you
	if not _roll_lock_opp:
		opp_score.text = "%d" % opp



	var target: = GameConfig.set_points






	var in_deuce_zone: bool = GameConfig.win_by_two and mini(you, opp) >= target - 1
	var deuce: bool = in_deuce_zone and you == opp
	var at_point: bool = ( not deuce) and \
	(maxi(you, opp) == target - 1 or (in_deuce_zone and absi(you - opp) == 1))
	var hot: = false
	var ctx: = "set %d" % set_number
	if deuce:
		hot = true
		ctx = "deuce"
	elif at_point:
		hot = true


		var lead_sets: = sets_you if you >= opp else sets_opp
		if lead_sets >= maxi(1, GameConfig.sets_to_win) - 1:
			ctx = "match point"
		else:
			ctx = "set point"
	_sets_you = sets_you
	_sets_opp = sets_opp
	_refresh_set_dots()
	_sb_sub.text = ctx
	if hot:
		_sb_sub.add_theme_color_override("font_color", Color(1.0, 0.46, 0.52))
		_sb_sub.add_theme_constant_override("outline_size", 5)
	else:


		_sb_sub.add_theme_color_override("font_color", Color.WHITE)
		_sb_sub.add_theme_constant_override("outline_size", 4)



	if hot and ctx != _announced_state:
		_announced_state = ctx
		announce_moment(ctx.replace(" ", "_"))
	elif not hot:
		_announced_state = ""






const MOMENTS: = {
	"ace": ["service ace!", true, true], 
	"break_point": ["break point!", true, true], 
	"line": ["on the line!", true, true], 
	"game": ["game!", true, true], 
	"set": ["set!", true, true], 


	"out": ["out!", true, false], 
	"foot_fault": ["foot fault", false, false], 
	"fault": ["fault", false, false], 


	"match_point": ["match point", false, false], 
	"set_point": ["set point", false, false], 
	"deuce": ["deuce", false, false], 
	"count_3": ["", true, false], 
	"count_2": ["", true, false], 
	"count_1": ["", true, false], 
}




func announce_moment(key: String, side: = 0) -> void :
	if _announcer != null:
		_announcer.say(key)
	var m: Array = MOMENTS.get(key, [])
	if m.is_empty():
		return
	var text: String = m[0]
	if text != "":
		var team: bool = m[2]
		announce_banner(text, Rules.side_color(side) if team else Color.WHITE, m[1])

	if key == "match_point" or key == "set_point" or key == "deuce":
		_pulse_caption()





func announce(key: String, text: = "", accent: = Color.WHITE, big: = true, 
		priority: = -1) -> void :
	if _announcer != null:
		_announcer.say(key, priority)
	if text != "":
		announce_banner(text, accent, big)
	else:

		_pulse_caption()




func announce_banner(text: String, accent: = Color.WHITE, big: = true) -> void :
	var box: CenterContainer = get_node_or_null("AnnounceBanner")
	var lbl: Label
	if box == null:
		box = CenterContainer.new()
		box.name = "AnnounceBanner"
		box.set_anchors_preset(Control.PRESET_TOP_WIDE)



		box.offset_top = 118.0
		box.offset_bottom = 188.0
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl = Label.new()
		lbl.name = "Text"
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.offset_transform_enabled = true
		lbl.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
		box.add_child(lbl)
		add_child(box)
	else:
		lbl = box.get_node("Text") as Label
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 58 if big else 34)
	lbl.add_theme_constant_override("outline_size", 16 if big else 9)
	lbl.add_theme_color_override("font_color", accent)
	box.visible = true
	box.modulate.a = 1.0
	lbl.offset_transform_scale = Vector2(0.55, 0.55)
	if _announce_tween != null and _announce_tween.is_valid():
		_announce_tween.kill()
	_announce_tween = create_tween().set_ignore_time_scale(true)
	_announce_tween.tween_property(lbl, "offset_transform_scale", 
		Vector2(1.12, 1.12), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_announce_tween.tween_property(lbl, "offset_transform_scale", 
		Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE)
	_announce_tween.tween_interval(1.3 if big else 1.0)
	_announce_tween.tween_property(box, "modulate:a", 0.0, 0.3)
	_announce_tween.tween_callback( func(): box.visible = false)



func _pulse_caption() -> void :
	if _sb_sub == null:
		return
	_sb_sub.offset_transform_enabled = true
	_sb_sub.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
	var t: = _sb_sub.create_tween().set_ignore_time_scale(true)
	t.tween_property(_sb_sub, "offset_transform_scale", Vector2(1.35, 1.35), 0.16)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_sb_sub, "offset_transform_scale", Vector2.ONE, 0.4)\
	.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

var _serve_urgent: = false
var _serve_pulse: Tween = null



func set_serve_prompt(text: String, mine: = false, clock: = -1.0) -> void :
	serve_label.text = text
	if text == "":
		mine = false
	var urgent: = mine and clock >= 0.0 and clock <= 5.0
	serve_label.add_theme_font_size_override("font_size", 
		(26 if urgent else 22) if mine else 17)
	serve_label.add_theme_color_override("font_color", 
		Color(1.0, 0.32, 0.32) if urgent else Color.WHITE)
	if urgent == _serve_urgent:
		return
	_serve_urgent = urgent
	if _serve_pulse != null and _serve_pulse.is_valid():
		_serve_pulse.kill()
	if urgent:


		serve_label.pivot_offset = Vector2(serve_label.size.x, serve_label.size.y * 0.5)
		_serve_pulse = serve_label.create_tween().set_loops().set_ignore_time_scale(true)
		_serve_pulse.tween_property(serve_label, "scale", Vector2(1.12, 1.12), 0.3)\
		.set_trans(Tween.TRANS_SINE)
		_serve_pulse.tween_property(serve_label, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_SINE)
	else:
		serve_label.scale = Vector2.ONE

var _banner_tween: Tween = null

func flash_banner(text: String) -> void :


	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	banner_label.text = text
	_banner_card.visible = true
	_banner_card.modulate.a = 1.0
	UiStyle.pop_in(_banner_card)
	_banner_tween = create_tween()
	_banner_tween.set_ignore_time_scale(true)
	_banner_tween.tween_interval(1.6)
	_banner_tween.tween_property(_banner_card, "modulate:a", 0.0, 0.5)
	_banner_tween.tween_callback( func(): _banner_card.visible = false)





const NOTICE_SECS: = 3.2
var _notice_box: VBoxContainer = null

func notice(text: String) -> void :
	if _notice_box == null:
		_notice_box = VBoxContainer.new()
		_notice_box.name = "Notices"
		_notice_box.add_theme_constant_override("separation", 6)
		_notice_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_notice_box.position = Vector2(22.0, 22.0)
		_notice_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_notice_box)
	var pill: = Label.new()
	pill.text = text
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.style_pill(pill, Color(UiStyle.card(), 0.94), UiStyle.text(), 14)
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_notice_box.add_child(pill)
	UiStyle.pop_in(pill)
	var t: = pill.create_tween()
	t.set_ignore_time_scale(true)
	t.tween_interval(NOTICE_SECS)
	t.tween_property(pill, "modulate:a", 0.0, 0.4)
	t.tween_callback(pill.queue_free)

var _stats_hash: = 0

func show_stats(rows: Array) -> void :



	var networked: bool = Net.active
	var local_peer: = 1
	var local_ping: = -1
	if networked:
		var mp: = get_multiplayer()
		if mp != null and mp.multiplayer_peer != null:
			local_peer = mp.get_unique_id()




		local_ping = maxi(int(round(Net.peer_rtt_ms(1))), int(Net.fake_latency_ms))
	_stats_drawer.set_rows(rows, local_peer, networked, local_ping)
	_stats_drawer.open()

func hide_stats() -> void :
	if _stats_drawer != null:
		_stats_drawer.close()



func set_fade(alpha: float) -> void :
	$Fade.modulate.a = clampf(alpha, 0.0, 1.0)

func show_cine_name(text: String, color: Color, subtitle: = "") -> void :

	var name_label: Label = $CineName
	name_label.text = text
	name_label.add_theme_color_override("font_color", color)
	name_label.visible = true
	var sub: Label = $CineSub
	sub.text = subtitle
	sub.add_theme_color_override("font_color", color)
	sub.visible = subtitle != ""

func hide_cine_name() -> void :
	$CineName.visible = false
	$CineSub.visible = false

func show_countdown(n: int) -> void :
	var label: Label = $Countdown
	if not label.visible or label.text != str(n):

		if n >= 1 and n <= 3:
			announce_moment("count_%d" % n)

		label.text = str(n)
		label.visible = true
		label.scale = Vector2(1.6, 1.6)
		label.pivot_offset = label.size * 0.5
		var tween: = create_tween()
		tween.set_ignore_time_scale(true)
		tween.tween_property(label, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_countdown() -> void :
	$Countdown.visible = false

func grab_dissolve() -> void :


	var img: = get_viewport().get_texture().get_image()
	if img == null:
		return
	var d: TextureRect = $Dissolve
	d.texture = ImageTexture.create_from_image(img)
	d.modulate.a = 1.0
	d.visible = true

func set_dissolve(alpha: float) -> void :
	var d: TextureRect = $Dissolve
	d.modulate.a = clampf(alpha, 0.0, 1.0)
	d.visible = d.modulate.a > 0.01

func set_loading(alpha: float) -> void :


	var l: ColorRect = $Loading
	l.modulate.a = clampf(alpha, 0.0, 1.0)
	l.visible = l.modulate.a > 0.01

func hide_cinematics() -> void :
	hide_cine_name()
	hide_countdown()
	set_fade(0.0)
	set_dissolve(0.0)
	set_replay_banner(false, 0, 0)

func set_replay_banner(shown: bool, votes: int, needed: int) -> void :




	_set_match_ui_hidden(shown)


	var box: Control = get_node_or_null("ReplayTag")
	if box == null:
		if not shown:
			return
		box = _build_replay_tag()
		add_child(box)
	box.visible = shown
	if shown:
		var sub: Label = box.find_child("Sub", true, false)
		sub.text = "space to skip    %d/%d" % [votes, needed] if needed > 1\
		else "space to skip"





func _build_replay_tag() -> Control:


	var box: = CenterContainer.new()
	box.name = "ReplayTag"
	box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_top = -140.0
	box.offset_bottom = -48.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var col: = VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 1)
	box.add_child(col)


	var row: = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 9)
	col.add_child(row)

	var dot: = Panel.new()
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.custom_minimum_size = Vector2(12, 12)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ds: = StyleBoxFlat.new()
	ds.bg_color = Color(1.0, 0.28, 0.3)
	ds.set_corner_radius_all(6)
	ds.shadow_color = Color(0, 0, 0, 0.7)
	ds.shadow_size = 3
	dot.add_theme_stylebox_override("panel", ds)
	row.add_child(dot)

	var pt: = dot.create_tween().set_ignore_time_scale(true).set_loops()
	pt.tween_property(dot, "modulate:a", 0.25, 0.6).set_trans(Tween.TRANS_SINE)
	pt.tween_property(dot, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)

	var tag: = Label.new()
	tag.name = "Tag"
	tag.text = "instant replay"
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_BLACK))
	tag.add_theme_font_size_override("font_size", 25)
	tag.add_theme_color_override("font_color", Color.WHITE)
	tag.add_theme_color_override("font_outline_color", Color.BLACK)
	tag.add_theme_constant_override("outline_size", 6)
	row.add_child(tag)

	var sub: = Label.new()
	sub.name = "Sub"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_SEMI))
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	sub.add_theme_constant_override("outline_size", 4)
	col.add_child(sub)
	return box



signal play_again_pressed
signal to_lobby_pressed

func _build_stats_boards() -> void :


	$StatsPanel / Box / Title.visible = false
	stats_grid.visible = false



	stats_panel.visible = false
	_stats_drawer = STATS_DRAWER.new()
	add_child(_stats_drawer)
	move_child(_stats_drawer, get_child_count() - 1)
	$PostStats / Box / Margin / Inner / Rows.visible = false
	_post_stats_board = STATS_BOARD.instantiate()
	$PostStats / Box / Margin / Inner.add_child(_post_stats_board)
	$PostStats / Box / Margin / Inner.move_child(_post_stats_board, 1)
	_style_stats_surfaces()

func _style_stats_surfaces() -> void :
	_stats_dark = UiStyle.dark
	UiStyle.style_panel(stats_panel)
	UiStyle.style_panel($PostStats, UiStyle.bg(), 24)
	($PostStats / Dim as ColorRect).color = Color(UiStyle.bg(), 0.94)
	UiStyle.wash($PostStats)
	UiStyle.style_button($PostStats / Box / Margin / Inner / Buttons / PlayAgainBtn, 
		"primary", 20)
	UiStyle.style_button($PostStats / Box / Margin / Inner / Buttons / LobbyBtn, 
		"secondary", 20)


func _ready_post() -> void :
	$PostStats / Box / Margin / Inner / Buttons / PlayAgainBtn.pressed.connect(
		func(): play_again_pressed.emit())
	$PostStats / Box / Margin / Inner / Buttons / LobbyBtn.pressed.connect(
		func(): to_lobby_pressed.emit())

func show_match_stats(rows: Array, winner_side: int, my_side: int, 
		host_controls: bool) -> void :
	_pa_states = {}
	_pa_name_labels = {}



	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var result: Label = $PostStats / Box / Margin / Inner / Result
	var won: = winner_side == my_side
	result.text = "victory!" if won else "defeat"



	result.add_theme_color_override("font_color", 
		Rules.side_color(my_side) if won else Color(0.62, 0.62, 0.66))
	var ordered: Array = []
	for side in [winner_side, - winner_side]:
		var side_rows: = rows.filter( func(r): return int(r.get("side", 1)) == side)
		side_rows.sort_custom( func(a, b): return int(a.pts) > int(b.pts))
		ordered.append_array(side_rows)
	_post_stats_board.set_rows(ordered)
	_pa_name_labels = _post_stats_board.name_labels
	$PostStats / Box / Margin / Inner / Buttons.visible = host_controls
	$PostStats / Box / Margin / Inner / WaitLabel.visible = not host_controls
	$PostStats.visible = true





func quick_stats_mode(can_leave: = true) -> void :
	$PostStats / Box / Margin / Inner / Buttons.visible = true


	$PostStats / Box / Margin / Inner / WaitLabel.visible = true
	($PostStats / Box / Margin / Inner / WaitLabel as Label).text = ""
	($PostStats / Box / Margin / Inner / Buttons / PlayAgainBtn as Button).text = "play again"


	($PostStats / Box / Margin / Inner / Buttons / PlayAgainBtn as Button).visible = true
	var lobby_btn: = $PostStats / Box / Margin / Inner / Buttons / LobbyBtn as Button
	lobby_btn.text = "back to menu"
	lobby_btn.visible = can_leave






func room_stats_mode() -> void :
	$PostStats / Box / Margin / Inner / Buttons.visible = true
	($PostStats / Box / Margin / Inner / Buttons / PlayAgainBtn as Button).visible = false
	var lobby_btn: = $PostStats / Box / Margin / Inner / Buttons / LobbyBtn as Button


	lobby_btn.text = "back to menu"
	lobby_btn.visible = true
	$PostStats / Box / Margin / Inner / WaitLabel.visible = true
	($PostStats / Box / Margin / Inner / WaitLabel as Label).text = \
	"you can wait here for the host to start another match."

func set_play_again(text: String, disabled: bool) -> void :
	var btn: = $PostStats / Box / Margin / Inner / Buttons / PlayAgainBtn as Button
	btn.text = text
	btn.disabled = disabled

func set_quick_wait(text: String) -> void :
	($PostStats / Box / Margin / Inner / WaitLabel as Label).text = text




const PA_SPIN: = ["|", "/", "-", "\\"]
var _pa_states: = {}
var _pa_name_labels: = {}
var _pa_spin: = 0.0

func set_pa_marks(states: Dictionary) -> void :
	_pa_states = states
	_render_pa_marks()

func _render_pa_marks() -> void :
	for pa_name in _pa_name_labels:
		var label: Label = _pa_name_labels[pa_name]
		if not is_instance_valid(label):
			continue
		var mark: = ""
		match String(_pa_states.get(pa_name, "")):
			"in":
				mark = "  ✓"
			"out":
				mark = "  ✗"
			"wait":
				mark = "  " + PA_SPIN[int(_pa_spin * 8.0) % PA_SPIN.size()]
		label.text = String(pa_name) + mark

func _stat_header(box: VBoxContainer) -> void :
	var grid: = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 24)
	for h in ["player", "points", "blocks", "receives", "sets"]:
		var cell: = Label.new()
		cell.text = h
		cell.custom_minimum_size = Vector2(200 if h == "player" else 90, 0)
		cell.add_theme_font_size_override("font_size", 15)
		cell.add_theme_color_override("font_color", Color(0.6, 0.62, 0.68))
		grid.add_child(cell)
	box.add_child(grid)




const _PARTY_COLORS: = [Color("46b4ff"), Color("ffc93c"), 
	Color("b06cff"), Color("ff8a3d")]
var _link_cache: = {}

func _party_color(group: int) -> Color:
	return _PARTY_COLORS[(group - 1) % _PARTY_COLORS.size()]


func _link_tex(col: Color) -> Texture2D:
	var key: = col.to_html()
	if _link_cache.has(key):
		return _link_cache[key]
	var w: = 30
	var h: = 20
	var s: = 3
	var img: = Image.create(w * s, h * s, false, Image.FORMAT_RGBA8)
	var cy: = (h * s) * 0.5
	var ax: = (w * s) * 0.22
	var ay: = (h * s) * 0.34
	var th: = (w * s) * 0.09
	for y in h * s:
		for x in w * s:
			var a: = 0.0
			for cx: float in [(w * s) * 0.36, (w * s) * 0.64]:
				var dx: float = (x - cx) / ax
				var dy: float = (y - cy) / ay
				var ring: float = absf(sqrt(dx * dx + dy * dy) - 1.0) * ax
				a = maxf(a, clampf(th - ring, 0.0, 1.0))
			if a > 0.0:
				img.set_pixel(x, y, Color(col.r, col.g, col.b, a))
	img.resize(w, h, Image.INTERPOLATE_LANCZOS)
	var tex: = ImageTexture.create_from_image(img)
	_link_cache[key] = tex
	return tex

func _stat_line(box: VBoxContainer, r: Dictionary, side: int) -> void :
	var grid: = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 24)


	var tint: = Rules.side_color(side)
	var vals: = [str(r.name), str(r.pts), str(r.blk), str(r.rcv), str(r.set)]
	for i in vals.size():
		if i == 0:
			var name_lbl: = Label.new()
			name_lbl.text = vals[0]
			name_lbl.add_theme_font_size_override("font_size", 20)
			name_lbl.add_theme_color_override("font_color", tint)
			_pa_name_labels[str(r.name)] = name_lbl
			var pgroup: = int(r.get("party", 0))
			if pgroup > 0:

				var hb: = HBoxContainer.new()
				hb.add_theme_constant_override("separation", 6)
				hb.custom_minimum_size = Vector2(200, 0)
				var link: = TextureRect.new()
				link.texture = _link_tex(_party_color(pgroup))
				link.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				link.custom_minimum_size = Vector2(26, 0)
				link.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				link.tooltip_text = "queued as a party"
				hb.add_child(link)
				hb.add_child(name_lbl)
				grid.add_child(hb)
			else:
				name_lbl.custom_minimum_size = Vector2(200, 0)
				grid.add_child(name_lbl)
		else:
			var cell: = Label.new()
			cell.text = vals[i]
			cell.custom_minimum_size = Vector2(90, 0)
			cell.add_theme_font_size_override("font_size", 20)
			grid.add_child(cell)
	box.add_child(grid)

func hide_match_stats() -> void :
	$PostStats.visible = false

func stats_open() -> bool:
	return $PostStats.visible
