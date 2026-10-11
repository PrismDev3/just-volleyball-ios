extends Node3D






const COURT_SCENE: = preload("res://game/court/court.tscn")
const BALL_SCENE: = preload("res://game/ball/ball.tscn")








const COURTS: = [
	{"size": 1, "hw": 4.0, "hl": 8.4, "x": -27.0, "label": "1v1"}, 
	{"size": 2, "hw": 5.1, "hl": 10.2, "x": -8.0, "label": "2v2"}, 
	{"size": 3, "hw": 5.1, "hl": 10.2, "x": 12.0, "label": "3v3"}, 
	{"size": 4, "hw": 7.0, "hl": 12.8, "x": 34.0, "label": "4v4"}, 
	{"size": 5, "hw": 7.0, "hl": 12.8, "x": 59.0, "label": "5v5"}, 
	{"size": 6, "hw": 7.6, "hl": 13.6, "x": 85.0, "label": "6v6"}, 
]
const PRACTICE_X: = -46.0
const PRACTICE_HW: = 5.5
const PRACTICE_HL: = 11.0
const HALL_CENTER_X: = 21.0
const HALL_HALF_W: = 88.0
const HALL_HALF_L: = 36.0

@onready var player: Player = $Player
@onready var camera_rig: CameraRig = $CameraRig
@onready var aim_indicator: AimMarker = $AimIndicator
@onready var barred_marker: Node3D = $BarredMarker
@onready var landing_marker: Node3D = $LandingMarker
@onready var verdict_label: Label3D = $LandingMarker / VerdictLabel
@onready var fx: Fx = $Fx
@onready var sfx: Sfx = $Sfx
@onready var crowd: CrowdAudio = $Crowd
@onready var hud: Hud = $UiLayer / Hud

var _input_collector: = InputCollector.new()
var _matches: Array = []
var _pads: Array = []
var _court_far: = {}
var _court_reflect: = {}
var _reflector: FloorReflector = null
var _hl_cache: = {}
var _serve_zone: = ServeZoneMarker.new()
var _zone_court: GymMatch = null
var _joined: GymMatch = null
var _practice_net_mat: ShaderMaterial = null
var _queued = null
var _result_timer: = 0.0
var _practice_ball: Ball = null
var reach_marker: ReachMarker = null
var _practice_floor_mat: ShaderMaterial = null
var _on_practice: = false
var _practice_serving: = false
var _foley: = Foley.new()
var net_client: = false
var _net: GymNet = null
var net_claimed_pads: Array = []




const FAR_COURT_DIST: = 30.0
var _lod_timer: = 0.0

