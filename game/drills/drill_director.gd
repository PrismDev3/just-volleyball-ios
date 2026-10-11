class_name DrillDirector
extends Node











var runner: DrillRunner = null
var overlay: Control = null
var sfx = null

func setup(r: DrillRunner, o: Control, entry: Dictionary) -> void :
	runner = r
	overlay = o
	if runner.progress_changed.is_connected(_on_progress):
		return
	runner.progress_changed.connect(_on_progress)
	runner.instruction_changed.connect(_on_instruction)
	runner.feedback.connect(_on_feedback)
	arm(entry)


func arm(entry: Dictionary) -> void :
	if overlay == null:
		return
	overlay.visible = true
	overlay.set_section(String(entry.get("name", "drill")), [], String(entry.get("info", "")))
	overlay.set_nav_visible(false)
	overlay.hide_box()
	overlay.set_action_prompt("", "", "")
	overlay.set_playing(true)
	overlay.set_checks(0, 0)

func hide() -> void :
	if overlay != null and is_instance_valid(overlay):
		overlay.set_playing(false)
		overlay.visible = false

func teardown() -> void :
	if runner != null:
		if runner.progress_changed.is_connected(_on_progress):
			runner.progress_changed.disconnect(_on_progress)
		if runner.instruction_changed.is_connected(_on_instruction):
			runner.instruction_changed.disconnect(_on_instruction)
		if runner.feedback.is_connected(_on_feedback):
			runner.feedback.disconnect(_on_feedback)
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = null

func _on_progress(done: int, req: int) -> void :
	overlay.set_checks(done, req)
	if sfx != null and done > 0:
		sfx.play_2d("combo_home_%d" % clampi(done, 1, 3), -6.0)

func _on_instruction(text: String) -> void :
	overlay.set_hint(text)

func _on_feedback(text: String, positive: bool) -> void :
	if positive:
		overlay.flash(text, true)
	else:
		if text != "":
			overlay.set_hint(text)
		overlay.emphasize_hint()
		if sfx != null:
			sfx.play_2d("combo_tut_fail", -8.0)
