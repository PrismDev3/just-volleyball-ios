extends Node3D


































const MENU_SCENE: = "res://game/ui/menu.tscn"
const LOGO: = preload("res://game/logo/jvlogo_HD.png")
const BALL_SCENE: = preload("res://game/ball/ball.tscn")
const MUSIC_INTRO: = "res://game/ost/replay/replay (w_stinger).wav"
const MUSIC_LOOP: = "res://game/ost/replay/replay loop.wav"
const PRESS_SFX: = "res://game/sfx/Ui/johnuisfx/UI_TwoNote Up_Set 11_03.wav"

const LAYER_BODIES: = 1
const LAYER_BALLS: = 1 << 1



const CAM_FOV: = 22.0
const VIEW_H: = 5.4
const LOOK: = Vector2(0.0, 1.95)










const SLOTS: = [
	{"x": 0.9, "y": 1.1, "rel": 1.15, "d": -0.5, "zone": "lead"}, 
	{"x": -0.7, "y": 0.0, "rel": 0.96, "d": 0, "zone": "key"}, 
	{"x": -1.7, "y": 0.0, "rel": 0.94, "d": 1, "zone": "ground"}, 
	{"x": -2.65, "y": 0.0, "rel": 0.93, "d": 2, "zone": "ground"}, 
	{"x": -3.6, "y": 0.0, "rel": 0.92, "d": 3, "zone": "ground"}, 
	{"x": -4.45, "y": 0.02, "rel": 0.9, "d": 4, "zone": "ground"}, 
	{"x": -1.15, "y": 0.62, "rel": 0.9, "d": 5, "zone": "mid"}, 
	{"x": -2.15, "y": 0.72, "rel": 0.89, "d": 6, "zone": "mid"}, 
	{"x": -3.1, "y": 0.66, "rel": 0.88, "d": 7, "zone": "mid"}, 
	{"x": -4.05, "y": 0.56, "rel": 0.86, "d": 8, "zone": "mid"}, 
	{"x": -1.65, "y": 1.3, "rel": 0.86, "d": 9, "zone": "air"}, 
	{"x": -2.7, "y": 1.36, "rel": 0.85, "d": 10, "zone": "air"}, 
]
const DEPTH_STEP: = 0.7


const FACE_YAW: = PI * 0.5 - 0.42




const LEAD_YAW: = PI * 0.5 - 0.72
const LEAD_LEAN: = 0.22








const POOLS: = {
	"lead": [["spike", 0.0], ["spike", 0.01]], 
	"air": [["jump_rise", 0.2], ["jump_fall", 0.3], ["set_air", 0.35], 
		["block", 0.9], ["jump_fall", 0.5], ["block", 0.2]], 
	"mid": [["approach", 0.4], ["set", 0.5], ["jump_fall", 0.3], ["receive", 0.3], 
		["set_air", 0.4], ["approach", 0.3], ["strafe_fwd", 0.1]], 


	"ground": [["approach", 0.5], ["receive", 0.3], ["idle_alt", 0.5], 
		["serve", 0.3], ["approach", 0.3], ["receive", 0.5], ["strafe_fwd", 0.1], 
		["idle_alt", 0.3]], 
}


const KEY_POSES: = [["jump_rise", 0.45], ["jump_rise", 0.35], ["block", 0.9], 
	["set_air", 0.35], ["jump_fall", 0.3]]



const CLOTH_MOTION: = {
	"spike": [true, 0.5], "spike_L": [true, 0.5], "set_air": [true, 0.4], 
	"block": [true, 0.8], "block_hit": [true, 0.3], 
	"jump_rise": [true, 4.0], "jump_fall": [true, -2.5], 
}






const HAIR_MOTION: = {
	"spike": [2.0, 15.0], "spike_L": [55.0, -15.0], "set_air": [25.0, 0.0], 
	"block": [35.0, 0.0], "block_hit": [40.0, 10.0], 
	"jump_rise": [-12.0, 0.0], "jump_fall": [60.0, 6.0], 
	"approach": [25.0, 0.0], "receive": [15.0, 0.0], "strafe_fwd": [10.0, 30.0], 
}






const BALL_COUNT: = 7



const BALL_SKINS: = ["school", "nationals", "beach"]
const BALL_Z: = -6.5
const ARC_P0: = Vector2(-2.0, 2.35)
const ARC_P1: = Vector2(0.3, 4.4)
const ARC_P2: = Vector2(2.95, 3.95)
const ARC_END: = 0.12
const ARC_SPREAD: = 0.75
const ARC_DRIFT: = 0.018


const SHADOW_OFF: = Vector2(14.0, 16.0)
const SHADOW_BODY: = 0.42
const SHADOW_BALL: = 0.22


const OVERSCAN: = 48.0


const FADE_IN: = 0.7
const POP_START: = 0.45
const POP_STAGGER: = 0.1
const POP_TIME: = 0.5
const PROMPT_DELAY: = 2.3
const INPUT_LOCK: = 2.9
const EXIT_BLINKS: = 7
const EXIT_BLINK: = 0.055
const EXIT_FLASH: = 0.35
const EXIT_LUNGE: = 1.0
const EXIT_WIPE_AT: = 0.5
const EXIT_SPEED_FROM: = 0.12
const FLOAT_AMP: = 0.035








const INTRO_CUTS: = true
const CUTS_LEN: = 3.0

const CUT_LENS: = [0.5, 0.4, 0.45, 0.4, 0.45, 0.35, 0.45]
const CUT_NEAR: = 0.15
const CUT_FAR: = 0.24
const CUT_PAN: = 0.07



const CUT_KINDS: = {"push": 0.3, "pull": 0.25, "pan": 0.3, "orbit": 0.2}
const PAN_DIST: = 0.32
const PAN_SLIDE: = 0.55
const ORBIT_SWEEP: = 0.55
const HEAD_H: = 1.45
const LEAD_NEAR: = 0.13
const PULL_OUT: = 0.32
var _cuts: Array = []
var _cut_i: = -1
var _cut_t: = 0.0
var _pull_t: = -1.0
var _orbit_dir: = 1.0
var _cam_home: = Vector3.ZERO
var _cam_from: = Vector3.ZERO
var _cam_from_basis: = Basis.IDENTITY
const FLOAT_RATE: = 1.1

@onready var ui: CanvasLayer = $Ui