func _ready() -> void :


	add_child(ChatBubbles.new( func():
		var out: Array = _net.remote_bodies() if _net != null else []
		if player != null:
			out.append(player)
		return out, func(): return player))
	GameConfig.use_cursor(true)
	Rules.set_swapped = false
	Haptics.wire(player)



	crowd.set_active(false)

	MusicManager.set_muffled(false)
	MusicManager.play("gym")
	GameConfig.new_match_seed()


	net_client = Net.active and Net.gym_session and not Net.is_host


	GameConfig.stage_reflections = true
	_build_hall()
	for config in COURTS:
		var m: = GymMatch.new()
		m.net_puppet_court = net_client
		m.configure(config.size, config.hw, config.hl)
		m.court_salt = _matches.size() + 1
		m.position = Vector3(config.x, 0.0, 0.0)
		add_child(m)
		_matches.append(m)
		m.ball.wall_min = Vector3(HALL_CENTER_X - HALL_HALF_W + 0.5, -1000000.0, 
			- HALL_HALF_L + 0.5)
		m.ball.wall_max = Vector3(HALL_CENTER_X + HALL_HALF_W - 0.5, 30.0, 
			HALL_HALF_L - 0.5)
		m.ball.struck.connect(_on_ball_struck.bind(m))
		m.ball.bounced.connect(_on_ball_bounced.bind(m.ball, m))
		m.ball.net_hit.connect( func():
			_court_sfx(m, "hit_soft", m.ball.global_position, -6.0, 0.6))
		m.rally_ended.connect(_on_rally_ended.bind(m))
		m.verdict_called.connect(_on_verdict.bind(m))
		m.block_broken_at.connect( func(pos: Vector3, who: Player):
			if not _court_far.get(m, false):
				fx.shield_crack(pos)
			_court_sfx(m, "block_hard", pos, 0.0, 0.85)
			who.show_float_text("block broken!", Color(1.0, 0.82, 0.25), true))
		m.thumped_at.connect( func(pos: Vector3, strength: float):
			var at: = Vector3(pos.x, 0.08, pos.z)
			_court_sfx(m, "hit_soft", at, -2.0, 0.55)




			if not _court_far.get(m, false):
				Rules.contact_fx(fx, at, strength, Vector3.UP, 0.0, m == _joined)
				fx.puff(at))
		m.launched_at.connect( func(pos: Vector3, charge: float):
			var at: = Vector3(pos.x, 0.06, pos.z)
			if not _court_far.get(m, false):
				fx.ring(at, Vector3.UP, 1.15 * charge)
				fx.puff(at)
			_court_sfx(m, "hit_soft", at, -4.0, 1.35))
		m.voice_called.connect( func(bank: String, pos: Vector3, pitch: float):
			_court_sfx(m, bank, pos, -3.0, pitch))




		m.whistle_at.connect( func(reason: String, pos: Vector3):
			if m == _joined:
				sfx.play("whistle", pos, -3.0)
				hud.flash_banner(reason))
		m.toss_at.connect( func(pos: Vector3):
			_court_sfx(m, "hit_soft", pos, -10.0, 1.1))
		m.flair_at.connect(_on_court_flair.bind(m))
		for side in [1, -1]:
			for slot in range(config.size):
				_build_pad(m, side, slot, config)
	_build_practice_court()
	player.team_side = 1
	player.indicator_enabled = true


	player.combo_shown.connect( func(count: int, fail: bool):
		var bank: = "combo_fail" if fail\
		else "combo_%s_%d" % ["home" if player.team_side >= 0 else "away", clampi(count, 1, 3)]
		sfx.play(bank, player.global_position, -13.0, 1.0, false, true))



	player.thumped.connect( func(pos: Vector3, strength: float):
		var at: = Vector3(pos.x, 0.08, pos.z)
		sfx.play("hit_soft", at, -2.0, 0.55)
		Rules.contact_fx(fx, at, strength, Vector3.UP, 0.0)
		fx.puff(at))
	player.knock_started.connect( func(_pos: Vector3, strength: float):
		camera_rig.shake(0.22 * strength))
	player.launched.connect( func(pos: Vector3, charge: float):
		var at: = Vector3(pos.x, 0.06, pos.z)
		fx.ring(at, Vector3.UP, 1.15 * charge)
		fx.puff(at)
		sfx.play("hit_soft", at, -4.0, 1.35))
	player.global_position = door_spawn(0)


	player.set_character(GameConfig.character.gym_look(), 
		GameConfig.character.gym_kit())



	player.set_display_name(Net.local_display_name())
	player.set_dev_tag(DevBadge.my_tier())
	camera_rig.player = player
	camera_rig.mode_changed.connect(hud.show_camera_name)
	camera_rig.ball = _matches[1].ball


	var reflector: = FloorReflector.new()
	add_child(reflector)
	reflector.setup(camera_rig.camera)
	reflector.scene_scoped = true
	_reflector = reflector
	add_child(_serve_zone)
	var reflect_mats: = []
	for m in _matches:
		var court: GymMatch = m
		if court.floor_reflect_mat != null:
			CourtDress.wire_reflection(court.floor_reflect_mat, 
				reflector.texture())
			reflect_mats.append(court.floor_reflect_mat)

	if _practice_floor_mat != null:
		CourtDress.wire_reflection(_practice_floor_mat, reflector.texture())
		reflect_mats.append(_practice_floor_mat)
	reflector.floor_mats = reflect_mats


	reflector.feet_provider = func():


		var all: = [player]
		for c in _matches:
			var court: = c as GymMatch
			for p in court.players():
				if not (p as Player).far_lod:
					all.append(p)
			if court.ball != null and not court.ball.far_lod:
				all.append(court.ball)


		if _net != null:
			for b in _net.remote_bodies():
				var rb: = b as Player
				if is_instance_valid(rb) and not rb.far_lod:
					all.append(rb)
		return all
	fx.setup(camera_rig)

	LandingCall.dress(landing_marker, verdict_label)
	reach_marker = ReachMarker.new()
	add_child(reach_marker)
	reach_marker.setup(camera_rig.camera)
	reach_marker.entered_reach.connect( func():
		sfx.play("reach_in", player.global_position, -8.0))
	reach_marker.action_queued.connect( func():
		sfx.play("reach_queue", player.global_position, -2.0))
	reach_marker.took.connect( func():
		sfx.play("reach_take", player.global_position, -4.0, 1.15))
	reach_marker.missed.connect( func():
		sfx.play("reach_miss", player.global_position, -8.0))
	reach_marker.early.connect( func():
		sfx.play("reach_miss", player.global_position, -8.0))
	player.out_of_range.connect( func():
		sfx.play("reach_miss", player.global_position, -8.0))

	_input_collector.dive_denied.connect( func():
		sfx.play("reach_miss", player.global_position, -8.0)
		hud.dive_denied()
		player.dive_denied())
	Ink.apply(camera_rig.camera)

	# The on-screen pad aims and looks through this pair; see TouchControls.
	TouchControls.bind(camera_rig, _input_collector)

	if Net.active and Net.gym_session:
		_net = GymNet.new()
		add_child(_net)
		_net.setup(self)


	hud.pause_pauses_tree = _net == null
	hud.apply_pause_mode()

