extends CanvasLayer







const LAYER: = 115
const KEEP_MS: = 160.0
const GHOSTS: = 7
const SPACING: = 11.0
const MIN_SPEED: = 700.0
const FULL_SPEED: = 2400.0
const HEAD_ALPHA: = 0.55



const GHOST_SCALE: = 0.55

var _canvas: Control
var _pts: Array = []
var _strength: = 0.0
var _last: = Vector2.INF

func _init() -> void :
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void :
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_ghosts)
	add_child(_canvas)

func _process(delta: float) -> void :
	var now: = float(Time.get_ticks_msec())
	var show: = Input.mouse_mode == Input.MOUSE_MODE_VISIBLE\
	and GameConfig._cursor_aiming != 1
	var p: = _canvas.get_global_mouse_position()
	var speed: = 0.0
	if show and _last != Vector2.INF and delta > 0.0:
		speed = p.distance_to(_last) / delta
	_last = p if show else Vector2.INF
	var want: = clampf((speed - MIN_SPEED) / (FULL_SPEED - MIN_SPEED), 0.0, 1.0)

	var k: = 1.0 - exp( - (22.0 if want > _strength else 9.0) * delta)
	_strength = lerpf(_strength, want, k)
	if show:
		_pts.append({"p": p, "t": now})
	while not _pts.is_empty() and now - float(_pts[0].t) > KEEP_MS:
		_pts.pop_front()
	_canvas.visible = _strength > 0.02 and _pts.size() >= 2
	if _canvas.visible:
		_canvas.queue_redraw()

func _draw_ghosts() -> void :
	var tex: Texture2D = GameConfig.cursor_texture()
	if tex == null or _pts.is_empty():
		return


	var px: = _canvas.get_global_transform_with_canvas().get_scale().x
	var inv: = GHOST_SCALE / maxf(px, 0.01)
	var hot: = GameConfig.cursor_hotspot() * inv
	var size: = Vector2.ONE * GameConfig.CURSOR_SIZE * inv


	var head: Vector2 = _pts[_pts.size() - 1].p
	var walked: = 0.0
	var next_at: = SPACING
	var placed: = 0
	var prev: = head
	for i in range(_pts.size() - 2, -1, -1):
		var q: Vector2 = _pts[i].p
		var seg: = prev.distance_to(q)
		while walked + seg >= next_at and placed < GHOSTS:
			var along: = (next_at - walked) / maxf(seg, 0.001)
			var at: = prev.lerp(q, along)
			var fade: = 1.0 - float(placed) / float(GHOSTS)
			var col: = Color(1, 1, 1, HEAD_ALPHA * fade * fade * _strength)
			_canvas.draw_texture_rect(tex, Rect2(at - hot, size), false, col)
			placed += 1
			next_at += SPACING
		walked += seg
		prev = q
		if placed >= GHOSTS:
			break
