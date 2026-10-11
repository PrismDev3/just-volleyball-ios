extends Control

















const NEXT_SCENE: = "res://game/ui/title.tscn"

const ONBOARD_SCENE: = "res://game/character/locker.tscn"

const SETTINGS_PANEL: = preload("res://game/ui/settings_panel.tscn")



@export var initial_black_hold: float = 0.5

@export var pixel_resolve_time: float = 1.2

@export var resolve_hold: float = 0.4

@export var burst_time: float = 0.8

@export var color_burst_time: float = 1.4


@export var flash_peak: float = 0.65
@export var flash_fade: float = 0.7

@export var wave_start_amp: float = 13.0
@export var wave_start_freq: float = 2.6
@export var wave_settle_time: float = 2.4

@export var post_burst_hold: float = 1.1

@export var screen_fade_out: float = 0.6

@export var post_fade_hold: float = 0.25



const RESOLVE_STEPS: Array[float] = [72.0, 48.0, 32.0, 20.0, 12.0, 7.0, 4.0, 2.0, 1.0]

const BURST_PIXEL_SIZE: float = 9.0

@onready var color_burst: ColorRect = $ColorBurst
@onready var text_viewport: SubViewport = $TextViewport
@onready var pixel_text: TextureRect = $PixelText
@onready var crisp_label: Label = $CrispLabel
@onready var burst_particles: GPUParticles2D = $BurstParticles
@onready var flash_overlay: ColorRect = $FlashOverlay
@onready var fade_out_overlay: ColorRect = $FadeOutOverlay
@onready var audio_player: AudioStreamPlayer = $AudioPlayer



var _wave_active: = false
var _wave_phase: = 0.0
var _wave_freq: = 0.0
var _wave_amp: = 0.0
var _shot_path: = ""
var _skipping: = false
var _left: = false
var _gating: = false



func _unhandled_input(event: InputEvent) -> void :
	if _skipping or _gating:
		return
	var pressed: = false
	if event is InputEventKey:
		pressed = event.pressed and not event.echo
	elif event is InputEventJoypadButton:
		pressed = event.pressed
	elif event is InputEventMouseButton:
		pressed = event.pressed
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	_skip()

func _skip() -> void :
	_skipping = true
	audio_player.stop()
	var t: = create_tween()
	t.tween_property(fade_out_overlay, "color:a", 1.0, 0.25)
	t.tween_callback(_go)





const WHITE_COVER: = preload("res://game/ui/boot/white_cover.gd")

func _go() -> void :
	if _left:
		return
	_left = true
	UiStyle.dark = GameConfig.dark_theme
	get_tree().root.add_child(WHITE_COVER.new())
	GameConfig.goto_scene(NEXT_SCENE)


func _beat(seconds: float) -> bool:
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout
	return not _skipping

func _process(delta: float) -> void :
	if not _wave_active:
		return
	_wave_phase += delta * _wave_freq * TAU
	var wm: ShaderMaterial = crisp_label.material
	wm.set_shader_parameter("phase", _wave_phase)
	wm.set_shader_parameter("amp", _wave_amp)
	if _wave_amp <= 0.01:
		wm.set_shader_parameter("amp", 0.0)
		_wave_active = false

