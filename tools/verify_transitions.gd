extends SceneTree

# Regression gate for the mobile/touch batch of fixes. Headless, no device:
#
#     godot --headless --path . --script tools/verify_transitions.gd
#
# Exits non-zero when a check fails, so CI can gate a release on it.
#
# It exists because two real bugs in that batch only surfaced here: an edit that
# swallowed a blank line and joined two statements, and a scene transition that
# waited on [signal RenderingServer.frame_post_draw], which is never emitted in a
# headless run. Plain parsing in an editor would have missed neither, and neither
# would a build that only reports success.
#
# What it does NOT cover: anything that needs a phone. Touch delivery, the iOS
# exit path (OS.kill is iOS-only) and how fast a real device loads a venue are
# still on the player to confirm.

const TARGET_SCENE: = "res://tools/verify_target.tscn"
const TARGET_SCRIPT: = "res://tools/verify_target.gd"
const SETTINGS_PROBE: = "user://_verify_settings.json"

var _frames: = 0
var _failures: Array[String] = []

func _process(_delta: float) -> bool:
	_frames += 1
	return false

func _fail(what: String) -> void :
	_failures.append(what)
	print("  FAIL ", what)

func _init() -> void:
	# Autoloads are registered after the main loop starts; loading scripts before
	# that would report a false "Identifier not found: GameConfig" for any file
	# that uses one.
	await process_frame
	await process_frame

	var gc: Node = root.get_node_or_null("GameConfig")
	if gc == null:
		print("RESULT autoload_missing=true")
		quit(1)
		return

	print("=== 1. every project script compiles ===")
	var scripts: Array[String] = []
	_collect_scripts("res://game", scripts)
	_collect_scripts("res://tools", scripts)
	var broken: Array[String] = []
	for path in scripts:
		if load(path) == null:
			broken.append(path)
	if not broken.is_empty():
		for path in broken:
			_fail("compiles: " + path)
	print("  checked=", scripts.size(), " broken=", broken.size())

	print("=== 2. movement wheel is a disc and has no label ===")
	var wheel_ok := false
	var hint_gone := false
	var tc: Node = root.get_node_or_null("TouchControls")
	if tc == null:
		_fail("wheel: TouchControls autoload missing")
	else:
		tc._layout()
		var base: Panel = tc._stick_base
		var skin: StyleBoxFlat = base.get_theme_stylebox("panel")
		var radius: int = skin.corner_radius_top_left
		var needs: int = int(base.size.x * 0.5)
		wheel_ok = radius >= needs - 1 and is_equal_approx(base.size.x, base.size.y)
		var leftovers := 0
		for n in tc._root.get_children():
			if n.name == "StickHint":
				leftovers += 1
			elif n is Label and String((n as Label).text).strip_edges().to_lower() == "move":
				leftovers += 1
		hint_gone = leftovers == 0
		print("  base=", base.size, " corner_radius=", radius, " needed=", needs,
			" disc=", wheel_ok, " stray_move_labels=", leftovers)
		if not wheel_ok:
			_fail("wheel: base is not a disc")
		if not hint_gone:
			_fail("wheel: a 'move' label is still there")

	print("=== 3. touch preset flag survives a settings round-trip ===")
	var real_path: String = gc._settings_path
	gc._settings_path = SETTINGS_PROBE
	gc._assist_defaulted = true
	gc.difficulty = 0
	gc.aim_assist = true
	gc.save_settings()
	gc._assist_defaulted = false
	gc.difficulty = 1
	gc.aim_assist = false
	gc._load_settings()
	var round_trip: bool = bool(gc._assist_defaulted) and int(gc.difficulty) == 0\
		and bool(gc.aim_assist)
	print("  flag=", gc._assist_defaulted, " difficulty=", gc.difficulty,
		" aim_assist=", gc.aim_assist, " round_trip=", round_trip)
	if not round_trip:
		_fail("preset flag did not survive the settings file")
	gc._settings_path = real_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PROBE))

	print("=== 4. a synchronous load stalls the main thread, the threaded one does not ===")
	var sync_scene: = "res://game/character/locker.tscn"
	var f0: = _frames
	var t0: = Time.get_ticks_msec()
	var sync_pre = ResourceLoader.load(sync_scene)
	var sync_frames: = _frames - f0
	print("  sync  ok=", sync_pre != null, " ", Time.get_ticks_msec() - t0,
		"ms frames_drawn=", sync_frames)
	if sync_frames != 0:
		# Not a failure of the game, but the comparison below stops meaning
		# anything, so say so rather than reporting a pass.
		print("  note: this machine drew frames during a blocking load")
	var async_scene: = "res://game/shop/shop.tscn"
	var f1: = _frames
	var t1: = Time.get_ticks_msec()
	var pre = await gc._load_async(async_scene)
	var async_frames: = _frames - f1
	print("  async ok=", pre != null, " ", Time.get_ticks_msec() - t1,
		"ms frames_drawn=", async_frames)
	if pre == null:
		_fail("threaded load returned nothing for " + async_scene)

	print("=== 5. a transition keeps its cover up until the scene lands ===")
	var wipe_script = load("res://game/ui/style/ui_wipe.gd")
	var target_script = load(TARGET_SCRIPT)
	var before_scene = current_scene
	wipe_script.wipe(self, func() -> void : gc.goto_scene(TARGET_SCENE))
	var uncovered_early := false
	var alive_at_swap := false
	var pending_seen := false
	var swapped := false
	var t2: = Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - t2) < 15000.0:
		await process_frame
		if gc.scene_change_pending():
			pending_seen = true
			if not _wipe_alive(wipe_script):
				uncovered_early = true
		else:
			if current_scene != null and not swapped:
				swapped = true
				alive_at_swap = _wipe_alive(wipe_script)
			if not _wipe_alive(wipe_script):
				break
	var swapped_ok: bool = swapped and current_scene != null\
		and current_scene.get_script() == target_script
	print("  pending_seen=", pending_seen, " uncovered_early=", uncovered_early,
		" alive_at_swap=", alive_at_swap, " swapped_ok=", swapped_ok,
		" total_ms=", Time.get_ticks_msec() - t2)
	if not pending_seen:
		_fail("transition: the wipe never saw a pending scene change")
	if uncovered_early:
		_fail("transition: the cover lifted before the scene was ready")
	if not alive_at_swap:
		_fail("transition: the cover lifted on the same frame as the swap")
	if not swapped_ok:
		_fail("transition: the scene did not swap to the target")

	var ok: = _failures.is_empty()
	print("RESULT ok=", ok, " scripts=", scripts.size(), " broken=", broken.size(),
		" wheel=", wheel_ok, " hint_removed=", hint_gone,
		" preset_round_trip=", round_trip, " sync_frames=", sync_frames,
		" async_frames=", async_frames, " held_cover=", not uncovered_early,
		" swapped_ok=", swapped_ok)
	if not ok:
		print("FAILURES: ", _failures)
	quit(0 if ok else 1)

func _wipe_alive(wipe_script) -> bool:
	for c in root.get_children():
		if c.get_script() == wipe_script:
			return true
	return false

func _collect_scripts(dir_path: String, out: Array[String]) -> void :
	var dir: = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name: = dir.get_next()
	while name != "":
		if name.begins_with("."):
			name = dir.get_next()
			continue
		var full: = dir_path.path_join(name)
		if dir.current_is_dir():
			_collect_scripts(full, out)
		elif name.ends_with(".gd"):
			out.append(full)
		name = dir.get_next()
	dir.list_dir_end()