const HALL_STAGE: = "training"

func _build_hall() -> void :
	Stage.apply_reverb(HALL_STAGE)


	var kit: = load(String(Stage.info(HALL_STAGE).venue)) as PackedScene
	if kit != null:
		add_child(kit.instantiate())


	var body: = StaticBody3D.new()
	body.collision_layer = 3
	add_child(body)
	var floor_shape: = CollisionShape3D.new()
	var floor_box: = BoxShape3D.new()
	floor_box.size = Vector3(HALL_HALF_W * 2.0, 0.2, HALL_HALF_L * 2.0)
	floor_shape.shape = floor_box
	floor_shape.position = Vector3(HALL_CENTER_X, -0.1, 0.0)
	body.add_child(floor_shape)
	for wall in [
		{"size": Vector3(0.4, 14, HALL_HALF_L * 2.0), "pos": Vector3(HALL_CENTER_X - HALL_HALF_W, 7, 0)}, 
		{"size": Vector3(0.4, 14, HALL_HALF_L * 2.0), "pos": Vector3(HALL_CENTER_X + HALL_HALF_W, 7, 0)}, 
		{"size": Vector3(HALL_HALF_W * 2.0, 14, 0.4), "pos": Vector3(HALL_CENTER_X, 7, - HALL_HALF_L)}, 
		{"size": Vector3(HALL_HALF_W * 2.0, 14, 0.4), "pos": Vector3(HALL_CENTER_X, 7, HALL_HALF_L)}, 
	]:


		var wall_col: = CollisionShape3D.new()
		var wall_shape: = BoxShape3D.new()
		wall_shape.size = wall.size
		wall_col.shape = wall_shape
		wall_col.position = wall.pos
		body.add_child(wall_col)


func _build_pad(m: GymMatch, side: int, slot: int, config: Dictionary) -> void :

	var pad: = MeshInstance3D.new()
	var mesh: = BoxMesh.new()
	mesh.size = Vector3(1.5, 0.06, 1.5)
	var mat: = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.25, 0.95, 0.35, 0.55)
	mesh.material = mat
	pad.mesh = mesh
	var frac: = (float(slot) + 0.5) / float(config.size)
	var pos: = Vector3(
		config.x + lerpf( - config.hw * 0.7, config.hw * 0.7, frac), 
		0.04, float(side) * (config.hl + 2.2))
	pad.position = pos
	add_child(pad)
	_pads.append({"match": m, "side": side, "slot": slot, "pos": pos, 
		"node": pad, "label": config.label})

func _build_practice_court() -> void :

	var court: Node3D = COURT_SCENE.instantiate()
	court.position = Vector3(PRACTICE_X, 0.0, 0.0)
	add_child(court)


	court.scale = Vector3(PRACTICE_HW / 4.5, 1.0, PRACTICE_HL / 9.0)



	_practice_floor_mat = CourtDress.unique_floor(court)
	_practice_floor_mat.set_shader_parameter("base_color", Stage.val(HALL_STAGE, "floor_color", Color(0.85, 0.5, 0.25)))
	Stage.dress_court(court, HALL_STAGE)
	CourtDress.unique_net(court.get_node("Net"), court.scale.x)



	var _gym_net: = court.get_node_or_null("Net") as MeshInstance3D
	if _gym_net != null:
		_practice_net_mat = (_gym_net.mesh as PlaneMesh).material as ShaderMaterial
		aim_indicator.net_mat = _practice_net_mat
	_practice_ball = BALL_SCENE.instantiate()


	_practice_ball.stage_ball = GymMatch.HALL_BALLS[
		absi(hash("%s|ball|0" % GameConfig.match_seed)) % GymMatch.HALL_BALLS.size()]
	add_child(_practice_ball)
	_practice_ball.global_position = Vector3(PRACTICE_X, 1.0, 3.0)
	_practice_ball.net_half_width = Ball.PHYS.net_half_width * (PRACTICE_HW / 4.5)
	_practice_ball.antenna_half_width = Ball.PHYS.antenna_half_width * (PRACTICE_HW / 4.5)
	_practice_ball.court_center_x = PRACTICE_X
	_practice_ball.court_half_w = PRACTICE_HW
	_practice_ball.court_half_l = PRACTICE_HL
	_practice_ball.wall_min = Vector3(HALL_CENTER_X - HALL_HALF_W + 0.5, -1000000.0, 
		- HALL_HALF_L + 0.5)
	_practice_ball.wall_max = Vector3(HALL_CENTER_X + HALL_HALF_W - 0.5, 30.0, 
		HALL_HALF_L - 0.5)
	_practice_ball.bounced.connect(_on_ball_bounced.bind(_practice_ball))
	_practice_ball.struck.connect( func(pos: Vector3, power: float, kind: int):
		_on_ball_struck(pos, power, kind, null))

