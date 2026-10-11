class_name GrassWake
extends Node









const SIZE: = 512
var area: = 24.0
var center: = Vector2.ZERO


var bodies_provider: = Callable()



var decay: = 0.05
const FOOT_RADIUS: = 0.55
const RUN_RADIUS: = 0.8
const DIVE_RADIUS: = 1.4

var _vp: SubViewport
var _fader: Node2D
var _stamper: Node2D
var _brush: Texture2D
var _stamps: Array = []

func setup(court_area: float, world_center: = Vector2.ZERO) -> void :
	area = maxf(court_area, 1.0)
	center = world_center
	_brush = _make_brush()
	_vp = SubViewport.new()
	_vp.size = Vector2i(SIZE, SIZE)
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	_vp.msaa_2d = Viewport.MSAA_DISABLED
	add_child(_vp)


	_fader = Node2D.new()
	var fm: = CanvasItemMaterial.new()
	fm.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	_fader.material = fm
	_fader.draw.connect(_draw_fade)
	_vp.add_child(_fader)
	_stamper = Node2D.new()
	var sm: = CanvasItemMaterial.new()
	sm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_stamper.material = sm
	_stamper.draw.connect(_draw_stamps)
	_vp.add_child(_stamper)

func texture() -> Texture2D:
	return _vp.get_texture()

func wake_center_xz() -> Vector2:
	return center

func wake_area() -> float:
	return area

func _process(_dt: float) -> void :
	_stamps.clear()
	if bodies_provider.is_valid():
		for b in bodies_provider.call():
			if b == null or not is_instance_valid(b):
				continue
			if not (b.has_method("grounded") and b.grounded()):
				continue
			var radius: = FOOT_RADIUS
			if b.has_method("diving") and b.diving():
				radius = DIVE_RADIUS
			else:
				var v: Vector3 = b.velocity
				if Vector2(v.x, v.z).length() > 4.0:
					radius = RUN_RADIUS
			_add_stamp(Vector2(b.global_position.x, b.global_position.z), radius)
	if _fader != null:
		_fader.queue_redraw()
		_stamper.queue_redraw()

func _add_stamp(world_xz: Vector2, radius_m: float) -> void :
	var ppm: = float(SIZE) / area
	var p: = (world_xz - center) * ppm + Vector2(SIZE, SIZE) * 0.5
	if p.x < -60.0 or p.y < -60.0 or p.x > SIZE + 60 or p.y > SIZE + 60:
		return
	_stamps.append({"p": p, "r": radius_m * ppm})

func _draw_fade() -> void :

	_fader.draw_rect(Rect2(0, 0, SIZE, SIZE), Color(0, 0, 0, decay))

func _draw_stamps() -> void :
	for s in _stamps:
		var r: float = s["r"]
		var rect: = Rect2(s["p"] - Vector2(r, r), Vector2(r, r) * 2.0)

		_stamper.draw_texture_rect(_brush, rect, false, Color(1, 1, 1, 0.6))

func _make_brush() -> Texture2D:
	var g: = Gradient.new()
	g.set_offset(0, 0.0)
	g.set_color(0, Color(1, 1, 1, 1))
	g.add_point(0.6, Color(1, 1, 1, 0.6))
	g.set_offset(g.get_point_count() - 1, 1.0)
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	var t: = GradientTexture2D.new()
	t.gradient = g
	t.width = 96
	t.height = 96
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t