var _cam_bodies: Camera3D = null
var _cam_balls: Camera3D = null
var _vp_bodies: SubViewport = null
var _vp_balls: SubViewport = null
var _pcs: Array = []
var _homes: Array[Vector3] = []
var _float_phase: Array[float] = []
var _scales: Array[float] = []
var _frozen: Array = []




const SLOWMO_SPAN: = 0.3
var _slow: Array = []
var _slow_arm: = false
var _balls: Array = []
var _t: = 0.0
var _page: TitlePage = null
var _prompt: Label = null
var _logo: TextureRect = null
var _leaving: = false
var _landed: = false
var _white: ColorRect = null
const BUILD_PER_FRAME: = 2
var _intro_tweens: Array = []
var _skip_presses: = 0
var _settled: = false
var _shot_path: = ""
var _cast_dir: = ""
var _sheet_path: = ""
var _music: AudioStreamPlayer = null
var _music_loop: AudioStream = null
var _t_music_base: = 0.0
var _logo_at: = -1.0
var _prompt_at: = -1.0
var _logo_shown: = false
var _prompt_shown: = false

func _ready() -> void :


	var args: = Array(OS.get_cmdline_user_args())
	args.erase("--boot-run")
	args.erase("--onboard")

	var shot: = args.find("--title-shot")
	var sheet: = args.find("--title-sheet")
	var cast: = args.find("--title-cast")
	if cast >= 0 and cast + 1 < args.size():
		_cast_dir = String(args[cast + 1])
	if shot >= 0 and shot + 1 < args.size():
		_shot_path = String(args[shot + 1])
	elif sheet >= 0 and sheet + 1 < args.size():
		_sheet_path = String(args[sheet + 1])
	elif cast >= 0:
		pass
	elif not args.is_empty():

		GameConfig.goto_scene(MENU_SCENE)
		return



	UiStyle.dark = false
	# Warm the lobby (and its venue) while this screen waits for input: the
	# swap to the menu then happens from memory instead of paying the whole
	# scene load under the solid yellow wipe.
	GameConfig.preload_scene(MENU_SCENE)
	if Stage.STAGES.has(GameConfig.freeplay_stage):
		GameConfig.preload_scene(String(Stage.info(GameConfig.freeplay_stage).venue))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_views()
	var roll: = RandomNumberGenerator.new()
	roll.randomize()
	_page.roll(roll)
	if _sheet_path != "":
		_build_sheet()
		return
	_build_balls()

	_build_ui()
	_slow_arm = INTRO_CUTS



	await _build_parade()
	_slow_arm = false
	if _leaving or not is_inside_tree():
		return
	_t = 0.0
	_start_music()
	_enter()
	if is_instance_valid(_white):
		var ft: = create_tween()
		ft.tween_property(_white, "color:a", 0.0, FADE_IN)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		ft.tween_callback(_white.queue_free)



func _build_views() -> void :
	var half_tan: = tan(deg_to_rad(CAM_FOV * 0.5))
	var dist: = VIEW_H / (2.0 * half_tan)
	_page = TitlePage.new()
	_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(_page)


	_vp_balls = _make_view(LAYER_BALLS, dist, SHADOW_BALL)
	_vp_balls.msaa_3d = Viewport.MSAA_DISABLED
	_cam_balls = _vp_balls.get_child(0)
	_vp_bodies = _make_view(LAYER_BODIES, dist, SHADOW_BODY)
	_cam_bodies = _vp_bodies.get_child(0)
	_cam_home = Vector3(LOOK.x, LOOK.y, dist)
	Ink.apply(_cam_bodies)
	get_tree().root.size_changed.connect(_fit_views)
	_fit_views()



const SILHOUETTE_SHADER: = "\r\nshader_type canvas_item;\r\nuniform vec4 fill : source_color = vec4(0.0, 0.0, 0.0, 1.0);\r\nvoid fragment() {\r\n\tfloat a = texture(TEXTURE, UV).a;\r\n\tCOLOR = vec4(fill.rgb, a * fill.a);\r\n}"







func _make_view(mask: int, dist: float, shadow_alpha: float) -> SubViewport:
	var vp: = SubViewport.new()
	vp.transparent_bg = true
	vp.own_world_3d = false


	var low: = not GameConfig.reflections or GameConfig.render_scale < 1.0\
	or GameConfig.low_end_renderer()
	vp.msaa_3d = Viewport.MSAA_DISABLED if low else Viewport.MSAA_2X
	vp.scaling_3d_scale = minf(GameConfig.render_scale, 0.75)\
	if GameConfig.low_end_renderer() else GameConfig.render_scale
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var cam: = Camera3D.new()
	cam.fov = CAM_FOV
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.cull_mask = mask
	cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cam.position = Vector3(LOOK.x, LOOK.y, dist)
	vp.add_child(cam)
	cam.look_at(Vector3(LOOK.x, LOOK.y, 0.0))



	var shadow: = TextureRect.new()
	shadow.texture = vp.get_texture()
	var sh: = Shader.new()
	sh.code = SILHOUETTE_SHADER
	var sm: = ShaderMaterial.new()
	sm.shader = sh
	sm.set_shader_parameter("fill", Color(0.0, 0.0, 0.0, shadow_alpha))
	shadow.material = sm
	shadow.stretch_mode = TextureRect.STRETCH_SCALE
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	shadow.offset_left = SHADOW_OFF.x - OVERSCAN
	shadow.offset_right = SHADOW_OFF.x + OVERSCAN
	shadow.offset_top = SHADOW_OFF.y - OVERSCAN
	shadow.offset_bottom = SHADOW_OFF.y + OVERSCAN
	ui.add_child(shadow)
	var crisp: = TextureRect.new()
	crisp.texture = vp.get_texture()
	crisp.stretch_mode = TextureRect.STRETCH_SCALE
	crisp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crisp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crisp.set_anchors_preset(Control.PRESET_FULL_RECT)
	crisp.offset_left = - OVERSCAN
	crisp.offset_right = OVERSCAN
	crisp.offset_top = - OVERSCAN
	crisp.offset_bottom = OVERSCAN
	ui.add_child(crisp)
	return vp

