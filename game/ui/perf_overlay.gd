extends CanvasLayer






const SAMPLE: = 0.25

var _label: Label
var _accum: = 0.0
var _frames: = 0
var _worst: = 0.0

func _ready() -> void :


	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.position = Vector2(10, 6)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_label.add_theme_constant_override("outline_size", 6)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	visible = false

func _process(delta: float) -> void :
	if visible != GameConfig.show_fps:
		visible = GameConfig.show_fps
		_accum = 0.0
		_frames = 0
		_worst = 0.0
	if not visible:
		return
	_accum += delta
	_frames += 1
	_worst = maxf(_worst, delta * 1000.0)
	if _accum < SAMPLE:
		return



	var fps: = float(_frames) / _accum
	_label.text = "%3.0f fps" % fps
	_label.add_theme_color_override("font_color", 
		Color(1, 1, 1) if fps >= 50.0
		else (Color(1.0, 0.9, 0.5) if fps >= 30.0 else Color(1.0, 0.55, 0.5)))
	_accum = 0.0
	_frames = 0
	_worst = 0.0
