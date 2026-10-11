class_name LoadingScreen
extends CanvasLayer















const DOT_SHADER: = preload("res://game/ui/style/halftone_dots.gdshader")



const CLIPS: = ["idle_alt", "idle", "run", "strafe_fwd", "run_back", 
	"strafe_left", "strafe_right"]


const DOT_BAND: = 0.204
const DOT_PITCH: = 0.017
const DOT_R_MAX: = 0.317
const DOT_R_GAMMA: = 1.52
const DOT_FADE_TO: = 0.532
const DOT_ALPHA: = 0.85


const ACCENTS: = ["yellow", "blue", "green", "red"]

const FADE_IN: = 0.35
const FADE_OUT: = 0.4
const BOB_AMP: = 22.0
const BOB_RATE: = 2.2
const SHADOW_OFF: = Vector2(16.0, 22.0)
const SHADOW_ALPHA: = 0.22


const FLOAT_X: = 190.0
const FLOAT_Y: = 70.0
const SPRING: = 7.0
const DAMP: = 3.2
const THROW_MAX: = 4000.0
const BOUNCE: = 0.55

var indeterminate: = false

var _page: ColorRect = null
var _vp: SubViewport = null
var _pc = null
var _body: TextureRect = null
var _shadow: TextureRect = null
var _bar: ProgressBar = null
var _root: Control = null
var _accent: = Color("ffd23f")
var _base: = Vector2.ZERO
var _pos: = Vector2.ZERO
var _vel: = Vector2.ZERO
var _held: = false
var _grab_mouse: = Vector2.ZERO
var _grab_pos: = Vector2.ZERO
var _settling: = false
var _t: = 0.0
var _bob_phase: = 0.0
var _progress: = 0.0
var _shown: = 0.0
var _fade: = 0.0

func _init() -> void :
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void :
	_roll_accent()
	_build()
	fade_in()



func _build() -> void :
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_page = ColorRect.new()
	_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat: = ShaderMaterial.new()
	mat.shader = DOT_SHADER

	mat.set_shader_parameter("page", UiStyle.NEUTRAL)
	mat.set_shader_parameter("dot", Color(_accent, DOT_ALPHA))
	mat.set_shader_parameter("band", DOT_BAND)
	mat.set_shader_parameter("r_max", DOT_R_MAX)
	mat.set_shader_parameter("r_gamma", DOT_R_GAMMA)
	mat.set_shader_parameter("fade_to", DOT_FADE_TO)
	_page.material = mat
	_page.color = Color.WHITE
	_root.add_child(_page)

	_build_character()

	var foot: = VBoxContainer.new()
	foot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_top = -120.0
	foot.offset_bottom = -40.0
	foot.add_theme_constant_override("separation", 12)
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(foot)

	var label: = Label.new()
	label.text = "loading"
	UiStyle.style_label(label, "shout", UiStyle.INK)
	label.add_theme_font_size_override("font_size", 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_child(label)

	var pad: = MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 120)
	pad.add_theme_constant_override("margin_right", 120)
	foot.add_child(pad)
	_bar = ProgressBar.new()
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 16)
	_style_bar(_bar)
	pad.add_child(_bar)

func _build_character() -> void :
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_2X
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.size = Vector2i(720, 820)
	add_child(_vp)

	var cam: = Camera3D.new()
	cam.fov = 30.0
	cam.position = Vector3(0.0, 1.0, 4.6)
	_vp.add_child(cam)
	cam.look_at(Vector3(0.0, 1.0, 0.0))
	Ink.apply(cam)

	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.WHITE
	e.ambient_light_energy = 1.4
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	_vp.add_child(env)

	var sun: = DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-45.0), deg_to_rad(35.0), 0.0)
	sun.light_energy = 0.5
	_vp.add_child(sun)

	var cfg: = _profile_config()
	var rng: = RandomNumberGenerator.new()
	rng.randomize()
	var look: = cfg
	var kit: Array
	match rng.randi() % 3:
		0:
			kit = cfg.kit_home
		1:
			kit = cfg.kit_away
		_:
			look = cfg.gym_look()
			kit = cfg.gym_kit()
	_pc = load("res://game/character/presentation_character.gd").new()
	_vp.add_child(_pc)
	_pc.setup(look, kit)


	var side: = 1.0 if rng.randf() < 0.5 else -1.0
	_pc.face(side * rng.randf_range(0.2, 0.7))
	_pc.play_clip(CLIPS[rng.randi() % CLIPS.size()], true)
	_bob_phase = rng.randf() * TAU

	var size: = Vector2(580, 660)

	_shadow = TextureRect.new()
	_shadow.texture = _vp.get_texture()
	_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_shadow.custom_minimum_size = size
	_shadow.size = size
	_shadow.modulate = Color(0, 0, 0, SHADOW_ALPHA)
	_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_shadow)

	_body = TextureRect.new()
	_body.texture = _vp.get_texture()
	_body.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_body.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_body.custom_minimum_size = size
	_body.size = size
	_body.mouse_filter = Control.MOUSE_FILTER_STOP
	_body.gui_input.connect(_on_body_input)
	_root.add_child(_body)