func _fit_views() -> void :



	var px: = Vector2(get_tree().root.size)
	var scr: = get_viewport().get_visible_rect().size
	var k: = px.y / maxf(scr.y, 1.0)
	var bleed: = OVERSCAN * k
	var size: = Vector2i(px + Vector2(bleed, bleed) * 2.0)
	var fov: = rad_to_deg(2.0 * atan(tan(deg_to_rad(CAM_FOV * 0.5)) * (px.y + bleed * 2.0) / px.y))
	for vp in [_vp_balls, _vp_bodies]:
		if vp == null:
			continue
		vp.size = size
		(vp.get_child(0) as Camera3D).fov = fov



func _start_music() -> void :
	MusicManager.stop(0.2)
	_music = AudioStreamPlayer.new()
	_music.bus = "music"
	add_child(_music)
	var intro: = load(MUSIC_INTRO) as AudioStream
	_music_loop = load(MUSIC_LOOP) as AudioStream
	if intro == null:
		intro = _music_loop
	if intro == null:
		return
	_music.stream = intro
	_music.play()
	_t_music_base = _t
	_music.finished.connect(_on_music_finished)

func _on_music_finished() -> void :


	if _leaving or _music == null or _music_loop == null:
		return
	if _music.stream != _music_loop:
		_music.stream = _music_loop
	_music.play()



func _build_balls() -> void :
	var rng: = RandomNumberGenerator.new()
	rng.randomize()
	for i in BALL_COUNT:
		var skin: String = BALL_SKINS[rng.randi() % BALL_SKINS.size()]
		var n: = _make_ball(skin)



		var t: = (float(i) + 0.5) / float(BALL_COUNT) + rng.randf_range(-0.025, 0.025)
		var side: = (1.0 if i % 2 == 0 else -1.0) * rng.randf_range(0.35, 1.0) * ARC_SPREAD
		var z: = BALL_Z - rng.randf_range(0.0, 2.5)

		var size: = lerpf(0.78, 0.5, t) * rng.randf_range(0.85, 1.15)
		_balls.append({"node": n, "t": t, "side": side, "z": z, "size": size, 
			"phase": rng.randf() * TAU, 
			"spin": rng.randf_range(0.25, 0.6) * (1.0 if rng.randf() < 0.5 else -1.0), 
			"bob": rng.randf_range(0.06, 0.14)})
	_place_balls()




func _at_depth(p: Vector2, z: float) -> Vector3:
	var k: = _depth_k(z)
	var xy: = LOOK + (p - LOOK) * k
	return Vector3(xy.x, xy.y, z)


func _depth_k(z: float) -> float:
	var dist: = VIEW_H / (2.0 * tan(deg_to_rad(CAM_FOV * 0.5)))
	return (dist - z) / dist

func _arc(t: float) -> Vector2:
	var u: = 1.0 - t
	return ARC_P0 * (u * u) + ARC_P1 * (2.0 * u * t) + ARC_P2 * (t * t)


func _arc_normal(t: float) -> Vector2:
	var tan_v: = (ARC_P1 - ARC_P0) * (2.0 * (1.0 - t)) + (ARC_P2 - ARC_P1) * (2.0 * t)
	return Vector2( - tan_v.y, tan_v.x).normalized()

func _place_balls() -> void :
	for b in _balls:
		var n: Node3D = b["node"]
		var t: = fposmod(float(b["t"]) + _t * ARC_DRIFT, 1.0)
		var p: = _arc(t) + _arc_normal(t) * float(b["side"])
		p.y += sin(_t * 0.7 + float(b["phase"])) * float(b["bob"])
		var z: = float(b["z"])
		n.position = _at_depth(p, z)
		n.rotation.z = _t * float(b["spin"])
		n.rotation.x = sin(_t * 0.31 + float(b["phase"])) * 0.4

		var edge: = minf(t, 1.0 - t)
		var vis: = smoothstep(0.0, 1.0, clampf(edge / ARC_END, 0.0, 1.0))
		n.scale = Vector3.ONE * float(b["size"]) * _depth_k(z) * maxf(vis, 0.001)


func _make_ball(skin: String) -> Node3D:
	var b: Node3D = BALL_SCENE.instantiate()
	b.set("stage_ball", skin)
	add_child(b)
	b.set_physics_process(false)
	b.set_process(false)


	for c in b.get_children():
		if c is Node3D and String(c.name) != "Mesh":
			(c as Node3D).visible = false
		if c is GPUParticles3D:
			(c as GPUParticles3D).emitting = false
	var mesh: = b.get_node_or_null("Mesh")
	if mesh != null:
		_relayer(mesh, LAYER_BALLS)


		var hull: = mesh.get_node_or_null("Outline")
		if hull != null:
			hull.visible = false
	return b

func _relayer(n: Node, mask: int) -> void :
	if n is VisualInstance3D:
		(n as VisualInstance3D).layers = mask
	for c in n.get_children():
		_relayer(c, mask)







const PROFILE_FILL: = true

func _cast() -> Array:
	var out: Array = []
	var active: SavedProfile = ProfileStore.active()
	var lead_cfg: CharacterConfig = GameConfig.character
	if lead_cfg == null:
		lead_cfg = CharacterConfig.from_dict(active.character) if active != null\
		else CharacterConfig.new()
	out.append(lead_cfg)
	for p in ProfileStore.profiles:
		if not PROFILE_FILL or p == active or out.size() >= SLOTS.size():
			continue
		if p.character is Dictionary and not (p.character as Dictionary).is_empty():
			out.append(CharacterConfig.from_dict(p.character))
	var rng: = RandomNumberGenerator.new()
	rng.randomize()
	while out.size() < SLOTS.size():
		out.append(CharacterConfig.random(rng))
	return out

