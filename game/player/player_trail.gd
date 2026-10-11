class_name PlayerTrail
extends GPUTrail3D




const LIFE: = 0.8


const WIDTH: = 0.17
const ALPHA: = 0.55
const RISE: = 0.08




var color: = Color(0.85, 0.95, 1.0): set = _set_color

func _ready() -> void :
	super._ready()
	length_seconds = LIFE

	scale = Vector3.ONE * WIDTH
	billboard = true

	curve = BallTrail.taper_curve()


	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_set_color(color)
	visible = false
	emitting = false
	set_process(false)





var _active: = false

func set_active(on: bool) -> void :
	if on == _active:
		return
	_active = on
	visible = on
	emitting = on


	set_process(on)
	if on:


		restart()
		var body: = get_parent() as CharacterBody3D
		_launch_vy = maxf(body.velocity.y, 1.0) if body != null else 1.0

var _launch_vy: = 1.0

func _process(delta: float) -> void :
	super._process(delta)
	var body: = get_parent() as Node3D
	if body != null:
		global_position = body.global_position + Vector3(0.0, RISE, 0.0)



		var vy: = 0.0
		if body is CharacterBody3D:
			vy = (body as CharacterBody3D).velocity.y




		var rise: = clampf(vy / maxf(_launch_vy, 1.0), 0.0, 1.0)
		var w: = rise * rise * (3.0 - 2.0 * rise)
		scale = Vector3.ONE * WIDTH * (1.0 + _boost * 1.0) * maxf(w, 0.01)




func set_boost(t: float) -> void :
	_boost = t
	_set_color(color)

var _boost: = 0.0

func _set_color(value: Color) -> void :
	color = value

	var head: = value.lerp(Color(1.0, 1.0, 1.0), _boost * 0.7)
	var grad: = Gradient.new()
	grad.set_color(0, Color(head.r, head.g, head.b, ALPHA + _boost * 0.3))
	grad.set_color(1, Color(head.r, head.g, head.b, 0.0))
	var tex: = GradientTexture1D.new()
	tex.gradient = grad
	color_ramp = tex
