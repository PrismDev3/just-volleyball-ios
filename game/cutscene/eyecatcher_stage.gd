class_name EyeCatcherStage
extends Node3D

















const COURT_SCENE: = preload("res://game/court/court.tscn")
const BASE_HALF_W: = 4.5
const BASE_HALF_L: = 9.0
const HALF_W: = 7.6
const HALF_L: = 13.6

var _court: Node3D
var _cam: Camera3D
var _ball: MeshInstance3D
var _casts: Array[PresentationCharacter] = []
var _ball_tween: Tween
var _frozen: = false



const SPOT_NEAR: = Vector3(1.4, 0.0, 4.6)
const SPOT_FAR: = Vector3(-1.0, 0.0, -4.6)

func _ready() -> void :
	_build_env()
	_build_court()
	_build_bottle()
	_build_ball()
	_build_camera()



func _build_env() -> void :



	var we: = WorldEnvironment.new()
	var env: = Environment.new()
	var sky: = Sky.new()
	var sm: = ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(1.0, 0.97, 0.88)
	sm.sky_horizon_color = Color(1.0, 0.82, 0.46)
	sm.ground_horizon_color = Color(0.99, 0.66, 0.28)
	sm.ground_bottom_color = Color(0.96, 0.52, 0.16)
	sm.sun_angle_max = 0.0
	sm.ground_curve = 0.1
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 1.12
	we.environment = env
	add_child(we)
	var key: = DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-52, -46, 0)
	key.light_energy = 0.7
	add_child(key)

func _build_court() -> void :
	_court = COURT_SCENE.instantiate()
	add_child(_court)
	_court.scale = Vector3(HALF_W / BASE_HALF_W, 1.0, HALF_L / BASE_HALF_L)
	var net: = _court.get_node_or_null("Net") as MeshInstance3D
	if net != null:
		CourtDress.unique_net(net, _court.scale.x)
	CourtDress.unique_floor(_court)

func _build_bottle() -> void :



	var bottle: = Node3D.new()
	bottle.name = "Bottle"
	add_child(bottle)


	bottle.position = Vector3(4.4, 0.0, 12.2)
	bottle.scale = Vector3.ONE * 1.15
	var body: = MeshInstance3D.new()
	var cm: = CapsuleMesh.new()
	cm.radius = 0.95
	cm.height = 5.2
	body.mesh = cm
	body.position.y = 2.6
	var glass: = StandardMaterial3D.new()
	glass.albedo_color = Color(0.85, 0.93, 0.97, 0.35)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.1
	glass.metallic = 0.0
	body.material_override = glass
	bottle.add_child(body)
	var cap: = MeshInstance3D.new()
	var capm: = CylinderMesh.new()
	capm.top_radius = 0.6
	capm.bottom_radius = 0.6
	capm.height = 0.8
	cap.mesh = capm
	cap.position.y = 5.4
	var capmat: = StandardMaterial3D.new()
	capmat.albedo_color = Color(0.9, 0.9, 0.92)
	cap.material_override = capmat
	bottle.add_child(cap)

func _build_ball() -> void :
	_ball = MeshInstance3D.new()
	_ball.name = "WaterBall"
	var sm: = SphereMesh.new()
	sm.radius = 0.34
	sm.height = 0.68
	_ball.mesh = sm
	var mat: = StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.9, 1.0, 0.72)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.05
	mat.rim_enabled = true
	_ball.material_override = mat
	add_child(_ball)
	_ball.visible = false

func _build_camera() -> void :
	_cam = Camera3D.new()
	_cam.fov = 42.0
	_cam.position = Vector3(9.5, 2.6, 11.5)
	_cam.look_at_from_position(_cam.position, Vector3(-0.5, 1.35, 0.0), Vector3.UP)
	add_child(_cam)



func clear_cast() -> void :
	for pc in _casts:
		if is_instance_valid(pc):
			pc.queue_free()
	_casts.clear()



func set_cast(roles: Array) -> void :
	clear_cast()
	for r in roles:
		var pc: = PresentationCharacter.new()
		add_child(pc)
		pc.setup(r.get("cfg"), r.get("kit", []))
		pc.position = r.get("spot", SPOT_NEAR)
		pc.face(r.get("yaw", 0.0))
		_casts.append(pc)





func play(entry: Dictionary, roles: Array) -> float:
	_frozen = false
	set_cast(roles)
	for i in _casts.size():
		var pc: = _casts[i]
		var clip: String = String(roles[i].get("clip", "spike"))
		var raw: = pc.rig.clip_name(clip) if pc.rig != null else ""
		pc.play_clip(raw if raw != "" else clip, true)
	_start_ball(entry)
	return float(entry.get("duration", 3.0))

func _start_ball(entry: Dictionary) -> void :
	if _ball == null:
		return
	if not bool(entry.get("ball", true)):
		_ball.visible = false
		return
	_ball.visible = true
	var a: Vector3 = entry.get("ball_from", SPOT_NEAR + Vector3(0, 1.4, -0.4))
	var b: Vector3 = entry.get("ball_to", SPOT_FAR + Vector3(0, 1.4, 0.4))
	var arc: float = float(entry.get("ball_arc", 2.6))
	var period: float = float(entry.get("ball_period", 1.3))
	_ball.position = a
	if _ball_tween != null and _ball_tween.is_valid():
		_ball_tween.kill()

	_ball_tween = create_tween().set_loops()
	_arc_hop(_ball_tween, a, b, arc, period)
	_arc_hop(_ball_tween, b, a, arc, period)

func _arc_hop(t: Tween, from: Vector3, to: Vector3, arc: float, period: float) -> void :

	t.tween_method( func(u: float):
		var p: = from.lerp(to, u)
		p.y += arc * 4.0 * u * (1.0 - u)
		if _ball != null:
			_ball.position = p
			_ball.rotate_y(0.25)
		, 0.0, 1.0, period).set_trans(Tween.TRANS_LINEAR)



func freeze() -> void :
	if _frozen:
		return
	_frozen = true
	if _ball_tween != null and _ball_tween.is_valid():
		_ball_tween.pause()
	for pc in _casts:
		if not is_instance_valid(pc) or pc.rig == null:
			continue
		var ap: AnimationPlayer = pc.rig.get("_anim")
		if ap != null and ap.current_animation != "":
			ap.pause()

func camera() -> Camera3D:
	return _cam