func _poll_callouts() -> void :



	if player == null or hud.chat_typing() or hud.pause_is_open():
		return

	for i in 4:
		if Input.is_action_just_pressed("callout_%d" % (i + 1)):
			if _net != null:
				_net.relay_callout(i)
			else:
				player.show_callout(i)
			return

func _update_court_lod() -> void :
	var cam_x: = camera_rig.camera.global_position.x






	var reflect_court: GymMatch = _joined
	if reflect_court == null:
		for m in _matches:
			var c: GymMatch = m
			if absf(player.global_position.x - c.cx) < c.half_w + 1.0\
			and absf(player.global_position.z) < c.half_l + 1.0:
				reflect_court = c
				break
	if reflect_court == null:


		var best: = FAR_COURT_DIST
		for m in _matches:
			var c: GymMatch = m
			var d: = absf(player.global_position.x - c.cx)
			if d < best:
				best = d
				reflect_court = c
	var on_practice: = reflect_court == null\
	and absf(player.global_position.x - PRACTICE_X) < PRACTICE_HW + 1.0\
	and absf(player.global_position.z) < PRACTICE_HL + 1.0
	if _practice_floor_mat != null\
	and _court_reflect.get("practice") != on_practice:
		_court_reflect["practice"] = on_practice
		_practice_floor_mat.set_shader_parameter("reflect_on", 
			on_practice and GameConfig.reflections_live())
	if _practice_ball != null:
		_practice_ball.mirror_off = not on_practice
		_practice_ball.show_landing_ring = on_practice

	player.mirror_off = reflect_court == null and not on_practice

	if _reflector != null:
		_reflector.live = reflect_court != null or on_practice
	for m in _matches:
		var court: GymMatch = m
		var far: bool = court != _joined\
		and absf(court.cx - cam_x) > FAR_COURT_DIST
		var was = _court_far.get(court)
		_court_far[court] = far
		court.sim_far = far
		var reflecting: = court == reflect_court
		if (was != far or _court_reflect.get(court) != reflecting)\
		and court.floor_reflect_mat != null:
			_court_reflect[court] = reflecting
			court.floor_reflect_mat.set_shader_parameter("reflect_on", 
				reflecting and GameConfig.reflections_live())
		for p in court.players():
			var member: = p as Player
			member.far_lod = far
			member.mirror_off = not reflecting
			if member._model != null:
				member._model.set_outline_lod(far)
		if court.ball != null:
			court.ball.far_lod = far
			court.ball.mirror_off = not reflecting


			court.ball.show_landing_ring = court == _joined
	if _practice_ball != null:
		_practice_ball.far_lod = absf(PRACTICE_X - cam_x) > FAR_COURT_DIST



	if _net != null:
		for b in _net.remote_bodies():
			var body: = b as Player
			if is_instance_valid(body):
				body.far_lod = absf(body.global_position.x - cam_x)\
				> FAR_COURT_DIST

func _unhandled_input(event: InputEvent) -> void :

	_input_collector.feed_motion(event)



func _exit_tree() -> void :
	TouchControls.unbind(camera_rig)

func _process(_delta: float) -> void :





	_input_collector.snap_targets = []
	_input_collector.foe_targets = []
	if _joined != null:
		for sp in _joined._all_players:
			var sb: Player = sp
			if sb == player:
				continue
			if sb.team_side == player.team_side:
				_input_collector.snap_targets.append(sb)
			else:
				_input_collector.foe_targets.append(sb)
		var r = _joined.get("_rally")
		_input_collector.team_touches = int(r.touch_count)\
		if r != null and r.touch_side == player.team_side else 0
	var touch_live: = not hud.pause_is_open() and not hud.chat_typing()\
		and not camera_rig.input_frozen
	TouchControls.set_live(touch_live)
	_input_collector.follow_cursor(camera_rig, touch_live)
	hud.set_aim_cursor(_input_collector.soft_cursor_active(), 
		_input_collector.soft_cursor_pos())



	var marked: Ball = null
	if _joined != null:
		marked = _joined.ball
	elif _on_practice:
		marked = _practice_ball
	hud.track_ball_marker(camera_rig.camera, marked, 
		marked != null and not hud.pause_is_open(), player)

