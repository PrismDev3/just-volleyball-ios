class_name OffscreenBall
extends Control








const RADIUS: = 27.0
const BALL_R: = 19.0
const MARGIN: = 46.0
const ARROW: = 15.0
const EDGE: = Color(0.07, 0.07, 0.1)
const RING: = Color(0.97, 0.97, 0.94)
const BALL_YELLOW: = Color(0.98, 0.84, 0.2)
const BALL_BLUE: = Color(0.16, 0.38, 0.86)




const NEAR: = 3.0
const FAR: = 26.0


const SCALE_MAX: = 2.5
const SCALE_MIN: = 0.45






const IMG_FILL: = 1.22
var ball_tex: Texture2D = null

var _dir: = Vector2.DOWN
var _at: = Vector2.ZERO
var _want: = false
var _alpha: = 0.0
var _scale: = 1.0
var _scale_want: = 1.0

func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 90




func track(camera: Camera3D, world_pos: Vector3, active: bool, 
		dist: = -1.0) -> void :
	_scale_want = 1.0 if dist < 0.0 else lerpf(SCALE_MAX, SCALE_MIN, 
		clampf((dist - NEAR) / (FAR - NEAR), 0.0, 1.0))
	_want = false
	if not active or camera == null:
		return
	var rect: = camera.get_viewport().get_visible_rect()
	if not camera.is_position_behind(world_pos)\
	and rect.grow(-2.0).has_point(camera.unproject_position(world_pos)):
		return
	var rel: = world_pos - camera.global_position
	var d: = Vector2(rel.dot(camera.global_basis.x), 
		- rel.dot(camera.global_basis.y))
	if d.length() < 0.001:
		d = Vector2.DOWN
	_dir = d.normalized()


	var m: = MARGIN * maxf(_scale, 1.0)
	var half: = rect.size * 0.5 - Vector2(m, m)
	var k: = 1000000000.0
	if absf(_dir.x) > 0.001:
		k = minf(k, half.x / absf(_dir.x))
	if absf(_dir.y) > 0.001:
		k = minf(k, half.y / absf(_dir.y))
	_at = rect.size * 0.5 + _dir * k
	_want = true

func _process(delta: float) -> void :
	var target: = 1.0 if _want else 0.0
	_alpha = lerpf(_alpha, target, 1.0 - exp(-16.0 * delta))

	_scale = lerpf(_scale, _scale_want, 1.0 - exp(-10.0 * delta))
	visible = _alpha > 0.02
	if visible:
		queue_redraw()

func _tint(c: Color) -> Color:
	return Color(c.r, c.g, c.b, c.a * _alpha)

func _draw() -> void :
	var r: = RADIUS * _scale
	var br: = BALL_R * _scale
	var arrow: = ARROW * _scale

	var tip: = _at + _dir * (r + arrow)
	var b1: = _at + _dir.rotated(0.5) * (r + 1.0)
	var b2: = _at + _dir.rotated(-0.5) * (r + 1.0)
	draw_colored_polygon(PackedVector2Array([tip, b1, b2]), _tint(EDGE))
	var tip2: = _at + _dir * (r + arrow - 3.5 * _scale)
	var c1: = _at + _dir.rotated(0.42) * (r + 1.0)
	var c2: = _at + _dir.rotated(-0.42) * (r + 1.0)
	draw_colored_polygon(PackedVector2Array([tip2, c1, c2]), _tint(RING))

	draw_circle(_at, r, _tint(EDGE))
	draw_circle(_at, r - 2.5 * _scale, _tint(RING))
	if ball_tex != null:


		var side: = br * 2.0 * IMG_FILL


		var off: = Vector2(1.6, 2.2) * _scale
		draw_texture_rect(ball_tex, 
			Rect2(_at - Vector2(side, side) * 0.5 + off, Vector2(side, side)), 
			false, _tint(Color(0.0, 0.0, 0.0, 0.5)))
		draw_texture_rect(ball_tex, 
			Rect2(_at - Vector2(side, side) * 0.5, Vector2(side, side)), 
			false, _tint(Color.WHITE))
	else:


		draw_circle(_at, br, _tint(BALL_YELLOW))
		draw_line(_at + Vector2( - br * 0.86, 0.0), 
			_at + Vector2(br * 0.86, 0.0), _tint(BALL_BLUE), 8.5 * _scale)
		draw_arc(_at, br - 0.5, 0.0, TAU, 40, _tint(EDGE), 2.0 * _scale)