func _build_parade() -> void :
	var cast: = _cast()
	var rng: = RandomNumberGenerator.new()
	rng.randomize()
	var used: Array = []
	var prev_hook: = ""



	var all_gym: = rng.randf() < 0.4

	var force_away: = "--title-away" in OS.get_cmdline_user_args()
	for i in SLOTS.size():
		var s: Dictionary = SLOTS[i]
		var rel: = float(s["rel"])
		var cfg: CharacterConfig = cast[i]
		var look: = cfg
		var kit: Array
		if force_away:
			kit = cfg.kit_away
		elif all_gym:
			look = cfg.gym_look()
			kit = cfg.gym_kit()
		elif rng.randi() % 2 == 0:
			kit = cfg.kit_home
		else:
			kit = cfg.kit_away
		var pc: = _spawn(look, kit, rel)
		if s["zone"] == "lead":
			pc.face(LEAD_YAW)
			pc.rotation.z = LEAD_LEAN
		var pick: = _pose(String(s["zone"]), rng, used, prev_hook)
		_freeze(pc, String(pick[0]), float(pick[1]))
		_cloth(pc, String(pick[0]), s["zone"] == "lead")




		var has_runup: = not _slow.is_empty() and pc.rig != null
		has_runup = has_runup and _slow.back()["rig"] == pc.rig
		if not has_runup:
			_hair(pc, String(pick[0]), s["zone"] == "lead")
		prev_hook = String(pick[0])
		var z: = - float(s["d"]) * DEPTH_STEP
		var home: = _at_depth(Vector2(float(s["x"]), float(s["y"])), z)
		_homes.append(home)
		_float_phase.append(rng.randf() * TAU)
		_scales.append(rel * _depth_k(z))
		pc.position = home
		pc.scale = Vector3.ONE * 0.001
		_pcs.append(pc)

		if (i + 1) % BUILD_PER_FRAME == 0 and i + 1 < SLOTS.size():
			await get_tree().process_frame

func _spawn(cfg: CharacterConfig, kit: Array, rel: float) -> PresentationCharacter:
	var pc: = PresentationCharacter.new()
	add_child(pc)
	pc.scale = Vector3.ONE * rel
	pc.setup(cfg, kit)
	pc.face(FACE_YAW)
	return pc




func _pose(zone: String, rng: RandomNumberGenerator, used: Array, prev_hook: String) -> Array:
	var pool: Array = KEY_POSES if zone == "key" else POOLS.get(zone, POOLS["ground"])
	var fresh: Array = []
	var fresh_any: Array = []
	for p in pool:
		var key: = "%s %.2f" % [String(p[0]), float(p[1])]
		if key in used:
			continue
		fresh_any.append(p)
		if String(p[0]) != prev_hook:
			fresh.append(p)
	var from: Array = fresh if not fresh.is_empty() else\
	(fresh_any if not fresh_any.is_empty() else pool)
	var pick: Array = from[rng.randi() % from.size()]
	used.append("%s %.2f" % [String(pick[0]), float(pick[1])])
	return pick



func _freeze(pc: PresentationCharacter, hook: String, frame: float) -> String:
	if pc.rig == null:
		return ""


	var want: String = pc.rig.clip_name(hook)
	if want == "":
		want = hook
	var got: = pc.play_clip(want, true)
	if got == "":
		pc.play_clip("idle", true)
		hook = "idle"
	pc.rig.seek_normalized(frame)


	var ap: AnimationPlayer = pc.rig.get("_anim")
	if ap != null and ap.current_animation != "":
		ap.pause()
		var at: = ap.current_animation_position
		_frozen.append({"ap": ap, "at": at})
		if _slow_arm:
			var from: = maxf(at - SLOWMO_SPAN * ap.current_animation_length, 0.0)
			if from < at - 0.001:
				_slow.append({"ap": ap, "from": from, "to": at, "rig": pc.rig, "pos": from})
				ap.seek(from, true)
	return hook




func _cloth(pc: PresentationCharacter, hook: String, lead: bool) -> void :
	if pc.rig == null or not pc.rig.has_method("drive_cloth"):
		return
	var m: Array = CLOTH_MOTION.get(hook, [false, 0.0])
	var airborne: bool = m[0]
	var vel_y: float = m[1]
	var boost: = 1.0 if lead else 0.7
	for i in 4:
		pc.rig.drive_cloth(1.0, vel_y, not airborne, boost, false, false, 0.0)



func _hair(pc: PresentationCharacter, hook: String, lead: bool) -> void :
	if pc.rig == null or not pc.rig.has_method("tail_still"):
		return
	var m: Array = HAIR_MOTION.get(hook, [0.0, 0.0])
	var k: = 1.25 if lead else 1.0
	pc.rig.tail_still(float(m[0]) * k, float(m[1]) * k)

func _build_ui() -> void :
	var logo: = TextureRect.new()
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


	logo.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	logo.offset_left = -560.0 - 30.0
	logo.offset_right = -30.0
	logo.offset_top = 62.0
	logo.offset_bottom = 62.0 + 210.0
	logo.pivot_offset = logo.size * 0.5
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.modulate.a = 0.0
	ui.add_child(logo)
	_logo = logo




	var prompt: = Label.new()
	prompt.text = "press any button"
	UiStyle.style_label(prompt, "shout", Color.WHITE)
	prompt.add_theme_font_size_override("font_size", 38)
	prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt.add_theme_constant_override("outline_size", 12)

	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.set_anchors_preset(Control.PRESET_TOP_RIGHT)


	var lw: = logo.offset_right - logo.offset_left
	prompt.offset_left = logo.offset_left + (lw - 700.0) * 0.5
	prompt.offset_right = prompt.offset_left + 700.0
	prompt.offset_top = logo.offset_bottom + 8.0
	prompt.offset_bottom = prompt.offset_top + 64.0
	prompt.pivot_offset = prompt.size * 0.5
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt.visible = false
	prompt.scale = Vector2(0.001, 0.001)
	ui.add_child(prompt)
	_prompt = prompt

	var version: = Label.new()
	version.text = "v%s" % GameConfig.VERSION

	UiStyle.style_label(version, "small", Color.WHITE)
	version.add_theme_font_size_override("font_size", 15)
	version.add_theme_color_override("font_outline_color", Color.BLACK)
	version.add_theme_constant_override("outline_size", 6)
	version.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	version.size = Vector2(160, 24)
	version.position = Vector2(16.0, -34.0)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	version.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(version)



	_white = _white_sheet()

func _white_sheet() -> ColorRect:
	var white: = ColorRect.new()
	white.color = Color.WHITE
	white.set_anchors_preset(Control.PRESET_FULL_RECT)
	white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(white)
	return white



