class_name TutorialDirector
extends Node












signal finished





const SECTIONS: = [
	{"name": "", "pages": [
		"let's learn the basics of just volleyball!", 
		"this game is cursor based, so every touch goes where you're aiming, whether you're bumping, setting, spiking, or blocking", 
		"your basic controls are {contact} to bump, {set} to set, and {dive} to dive or block", 
		"jumping is {jump}, you need to jump in order to spike and block", 
		"the main goal of volleyball is to send the ball over the net and land it on the opponent's floor, while stopping them from doing the same to you", 
	]}, 
	{"name": "movement", "objective": "movement", "mine": [], "far": [], 
		"prompt": "move  {move}", "inputs": [["move", "move"]], 
		"pages": [
		"make your way to each marker!", 
	]}, 
	{"name": "camera", "objective": "tutorial_camera", "mine": [], "far": [], 
		"prompt": "camera  {camera_toggle}   zoom  {camera_zoom}", "inputs": [["camera_toggle", "change camera"], ["camera_zoom", "zoom"]], 
		"pages": [
		"you can press {camera_toggle} to change your camera mode, and {camera_zoom} to switch zoom distance! alternatively, if you're on mouse you can simply scroll in and out", 
	]}, 
	{"name": "strafing", "objective": "strafing", "mine": [], "far": [], 
		"prompt": "strafe  {strafe}   hold", "inputs": [["move", "move"], ["strafe", "hold strafe"], ["@mouse", "aim"]], 
		"coach": "try keeping your cursor on your teammate while strafing around!", 
		"pages": [
		"by holding down {strafe}, your character will always face towards your cursor! strafing is also good for canceling momentum", 
	]}, 
	{"name": "jumping", "objective": "jumping", "mine": [], "far": [0, 1], 
		"prompt": "jump  {jump}   hold to charge", "inputs": [["move", "move"], ["jump", "jump"], ["@mouse", "aim"]], 
		"coach": "starting on each marker, jump through the hoop!", 
		"pages": [
		"by pressing {jump}, you can jump! you can charge it to jump even higher", 
		"practice some jumps by going through these hoops!", 
	]}, 
	{"name": "bumping", "objective": "receiving_1", "mine": [], "far": [0], "mark": "teammate", 
		"prompt": "bump  {contact}", "inputs": [["move", "move"], ["@mouse", "aim at your teammate"], ["contact", "bump"]], 
		"coach": "try getting some bumps to your teammate!", 
		"pages": [
		"bumping is usually the first touch, and all bumps go towards where your cursor is!", 
		"there are three ways to bump the ball:", 
		"once you're in range, press {contact} and your character will queue the bump for you", 
		"or, you can hold {contact} as you stand in the proper position, which is recommended when playing on higher ping online", 
		"lastly, you can simply time it and press {contact} once the ball is in range", 
	]}, 
	{"name": "diving", "objective": "tutorial_dive", "mine": [], "far": [0], "mark": "teammate", 
		"prompt": "dive  {dive}   on the ground", "inputs": [["move", "move"], ["dive", "dive"], ["@mouse", "aim at your teammate"]], 
		"coach": "dive for the ball and get it to your teammate!", 
		"pages": [
		"there'll be times you won't be able to reach the ball by running, so you'll have to press {dive} to dive instead!", 
		"you'll dive towards where the ball lands, but your cursor still aims where you bump it", 
	]}, 
	{"name": "setting", "objective": "tutorial_set", "mine": [], "far": [0, 1, 2], "mark": "body", 
		"prompt": "set  {set}", "inputs": [["@mouse", "aim at your spiker"], ["set", "set"]], 
		"coach": "set the ball up to your teammate!", 
		"pages": [
		"pressing {set} will set the ball, letting you set up spikes for your attacks with better precision", 
		"you still need to aim in the general area where you want the ball to go", 
	]}, 
	{"name": "spiking", "objective": "tutorial_spike", "mine": [], "far": [0, 1], "mark": "setter", 
		"prompt": "spike  {contact} in the air", "inputs": [["jump", "jump"], ["@mouse", "aim"], ["contact", "spike"]], 
		"coach": "practice hitting spikes across the net!", 
		"pages": [
		"while airborne, you can hold down {contact} to charge a spike! how long you charge it, and the height of your contact point, will vary the type of spike you get", 
		"your teammate will set for you, so aim your cursor where you want the ball to land", 
	]}, 
	{"name": "rally", "objective": "tutorial_rally", "mine": [], "far": [0], "mark": "teammate", 
		"prompt": "bump  {contact}     then jump {jump} and spike {contact}", "inputs": [["move", "move"], ["contact", "bump"], ["jump", "jump"], ["contact", "spike"]], 
		"coach": "let's practice it all together!", 
		"pages": [
		"now you can understand the essence of just volleyball, rallies! a bump, into a set, into a spike!", 
		"by building up these three touches, a combo will build, resulting in more powerful spikes!", 
	]}, 
	{"name": "blocking", "objective": "tutorial_block", "mine": [], "far": [], "mark": "hitters", 
		"prompt": "block  {dive} in the air", "inputs": [["jump", "jump"], ["dive", "block in the air"], ["@mouse", "aim"]], 
		"coach": "watch the hitter and block their spike!", 
		"pages": [
		"now for some more defense, by pressing {dive} you can block, which will be your ultimate weapon against attackers", 
		"watch the attacker, you don't want to time your block too early, or too late", 
		"in most cases, you want to jump right after they do, and then throw your hands up!", 
	]}, 
	{"name": "serving", "objective": "serving_1", "mine": [0], "far": [0, 1], "mark": "zone", 
		"prompt": "serve  {contact}   hold to charge the toss", "inputs": [["move", "move"], ["@mouse", "aim"], ["contact", "toss, hit"]], 
		"pages": [
		"every rally starts with a serve, and the glowing box is your serving area! you want to toss and hit it inside the green area", 
		"hold {contact} to charge your serve toss, and release it to send it in the air", 
		"afterwards you can do a basic bump, a jump attack, there's plenty of options! just make sure you're aiming across to the other side of the court", 
	]}, 
	{"name": "", "pages": [
		"those are the basics! there's a lot more to learn, like curves, jump floats, and quick sets. they'll be under the drills tab in the future!", 
		"now let's put it all together in a real match!", 
	]}, 
]



