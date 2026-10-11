class_name CharacterPortrait





















const CROPS: = ["full", "upper", "head"]







const PRESETS: = {
	"head": {"look": Vector3(0.0, 1.5, 0.0), "dist": 5.5, "vp": Vector2i(512, 512), "norm": true}, 


	"lobby": {"look": Vector3(0.0, 1.46, 0.0), "dist": 6.4, "vp": Vector2i(512, 512), "norm": true}, 
	"upper": {"look": Vector3(0.0, 1.24, 0.0), "dist": 7.8, "vp": Vector2i(512, 512), "norm": true}, 
	"extra": {"look": Vector3(0.0, 1.3, 0.0), "dist": 6.9, "vp": Vector2i(512, 512), "norm": true}, 
	"full": {"look": Vector3(0.0, 1.0, 0.0), "dist": 14.1, "vp": Vector2i(480, 620), "norm": false}, 


	"full_hd": {"look": Vector3(0.0, 1.0, 0.0), "dist": 14.1, "vp": Vector2i(960, 1240), "norm": false}, 
}




const FOV: = 10.0



static var _busy: = false




static func _portrait_path(crop: String) -> String:
	return AppData.cache_path("portraits/%s.png" % crop)




static var _head_cache: = {}

static func head_cached(cfg_data: Dictionary, host: Node = null, 
		preset: = "head") -> ImageTexture:
	if cfg_data.is_empty():
		return null
	var key: = hash([cfg_data, preset])
	if _head_cache.has(key):
		return _head_cache[key]
	var tex: ImageTexture = await render(CharacterConfig.from_dict(cfg_data), preset, 
		Vector2i(80, 80), host)
	if tex != null:
		_head_cache[key] = tex
	return tex




static func render(cfg: CharacterConfig, preset: = "full", 
		size: = Vector2i(256, 340), host: Node = null, kit_override: Array = []) -> ImageTexture:
	var tree: = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null

	while _busy:
		await tree.process_frame
	_busy = true





	if host != null and not is_instance_valid(host):
		host = null
	var tex: ImageTexture = null

	tex = await _render_impl(cfg, preset, tree, host, kit_override)
	_busy = false
	return tex





static var _rig: = {}

static func _ensure_rig(tree: SceneTree) -> Dictionary:
	if _rig.has("body") and is_instance_valid(_rig["body"]):
		return _rig
	var vp: = SubViewport.new()
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	tree.root.add_child(vp)
	var cam: = Camera3D.new()
	cam.fov = FOV
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	vp.add_child(cam)
	Ink.apply(cam)
	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.WHITE
	e.ambient_light_energy = 1.5
	env.environment = e
	vp.add_child(env)
	var body: Player = (load("res://game/player/player.tscn") as PackedScene).instantiate()
	body.enable_reflection = false
	vp.add_child(body)

	body.drop_shadow.visible = false


	body.process_mode = Node.PROCESS_MODE_DISABLED
	_rig = {"vp": vp, "cam": cam, "body": body}
	return _rig




static func _render_impl(cfg: CharacterConfig, preset: String, 
		tree: SceneTree, _host = null, kit_override: Array = []) -> ImageTexture:
	if cfg == null:
		cfg = CharacterConfig.new()
	var p: Dictionary = PRESETS.get(preset, PRESETS["full"])
	if bool(p["norm"]):



		cfg = cfg.clone()
		cfg.height = 0.5

	var rig: = _ensure_rig(tree)
	var vp: SubViewport = rig["vp"]
	var cam: Camera3D = rig["cam"]
	var body: Player = rig["body"]


	vp.size = p["vp"]
	var look: Vector3 = p["look"]
	cam.global_position = look + Vector3(0.0, 0.0, float(p["dist"]))
	cam.look_at(look)

	body.global_position = Vector3.ZERO
	body.visual.rotation.y = 0.0
	body.set_character(cfg, kit_override if not kit_override.is_empty() else cfg.kit_home)



	body.force_portrait_pose()




	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for _i in 4:
		await RenderingServer.frame_post_draw
	if not is_instance_valid(vp):
		_rig = {}
		return null
	var img: = vp.get_texture().get_image()
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if img == null:
		return null



	var used: = img.get_used_rect()
	if used.size.x < 8 or used.size.y < 8:
		return null


	return ImageTexture.create_from_image(img)



static func generate_and_save(cfg: CharacterConfig, host: Node = null) -> void :
	DirAccess.make_dir_recursive_absolute(AppData.cache_path("portraits"))
	for crop in CROPS:
		var tex: = await render(cfg, crop, Vector2i.ZERO, host)
		if tex != null:
			tex.get_image().save_png(_portrait_path(crop))


static func load_full() -> Texture2D:
	return _load(_portrait_path("full"))

static func load_upper() -> Texture2D:
	return _load(_portrait_path("upper"))

static func load_head() -> Texture2D:
	return _load(_portrait_path("head"))

static func _load(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var img: = Image.new()
	if img.load(path) != OK:
		return null
	return ImageTexture.create_from_image(img)
