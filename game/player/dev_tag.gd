class_name DevTag
extends Node3D










const GOLD_DEEP: = Color(0.98, 0.7, 0.14)
const GOLD_PALE: = Color(1.0, 0.94, 0.6)
const GOLD_OUTLINE: = Color(0.34, 0.2, 0.02)
const GOLD_SPARK: = Color(1.0, 0.96, 0.7)
const SILVER_DEEP: = Color(0.7, 0.74, 0.82)
const SILVER_PALE: = Color(0.96, 0.98, 1.0)
const SILVER_OUTLINE: = Color(0.16, 0.19, 0.26)
const SILVER_SPARK: = Color(0.9, 0.96, 1.0)
const SPARKS: = 9
const SPARK_SIZE: = 0.19
const TEX_PX: = 48

var _label: Label3D
var _deep: = GOLD_DEEP
var _pale: = GOLD_PALE
var _outline: = GOLD_OUTLINE
var _spark: = GOLD_SPARK
var _sparks: Array[Sprite3D] = []
var _phase: Array[float] = []
var _speed: Array[float] = []
var _t: = 0.0
var _saved_mod: = Color.WHITE
var _saved_outline: = Color.BLACK
static var _star_tex: ImageTexture

func setup(label: Label3D, tier: int = DevBadge.Tier.GOLD) -> void :
	_label = label
	if tier == DevBadge.Tier.SILVER:
		_deep = SILVER_DEEP
		_pale = SILVER_PALE
		_outline = SILVER_OUTLINE
		_spark = SILVER_SPARK
	_saved_mod = label.modulate
	_saved_outline = label.outline_modulate
	_t = randf() * 20.0
	for i in SPARKS:
		var s: = Sprite3D.new()
		s.texture = _star()
		s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		s.no_depth_test = true
		s.shaded = false
		s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		s.pixel_size = SPARK_SIZE / float(TEX_PX)
		s.render_priority = label.render_priority + 1
		s.top_level = true
		add_child(s)
		_sparks.append(s)
		_phase.append(randf() * TAU)
		_speed.append(0.35 + randf() * 0.5)
	set_process(true)


func teardown() -> void :
	if is_instance_valid(_label):
		_label.modulate = _saved_mod
		_label.outline_modulate = _saved_outline


	if get_parent() != null:
		get_parent().remove_child(self)
	queue_free()

func _process(delta: float) -> void :
	if not is_instance_valid(_label):
		return
	_t += delta


	var breathe: = 0.5 + 0.5 * sin(_t * 2.4)
	var glint: = pow(maxf(0.0, sin(_t * 1.25)), 14.0)
	var shine: = _deep.lerp(_pale, breathe).lerp(Color.WHITE, glint * 0.85)
	shine.a = _saved_mod.a
	_label.modulate = shine
	_label.outline_modulate = _outline
	var shown: = _label.visible and _label.text != "" and is_visible_in_tree()
	var cam: = get_viewport().get_camera_3d() if is_inside_tree() else null
	if not shown or cam == null:
		for s in _sparks:
			s.visible = false
		return


	var half_w: float = maxf(_label.get_aabb().size.x * 0.5, 0.25)
	var right: = cam.global_basis.x
	var up: = cam.global_basis.y
	var centre: = _label.global_position
	for i in SPARKS:
		var s: = _sparks[i]
		var a: = _phase[i] + _t * _speed[i]
		var ox: = cos(a) * half_w * 1.2
		var oy: = sin(a * 1.7 + _phase[i]) * 0.11 + 0.03

		var tw: = pow(maxf(0.0, sin(_t * 3.0 + _phase[i] * 3.1)), 3.5)
		s.visible = tw > 0.02
		if not s.visible:
			continue
		s.global_position = centre + right * ox + up * oy
		var k: = 0.35 + 0.9 * tw
		s.scale = Vector3(k, k, k)
		s.modulate = Color(_spark, 0.35 + 0.65 * tw)


static func _star() -> ImageTexture:
	if _star_tex != null:
		return _star_tex
	var img: = Image.create(TEX_PX, TEX_PX, false, Image.FORMAT_RGBA8)
	var half: = TEX_PX * 0.5
	for y in TEX_PX:
		for x in TEX_PX:
			var px: = (x + 0.5 - half) / half
			var py: = (y + 0.5 - half) / half

			var edge: = pow(absf(px), 0.55) + pow(absf(py), 0.55)
			var star: = clampf((1.0 - edge) * 4.0, 0.0, 1.0)
			var glow: = exp( - (px * px + py * py) * 7.0)
			var a: = clampf(star + glow * 0.9, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	_star_tex = ImageTexture.create_from_image(img)
	return _star_tex