const FORMATION: = [
	Vector3(-3.6, 0.0, 2.2), 
	Vector3(3.6, 0.0, 2.2), 
	Vector3(0.0, 0.0, 6.0), 
]
const ARROW_SHADER: = preload("res://game/fx/waypoint_arrow.gdshader")
const MARK_COLOR: = Color("ffd33d")
const MARK_HEIGHT: = 2.5
const SERVE_ZONE: = Vector3(0.0, 0.0, -7.5)
const SERVE_ZONE_R: = 2.8
const SERVE_AREA: = preload("res://game/fx/serve_zone.gd")




const SECTION_ACTION: = {
	"bumping": ["bump", "contact", ""], 
	"diving": ["dive", "dive", "on the ground"], 
	"setting": ["set", "set", ""], 
	"jumping": ["jump", "jump", ""], 
	"spiking": ["spike", "contact", "in the air"], 
	"blocking": ["block", "dive", "in the air"], 
}

var runner: DrillRunner = null
var overlay: Control = null
var section_starter: = Callable()
var section: = -1
var page: = 0
var playing: = false
var _extras: Array[Player] = []
var _fading: = false
var _on_progress: = Callable()
var _on_instruction: = Callable()
var _on_feedback: = Callable()
var _arrow: MeshInstance3D = null
var _mark: = ""
var _mouse_was_down: = false
var _bksp_was_down: = false
var _serve_area: MeshInstance3D = null
var _serve_miss_hold: = 0.0
var control_hud: Node = null

var sfx = null

const TUT_SFX_DB: = -8.0
var cam_rig = null



var _grace: = 0.0




