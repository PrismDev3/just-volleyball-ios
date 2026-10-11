class_name BallTrail
extends GPUTrail3D









const LIFE: = 0.55




const WIDTH: = 0.38
const ALPHA: = 0.9

var color: = Color(0.3, 0.6, 1.0): set = _set_color

func _ready() -> void :
	super._ready()
	length_seconds = LIFE


	scale = Vector3.ONE * WIDTH
	billboard = true





	clip_overlaps = false
	curve = taper_curve()


	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_set_color(color)







const FADE_TIME: = 0.3
var _active: = true
var _fade: = 1.0

func set_active(on: bool) -> void :
	if on:
		if _active and _fade >= 1.0:
			return
		_active = true
		_fade = 1.0
		_apply_ramp(1.0)
		visible = true
		emitting = true
		restart()
		return
	if not _active:
		return

	_active = false
	emitting = false

func _process(delta: float) -> void :
	super._process(delta)
	if not _active and _fade > 0.0:
		_fade = maxf(_fade - delta / FADE_TIME, 0.0)
		_apply_ramp(_fade * _fade)
		if _fade <= 0.0:
			visible = false




	var parent_ball: = get_parent() as Node3D
	if parent_ball != null:
		global_position = parent_ball.get_global_transform_interpolated().origin


static func taper_curve() -> CurveTexture:





	var c: = Curve.new()
	c.add_point(Vector2(0.0, 0.66))
	c.add_point(Vector2(0.06, 1.0))
	c.add_point(Vector2(0.5, 0.68))
	c.add_point(Vector2(1.0, 0.0))
	var tex: = CurveTexture.new()
	tex.curve = c
	return tex

func _set_color(value: Color) -> void :
	color = value
	_apply_ramp(1.0 if _active else _fade)




func _apply_ramp(mul: float) -> void :
	var grad: = Gradient.new()
	grad.set_color(0, Color(color.r, color.g, color.b, ALPHA * mul))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var tex: = GradientTexture1D.new()
	tex.gradient = grad
	color_ramp = tex
