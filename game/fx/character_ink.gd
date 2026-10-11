class_name CharacterInk
extends CompositorEffect












const SHADER: = "res://game/fx/character_ink.glsl"



var thickness: = 8.0
var ink_color: = Color(0.0, 0.0, 0.0)
var strength: = 1.0

var mask_texture: Texture2D = null
var acc_mask_texture: Texture2D = null

var _rd: RenderingDevice
var _shader: = RID()
var _pipeline: = RID()
var _sampler: = RID()
var _sampler_hard: = RID()

func _init() -> void :
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_OPAQUE
	RenderingServer.call_on_render_thread(_build)

func _build() -> void :
	_rd = RenderingServer.get_rendering_device()
	if _rd == null:
		return
	var src: RDShaderFile = load(SHADER)
	if src == null:
		push_warning("character ink shader missing")
		return
	_shader = _rd.shader_create_from_spirv(src.get_spirv())
	if not _shader.is_valid():
		return
	_pipeline = _rd.compute_pipeline_create(_shader)
	var ss: = RDSamplerState.new()


	ss.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	ss.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	ss.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	ss.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	_sampler = _rd.sampler_create(ss)


	var hs: = RDSamplerState.new()
	hs.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	hs.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	hs.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	hs.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	_sampler_hard = _rd.sampler_create(hs)

func _notification(what: int) -> void :
	if what != NOTIFICATION_PREDELETE or _rd == null:
		return
	for rid in [_pipeline, _shader, _sampler, _sampler_hard]:
		if rid.is_valid():
			_rd.free_rid(rid)

func _render_callback(callback: int, render_data: RenderData) -> void :
	if _rd == null or not _pipeline.is_valid() or mask_texture == null:
		return
	if callback != EFFECT_CALLBACK_TYPE_POST_OPAQUE:
		return
	var buffers: = render_data.get_render_scene_buffers() as RenderSceneBuffersRD
	var scene: = render_data.get_render_scene_data() as RenderSceneDataRD
	if buffers == null or scene == null:
		return
	var size: = buffers.get_internal_size()
	if size.x == 0 or size.y == 0:
		return
	var mask_rd: = RenderingServer.texture_get_rd_texture(mask_texture.get_rid())
	if not mask_rd.is_valid():
		return


	var acc_rd: = mask_rd
	if acc_mask_texture != null:
		var a: = RenderingServer.texture_get_rd_texture(acc_mask_texture.get_rid())
		if a.is_valid():
			acc_rd = a

	var groups_x: = int((size.x - 1) / 8 + 1)
	var groups_y: = int((size.y - 1) / 8 + 1)

	for view in buffers.get_view_count():
		var color: = buffers.get_color_layer(view)
		if not color.is_valid():
			continue
		var set: = UniformSetCacheRD.get_cache(_shader, 0, [
			_image_uniform(color, 0), 
			_sampler_uniform(mask_rd, 3), 
			_sampler_uniform(acc_rd, 4, _sampler_hard), 
		])
		var push: = PackedFloat32Array([
			float(size.x), float(size.y), thickness, 0.0, 
			ink_color.r, ink_color.g, ink_color.b, strength, 
		]).to_byte_array()

		var list: = _rd.compute_list_begin()
		_rd.compute_list_bind_compute_pipeline(list, _pipeline)
		_rd.compute_list_bind_uniform_set(list, set, 0)
		_rd.compute_list_set_push_constant(list, push, push.size())
		_rd.compute_list_dispatch(list, groups_x, groups_y, 1)
		_rd.compute_list_end()

func _image_uniform(tex: RID, binding: int) -> RDUniform:
	var u: = RDUniform.new()
	u.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u.binding = binding
	u.add_id(tex)
	return u

func _sampler_uniform(tex: RID, binding: int, samp: = RID()) -> RDUniform:
	var u: = RDUniform.new()
	u.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	u.binding = binding
	u.add_id(samp if samp.is_valid() else _sampler)
	u.add_id(tex)
	return u