func setup(drill_runner: DrillRunner, chrome: Control, starter: Callable) -> void :
	runner = drill_runner
	overlay = chrome
	section_starter = starter
	runner.completed.connect(_on_section_done)



	_on_progress = func(done: int, req: int):
		overlay.set_checks(done, req)
		if done > 0 and sfx != null:
			var bank: = "combo_tut_bonus" if done >= req else "combo_tut_%d" % clampi(done, 1, 8)
			sfx.play_2d(bank, TUT_SFX_DB)

		if SECTIONS[section].has("coach"):
			overlay.set_hint(String(SECTIONS[section].coach))




	_on_instruction = func(text: String):
		var nm: = String(SECTIONS[section].name)



		if nm == "movement" or nm == "serving" or SECTIONS[section].has("coach"):
			return
		overlay.set_hint(text)


	_on_feedback = func(text: String, positive: bool):
		if positive:
			overlay.flash(text, true)
			overlay.pulse_action()
		else:

			if text != "":
				overlay.set_hint(text)
			overlay.emphasize_hint()


			if String(SECTIONS[section].name) == "serving":
				_serve_miss_hold = 1.6
			if sfx != null:
				sfx.play_2d("combo_tut_fail", TUT_SFX_DB)
	runner.progress_changed.connect(_on_progress)
	runner.instruction_changed.connect(_on_instruction)
	runner.feedback.connect(_on_feedback)
	_ensure_nav_actions()




func _ensure_nav_actions() -> void :
	_add_nav_action("tut_restart", KEY_LEFT, JOY_BUTTON_DPAD_LEFT)
	_add_nav_action("tut_skip", KEY_RIGHT, JOY_BUTTON_DPAD_RIGHT)

func _add_nav_action(name: String, key: Key, pad: JoyButton) -> void :
	if InputMap.has_action(name):
		return
	InputMap.add_action(name)
	var k: = InputEventKey.new()
	k.physical_keycode = key
	InputMap.action_add_event(name, k)
	var j: = InputEventJoypadButton.new()
	j.button_index = pad
	InputMap.action_add_event(name, j)


func _restart_section() -> void :
	if _fading:
		return
	if runner != null:
		runner.cancel()
	_enter_section(section)

func _skip_section() -> void :
	if _fading:
		return
	if runner != null:
		runner.cancel()
	if section + 1 < SECTIONS.size():
		_next_section()
	else:
		finished.emit()





func skip_to_end() -> void :
	if _fading:
		return
	if runner != null:
		runner.cancel()
	playing = false
	_fading = true
	overlay.fade( func():
		_fading = false
		_enter_section(SECTIONS.size() - 1))

func begin() -> void :
	DrillObjective.practice_dress = true
	if runner != null:
		runner.sfx = sfx
	_enter_section(0)


func blocking_input() -> bool:
	return (overlay != null and overlay.box_visible()) or _fading or _grace > 0.0

func _enter_section(i: int) -> void :
	section = i
	page = 0
	playing = false
	var s: Dictionary = SECTIONS[i]
	_clear_extras()
	_clear_mark()
	overlay.set_section(String(s.name), s.get("inputs", []), String(s.get("info", "")))


	overlay.set_nav_visible(s.has("objective"))


	_action_cur = ["", "", ""]
	overlay.set_action_prompt("", "", "")
	overlay.set_playing(false)
	overlay.set_hint("")
	if s.has("objective"):

		section_starter.call(String(s.objective))
		_spawn_extras(s)
		_mark = String(s.get("mark", ""))
		if _mark == "zone":



			runner.add_column_marker(SERVE_ZONE, 2.5, MARK_COLOR)
			_serve_area = SERVE_AREA.new()
			runner.get_parent().add_child(_serve_area)
			_serve_area.setup(runner.ball.court_center_x, runner.ball.court_half_w, 
				runner.ball.court_half_l)
		elif _mark != "":
			_make_arrow()
	_show_page()

func _show_page() -> void :


	if cam_rig != null:
		cam_rig.input_frozen = true
	var s: Dictionary = SECTIONS[section]
	var pages: Array = s.pages


	var last_label: = "start" if s.has("objective") else "next"
	overlay.show_page(String(pages[page]), page, pages.size(), 
		page == pages.size() - 1, String(s.get("prompt", "")), last_label, page > 0)