func _ready() -> void :
	UiStyle.dark = false




	var gate: = LaunchGate.check()
	if gate["verdict"] != LaunchGate.VERDICT_OK:
		_gating = true
		LaunchGate.show_block(self, gate)
		return


	var raw_args: = Array(OS.get_cmdline_user_args())
	var args: = raw_args.duplicate()
	args.erase("--boot-run")



	var force_onboard: = args.has("--onboard")
	args.erase("--onboard")
	args.erase("--beta")
	var shot: = args.find("--boot-shot")
	if shot >= 0 and shot + 1 < args.size():
		_shot_path = String(args[shot + 1])
	elif not args.is_empty():
		GameConfig.goto_scene(NEXT_SCENE)
		return






	if (force_onboard or ProfileStore.seeded_fresh) and not GameConfig.onboarding_seen\
	and _shot_path == "" and not raw_args.has("--boot-run"):
		GameConfig.onboarding_seen = true
		GameConfig.onboarding_active = true

		GameConfig.preload_scene(ONBOARD_SCENE)
		await _first_run_settings_gate()
		UiStyle.dark = GameConfig.dark_theme
		GameConfig.goto_scene(ONBOARD_SCENE)
		return
	MusicManager.stop(0.0)

	# Warm the title scene during the intro animation (~6 s) so the white
	# cover never has to wait for a synchronous load.
	GameConfig.preload_scene(NEXT_SCENE)

	pixel_text.texture = text_viewport.get_texture()
	var mat: ShaderMaterial = pixel_text.material
	mat.set_shader_parameter("pixel_size", RESOLVE_STEPS[0])
	mat.set_shader_parameter("scatter", 0.0)
	mat.set_shader_parameter("tint_white", 1.0)
	mat.set_shader_parameter("alpha", 0.0)


	var burst_mat: ShaderMaterial = color_burst.material
	burst_mat.set_shader_parameter("progress", 0.0)
	burst_mat.set_shader_parameter("settle_color", UiStyle.bg())
	var scr: = get_viewport_rect().size
	burst_mat.set_shader_parameter("aspect", scr.x / maxf(scr.y, 1.0))
	crisp_label.modulate.a = 0.0
	flash_overlay.color.a = 0.0
	fade_out_overlay.color.a = 0.0

	burst_particles.position = scr * 0.5

	var credits: Array[String] = ["made by temkosoft", "port by james b (jexel)"]
	var sting_start: = -1
	for credit_i in range(credits.size()):
		var view_label: Label = text_viewport.get_node("ViewLabel")
		view_label.text = credits[credit_i]
		text_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw

		pixel_text.visible = true
		crisp_label.text = credits[credit_i]
		crisp_label.modulate.a = 0.0
		flash_overlay.color.a = 0.0
		burst_mat.set_shader_parameter("progress", 0.0)
		mat.set_shader_parameter("pixel_size", RESOLVE_STEPS[0])
		mat.set_shader_parameter("scatter", 0.0)
		mat.set_shader_parameter("tint_white", 1.0)
		mat.set_shader_parameter("alpha", 0.0)

		if credit_i == 0 and not await _beat(initial_black_hold):
			return

		mat.set_shader_parameter("alpha", 1.0)
		var cool: = create_tween()
		cool.tween_method( func(v: float): mat.set_shader_parameter("tint_white", v), 
			1.0, 0.0, pixel_resolve_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		var step_time: = pixel_resolve_time / float(RESOLVE_STEPS.size())
		for s in RESOLVE_STEPS:
			mat.set_shader_parameter("pixel_size", s)
			if not await _beat(step_time):
				return

		if not await _beat(resolve_hold):
			return

		if credit_i == 0:
			audio_player.play()
			sting_start = Time.get_ticks_msec()
		crisp_label.modulate.a = 1.0
		mat.set_shader_parameter("pixel_size", BURST_PIXEL_SIZE)
		burst_particles.restart()
		_wave_active = true
		_wave_freq = wave_start_freq
		_wave_amp = wave_start_amp
		var wave: = create_tween().set_parallel(true)
		wave.tween_property(self, "_wave_freq", 0.0, wave_settle_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		wave.tween_property(self, "_wave_amp", 0.0, wave_settle_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		flash_overlay.color.a = flash_peak
		var burst: = create_tween().set_parallel(true)
		burst.tween_property(flash_overlay, "color:a", 0.0, flash_fade).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		burst.tween_method( func(v: float): mat.set_shader_parameter("scatter", v), 
			0.0, 1.0, burst_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		burst.tween_method( func(v: float): burst_mat.set_shader_parameter("progress", v), 
			0.0, 1.0, color_burst_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		if _shot_path != "" and credit_i == credits.size() - 1:
			_shoot_after(0.35)
		await burst.finished
		await wave.finished
		if _skipping:
			return
		mat.set_shader_parameter("alpha", 0.0)
		pixel_text.visible = false

	var sting_elapsed: = float(Time.get_ticks_msec() - sting_start) / 1000.0
	var sting_len: float = audio_player.stream.get_length() if audio_player.stream else 0.0
	var rest: = maxf(post_burst_hold, sting_len - sting_elapsed + 0.15)
	if not await _beat(rest):
		return


	var fade_out: = create_tween()
	fade_out.tween_property(fade_out_overlay, "color:a", 1.0, screen_fade_out).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await fade_out.finished
	if _skipping:
		return
	await _beat(post_fade_hold)
	_go()

func _shoot_after(wait: float) -> void :
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shot_path)
	print("boot shot -> ", _shot_path)
	get_tree().quit()





func _first_run_settings_gate() -> void :
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE



	UiStyle.dark = GameConfig.dark_theme
	var overlay: = CanvasLayer.new()
	overlay.layer = 120
	add_child(overlay)
	var bg: = ColorRect.new()
	bg.color = UiStyle.bg()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)
	var done: = {"v": false}

	_gating = true
	_settings_prompt(overlay, bg, done)


	while not done["v"] and is_inside_tree():
		await get_tree().process_frame
	_gating = false
	if is_instance_valid(overlay):
		overlay.queue_free()

func _settings_prompt(overlay: CanvasLayer, bg: ColorRect, done: Dictionary) -> void :
	var center: = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var card: = PanelContainer.new()
	UiStyle.style_panel(card, UiStyle.card(), UiStyle.RADIUS_SOFT)
	center.add_child(card)
	var m: = MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 24)
	card.add_child(m)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size.x = 400
	m.add_child(v)
	var t: = Label.new()
	t.text = "before you play"
	UiStyle.style_label(t, "title")
	v.add_child(t)
	var d: = Label.new()
	d.text = "would you like to configure your settings first? (these may be changed at any time)"
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.style_label(d, "body")
	v.add_child(d)
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(row)
	var skip: = Button.new()
	skip.text = "don't need to!"
	UiStyle.style_button(skip, "secondary", 16)
	skip.pressed.connect( func(): done["v"] = true)
	row.add_child(skip)
	var go: = Button.new()
	go.text = "configure settings"
	UiStyle.style_button(go, "primary", 16)
	go.pressed.connect( func():
		center.queue_free()
		_settings_view(overlay, bg, done))
	row.add_child(go)

func _settings_view(overlay: CanvasLayer, bg: ColorRect, done: Dictionary) -> void :
	var root: = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(root)
	var m: = MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 56)
	m.add_theme_constant_override("margin_right", 56)
	m.add_theme_constant_override("margin_top", 40)
	m.add_theme_constant_override("margin_bottom", 40)
	root.add_child(m)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)
	var t: = Label.new()
	t.text = "settings"
	UiStyle.style_label(t, "shout")
	v.add_child(t)
	var panel: = SETTINGS_PANEL.instantiate() as SettingsPanel
	panel.set_scope(SettingsPanel.Scope.SYSTEM)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL




	panel.retheme_requested.connect( func(_dark: bool):
		bg.color = UiStyle.bg()
		root.queue_free()
		_settings_view.call_deferred(overlay, bg, done))
	v.add_child(panel)
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	var back: = Button.new()
	back.text = "back"
	UiStyle.style_button(back, "tertiary", 16)
	back.pressed.connect( func(): done["v"] = true)
	row.add_child(back)
	var reset: = Button.new()
	reset.text = "reset all"
	UiStyle.style_button(reset, "exit", 15)
	reset.pressed.connect( func(): panel.reset_all())
	row.add_child(reset)
