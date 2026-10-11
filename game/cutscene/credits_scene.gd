class_name CreditsScene
extends Node3D







signal finished

const EyeCatcherStageScript: = preload("res://game/cutscene/eyecatcher_stage.gd")

@export var scroll_speed: = 55.0
@export var fast_multiplier: = 5.0
@export var music_key: = "menu"


const HOLD_FROZEN: = 0.7
const FADE_TO_WHITE: = 0.32
const FADE_FROM_WHITE: = 0.42

var _stage: EyeCatcherStage
var _cast: CutsceneCast
var _rng: = RandomNumberGenerator.new()

var _layer: CanvasLayer
var _col: VBoxContainer
var _white: ColorRect
var _scroll: = 0.0
var _total: = 0.0
var _running: = true
var _finishing: = false

func _ready() -> void :
	_rng.randomize()
	_stage = EyeCatcherStageScript.new()
	add_child(_stage)
	_cast = CutsceneCast.new()
	_build_ui()
	if typeof(MusicManager) != TYPE_NIL and MusicManager.has_method("play"):
		MusicManager.play(music_key)
	await get_tree().process_frame
	_total = _col.get_combined_minimum_size().y
	var vh: = float(get_viewport().get_visible_rect().size.y)
	_scroll = - vh
	_run()



func _build_ui() -> void :
	var vp: = get_viewport().get_visible_rect().size
	_layer = CanvasLayer.new()
	_layer.layer = 10
	add_child(_layer)


	var scrim: = ColorRect.new()
	scrim.color = Color(1.0, 0.97, 0.9, 0.0)
	scrim.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	scrim.offset_left = - vp.x * 0.44
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sg: = Gradient.new()
	sg.set_color(0, Color(1, 1, 1, 0.0));sg.set_color(1, Color(1, 0.98, 0.92, 0.55))
	var sgt: = GradientTexture2D.new()
	sgt.gradient = sg;sgt.fill_from = Vector2(0, 0);sgt.fill_to = Vector2(1, 0)
	var scrim_tr: = TextureRect.new()
	scrim_tr.texture = sgt
	scrim_tr.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	scrim_tr.offset_left = - vp.x * 0.5
	scrim_tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrim_tr.stretch_mode = TextureRect.STRETCH_SCALE
	_layer.add_child(scrim_tr)


	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 6)
	_col.alignment = BoxContainer.ALIGNMENT_BEGIN
	_col.custom_minimum_size = Vector2(vp.x * 0.4, 0)
	_col.position = Vector2(vp.x * 0.56, 0)
	_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_populate(_col)
	_layer.add_child(_col)


	_white = ColorRect.new()
	_white.color = Color(1, 1, 1, 0.0)
	_white.set_anchors_preset(Control.PRESET_FULL_RECT)
	_white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_white)


	var back: = Button.new()
	back.text = "back"
	back.position = Vector2(vp.x - 110, 24)
	back.size = Vector2(86, 34)
	back.pressed.connect(_exit)
	_layer.add_child(back)

func _populate(col: VBoxContainer) -> void :
	for block in CreditsData.sections():
		if block.has("gap"):
			var sp: = Control.new()
			sp.custom_minimum_size = Vector2(0, float(block["gap"]))
			col.add_child(sp)
		if block.has("title"):
			col.add_child(_label(String(block["title"]), 40, Color(0.12, 0.13, 0.17), true))
		if block.has("line"):
			col.add_child(_label(String(block["line"]), 22, Color(0.2, 0.21, 0.26)))
		if block.has("header"):
			col.add_child(_label(String(block["header"]), 28, Color(0.86, 0.32, 0.12), true))
			var u: = Control.new();u.custom_minimum_size = Vector2(0, 4);col.add_child(u)
		if block.has("entries"):
			for e in block["entries"]:
				col.add_child(_label(String(e.get("name", "")), 22, Color(0.12, 0.13, 0.17), true))
				for w in e.get("works", []):
					col.add_child(_label(String(w), 16, Color(0.3, 0.31, 0.36)))
				var g: = Control.new();g.custom_minimum_size = Vector2(0, 14);col.add_child(g)

func _label(text: String, size: int, col: Color, bold: = false) -> Label:
	var l: = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)

	l.add_theme_color_override("font_outline_color", Color(1, 0.99, 0.94, 0.9))
	l.add_theme_constant_override("outline_size", 5 if bold else 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l



func _process(delta: float) -> void :
	if not _running:
		return
	var fast: = Input.is_action_pressed("ui_accept")
	_scroll += scroll_speed * (fast_multiplier if fast else 1.0) * delta
	_col.position.y = - _scroll
	var vh: = float(get_viewport().get_visible_rect().size.y)
	if _scroll > _total + vh and not _finishing:
		_finishing = true

func _input(event: InputEvent) -> void :
	if event.is_action_pressed("ui_cancel"):
		_exit()
		get_viewport().set_input_as_handled()



func _run() -> void :
	var first: = true
	while _running and not _finishing:
		var cast: = _cast.next()
		var tmpl: = EyeCatcherData.resolve(cast, _rng)
		var dur: = _stage.play(tmpl, tmpl["roles"])
		if not first:
			await _fade_white(1.0, 0.0, FADE_FROM_WHITE)
		first = false
		await _wait(dur)
		if not _running:
			return
		_stage.freeze()
		await _wait(HOLD_FROZEN)
		if _finishing or not _running:
			break
		await _fade_white(0.0, 1.0, FADE_TO_WHITE)
	if _running:
		_exit()

func _fade_white(from: float, to: float, time: float) -> void :
	if _white == null:
		return
	_white.color.a = from
	var t: = create_tween()
	t.tween_property(_white, "color:a", to, time).set_trans(Tween.TRANS_SINE)
	await t.finished

func _wait(seconds: float) -> void :

	await get_tree().create_timer(seconds, true, false, true).timeout



func _exit() -> void :
	if not _running:
		return
	_running = false
	if typeof(MusicManager) != TYPE_NIL and MusicManager.has_method("stop"):
		MusicManager.stop()
	var t: = create_tween()
	t.tween_property(_white, "color:a", 1.0, 0.5)
	await t.finished
	finished.emit()