func _advance_page() -> void :
	if _fading or not overlay.box_visible():
		return
	if overlay.typing():
		overlay.reveal_all()
		return
	var pages: Array = SECTIONS[section].pages
	if page + 1 < pages.size():
		page += 1
		_show_page()
		return
	overlay.hide_box()
	if cam_rig != null:
		cam_rig.input_frozen = false
	_grace = 0.35
	if SECTIONS[section].has("objective"):
		playing = true
		overlay.set_playing(true)
		if SECTIONS[section].has("coach"):
			overlay.set_hint(String(SECTIONS[section].coach))
	elif section + 1 < SECTIONS.size():
		_next_section()
	else:



		_fading = true
		overlay.fade( func(): finished.emit(), 0.6)

func _next_section() -> void :
	_fading = true
	overlay.fade( func():
		_fading = false
		_enter_section(section + 1))

func _on_section_done(_id: String, _ms: int) -> void :
	if not playing:
		return
	playing = false
	overlay.set_checks(overlay.checks_count())

	var t: = get_tree().create_timer(0.7)
	t.timeout.connect(_next_section)

func _process(delta: float) -> void :
	if _grace > 0.0:
		_grace = maxf(_grace - delta, 0.0)


	if control_hud != null and is_instance_valid(control_hud):
		control_hud.visible = not ((overlay != null and overlay.box_visible()) or _fading)



	if not _fading and section >= 0 and SECTIONS[section].has("objective"):
		if Input.is_action_just_pressed("tut_restart"):
			_restart_section()
			return
		if Input.is_action_just_pressed("tut_skip"):
			_skip_section()
			return
	if overlay == null or not overlay.box_visible() or _fading:
		return


	var click: = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var click_edge: = click and not _mouse_was_down
	_mouse_was_down = click


	var bksp: = Input.is_key_pressed(KEY_BACKSPACE)
	var bksp_edge: = bksp and not _bksp_was_down
	_bksp_was_down = bksp
	if Input.is_action_just_pressed("ui_accept")\
	or Input.is_action_just_pressed("jump") or click_edge:
		UiStyle.sfx("press")
		_advance_page()
	elif Input.is_action_just_pressed("dive") or bksp_edge:
		_back_page()

func _back_page() -> void :
	if _fading or not overlay.box_visible() or page <= 0:
		return
	if overlay.typing():
		overlay.reveal_all()
		return
	UiStyle.sfx("press")
	page -= 1
	_show_page()

const NET_KEEP_Z: = 0.7

func _physics_process(delta: float) -> void :
	for body in _extras:
		if is_instance_valid(body):
			body.puppet_tick(delta)
	if _serve_miss_hold > 0.0:
		_serve_miss_hold -= delta
	_mark_tick()
	_confine_player()
	_action_tick()

var _action_cur: Array = ["", "", ""]




func _current_action() -> Array:
	var nm: = String(SECTIONS[section].name)
	if nm == "rally":
		var ph: = 0
		if runner != null and runner.objective != null:
			var v: Variant = runner.objective.get("rally_phase")
			if v != null:
				ph = int(v)
		if ph <= 0:
			return ["bump", "contact", ""]
		elif ph == 1:
			return ["jump", "jump", "then spike"]
		return ["spike", "contact", "in the air"]
	if nm == "serving":
		var tossing: = runner != null and runner.ball != null and runner.ball.serve_held
		if runner != null and runner.player != null and runner.player.serve_charge_ui:
			tossing = true
		if tossing:
			return ["toss", "contact", "hold to charge"]

		return ["spike", "contact", "in the air", "bump", "contact", "on the ground"]
	var a: Array = SECTION_ACTION.get(nm, ["", "", ""])
	return [String(a[0]), String(a[1]), String(a[2]) if a.size() > 2 else ""]

func _action_tick() -> void :
	if not playing or overlay == null:
		return
	var want: = _current_action()
	if want != _action_cur:
		_action_cur = want
		if want.size() >= 6:
			overlay.set_action_pair(String(want[0]), String(want[1]), String(want[2]), 
				String(want[3]), String(want[4]), String(want[5]))
		else:
			overlay.set_action_prompt(String(want[0]), String(want[1]), String(want[2]))

	var act: = String(want[1])
	if act != "" and InputMap.has_action(act) and Input.is_action_just_pressed(act):
		overlay.pulse_action()