func _physics_process(delta: float) -> void :


	_lod_timer -= delta
	if _lod_timer <= 0.0:
		_lod_timer = 0.5
		_update_court_lod()


	if landing_marker.visible and (_joined == null or _joined._rally_live):
		landing_marker.visible = false
	_poll_callouts()
	var input: = _input_collector.collect(camera_rig, player)
	if hud.chat_typing():



		input = PlayerInput.new()






	if _net != null and not _net.is_host:
		var want: GymMatch = null
		if _net.client_court_idx >= 0 and _net.client_court_idx < _matches.size():
			want = _matches[_net.client_court_idx]
		if want != _joined:
			_joined = want
			if want != null:
				_queued = null
				_bind_to_match()
			else:
				_unbind_from_match()
	elif _joined == null:
		for m in _matches:
			var match_node: GymMatch = m
			if match_node.humans.has(player):
				_joined = match_node
				_queued = null
				_bind_to_match()
				break
	if _joined != null:
		_joined.set_member_input(player, input)
	player.simulate(input, delta)





	var roaming: = _joined == null
	camera_rig.roam = roaming
	var force_action: = roaming and not _on_practice
	if force_action != camera_rig.mode_locked:
		camera_rig.mode_locked = force_action
		var want: = CameraRig.Mode.ACTION
		if not force_action:
			want = clampi(GameConfig.default_camera, 0, 
				CameraRig.Mode.size() - 1) as CameraRig.Mode
		camera_rig.mode = want
		camera_rig.apply_mouse_mode()
	if _joined == null:
		_pad_logic()
		_practice_logic(input)
		keep_off_courts(player)
	else:
		contain_in_court(player, _joined)
		_check_air_bumps(_joined)
		_check_match_end(delta)





	if _net != null:
		if _net.is_host:
			_net.host_tick(delta)
		else:
			_net.client_tick(input, delta)
			_net.client_frame(delta)
	_update_pads()
	_motion_foley(delta)
	_update_indicators(input)
	_tick_reach_marker()










func _tick_reach_marker() -> void :
	if reach_marker == null:
		return
	var body: Player = player
	var target: Ball = null
	if _joined != null:
		body = player if _joined.humans.has(player) else player
		target = _joined.ball
	elif _on_practice:
		target = _practice_ball
	reach_marker.drive(body, target, GameConfig.reach_marker and target != null)

func _practice_logic(input: PlayerInput) -> void :
	_on_practice = absf(player.global_position.x - PRACTICE_X) < PRACTICE_HW + 4.0\
	and absf(player.global_position.z) < PRACTICE_HL + 5.0
	_set_practice_aim_bounds(_on_practice)
	player.serve_charge_ui = false
	if _on_practice:
		player.ball = _practice_ball


		player.touch_barred = _practice_serving
		if input.serve_pressed and not _practice_serving:

			_practice_serving = true
			_practice_ball.frozen = true
			_practice_ball.vel = Vector3.ZERO
		_practice_ball.serve_held = _practice_serving
		if _practice_serving:
			player.serve_charge_ui = true

			_practice_ball.global_position = player.serve_cradle_point()
			if input.contact_released:
				_practice_serving = false
				_practice_ball.frozen = false
				_practice_ball.serve_assist = true
				_practice_ball.toss(player.serve_cradle_point(), 
					lerpf(6.5, 12.0, player.hold_power()))
				player.present_serve_toss()
		var bp: = _practice_ball.global_position
		if absf(bp.x - PRACTICE_X) > PRACTICE_HW + 8.0\
		or absf(bp.z) > PRACTICE_HL + 9.0 or bp.y < -2.0:
			_practice_ball.toss(Vector3(PRACTICE_X, 1.0, 3.0), 4.0)
	else:
		if _practice_serving:
			_practice_serving = false
			_practice_ball.frozen = false
		if player.ball == _practice_ball:
			player.ball = null
		player.touch_barred = true

func _set_practice_aim_bounds(on: bool) -> void :





	if on:
		_input_collector.aim_min = Vector2(
			PRACTICE_X - PRACTICE_HW - 1.5, - PRACTICE_HL - 2.5)
		_input_collector.aim_max = Vector2(
			PRACTICE_X + PRACTICE_HW + 1.5, PRACTICE_HL + 2.5)
	else:
		_input_collector.aim_min = Vector2(-1000000.0, -1000000.0)
		_input_collector.aim_max = Vector2(1000000.0, 1000000.0)

