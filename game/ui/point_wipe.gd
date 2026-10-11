class_name PointWipe
extends CanvasLayer













const COVER_TIME: = 0.8
const REVEAL_TIME: = 0.48
const WIPE_SHADER: = preload("res://game/fx/point_wipe.gdshader")




const VARIANTS: = {
	"nationals": {
		"ball": preload("res://game/images/gameballs/ball_nationals.png"), 
		"a": Color(0.1, 0.26, 0.74), "b": Color(1.0, 0.8, 0.12), 
		"line": Color(1, 1, 1), 
	}, 
	"school": {
		"ball": preload("res://game/images/gameballs/ball_school.png"), 
		"a": Color(0.82, 0.13, 0.16), "b": Color(0.11, 0.54, 0.3), 
		"line": Color(0.04, 0.04, 0.05), 
	}, 
	"outdoor": {
		"ball": preload("res://game/images/gameballs/ball_outdoor.png"), 
		"a": Color(0.15, 0.45, 0.95), "b": Color(1.0, 0.85, 0.22), 
		"line": Color(0.04, 0.04, 0.05), 
	}, 
}


static func variant_for_stage(stage_id: String) -> String:
	var path: = Stage.ball_model(stage_id)
	if path.contains("national"):
		return "nationals"
	if path.contains("jv"):
		return "school"
	return "outdoor"




static func ball_image_for(stage_id: String) -> Texture2D:
	var vk: = variant_for_stage(stage_id if stage_id != "" else GameConfig.stage)
	return VARIANTS.get(vk, VARIANTS["nationals"])["ball"]

var _mat: ShaderMaterial
var _rect: ColorRect
var _center: Control
var _ring: _DottedRing
var _ball: TextureRect
var _scroll: = 0.0
var _variant: = ""
var _done: = Callable()




static func play(tree: SceneTree, mid: = Callable(), hold: = 0.0, variant: = "", 
		done: = Callable()) -> CanvasLayer:
	var w: CanvasLayer = (load("res://game/ui/point_wipe.gd") as GDScript).new()
	w.set("_variant", variant)
	w.set("_done", done)
	w.layer = 120
	w.process_mode = Node.PROCESS_MODE_ALWAYS



	tree.root.add_child.call_deferred(w)
	w.call_deferred("_run", mid, hold)
	return w

func _build() -> void :
	var vp: = get_viewport().get_visible_rect().size
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vk: = _variant if VARIANTS.has(_variant) else variant_for_stage(GameConfig.stage)
	var v: Dictionary = VARIANTS.get(vk, VARIANTS["nationals"])
	_mat = ShaderMaterial.new()
	_mat.shader = WIPE_SHADER
	_mat.set_shader_parameter("cover", 0.0)
	_mat.set_shader_parameter("reveal", 0.0)
	_mat.set_shader_parameter("res", vp)
	_mat.set_shader_parameter("col_a", v.a)
	_mat.set_shader_parameter("col_b", v.b)
	var line: Color = v.get("line", Color.WHITE)
	_mat.set_shader_parameter("line_col", line)
	_rect.material = _mat
	add_child(_rect)

	_center = Control.new()
	_center.set_anchors_preset(Control.PRESET_CENTER)
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_center)
	_ring = _DottedRing.new()
	_ring.col = line
	_ring.position = Vector2.ZERO
	_center.add_child(_ring)
	_ball = TextureRect.new()
	_ball.texture = v.ball
	_ball.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ball.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ball.custom_minimum_size = Vector2(150, 150)
	_ball.size = Vector2(150, 150)
	_ball.pivot_offset = Vector2(75, 75)
	_ball.position = Vector2(-75, -75)
	_ball.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center.add_child(_ball)
	_center.scale = Vector2.ZERO

func _process(delta: float) -> void :
	_scroll += delta * 0.5
	if _mat != null:
		_mat.set_shader_parameter("scroll", _scroll)
	if _ring != null:
		_ring.rotation += delta * 1.4
		_ring.queue_redraw()
	if _ball != null:
		_ball.rotation += delta * 2.2

func _run(mid: Callable, hold: float) -> void :
	_build()

	var t: = create_tween().set_ignore_time_scale(true)
	t.tween_property(_mat, "shader_parameter/cover", 1.0, COVER_TIME)\
	.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	var bt: = create_tween().set_ignore_time_scale(true).set_parallel(true)
	bt.tween_property(_center, "scale", Vector2.ONE, COVER_TIME * 0.85)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished

	if mid.is_valid():
		mid.call()
	await get_tree().process_frame

	var mt: = create_tween().set_ignore_time_scale(true)
	mt.tween_property(_ring, "merge", 1.0, 0.42)\
	.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if hold > 0.0:
		await get_tree().create_timer(hold, true, false, true).timeout



	var ct: = create_tween().set_ignore_time_scale(true).set_parallel(true)
	ct.tween_property(_ball, "scale", Vector2.ONE * 2.4, REVEAL_TIME * 0.6)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ct.tween_property(_ball, "modulate", Color(3.0, 3.0, 3.0, 0.0), REVEAL_TIME * 0.6)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var gt: = create_tween().set_ignore_time_scale(true)
	gt.tween_property(_ring, "scale", Vector2.ONE * 0.05, REVEAL_TIME * 0.5)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	var ft: = create_tween().set_ignore_time_scale(true)
	ft.tween_property(_ring, "modulate:a", 0.0, REVEAL_TIME * 0.55)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var rt: = create_tween().set_ignore_time_scale(true)
	rt.tween_property(_mat, "shader_parameter/cover", 0.0, COVER_TIME * 0.9)\
	.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	await rt.finished
	if _done.is_valid():
		_done.call()
	queue_free()





class _DottedRing extends Control:
	const DOTS: = 20
	const RADIUS: = 108.0
	const DOT_R: = 6.0
	var col: = Color.WHITE
	var merge: = 0.0:
		set(value):
			merge = value
			queue_redraw()
	func _pos(a: float) -> Vector2:
		return Vector2(cos(a), sin(a)) * RADIUS
	func _draw() -> void :
		var step: = TAU / float(DOTS)


		var half: float = maxf(merge, 0.0) * step * 0.52
		for i in DOTS:
			var a: = step * float(i)
			if half < 0.004:
				draw_circle(_pos(a), DOT_R, col)
			else:

				draw_arc(Vector2.ZERO, RADIUS, a - half, a + half, 10, col, DOT_R * 2.0, true)

				draw_circle(_pos(a - half), DOT_R, col)
				draw_circle(_pos(a + half), DOT_R, col)
