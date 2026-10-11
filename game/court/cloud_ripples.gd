extends Node3D













@export var floor_path: NodePath = ^"../MirrorFloor"
@export var stride: = 1.3
@export var step_strength: = 0.55
@export var land_strength: = 1.0
@export var ball_strength: = 0.8
@export var min_gap: = 0.2
@export var per_body: = 3

const MAX_RIPPLES: = 40

var _bodies_provider: = Callable()
var _ball_provider: = Callable()
var _mat: ShaderMaterial = null
var _rings: Array = []
var _last_pos: = {}
var _last_t: = {}
var _was_grounded: = {}
var _ball_low: = false

const BAKE_SHADER: = "res://game/court/cloud_sky_bake.gdshader"


const SKY_UNIFORMS: = ["top_color", "horizon_color", "cloud_color", "cloud_shade", 
	"cloud_cover", "cloud_scale", "cloud_softness"]

func _ready() -> void :
	var mi: = get_node_or_null(floor_path) as MeshInstance3D
	if mi != null:
		_mat = mi.material_override as ShaderMaterial



	if _mat != null:
		_bake_sky()

func _bake_sky() -> void :
	var bake: = load(BAKE_SHADER) as Shader
	if bake == null:
		return
	var vp: = SubViewport.new()
	vp.size = Vector2i(2048, 1024)
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var rect: = ColorRect.new()
	rect.size = Vector2(2048, 1024)
	var bmat: = ShaderMaterial.new()
	bmat.shader = bake


	for u in SKY_UNIFORMS:
		var v: Variant = _mat.get_shader_parameter(u)
		if v != null:
			bmat.set_shader_parameter(u, v)
	rect.material = bmat
	vp.add_child(rect)
	add_child(vp)

	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: = vp.get_texture().get_image()
	if img != null and _mat != null:
		var tex: = ImageTexture.create_from_image(img)
		_mat.set_shader_parameter("sky_tex", tex)
		_mat.set_shader_parameter("sky_baked", true)
	vp.queue_free()

func set_feeds(bodies_provider: Callable, ball_provider: Callable) -> void :
	_bodies_provider = bodies_provider
	_ball_provider = ball_provider


	var ball = ball_provider.call()
	if ball != null and is_instance_valid(ball) and ball.has_signal("bounced") and not ball.bounced.is_connected(_on_ball_bounced):
		ball.bounced.connect(_on_ball_bounced)

func _on_ball_bounced() -> void :
	var ball = _ball_provider.call() if _ball_provider.is_valid() else null
	if ball != null and is_instance_valid(ball) and ball.global_position.y < 0.6:
		stamp(ball.global_position, ball_strength, "ball")
		_ball_low = true




func wire_reflection(tex: Texture2D) -> void :
	if _mat == null:
		return
	_mat.set_shader_parameter("reflect_tex", tex)
	_mat.set_shader_parameter("reflect_on", true)

func stamp(pos: Vector3, strength: float, owner: Variant = null) -> void :



	if owner != null:




		var mine: Array = _rings.filter( func(r):
			var o: Variant = r["o"]
			if owner is Object:
				return o is Object and o == owner
			return not (o is Object) and o == owner)
		while mine.size() >= per_body:
			_rings.erase(mine.pop_front())
	_rings.append({"pos": Vector2(pos.x, pos.z), "t0": _now(), "s": strength, "o": owner})
	while _rings.size() > MAX_RIPPLES:
		_rings.pop_front()

func _now() -> float:
	return float(Time.get_ticks_msec()) * 0.001

func _process(_delta: float) -> void :
	if _mat == null:
		return
	var now: = _now()
	_poll_bodies(now)
	_poll_ball()


	var life: = float(_mat.get_shader_parameter("ripple_life"))
	var packed: = PackedVector4Array()
	var keep: Array = []
	for r in _rings:
		var age: float = now - float(r["t0"])
		if age > life:
			continue
		keep.append(r)
		packed.append(Vector4(r["pos"].x, r["pos"].y, age, float(r["s"])))
	_rings = keep
	_mat.set_shader_parameter("ripple_count", packed.size())
	while packed.size() < MAX_RIPPLES:
		packed.append(Vector4.ZERO)
	_mat.set_shader_parameter("ripples", packed)


	var feet: = PackedVector4Array()
	if _bodies_provider.is_valid():
		for b in _bodies_provider.call():
			if feet.size() >= 8:
				break
			if b != null and is_instance_valid(b):
				var fp: Vector3 = b.global_position
				feet.append(Vector4(fp.x, fp.y, fp.z, 1.0))
	while feet.size() < 8:
		feet.append(Vector4.ZERO)
	_mat.set_shader_parameter("feet", feet)

func _poll_bodies(now: float) -> void :
	if not _bodies_provider.is_valid():
		return
	var bodies: Array = _bodies_provider.call()
	for b in bodies:
		if b == null or not is_instance_valid(b) or not b.has_method("grounded"):
			continue
		var grounded: bool = b.grounded()
		var pos: Vector3 = b.global_position
		var was: bool = _was_grounded.get(b, true)
		_was_grounded[b] = grounded
		if not grounded:
			continue
		var last_t: float = _last_t.get(b, -10.0)
		if not was:

			if now - last_t >= min_gap:
				stamp(pos, land_strength, b)
				_last_pos[b] = pos
				_last_t[b] = now
			continue
		if not _last_pos.has(b):
			_last_pos[b] = pos
			continue
		var last: Vector3 = _last_pos[b]
		var moved: = Vector2(pos.x - last.x, pos.z - last.z).length()
		if moved >= stride and now - last_t >= min_gap:
			stamp(pos, step_strength, b)
			_last_pos[b] = pos
			_last_t[b] = now

func _poll_ball() -> void :
	if not _ball_provider.is_valid():
		return
	var ball = _ball_provider.call()
	if ball == null or not is_instance_valid(ball):
		return
	var low: bool = ball.global_position.y < 0.2
	if low and not _ball_low:
		stamp(ball.global_position, ball_strength, "ball")
	_ball_low = low