const PAD_GREEN: = Color(0.25, 0.95, 0.35, 0.55)
const PAD_RED: = Color(0.95, 0.25, 0.2, 0.6)

func _on_verdict(pos: Vector3, text: String, winner: int, m) -> void :


	if m != _joined:
		return
	landing_marker.visible = true
	landing_marker.global_position = Vector3(pos.x, maxf(0.03, SandDeform.decal_y), pos.z)


	LandingCall.apply(landing_marker, verdict_label, text, Rules.side_color(winner))

func _update_pads() -> void :




	for i in _pads.size():
		var pad = _pads[i]
		pad.node.visible = _joined == null
		var claimed: bool
		if _net != null and not _net.is_host:
			claimed = net_claimed_pads.has(i)
		else:
			claimed = _queued == pad\
			or (pad.match as GymMatch).human_on(pad.side, pad.slot)



			if not claimed and _net != null:
				for pp in _net._peer_pad.values():
					if pp == pad:
						claimed = true
		((pad.node.mesh as BoxMesh).material as StandardMaterial3D)\
		.albedo_color = PAD_RED if claimed else PAD_GREEN

func _pad_logic() -> void :
	var standing = null
	for pad in _pads:
		var flat: = Vector2(player.global_position.x - pad.pos.x, 
			player.global_position.z - pad.pos.z)
		if flat.length() < 1.2:
			standing = pad
			break
	if standing != null:
		if _queued != standing:
			if _queued != null:
				_queued.match .cancel_join(player)
			_queued = standing
		_queued.match .request_join(player, _queued.side, _queued.slot, 
			Net.local_display_name(), GameConfig.character)
		if _queued.match .humans.has(player):
			_joined = _queued.match
			_queued = null
			_bind_to_match()
	elif _queued != null:
		_queued.match .cancel_join(player)
		_queued = null

func _bind_to_match() -> void :



	camera_rig.ball = _joined.ball




	player.ball = _joined.ball
	camera_rig.home_side = float(player.team_side)
	camera_rig.tv_center_x = _joined.cx
	camera_rig.court_span = _joined.half_l
	camera_rig.face_net()
	_input_collector.aim_min = Vector2(
		_joined.cx - _joined.half_w - 1.5, - _joined.half_l - 2.5)
	_input_collector.aim_max = Vector2(
		_joined.cx + _joined.half_w + 1.5, _joined.half_l + 2.5)

func _unbind_from_match() -> void :
	player.set_highlight(Color(0, 0, 0, 0))

	if player.ball != _practice_ball:
		player.ball = null
	camera_rig.tv_center_x = 0.0
	camera_rig.court_span = CameraRig.TV_REF_SPAN



	camera_rig.ball = _practice_ball
	camera_rig.serve_view = false
	camera_rig.focus_boost = 0.0
	_set_practice_aim_bounds(_on_practice)






func door_spawn(i: int) -> Vector3:
	return Vector3(HALL_CENTER_X + 1.2 * float(i % 6), 0.0, 
		HALL_HALF_L - 4.0 - 1.4 * floorf(i / 6.0))




func keep_off_courts(body: Player) -> void :


	for m in _matches:
		var court: GymMatch = m
		var margin_w: float = court.half_w + 1.5
		var margin_l: float = court.half_l + 1.5
		var dx: float = body.global_position.x - court.cx
		var dz: float = body.global_position.z
		if absf(dx) >= margin_w or absf(dz) >= margin_l:
			continue
		var push_x: float = margin_w - absf(dx)
		var push_z: float = margin_l - absf(dz)
		if push_x < push_z:
			body.global_position.x = court.cx\
			+ margin_w * (signf(dx) if dx != 0.0 else 1.0)
		else:
			body.global_position.z = margin_l * (signf(dz) if dz != 0.0 else 1.0)

func contain_in_court(body: Player, m: GymMatch) -> void :

	body.global_position.x = clampf(body.global_position.x, 
		m.cx - m.half_w - 5.0, m.cx + m.half_w + 5.0)
	var side: = float(body.team_side)
	var z: = body.global_position.z * side
	body.global_position.z = clampf(z, -0.05, m.half_l + 7.0) * side