func _profile_config() -> CharacterConfig:
	if GameConfig.character != null:
		return GameConfig.character
	var p: SavedProfile = ProfileStore.active()
	if p != null and p.character is Dictionary and not (p.character as Dictionary).is_empty():
		return CharacterConfig.from_dict(p.character)
	return CharacterConfig.new()

func _roll_accent() -> void :
	match ACCENTS[randi() % ACCENTS.size()]:
		"blue":
			_accent = UiStyle.SECONDARY
		"green":
			_accent = UiStyle.SUCCESS
		"red":
			_accent = UiStyle.RED
		_:
			_accent = UiStyle.PRIMARY

func _style_bar(bar: ProgressBar) -> void :
	var bg: = StyleBoxFlat.new()
	bg.bg_color = Color(UiStyle.muted(), 0.28)
	bg.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("background", bg)
	var fill: = StyleBoxFlat.new()
	fill.bg_color = _accent
	fill.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("fill", fill)



func set_progress(v: float) -> void :
	indeterminate = false
	_progress = clampf(v, 0.0, 1.0)

func fade_in(dur: = FADE_IN) -> void :
	var t: = create_tween()
	t.tween_method(_set_fade, _fade, 1.0, dur).set_trans(Tween.TRANS_SINE)

func fade_out(done: = Callable(), dur: = FADE_OUT) -> void :
	_settling = true
	var t: = create_tween()
	t.tween_method(_set_fade, _fade, 0.0, dur).set_trans(Tween.TRANS_SINE)
	if done.is_valid():
		t.tween_callback(done)

func _set_fade(v: float) -> void :
	_fade = v
	_root.modulate.a = v



func _on_body_input(event: InputEvent) -> void :
	if event is InputEventMouseButton\
	and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT\
	and (event as InputEventMouseButton).pressed:
		_held = true
		_grab_mouse = _root.get_global_mouse_position()
		_grab_pos = _pos

func _input(event: InputEvent) -> void :
	if _held and event is InputEventMouseButton\
	and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT\
	and not (event as InputEventMouseButton).pressed:
		_held = false



func _process(delta: float) -> void :
	_t += delta
	if _page != null:
		var mat: ShaderMaterial = _page.material
		mat.set_shader_parameter("t", _t)
		mat.set_shader_parameter("size_px", _root.size)
		mat.set_shader_parameter("step_px", _root.size.y * DOT_PITCH)

	if _body == null:
		return
	_base = _root.size * 0.5 - _body.size * 0.5



	var target: = Vector2.ZERO
	if not _settling:
		target = Vector2(sin(_t * 0.5) * FLOAT_X + sin(_t * 0.23) * FLOAT_X * 0.4, 
			sin(_t * 0.41 + 1.0) * FLOAT_Y)

	if _held:
		var m: = _root.get_global_mouse_position()
		var np: = _grab_pos + (m - _grab_mouse)
		_vel = ((np - _pos) / maxf(delta, 0.001)).limit_length(THROW_MAX)
		_pos = np
	else:
		var acc: = (target - _pos) * SPRING - _vel * DAMP
		_vel += acc * delta
		_pos += _vel * delta


	var half: = _root.size * 0.5 - Vector2(120.0, 120.0)
	for ax in 2:
		if _pos[ax] < - half[ax]:
			_pos[ax] = - half[ax]
			_vel[ax] = absf(_vel[ax]) * BOUNCE
		elif _pos[ax] > half[ax]:
			_pos[ax] = half[ax]
			_vel[ax] = - absf(_vel[ax]) * BOUNCE

	var bob: = Vector2(0.0, sin(_t * BOB_RATE + _bob_phase) * BOB_AMP)
	_body.position = _base + _pos + bob
	_shadow.position = _body.position + SHADOW_OFF

	if _bar != null:
		if indeterminate:
			_bar.value = 0.5 + 0.4 * sin(_t * 1.6)
		else:
			_shown = lerpf(_shown, _progress, 1.0 - exp(-8.0 * delta))
			_bar.value = _shown
