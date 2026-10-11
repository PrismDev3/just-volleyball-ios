class_name FloorReflector
extends Node3D











const REFLECT_LAYER: = 3
const REFLECT_MASK: = 1 << (REFLECT_LAYER - 1)

var _cam: Camera3D
var _src: Camera3D
var _vp: SubViewport




var floor_mats: Array = []
var feet_provider: = Callable()




var scene_scoped: = false
var live: = true

func setup(source_cam: Camera3D) -> void :
	_src = source_cam

	source_cam.cull_mask &= ~ REFLECT_MASK
	_vp = SubViewport.new()
	_vp.size = _want_size()
	_vp.world_3d = get_world_3d()
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.msaa_3d = Viewport.MSAA_DISABLED
	add_child(_vp)
	_cam = Camera3D.new()




	_cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_cam.cull_mask = REFLECT_MASK
	_vp.add_child(_cam)
	_cam.current = true

func texture() -> Texture2D:
	return _vp.get_texture()





func _want_size() -> Vector2i:
	var full: = Vector2i(get_viewport().size)
	if GameConfig.reflection_half:
		return Vector2i(maxi(full.x / 2, 2), maxi(full.y / 2, 2))
	return full

var _was_on: = true

func _process(_delta: float) -> void :
	if _src == null or _cam == null:
		return


	# Reflection is an extra 3D camera pass. Skip it on the web Compatibility
	# renderer and on phones, where it costs a substantial amount of GPU time.
	var on: = live and GameConfig.reflections_live() and not GameConfig.low_end_renderer()
	if on != _was_on:
		_was_on = on
		if on:
			_cam.cull_mask = REFLECT_MASK
			_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		else:




			_cam.cull_mask = 0
			_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
			_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		for m in floor_mats:
			if m != null:
				(m as ShaderMaterial).set_shader_parameter("reflect_on", on)
	if not on:
		return
	if _vp.size != _want_size():
		_vp.size = _want_size()


	_cam.global_transform = _src.global_transform
	_cam.fov = _src.fov
	_cam.near = _src.near
	_cam.far = _src.far
	_cam.keep_aspect = _src.keep_aspect
	_cam.projection = _src.projection
	_update_feet()

func _update_feet() -> void :
	if floor_mats.is_empty() or not feet_provider.is_valid():
		return
	var players: Array = feet_provider.call()
	var feet: = PackedVector4Array()
	for p in players:
		if feet.size() >= 8:
			break
		if p == null:
			continue
		var pos: Vector3 = p.global_position
		feet.append(Vector4(pos.x, pos.y, pos.z, 1.0))
	while feet.size() < 8:
		feet.append(Vector4(0.0, 0.0, 0.0, 0.0))
	for m in floor_mats:
		if m != null:
			m.set_shader_parameter("feet", feet)
