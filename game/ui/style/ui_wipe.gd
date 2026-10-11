class_name UiWipe
extends CanvasLayer












const TILT: = 0.09
const SWEEP_IN: = 0.26
const SWEEP_OUT: = 0.3
const CHASE: = 0.05
# Last-resort deadline for the whole transition. The overlay is full-screen
# solid yellow, so any path that fails to reach the end strands the player on
# a blank screen with no way out. Better to drop the overlay late than never.
const FAILSAFE: = 4.0

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
		if not _done:
			push_warning("UiWipe failsafe fired; dropping the overlay")
			_finish())


func _finish() -> void :
	if _done:
		return
	_done = true
	if _active == self:
		_active = null
	queue_free()