func _confine_player() -> void :
	if runner == null or runner.player == null or not is_instance_valid(runner.player):
		return
	var p: Player = runner.player
	if p.global_position.z < NET_KEEP_Z:
		p.global_position.z = NET_KEEP_Z
		if p.velocity.z < 0.0:
			p.velocity.z = 0.0



func _make_arrow() -> void :
	_arrow = MeshInstance3D.new()
	var quad: = QuadMesh.new()
	quad.size = Vector2(0.7, 1.0)
	var mat: = ShaderMaterial.new()
	mat.shader = ARROW_SHADER
	mat.render_priority = 11
	mat.set_shader_parameter("tint", Color(MARK_COLOR.r, MARK_COLOR.g, MARK_COLOR.b, 1.0))
	mat.set_shader_parameter("edge", Color(MARK_COLOR.r, MARK_COLOR.g, MARK_COLOR.b, 0.94).darkened(0.88))
	quad.material = mat
	_arrow.mesh = quad
	_arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	runner.get_parent().add_child(_arrow)
	_arrow.visible = false

func _mark_tick() -> void :
	if _serve_area != null and runner.player != null:


		var p: = runner.player
		var half_l: float = runner.ball.court_half_l


		var depth: = p.global_position.z * float(p.team_side)
		var front: float = SERVE_AREA.ZONE_FRONT
		var back: float = front - SERVE_AREA.ZONE_DEPTH
		var side_m: float = SERVE_AREA.ZONE_SIDE
		var inside: bool = depth > half_l - front and depth < half_l - back and absf(p.global_position.x - runner.ball.court_center_x) < runner.ball.court_half_w + side_m and not Rules.serve_foot_fault(absf(p.global_position.z), half_l)
		_serve_area.tick(true, float(p.team_side), inside)





		if playing and overlay != null and _serve_miss_hold <= 0.0:
			overlay.set_hint("step inside the glowing box to serve" if not inside\
			else "toss the ball up, then send it over!")
	if _arrow == null or runner.objective == null:
		return
	var target = runner.objective.get(_mark)
	if target is Array:
		target = target[0] if not (target as Array).is_empty() else null
	if target == null or not is_instance_valid(target):
		_arrow.visible = false
		return
	_arrow.visible = true
	_arrow.global_position = (target as Node3D).global_position + Vector3.UP * MARK_HEIGHT

func _clear_mark() -> void :
	_mark = ""
	if _arrow != null and is_instance_valid(_arrow):
		_arrow.queue_free()
	_arrow = null
	if _serve_area != null and is_instance_valid(_serve_area):
		_serve_area.queue_free()
	_serve_area = null



func _spawn_extras(s: Dictionary) -> void :
	var parent: = runner.get_parent()
	for i in s.get("mine", []):
		var b: = DrillObjective.make_puppet(parent, FORMATION[i], 1, 100 + i)
		_extras.append(b)
	for i in s.get("far", []):
		var spot: Vector3 = FORMATION[i]
		var b: = DrillObjective.make_puppet(parent, Vector3(spot.x, 0.0, - spot.z), -1, 200 + i)
		_extras.append(b)

func _clear_extras() -> void :
	for body in _extras:
		if is_instance_valid(body):
			body.queue_free()
	_extras.clear()

func teardown() -> void :
	DrillObjective.practice_dress = false
	if control_hud != null and is_instance_valid(control_hud):
		control_hud.visible = true
	_clear_extras()
	_clear_mark()
	if runner != null:
		if runner.completed.is_connected(_on_section_done):
			runner.completed.disconnect(_on_section_done)
		if _on_progress.is_valid() and runner.progress_changed.is_connected(_on_progress):
			runner.progress_changed.disconnect(_on_progress)
		if _on_instruction.is_valid() and runner.instruction_changed.is_connected(_on_instruction):
			runner.instruction_changed.disconnect(_on_instruction)
		if _on_feedback.is_valid() and runner.feedback.is_connected(_on_feedback):
			runner.feedback.disconnect(_on_feedback)
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = null
