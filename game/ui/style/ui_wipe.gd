class_name UiWipe
extends CanvasLayer












# The sweeps are the whole transition cost on a warm load, so they stay short:
# long enough to read as a wipe rather than a cut, short enough that entering a
# match does not start with a second of solid yellow. A cold load is no longer
# covered by a longer sweep either, it is waited out under the slabs with a
# moving bar (see [method _hold_for_scene]).
const TILT: = 0.09
const SWEEP_IN: = 0.15
const SWEEP_OUT: = 0.17
const CHASE: = 0.03
# Last-resort deadline for the whole transition. The overlay is full-screen
# solid yellow, so any path that fails to reach the end strands the player on
# a blank screen with no way out. Better to drop the overlay late than never.
const FAILSAFE: = 4.0
# Hard ceiling on how long a real scene load may keep the slabs up. Past this
# the overlay comes down even if the load is still running, so a request that
# never completes cannot strand the player on solid yellow either.
const HOLD_MAX: = 30.0

const BAR_W: = 320.0
const BAR_H: = 12.0

static var _active: UiWipe = null

static func wipe(tree: SceneTree, mid: = Callable()) -> void :
	# Overlapping wipes stack slabs and can strand the top one; retire the old
	# overlay first so only one is ever animating.
	if is_instance_valid(_active):
		_active.queue_free()
		_active = null
	var w: UiWipe = UiWipe.new()
	w.layer = 100




	w.process_mode = Node.PROCESS_MODE_ALWAYS
	_active = w
	# Adding to the tree root fails outright while the root is still setting up
	# its children (which is exactly when the title screen fires its first
	# transition). A silently-unparented wipe then has a null viewport, dies
	# partway through, and leaves the transition -- and sometimes the screen --
	# stranded. Try the direct add, and defer only if the root refused it.
	w.tree_entered.connect(func() -> void : w._run(mid), CONNECT_ONE_SHOT)
	tree.root.add_child(w)
	if w.get_parent() == null:
		tree.root.add_child.call_deferred(w)



var _done := false
var _holding := false
var _hold_started := 0
var _load_row: Control = null
var _load_track: Panel = null
var _load_fill: Panel = null


func _slab(color: Color, vp: Vector2) -> Panel:
	var p: = Panel.new()
	var b: = StyleBoxFlat.new()
	b.bg_color = color
	b.set_corner_radius_all(64)
	p.add_theme_stylebox_override("panel", b)

	p.size = vp * Vector2(1.6, 1.8)
	p.rotation = TILT
	p.pivot_offset = p.size * 0.5
	add_child(p)
	return p

func _park(p: Panel, vp: Vector2, side: float) -> void :
	p.position = Vector2(side * vp.x * 1.8 - p.size.x * 0.5 + vp.x * 0.5, 
		- p.size.y * 0.5 + vp.y * 0.5)

func _run(mid: Callable) -> void :
	_arm_failsafe()
	var vp: = get_viewport().get_visible_rect().size
	UiStyle.sfx("wipe_in")
	var chase: = _slab(UiStyle.INK, vp)
	var lead: = _slab(UiStyle.PRIMARY, vp)
	_park(lead, vp, -1.0)
	_park(chase, vp, -1.0)
	var t: = create_tween().set_parallel(true).set_ignore_time_scale(true)
	t.tween_property(lead, "position:x", 
		vp.x * 0.5 - lead.size.x * 0.5, SWEEP_IN)\
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	t.tween_property(chase, "position:x", 
		vp.x * 0.5 - chase.size.x * 0.5, SWEEP_IN)\
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)\
		.set_delay(CHASE)
	await _settle(t, SWEEP_IN + CHASE)
	if mid.is_valid():
		mid.call()
	await _hold_for_scene()

	await get_tree().process_frame
	await get_tree().process_frame
	UiStyle.sfx("wipe_out")
	var out: = create_tween().set_parallel(true).set_ignore_time_scale(true)
	out.tween_property(lead, "position:x", 
		vp.x * 0.5 + vp.x * 1.8 - lead.size.x * 0.5, SWEEP_OUT)\
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	out.tween_property(chase, "position:x", 
		vp.x * 0.5 + vp.x * 1.8 - chase.size.x * 0.5, SWEEP_OUT)\
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)\
		.set_delay(CHASE)
	await _settle(out, SWEEP_OUT + CHASE)
	_finish()