func _enter() -> void :

	var order: = range(_pcs.size())
	order.sort_custom( func(a, b): return _homes[a].x < _homes[b].x)
	var k: = 0
	for i in order:
		var pc: Node3D = _pcs[i]
		var rel: = float(SLOTS[i]["rel"])
		if INTRO_CUTS:
			pc.scale = Vector3.ONE * rel
			continue
		var tw: = create_tween()
		tw.tween_interval(POP_START + float(k) * POP_STAGGER)
		tw.tween_property(pc, "scale", Vector3.ONE * rel, POP_TIME)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		k += 1
	var logo_at: = CUTS_LEN + 0.12 if INTRO_CUTS else POP_START + 0.2
	var prompt_at: = CUTS_LEN + 0.75 if INTRO_CUTS else PROMPT_DELAY
	if INTRO_CUTS:
		_plan_cuts()
	_reveal(logo_at, prompt_at)
	if _cast_dir != "":
		_take_cast_shots()
	elif _shot_path != "":
		_take_shot()
	if "--title-skip3" in OS.get_cmdline_user_args():

		get_tree().create_timer(0.5).timeout.connect(_skip_to_pull_out)



func _reveal(logo_at: float, prompt_at: float) -> void :



	for tw in _intro_tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_intro_tweens.clear()
	_logo.modulate.a = 0.0
	_logo.scale = Vector2(0.6, 0.6)
	_logo_at = _t + logo_at
	_prompt_at = _t + prompt_at
	_logo_shown = false
	_prompt_shown = false

