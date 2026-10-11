class_name UiBackdrop
extends Control
















var style: = "balls"
var animated: = true



var dark_page: = Color(0, 0, 0, 0)
var _t: = 0.0


const _BALLS: = [
	[0.08, 0.16, 0.34, 0.05, 0.0], 
	[0.92, 0.8, 0.46, -0.04, 2.1], 
	[0.55, 1.04, 0.24, 0.06, 4.0], 
	[0.3, 0.62, 0.1, -0.08, 1.2], 
	[0.78, 0.12, 0.13, 0.07, 5.3], 
]

func _init(style_in: = "balls") -> void :
	style = style_in
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void :
	if animated:
		_t += delta
		queue_redraw()

func _draw() -> void :
	var page: = dark_page if (UiStyle.dark and dark_page.a > 0.0) else UiStyle.bg()
	draw_rect(Rect2(Vector2.ZERO, size), page)
	var line: = Color(UiStyle.text(), 0.055 if UiStyle.dark else 0.065)
	if style == "stripes":
		var band: = Color(UiStyle.text(), 0.03)
		var w: = size.x * 0.22
		var drift: = fmod(_t * 12.0, w * 2.0)
		var x: = - size.y - w * 2.0 + drift
		while x < size.x + size.y:
			draw_colored_polygon(PackedVector2Array([
				Vector2(x, size.y), Vector2(x + w, size.y), 
				Vector2(x + w + size.y, 0.0), Vector2(x + size.y, 0.0), 
			]), band)
			x += w * 2.0
		_ball(Vector2(size.x * 0.9, size.y * 0.16), size.y * 0.11, 
			_t * 0.05, line)
		_ball(Vector2(size.x * 0.08, size.y * 0.86), size.y * 0.08, 
			- _t * 0.06, line)
		return
	for b in _BALLS:
		var breathe: = sin(_t * 0.35 + float(b[4])) * size.y * 0.012
		_ball(Vector2(size.x * float(b[0]), size.y * float(b[1]) + breathe), 
			size.y * float(b[2]), _t * float(b[3]) + float(b[4]), line)





const _BALL_TEX_PATH: = "res://game/images/volleyball/Untitled.png"
static var _ball_tex: Texture2D = null
static var _ball_tex_tried: = false

static func _ball_texture() -> Texture2D:
	if _ball_tex_tried:
		return _ball_tex
	_ball_tex_tried = true
	if not ResourceLoader.exists(_BALL_TEX_PATH):
		return null
	var src: = load(_BALL_TEX_PATH) as Texture2D
	if src == null:
		return null
	var img: = src.get_image()
	if img == null:
		return null
	img = img.duplicate()


	if img.get_width() > 160:
		img.resize(160, 160, Image.INTERPOLATE_LANCZOS)
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var px: = img.get_pixel(x, y)
			var ink: = 1.0 - (px.r + px.g + px.b) / 3.0
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, ink * px.a))
	_ball_tex = ImageTexture.create_from_image(img)
	return _ball_tex


func _ball(center: Vector2, r: float, spin: float, color: Color) -> void :
	var tex: = _ball_texture()
	if tex == null:
		return
	draw_set_transform(center, spin, Vector2.ONE)
	draw_texture_rect(tex, Rect2( - r, - r, r * 2.0, r * 2.0), false, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