func _check_match_end(delta: float) -> void :
	if not _joined.set_over:
		return
	if _result_timer <= 0.0:
		var won: bool = _joined.winner_team == player.team_side
		hud.flash_banner("you win the set!" if won else "set lost")
		crowd.cheer(1.0)
		_result_timer = 3.0
		return
	_result_timer -= delta
	if _result_timer <= 0.0:
		var exit_x: float = _joined.cx + _joined.half_w + 2.2
		var exit_z: float = float(player.team_side) * (_joined.half_l * 0.5)
		_joined.release_member(player)
		player.global_position = Vector3(exit_x, 0.0, exit_z)
		player.reset_physics_interpolation()
		_joined = null
		_serve_zone.tick(false, 1.0, false)
		_zone_court = null
		_unbind_from_match()







func _court_sfx(m: GymMatch, bank: String, pos: Vector3, db: float, 
		pitch: = 1.0) -> void :
	if m != _joined:
		if _court_far.get(m, false):
			return
		db -= 8.0
	sfx.play(bank, pos, db, pitch)

func _check_air_bumps(m: GymMatch) -> void :



	for hit in Rules.air_bumps(m._all_players):
		var mid: Vector3 = hit.pos
		sfx.play("block_soft", mid, -4.0)
		fx.impact(mid, 0.7, hit.dir)
		fx.puff(mid)

func _on_ball_struck(pos: Vector3, power: float, kind: int, m) -> void :

	var mine: bool = m == null or m == _joined
	var b: Ball = _practice_ball if m == null else m.ball



	var strength: = Rules.contact_strength(kind, power)
	var snd: = Rules.contact_sound(kind, power, -4.0)
	if mine:
		sfx.play(String(snd["n"]), pos, float(snd["db"]), float(snd["pt"]))
	else:
		_court_sfx(m, String(snd["n"]), pos, float(snd["db"]), float(snd["pt"]))


	var tier: int = b.combo_tier if kind == Player.TouchKind.SPIKE else 0
	if kind == Player.TouchKind.SPIKE and (power > 0.8 or tier == 3) and mine:
		fx.big_spike(pos, b.vel)

	if mine and kind == Player.TouchKind.SPIKE and b.hitstop_left > 0.0:
		camera_rig.shake(minf(0.12 + b.hitstop_left * 2.0, 0.4))



	if mine or not _court_far.get(m, false):
		var wet: float = m.current_sweat if m != null else 0.0
		Rules.contact_fx(fx, pos, strength, b.vel, wet, mine, kind, tier)

func _on_ball_bounced(b: Ball, m: GymMatch = null) -> void :

	if m == null or m == _joined:
		sfx.play("hit_soft", b.global_position, -12.0, 0.75)
	else:
		_court_sfx(m, "hit_soft", b.global_position, -12.0, 0.75)
	if m != null and _court_far.get(m, false):
		return
	var floor_pos: = Vector3(b.global_position.x, 0.06, b.global_position.z)
	fx.ring(floor_pos, Vector3.UP, clampf(b.vel.y * 0.12, 0.3, 0.9))
	fx.puff(floor_pos)




func _on_court_flair(kind: String, who: Player, m: GymMatch) -> void :
	if m != _joined:
		return
	match kind:
		"perfect":
			sfx.play("hit_hard", who.chest_position(), -2.0, 1.1)
			fx.ring(m.ball.global_position, m.ball.vel, 1.1)
		"dive":
			crowd.cheer(0.8)
		"stuff":
			crowd.cheer(0.6)

func _on_rally_ended(winner_side: int, m: GymMatch) -> void :


	var reason: String = m.last_end_reason
	if m != _joined:



		return

	hud.point_moment(winner_side, player.team_side, reason, 
		int(m.scores.get(1, 0)), int(m.scores.get(-1, 0)))
	if m.kill_power(winner_side) > 0.65:
		fx.slowmo(0.35, 0.8)
		crowd.cheer(1.0)
	else:
		crowd.cheer(0.45)

func _motion_foley(delta: float) -> void :
	var bodies: Array = [player]
	for m in _matches:
		bodies.append_array(m._all_players)


	if _net != null:
		bodies.append_array(_net.remote_bodies())
	for p in bodies:
		var member: Player = p
		if member == null or not is_instance_valid(member):
			continue


		if member.far_lod:
			continue
		if member.sweat > 0.25 and randf() < member.sweat * 0.25:
			fx.sweat(member.global_position + Vector3(
				randf_range(-0.25, 0.25), 1.55, randf_range(-0.25, 0.25)))


	_foley.tick(bodies, delta, sfx, fx)