func _tick_reveal() -> void :
	if not _logo_shown and _logo_at >= 0.0 and _t >= _logo_at:
		_logo_shown = true
		var lt: = create_tween()
		lt.tween_property(_logo, "modulate:a", 1.0, 0.25)
		var ls: = create_tween()
		ls.tween_property(_logo, "scale", Vector2.ONE, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_intro_tweens.append_array([lt, ls])
	if not _prompt_shown and _prompt_at >= 0.0 and _t >= _prompt_at:
		_prompt_shown = true
		_prompt.visible = true
		var pt: = create_tween()
		pt.tween_property(_prompt, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pt.tween_callback( func(): _landed = true)
		_intro_tweens.append(pt)






func _skip_to_pull_out() -> void :
	if _leaving or _t >= CUTS_LEN:
		return
	_t = CUTS_LEN
	for sl in _slow:
		var ap: AnimationPlayer = sl["ap"]
		if is_instance_valid(ap):
			ap.seek(float(sl["to"]), true)
			ap.pause()
	_slow.clear()
	if INTRO_CUTS and _cut_i >= 0:
		_cut_i = -1
		_cam_from = _cam_bodies.position
		_cam_from_basis = _cam_bodies.basis
		_pull_t = 0.0
	_reveal(0.12, 0.75)
	if _music != null and _music.playing and _music.stream != _music_loop\
	and _music.get_playback_position() < CUTS_LEN:
		_music.seek(CUTS_LEN)
		_t_music_base = 0.0


func _pop_parade(start: float) -> void :
	var order: = range(_pcs.size())
	order.sort_custom( func(a, b): return _homes[a].x < _homes[b].x)
	var k: = 0
	for i in order:
		var pc: Node3D = _pcs[i]
		var rel: = float(SLOTS[i]["rel"])
		var tw: = create_tween()
		tw.tween_interval(start + float(k) * POP_STAGGER)
		tw.tween_property(pc, "scale", Vector3.ONE * rel, POP_TIME)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		k += 1



func _shuffle() -> void :
	_slow.clear()
	_slow_arm = false
	for pc in _pcs:
		(pc as Node).queue_free()
	for b in _balls:
		(b["node"] as Node).queue_free()
	_pcs.clear()
	_homes.clear()
	_float_phase.clear()
	_scales.clear()
	_settled = false
	_frozen.clear()
	_balls.clear()
	var rng: = RandomNumberGenerator.new()
	rng.randomize()
	_page.roll(rng)
	_build_balls()
	await _build_parade()
	_pop_parade(0.0)
	UiStyle.sfx("slide")

	_landed = false
	var st: = create_tween()
	st.tween_interval(POP_START + float(_pcs.size()) * POP_STAGGER + POP_TIME)
	st.tween_callback( func(): _landed = true)






func _plan_cuts() -> void :
	var rng: = RandomNumberGenerator.new()
	rng.randomize()
	var bodies: Array = []
	for i in _pcs.size():
		var zone: = String(SLOTS[i]["zone"])
		if zone == "lead" or zone == "mid" or zone == "air":
			continue
		bodies.append({"node": _pcs[i], "off": Vector3(0.0, HEAD_H * _scales[i], 0.0)})
	var picks: Array = []
	var n_bodies: = CUT_LENS.size() - 2
	while picks.size() < n_bodies and not bodies.is_empty():
		picks.append(bodies.pop_at(rng.randi() % bodies.size()))
	var mid_balls: Array = []
	for b in _balls:
		var t: = float(b["t"])
		if minf(t, 1.0 - t) > ARC_END * 2.0:
			mid_balls.append(b)
	if not mid_balls.is_empty():
		var b: Dictionary = mid_balls[rng.randi() % mid_balls.size()]
		picks.insert(mini(2, picks.size()), {"node": b["node"], "off": Vector3.ZERO, "ball": true})
	if not _pcs.is_empty():
		picks.append({"node": _pcs[0], "off": Vector3(0.0, HEAD_H * _scales[0], 0.0), "lead": true})
	_cuts = []
	var prev_kind: = ""
	for k in CUT_LENS.size():
		var sub: Dictionary = picks[mini(k, picks.size() - 1)]
		var last: = k == CUT_LENS.size() - 1
		var kind: = _roll_kind(rng, prev_kind, sub.has("ball"))
		prev_kind = kind
		var push: = kind != "pull"

		var orbit: = not last and kind == "orbit"
		var p0: = Vector3(rng.randf_range( - CUT_PAN, CUT_PAN), 
			rng.randf_range( - CUT_PAN * 0.5, CUT_PAN * 0.5), 0.0)
		var drift: = Vector3(rng.randf_range( - CUT_PAN, CUT_PAN), 
			rng.randf_range( - CUT_PAN * 0.4, CUT_PAN * 0.4), 0.0) * 0.5


		var a0: = rng.randf_range(-0.5, 0.5 - ORBIT_SWEEP)
		var a1: = a0 + ORBIT_SWEEP
		if orbit:
			if _orbit_dir < 0.0:
				var t: = a0
				a0 = a1
				a1 = t
			_orbit_dir = - _orbit_dir
		var d0: = CUT_FAR if push else CUT_NEAR
		var d1: = CUT_NEAR if push else CUT_FAR * 1.25
		if kind == "pan":


			d0 = PAN_DIST
			d1 = PAN_DIST
			var side: = 1.0 if rng.randf() < 0.5 else -1.0
			if rng.randf() < 0.3:
				p0 = Vector3(rng.randf_range(-0.15, 0.15), - PAN_SLIDE * 0.5 * side, 0.0)
				drift = Vector3(0.0, PAN_SLIDE * side, 0.0)
			else:
				p0 = Vector3( - PAN_SLIDE * 0.5 * side, rng.randf_range(-0.1, 0.1), 0.0)
				drift = Vector3(PAN_SLIDE * side, 0.0, 0.0)
		if last:

			d0 = LEAD_NEAR * 1.35
			d1 = LEAD_NEAR
			p0 = Vector3.ZERO
			drift = Vector3.ZERO
		_cuts.append({"node": sub["node"], "off": sub["off"], "len": float(CUT_LENS[k]), 
			"ball": sub.has("ball"), "orbit": orbit, "d0": d0, "d1": d1, 
			"p0": p0, "p1": p0 + drift, "a0": a0, "a1": a1})
	_cut_i = 0
	_cut_t = 0.0
	_pull_t = -1.0
	_orbit_dir = 1.0
	_drive_cuts(0.0)

func _roll_kind(rng: RandomNumberGenerator, prev: String, is_ball: bool) -> String:
	var total: = 0.0
	for k in CUT_KINDS:
		if k == prev or (is_ball and k == "orbit"):
			continue
		total += float(CUT_KINDS[k])
	var r: = rng.randf() * total
	for k in CUT_KINDS:
		if k == prev or (is_ball and k == "orbit"):
			continue
		r -= float(CUT_KINDS[k])
		if r <= 0.0:
			return k
	return "push"





func _set_cams(pos: Vector3, look_at: Vector3 = Vector3.INF, snap: = false) -> void :
	for c in [_cam_bodies, _cam_balls]:
		var cam: = c as Camera3D
		if cam == null:
			continue
		cam.position = pos
		if look_at == Vector3.INF:
			cam.basis = Basis.IDENTITY
		else:
			cam.look_at(look_at)
		if snap:
			cam.reset_physics_interpolation()

func _drive_cuts(delta: float) -> void :
	if _cut_i >= 0:
		var snap: = _cut_t == 0.0
		_cut_t += delta
		if _cut_t >= float(_cuts[_cut_i]["len"]):
			_cut_i += 1
			_cut_t = 0.0
			snap = true
		if _cut_i >= _cuts.size() or not is_instance_valid(_cuts[_cut_i]["node"]):

			_cut_i = -1
			_cam_from = _cam_bodies.position
			_cam_from_basis = _cam_bodies.basis
			_pull_t = 0.0
		else:
			var c: Dictionary = _cuts[_cut_i]
			var n: Node3D = c["node"]
			var u: = clampf(_cut_t / float(c["len"]), 0.0, 1.0)


			var at: Vector3 = n.position + (c["off"] as Vector3)
			if not bool(c.get("ball", false)) and n is PresentationCharacter and (n as PresentationCharacter).rig != null:
				at = (n as PresentationCharacter).rig.head_centre_global()
			var frac: = lerpf(float(c["d0"]), float(c["d1"]), u)
			if bool(c["orbit"]):
				var ang: = lerpf(float(c["a0"]), float(c["a1"]), u)
				var r: = frac * _cam_home.z
				var eye: = at + Vector3(sin(ang) * r, 0.06 * r, cos(ang) * r)
				_set_cams(eye, at, snap)
			else:
				var pan: Vector3 = (c["p0"] as Vector3).lerp(c["p1"], u)
				_set_cams(Vector3(at.x + pan.x, at.y + pan.y, at.z + frac * _cam_home.z), 
					Vector3.INF, snap)
			return
	if _pull_t >= 0.0:
		_pull_t += delta
		var u: = clampf(_pull_t / PULL_OUT, 0.0, 1.0)
		var e: = 1.0 - pow(1.0 - u, 3.0)
		for c in [_cam_bodies, _cam_balls]:
			var cam: = c as Camera3D
			if cam == null:
				continue
			cam.position = _cam_from.lerp(_cam_home, e)
			cam.basis = _cam_from_basis.slerp(Basis.IDENTITY, e)
		if u >= 1.0:
			_pull_t = -1.0

func _process(delta: float) -> void :
	_t += delta
	_page.tick(_t)
	_place_balls()
	if INTRO_CUTS and not _leaving:



		var dt: = delta
		if _music != null and _music.playing and _music.stream != _music_loop\
		and _t < CUTS_LEN + 1.0:
			var mt: = _music.get_playback_position() + AudioServer.get_time_since_last_mix()
			if mt > 0.0:
				dt = maxf(mt + _t_music_base - (_t - delta), 0.0)
		_t += dt - delta

		var left: = dt
		while left > 0.0:
			var step: = minf(left, 0.1)
			_drive_cuts(step)
			left -= step
		if not _slow.is_empty():



			var u: = clampf(_t / CUTS_LEN, 0.0, 1.0)
			var e: = lerpf(u, 1.0 - (1.0 - u) * (1.0 - u), 0.3)
			for sl in _slow:
				var ap: AnimationPlayer = sl["ap"]
				if not is_instance_valid(ap):
					continue
				var pos: = lerpf(float(sl["from"]), float(sl["to"]), e)
				ap.seek(pos, true)
				ap.pause()



				var rig: ModelRig = sl["rig"]
				var clip_dt: = pos - float(sl["pos"])
				sl["pos"] = pos
				if rig != null and is_instance_valid(rig) and clip_dt > 0.0:
					rig.tail_tick(clip_dt)
			if u >= 1.0:
				_slow.clear()
	_tick_reveal()


	if not _leaving:
		for i in _pcs.size():
			var pc: Node3D = _pcs[i]
			pc.position.y = _homes[i].y + sin(_t * FLOAT_RATE + _float_phase[i]) * FLOAT_AMP




			var rig = pc.get("rig")
			if rig != null and is_instance_valid(rig) and rig.has_method("tick_hair_gradient"):
				rig.tick_hair_gradient()
	for f in _frozen:
		var ap: AnimationPlayer = f["ap"]
		if ap.is_playing():
			ap.seek(float(f["at"]), true)
			ap.pause()


	if not _settled and _landed:
		_settled = true
		for pc in _pcs:
			(pc as Node).set_process(false)

	if _prompt != null and _landed and not _leaving:
		var k: = 0.5 + 0.5 * sin(_t * 3.2)
		_prompt.scale = Vector2.ONE * lerpf(0.97, 1.03, k)

func _unhandled_input(event: InputEvent) -> void :
	var lock: = CUTS_LEN + 0.9 if INTRO_CUTS else INPUT_LOCK
	if _leaving or _sheet_path != "":
		return
	if _t < lock:


		if _t < CUTS_LEN and _is_press(event)\
		and not (event is InputEventKey and (event as InputEventKey).keycode == KEY_R):
			_skip_presses += 1
			if _skip_presses >= 3:
				get_viewport().set_input_as_handled()
				_skip_to_pull_out()
		return
	var pressed: = false
	if event is InputEventKey:
		pressed = event.pressed and not event.echo



		if pressed and event.keycode == KEY_R:
			get_viewport().set_input_as_handled()
			if _landed:
				_shuffle()
			return
	elif event is InputEventJoypadButton:
		pressed = event.pressed
	elif event is InputEventMouseButton:
		pressed = event.pressed
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	_leave()

func _is_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventJoypadButton or event is InputEventMouseButton:
		return event.pressed
	return false

func _leave() -> void :
	_leaving = true

	if _music != null:
		_music.stop()
	var chime: = AudioStreamPlayer.new()
	chime.bus = "Master"
	chime.stream = load(PRESS_SFX)
	add_child(chime)
	chime.play()

	var flash: = _white_sheet()
	flash.color.a = EXIT_FLASH
	var fl: = create_tween()
	fl.tween_property(flash, "color:a", 0.0, 0.45)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)



	_prompt.scale = Vector2.ONE
	_frozen.clear()
	for i in _pcs.size():
		var pc: PresentationCharacter = _pcs[i]
		pc.set_process(true)
		var ap: AnimationPlayer = pc.rig.get("_anim") if pc.rig != null else null


		if ap != null and ap.assigned_animation != "":
			var anim: = ap.get_animation(ap.assigned_animation)
			if anim != null:
				anim.loop_mode = Animation.LOOP_NONE


			ap.speed_scale = EXIT_SPEED_FROM
			ap.play()
			var sp: = create_tween()
			sp.tween_property(ap, "speed_scale", 1.0, EXIT_LUNGE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	for i in _pcs.size():
		var pc: Node3D = _pcs[i]
		var tw: = create_tween()
		tw.tween_interval(float(i) * 0.03)

		var off: = 8.0 * _depth_k(_homes[i].z)
		tw.tween_property(pc, "position:x", _homes[i].x + off, EXIT_LUNGE)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var lg: = create_tween()
	lg.tween_property(_logo, "scale", Vector2(1.06, 1.06), EXIT_LUNGE * 0.6)\
	.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(EXIT_WIPE_AT).timeout


	UiWipe.wipe(get_tree(), func():
		UiStyle.dark = GameConfig.dark_theme
		GameConfig.goto_scene(MENU_SCENE))



func _take_shot() -> void :
	var args: = OS.get_cmdline_user_args()

	await get_tree().create_timer(0.8 if "--title-skip3" in args else 3.4).timeout
	_shoot(_shot_path, "--title-press" in args)




func _take_cast_shots() -> void :
	await get_tree().create_timer(3.4).timeout
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_cast_dir))
	var n: = _pcs.size()
	for i in n:
		for j in n:
			if is_instance_valid(_pcs[j]):
				(_pcs[j] as Node3D).visible = (j == i)



		var pc = _pcs[i]
		if pc != null and pc.rig != null and pc.rig.has_method("tail_still"):
			pc.rig.tail_still(0.0, 0.0, 0.9)
		for _f in 3:
			await RenderingServer.frame_post_draw
		var img: = _vp_bodies.get_texture().get_image()
		var used: = img.get_used_rect()
		if used.size.x >= 8 and used.size.y >= 8:
			var m: = 24
			var x: = maxi(0, used.position.x - m)
			var y: = maxi(0, used.position.y - m)
			var w: = mini(img.get_width() - x, used.size.x + m * 2)
			var h: = mini(img.get_height() - y, used.size.y + m * 2)
			img.get_region(Rect2i(x, y, w, h)).save_png("%s/body_%d.png" % [_cast_dir, i])
			print("cast body ", i, " -> ", used.size)
		else:
			print("cast body ", i, " BLANK")
	for j in n:
		if is_instance_valid(_pcs[j]):
			(_pcs[j] as Node3D).visible = true
	print("title cast shots done -> ", _cast_dir)
	get_tree().quit()



