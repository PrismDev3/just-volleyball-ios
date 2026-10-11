class_name FaceDraw
extends Control






const TEX_W: = 512.0
const TEX_H: = 256.0


var face_u: = 0.5
var face_v: = 0.52

var config: CharacterConfig

func _ready() -> void :
	custom_minimum_size = Vector2(TEX_W, TEX_H)

func refresh() -> void :
	queue_redraw()

func _face_pos(x: float, y: float) -> Vector2:

	return Vector2(TEX_W * (face_u + x * 0.115), TEX_H * (face_v + y * 0.24))

func _draw() -> void :
	if config == null:
		return
	var ink: = Color(0.1, 0.09, 0.1)

	var eye_dx: = lerpf(0.28, 0.62, config.eye_spacing)
	var eye_y: = lerpf(0.15, -0.35, config.eye_height)
	var eye_x: = lerpf(-0.45, 0.45, config.eye_x)
	var eye_w: = lerpf(6.0, 15.0, config.eye_width)
	var eye_h: = lerpf(6.0, 15.0, config.eye_size_y)
	for side in [-1.0, 1.0]:
		var p: = _face_pos(side * eye_dx + eye_x, eye_y)
		match config.eye_shape:
			0:
				_ellipse(p, Vector2(eye_w * 0.62, eye_h), ink)
				_ellipse(p + Vector2(0, eye_h * 0.1), Vector2(eye_w * 0.4, eye_h * 0.62), 
					config.eye_color)
				_ellipse(p - Vector2(eye_w * 0.12, eye_h * 0.3), 
					Vector2(eye_w * 0.16, eye_h * 0.2), Color.WHITE)
			1:
				_ellipse(p, Vector2(eye_w * 0.85, eye_h * 0.85), ink)
				_ellipse(p - Vector2(eye_w * 0.2, eye_h * 0.25), 
					Vector2(eye_w * 0.22, eye_h * 0.22), Color.WHITE)
			2:
				draw_set_transform(p, 0.0, Vector2(eye_w / 8.0, eye_h / 8.0))
				draw_circle_arc_poly(Vector2.ZERO, 8.0, PI, TAU, ink)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			3:
				draw_set_transform(p, 0.0, Vector2(eye_w / 10.0, eye_h / 10.0))
				draw_arc(Vector2.ZERO, 8.0, PI + 0.35, TAU - 0.35, 12, 
					ink, 2.8, true)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var brow_y: = eye_y - lerpf(0.55, 0.95, config.brow_height) * 0.6 - 0.25
	var brow_x: = lerpf(-0.45, 0.45, config.brow_x)
	var brow_gap: = lerpf(-0.14, 0.18, config.brow_spacing)
	var brow_scale: = Vector2(lerpf(0.65, 1.35, config.brow_width), 
		lerpf(0.65, 1.35, config.brow_size_y))
	var brow_c: = config.hair_color().darkened(0.2)
	for side in [-1.0, 1.0]:
		var p: = _face_pos(side * (eye_dx + 0.04 + brow_gap) + brow_x, brow_y)
		match config.brow_shape:
			0:
				draw_set_transform(p, side * 0.08, brow_scale)
				draw_rect(Rect2(-7.0, -2.2, 14.0, 4.4), brow_c)
			1:
				draw_set_transform(p, side * 0.35, brow_scale)
				draw_rect(Rect2(-7.0, -2.2, 14.0, 4.4), brow_c)
			2:
				draw_set_transform(p, 0.0, brow_scale)
				draw_arc(Vector2.ZERO, 7.5, PI + 0.5, TAU - 0.5, 10, 
					brow_c, 4.5, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var nose_y: = lerpf(0.35, -0.05, config.nose_height)
	var nose_x: = lerpf(-0.45, 0.45, config.nose_x)
	var nose_w: = lerpf(2.5, 8.0, config.nose_width)
	var nose_h: = lerpf(2.5, 8.0, config.nose_size_y)
	var nose_p: = _face_pos(nose_x, nose_y)
	var nose_scale_x: = nose_w / 5.0 * (-1.0 if config.nose_flip else 1.0)
	draw_set_transform(nose_p, 0.0, Vector2(nose_scale_x, nose_h / 5.0))
	match config.nose_shape:
		0:
			draw_arc(Vector2.ZERO, 5.0, 0.35, PI - 0.35, 10, ink, 2.6, true)
		1:
			draw_circle(Vector2.ZERO, 4.0, config.skin_tone().darkened(0.22))
		2:
			draw_arc(Vector2.ZERO, 5.0, - PI * 0.5, PI * 0.55, 10, ink, 2.6, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var mouth_y: = lerpf(0.85, 0.35, 1.0 - config.mouth_height)
	var mouth_x: = lerpf(-0.45, 0.45, config.mouth_x)
	var mouth_w: = lerpf(6.0, 16.0, config.mouth_width)
	var mouth_h: = lerpf(6.0, 16.0, config.mouth_size_y)
	var mouth_s: = 10.0
	var mouth_p: = _face_pos(mouth_x, mouth_y)
	draw_set_transform(mouth_p, (config.mouth_rot - 0.5) * PI, 
		Vector2(mouth_w / mouth_s, 
		mouth_h / mouth_s))
	match config.mouth_shape:
		0:
			draw_arc(Vector2(0, - mouth_s * 0.35), mouth_s, 0.45, 
				PI - 0.45, 14, ink, 3.2, true)
		1:
			draw_circle_arc_poly(Vector2.ZERO, mouth_s, 0.0, PI, Color(0.55, 0.15, 0.15))
			draw_circle_arc_poly(Vector2(0, 1.0), mouth_s * 0.55, 0.0, PI, 
				Color(0.9, 0.5, 0.5))
		2:
			draw_rect(Rect2( - mouth_s * 0.7, -1.6, 
				mouth_s * 1.4, 3.2), ink)
		3:
			draw_arc(Vector2(0, mouth_s * 0.5), mouth_s, PI + 0.45, 
				TAU - 0.45, 14, ink, 3.2, true)
		4:
			draw_circle(Vector2.ZERO, mouth_s * 0.5, ink)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if config.blush:
		var blush_c: = Color(config.blush_color, 
			lerpf(0.08, 0.65, config.blush_opacity))
		for side in [-1.0, 1.0]:
			_ellipse(_face_pos(side * (eye_dx + 0.28), eye_y + 0.55), 
				Vector2(7.0, 4.5), blush_c)

func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void :
	draw_set_transform(center, 0.0, Vector2(radii.x / 10.0, radii.y / 10.0))
	draw_circle(Vector2.ZERO, 10.0, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_circle_arc_poly(center: Vector2, radius: float, from: float, 
		to: float, color: Color) -> void :
	var pts: = PackedVector2Array()
	pts.append(center)
	for i in 17:
		var a: = from + (to - from) * float(i) / 16.0
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_polygon(pts, PackedColorArray([color]))