# The slabs are up, so the next scene has to exist before they sweep out:
# sweeping out first would show the old screen again for a moment. A scene load
# used to happen right here on the main thread, inside change_scene_to_file,
# which is why a big venue looked like a hang -- solid yellow, not one frame
# drawn. GameConfig loads on a worker thread now, so this is a wait the engine
# can render through, and the time it takes is shown instead of hidden.
func _hold_for_scene() -> void :
	if not GameConfig.scene_change_pending():
		return
	_holding = true
	_hold_started = Time.get_ticks_msec()
	_show_load_row()
	while GameConfig.scene_change_pending()\
	and float(Time.get_ticks_msec() - _hold_started) < HOLD_MAX * 1000.0\
	and not _done:
		_set_load_progress(GameConfig.scene_load_progress())
		await get_tree().process_frame
	if GameConfig.scene_change_pending():
		push_warning("UiWipe gave up waiting for the scene load")
	_holding = false
	_hide_load_row()

func _show_load_row() -> void :
	if _load_row != null:
		return
	var col: = VBoxContainer.new()
	col.name = "LoadRow"
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 12)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_row = col
	add_child(col)

	# Upright, unlike the tilted slabs behind it, and in ink on the yellow
	# lead slab so it reads at a glance.
	var label: = Label.new()
	label.text = "loading"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.style_label(label, "shout", UiStyle.INK)
	label.add_theme_font_size_override("font_size", 30)
	col.add_child(label)

	var holder: = CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(holder)

	_load_track = Panel.new()
	_load_track.custom_minimum_size = Vector2(BAR_W, BAR_H)
	_load_track.size = Vector2(BAR_W, BAR_H)
	_load_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track: = StyleBoxFlat.new()
	track.bg_color = Color(UiStyle.INK, 0.22)
	track.set_corner_radius_all(int(BAR_H * 0.5))
	_load_track.add_theme_stylebox_override("panel", track)
	holder.add_child(_load_track)

	_load_fill = Panel.new()
	_load_fill.size = Vector2(0.0, BAR_H)
	_load_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill: = StyleBoxFlat.new()
	fill.bg_color = UiStyle.INK
	fill.set_corner_radius_all(int(BAR_H * 0.5))
	_load_fill.add_theme_stylebox_override("panel", fill)
	_load_track.add_child(_load_fill)

	var vp: = get_viewport()
	if vp != null:
		var size: = vp.get_visible_rect().size
		col.position = Vector2.ZERO
		col.size = size

func _hide_load_row() -> void :
	if _load_row != null:
		_load_row.queue_free()
	_load_row = null
	_load_track = null
	_load_fill = null

func _set_load_progress(p: float) -> void :
	if _load_fill == null:
		return
	if p < 0.0:
		# Not every platform reports progress for a threaded load; sweep the
		# segment instead of parking a dead bar in front of the player.
		var span: = BAR_W * 0.34
		var k: = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 320.0)
		_load_fill.size = Vector2(span, BAR_H)
		_load_fill.position = Vector2((BAR_W - span) * k, 0.0)
		return
	_load_fill.position = Vector2.ZERO
	_load_fill.size = Vector2(BAR_W * clampf(p, 0.0, 1.0), BAR_H)


# Await a Tween without trusting its `finished` signal. A Tween that gets killed
# (a second wipe, a freed node, a scene swap) never emits `finished`, so a bare
# `await t.finished` waits forever and strands the full-screen slab. Race it
# against a real timer instead, and kill the tween if it overran.
func _settle(t: Tween, limit: float) -> void :
	var finished := [false]
	t.finished.connect(func() -> void : finished[0] = true,
		CONNECT_ONE_SHOT)
	await get_tree().create_timer(limit, true, false, true).timeout
	if not finished[0] and t.is_valid():
		t.kill()


# Runs independently of _run's own call stack, so the overlay still comes down
# when a runtime error inside the mid() callback aborts _run partway through.
func _arm_failsafe() -> void :
	var t: SceneTreeTimer = get_tree().create_timer(FAILSAFE, true, false, true)
	t.timeout.connect(func() -> void :
		if _done:
			return
		# A scene load is genuinely in flight and the bar is moving, so this is
		# not a stall: re-arm instead of yanking the cover off a load that is
		# about to finish. _hold_for_scene owns the hard ceiling, so this window
		# cannot keep re-arming forever.
		if _holding and float(Time.get_ticks_msec() - _hold_started) / 1000.0 < HOLD_MAX:
			_arm_failsafe()
			return
		push_warning("UiWipe failsafe fired; dropping the overlay")
		_finish())


func _finish() -> void :
	if _done:
		return
	_done = true
	if _active == self:
		_active = null
	queue_free()