func _shoot(path: String, press: bool) -> void :
	var tree: = get_tree()
	var wait: = 0.01
	if press:
		_leave()
		wait = 2.5
		var args: = OS.get_cmdline_user_args()
		var at: = args.find("--title-press-at")
		if at >= 0 and at + 1 < args.size():
			wait = float(args[at + 1])
	var t: = Timer.new()
	t.one_shot = true
	t.wait_time = wait
	tree.root.add_child(t)
	t.timeout.connect( func():
		await RenderingServer.frame_post_draw


		var img: Image
		if "--title-bodies" in OS.get_cmdline_user_args() and _vp_bodies != null:
			img = _vp_bodies.get_texture().get_image()
		else:
			img = tree.root.get_viewport().get_texture().get_image()
		img.save_png(path)
		print("title shot -> ", path)
		tree.quit())
	t.start()



const SHEET_FRAMES: = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]

func _build_sheet() -> void :
	var hooks: Array = []

	var args: = OS.get_cmdline_user_args()
	var only: = args.find("--title-sheet-hooks")
	if only >= 0 and only + 1 < args.size():
		for h in String(args[only + 1]).split(","):
			hooks.append(h.strip_edges())
	else:
		for z in POOLS:
			for h in POOLS[z]:
				var name: String = String(h[0]) if h is Array else String(h)
				if not name in hooks:
					hooks.append(name)

	var frames: Array = SHEET_FRAMES
	var fr: = args.find("--title-sheet-frames")
	if fr >= 0 and fr + 1 < args.size():
		frames = []
		for f in String(args[fr + 1]).split(","):
			frames.append(float(f))
	var cfg: CharacterConfig = GameConfig.character
	if cfg == null:
		cfg = CharacterConfig.new()
	var kit: Array = cfg.kit_home
	var cols: = frames.size()
	var rows: = hooks.size()

	var cell: = Vector2(1.6, 2.3)
	var grid_h: = cell.y * float(rows)
	var half_tan: = tan(deg_to_rad(CAM_FOV * 0.5))
	var dist: = (grid_h + 0.6) / (2.0 * half_tan)
	var centre: = Vector3(0.0, grid_h * 0.5, dist)
	for cam in [_cam_bodies, _cam_balls]:
		cam.position = centre
		cam.look_at(Vector3(0.0, grid_h * 0.5, 0.0))
	var labels: = Control.new()
	labels.set_anchors_preset(Control.PRESET_FULL_RECT)
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(labels)
	for r in rows:
		for c in cols:
			var hook: String = hooks[r]
			var frame: float = float(frames[c])
			var pc: = _spawn(cfg, kit, 0.9)
			var got: = _freeze(pc, hook, frame)
			var wx: = (float(c) - float(cols - 1) * 0.5) * cell.x
			var wy: = grid_h - float(r + 1) * cell.y
			pc.position = Vector3(wx, wy, 0.0)
			var tag: = Label.new()
			tag.text = "%s %.2f" % [hook, frame]
			if got != hook:
				tag.text += " (%s)" % got
			UiStyle.style_label(tag, "small", UiStyle.INK)
			labels.add_child(tag)
			tag.set_meta("world", Vector3(wx, wy - 0.1, 0.0))
	await get_tree().process_frame

	var scr: = get_viewport().get_visible_rect().size
	var px: = Vector2(get_tree().root.size)
	for tag in labels.get_children():
		var w: Vector3 = tag.get_meta("world")
		var p: = _cam_bodies.unproject_position(w) / px * scr
		tag.position = p + Vector2(-60.0, 0.0)
		tag.size = Vector2(120, 20)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	await get_tree().create_timer(1.5).timeout
	_shoot(_sheet_path, false)




