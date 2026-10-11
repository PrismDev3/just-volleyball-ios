class_name Ink
extends Node3D





















const INK_LAYER: = 4
const INK_MASK: = 1 << (INK_LAYER - 1)







const INK_ACC_LAYER: = 5
const INK_ACC_MASK: = 1 << (INK_ACC_LAYER - 1)



static var _acc_mat: StandardMaterial3D = null
static func acc_proxy_material() -> StandardMaterial3D:
	if _acc_mat == null:
		_acc_mat = StandardMaterial3D.new()
		_acc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_acc_mat.albedo_color = Color(0.0, 1.0, 0.0)
		_acc_mat.cull_mode = BaseMaterial3D.CULL_BACK
	return _acc_mat

static func supported() -> bool:

	return RenderingServer.get_rendering_device() != null

static func active() -> bool:


	return supported() and GameConfig.style_is(GameConfig.ArtStyle.CEL_INK)

static func tag(meshes: Array) -> void :



	for m in meshes:
		var mi: = m as MeshInstance3D
		if mi == null or String(mi.name).to_lower().contains("number"):
			continue
		mi.layers |= INK_MASK

static func untag(meshes: Array) -> void :



	for m in meshes:
		var mi: = m as MeshInstance3D
		if mi != null:
			mi.layers &= ~ INK_MASK

static func apply(camera: Camera3D) -> Ink:
	if camera == null or not active():
		return null


	camera.cull_mask &= ~ INK_ACC_MASK
	var node: = Ink.new()
	camera.add_child(node)
	node.setup(camera)
	return node

var effect: CharacterInk = null

var _src: Camera3D
var _cam: Camera3D
var _vp: SubViewport
var _cam_acc: Camera3D
var _vp_acc: SubViewport

func setup(source_cam: Camera3D) -> void :
	_src = source_cam




	_vp = _make_mask_vp(INK_MASK, Viewport.MSAA_4X)
	_cam = _vp.get_child(0)




	_vp_acc = _make_mask_vp(INK_MASK | INK_ACC_MASK, Viewport.MSAA_DISABLED)
	_cam_acc = _vp_acc.get_child(0)

	effect = CharacterInk.new()
	effect.mask_texture = _vp.get_texture()
	effect.acc_mask_texture = _vp_acc.get_texture()
	var comp: = Compositor.new()
	comp.compositor_effects = [effect]
	source_cam.compositor = comp


func _make_mask_vp(cull: int, msaa: int) -> SubViewport:
	var vp: = SubViewport.new()
	vp.size = _viewport_size()
	vp.world_3d = _src.get_world_3d()
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = msaa
	vp.positional_shadow_atlas_size = 0
	add_child(vp)
	var cam: = Camera3D.new()


	cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cam.cull_mask = cull
	vp.add_child(cam)
	cam.current = true
	return vp

func _process(_delta: float) -> void :
	if _src == null or _cam == null:
		return
	var want: = _viewport_size()
	if _vp.size != want:
		_vp.size = want
		_vp_acc.size = want



	for c in [_cam, _cam_acc]:
		c.global_transform = _src.global_transform
		c.fov = _src.fov
		c.near = _src.near
		c.far = _src.far
		c.keep_aspect = _src.keep_aspect
		c.projection = _src.projection
		c.size = _src.size

func _viewport_size() -> Vector2i:



	var vp: = _src.get_viewport()
	if vp == null:
		return Vector2i(2, 2)
	var px: = vp.get_visible_rect().size * clampf(GameConfig.render_scale, 0.3, 1.0)
	return Vector2i(maxi(int(px.x), 2), maxi(int(px.y), 2))