func _update_indicators(input: PlayerInput) -> void :


	player.set_name_visible(GameConfig.show_own_name)
	player.set_first_person(camera_rig.mode == CameraRig.Mode.FIRST_PERSON)








	if Engine.get_physics_frames() % 60 == 0:
		_hl_cache.clear()
	for m in _matches:
		var court: GymMatch = m
		var lt: Player = court._last_toucher\
		if court == _joined and court._rally_live\
		and GameConfig.touch_highlight and court.team_size > 1 else null
		for p in court._all_players:
			var b: Player = p
			var want: = Rules.side_color(b.team_side) if b == lt\
			else Color(0.0, 0.0, 0.0, 0.0)
			if _hl_cache.get(b) != want:
				_hl_cache[b] = want
				b.set_highlight(want)
	var free: = camera_rig.mode == CameraRig.Mode.ACTION or camera_rig.mode == CameraRig.Mode.FIRST_PERSON
	aim_indicator.visible = not free and _joined != null


	aim_indicator.net_mat = _joined.net_material() if _joined != null else _practice_net_mat
	var gaim_ib: = _joined != null\
	and absf(input.aim.x - _joined.cx) <= _joined.half_w\
	and absf(input.aim.z) <= _joined.half_l
	aim_indicator.aim_at(input.aim, float(player.team_side), gaim_ib)
	hud.set_crosshair_visible(free)
	hud.set_crosshair_side(input.aim.z, gaim_ib)
	hud.set_dive(player.dive_cooldown)
	hud.update_state(player)


	hud.refresh_controls(player, player.serve_charge_ui or _practice_serving)
	if _joined != null:
		var side: = player.team_side
		player.serve_charge_ui = _joined._phase == GymMatch.Phase.SERVE_PREP\
		and _joined._server == player


		hud.set_score_colors(side)
		hud.set_score(_joined.scores[side], _joined.scores[ - side], 0, 0, 1)
		hud.set_sweat(_joined.current_sweat)
		hud.set_touches(_joined._touch_count)
		hud.set_serve_prompt(_joined.serve_prompt(player))



		if _zone_court != _joined:
			_zone_court = _joined
			_serve_zone.setup(_joined.cx, _joined.half_w, _joined.half_l)
		var gz: Player = null
		if _joined.serving_me(player):
			gz = player
		elif GameConfig.debug_serve_zones and not _joined.net_puppet_court\
		and _joined._phase == GymMatch.Phase.SERVE_PREP:
			gz = _joined._server
		_serve_zone.tick(gz != null, 
			float(gz.team_side) if gz != null else 1.0, 
			gz != null and _joined.in_safe_serve_spot(gz))
		if GameConfig.show_cam_debug:
			hud.set_net_info(camera_rig.debug_line())
		else:
			hud.set_net_info("")


		var barred: bool = _joined._rally_live and player.touch_barred_self
		barred_marker.visible = barred
		_joined.ball.landing_ring_muted = barred
		if barred:
			barred_marker.global_position = Vector3(
				_joined.ball.global_position.x, 0.03, 
				_joined.ball.global_position.z)
		camera_rig.possession = signf(_joined.ball.global_position.z)\
		if _joined.ball.global_position.z != 0.0 else camera_rig.possession

		camera_rig.focus_boost = 0.0
		var server: Player = _joined._server
		var ally_serving: = server != null and server.team_side == player.team_side
		if _joined._phase == GymMatch.Phase.SERVE_PREP:
			camera_rig.focus_boost = 1.0 if ally_serving else 0.25
		elif _joined._phase == GymMatch.Phase.LIVE and ally_serving\
		and not _joined._serve_crossed\
		and _joined.ball.global_position.z * player.team_side\
		> player.global_position.z * player.team_side:
			camera_rig.focus_boost = 1.0




		var my_serve: bool = server == player
		var serving_phase: bool = _joined._phase == GymMatch.Phase.SERVE_PREP or (_joined._phase == GymMatch.Phase.LIVE and not _joined._serve_done)
		camera_rig.serve_view = my_serve and serving_phase
		if Input.is_action_pressed("stats"):


			if _net != null and not _net.is_host:
				_net.request_stats()
				hud.show_stats(_net.net_stat_rows)
			else:
				hud.show_stats(_joined.stat_rows())
		elif Input.is_action_just_released("stats"):
			hud.hide_stats()
	else:
		camera_rig.serve_view = false
		hud.set_touches(0)
		hud.set_sweat(0.0)
		barred_marker.visible = false
		if _joined != null:
			_joined.ball.landing_ring_muted = false
		if _queued != null:
			hud.set_serve_prompt("joining the %s when the rally ends..." % _queued.label)
		elif _practice_serving:
			hud.set_serve_prompt("hold lmb to charge the toss & release to throw")
		elif _on_practice:
			hud.set_serve_prompt("practice court: press r to take a ball in hand")
		else:
			hud.set_serve_prompt("stand on a green pad to join a match")
	hud.set_scoreboard_visible(_joined != null)