class TitlePage extends ColorRect:
	var dot_color: = UiStyle.PRIMARY



	const ALPHA: = 0.69
	const BAND: = 0.379
	const PITCH: = 0.018
	const R_MAX: = 0.375
	const R_GAMMA: = 1.34
	const FADE_TO: = 0.6

	var band: = NAN
	var pitch: = NAN
	var r_max: = NAN
	var r_gamma: = NAN
	var fade_to: = NAN
	var alpha: = NAN


	const PALETTE: = ["red", "green", "blue", "yellow", "grey"]
	const LIGHT_GREY: = Color("c9cfdb")
	const SHADER: = "\r\nshader_type canvas_item;\r\nuniform vec4 page : source_color;\r\nuniform vec4 dot : source_color;\r\nuniform float t = 0.0;\r\nuniform float step_px = 24.0;     // dot pitch in pixels\r\nuniform float band = 0.62;        // fraction of the height the dots climb\r\nuniform float r_max = 0.42;       // max disc radius, fraction of pitch\r\nuniform float r_gamma = 1.0;      // size ramp curve\r\nuniform float fade_to = 0.12;     // opacity ease-in span (fraction of band)\r\nuniform vec2 size_px = vec2(1920.0, 1080.0);\r\nvoid fragment() {\r\n\tvec2 px = UV * size_px;\r\n\tfloat top = size_px.y * (1.0 - band);\r\n\tfloat f = clamp((px.y - top) / (size_px.y - top), 0.0, 1.0);\r\n\t// a REAL halftone ramp: the dot size grows over the whole band (tiny\r\n\t// specks at the top, distinct discs at the foot), which is what makes the\r\n\t// long even gradient read. pitch is constant; only the disc grows.\r\n\t// opacity only eases the very top to kill aliasing specks.\r\n\tfloat base_r = r_max * pow(f, r_gamma);\r\n\tfloat fade = smoothstep(0.0, max(fade_to, 0.001), f);\r\n\t// staggered rows, crawling right; a slow size wave rolls across\r\n\tfloat row_h = step_px * 0.87;\r\n\tfloat row = floor((size_px.y - px.y) / row_h);\r\n\tfloat x = px.x - t * 9.0 - (mod(row, 2.0) * 0.5 * step_px);\r\n\tvec2 cell = vec2(mod(x, step_px), mod(size_px.y - px.y, row_h)) - vec2(step_px * 0.5, row_h * 0.5);\r\n\tfloat breathe = 1.0 + 0.16 * sin(t * 1.4 + px.x * 0.012 + px.y * 0.02);\r\n\tfloat r = base_r * step_px * breathe;\r\n\tfloat d = length(cell);\r\n\tfloat a = (1.0 - smoothstep(r - 1.2, r + 1.2, d)) * fade * dot.a;\r\n\tCOLOR = mix(page, vec4(dot.rgb, 1.0), a);\r\n}"































	var _mat: ShaderMaterial

	func _init() -> void :
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sh: = Shader.new()
		sh.code = SHADER
		_mat = ShaderMaterial.new()
		_mat.shader = sh
		material = _mat
		color = Color.WHITE
		_push()


	func tune(key: String, value: float) -> void :
		set(key, value)
		_push()

	func _v(override: float, base: float) -> float:
		return base if is_nan(override) else override

	func roll(rng: RandomNumberGenerator) -> void :
		match PALETTE[rng.randi() % PALETTE.size()]:
			"red":
				dot_color = UiStyle.RED
			"green":
				dot_color = UiStyle.SUCCESS
			"blue":
				dot_color = UiStyle.SECONDARY
			"grey":
				dot_color = LIGHT_GREY
			_:
				dot_color = UiStyle.PRIMARY
		_push()

	func tick(t: float) -> void :
		_mat.set_shader_parameter("t", t)
		_mat.set_shader_parameter("size_px", size)
		_mat.set_shader_parameter("step_px", size.y * _v(pitch, PITCH))

	func _push() -> void :
		_mat.set_shader_parameter("page", UiStyle.bg())
		_mat.set_shader_parameter("dot", Color(dot_color, _v(alpha, ALPHA)))
		_mat.set_shader_parameter("band", _v(band, BAND))
		_mat.set_shader_parameter("r_max", _v(r_max, R_MAX))
		_mat.set_shader_parameter("r_gamma", _v(r_gamma, R_GAMMA))
		_mat.set_shader_parameter("fade_to", _v(fade_to, FADE_TO))
