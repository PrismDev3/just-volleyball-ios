class_name HandTrail
extends GPUTrail3D








var life: = 0.2
var width: = 0.09
var trail_color: = Color(1.0, 0.97, 0.88)
var alpha: = 0.7

func _ready() -> void :
	super._ready()
	length_seconds = life

	scale = Vector3.ONE * width
	billboard = true
	curve = BallTrail.taper_curve()


	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var grad: = Gradient.new()
	grad.set_color(0, Color(trail_color.r, trail_color.g, trail_color.b, alpha))
	grad.set_color(1, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
	var tex: = GradientTexture1D.new()
	tex.gradient = grad
	color_ramp = tex
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

func _process(delta: float) -> void :
	super._process(delta)
	var hand: = get_parent() as Node3D
	if hand != null:
		global_position = hand.global_position
