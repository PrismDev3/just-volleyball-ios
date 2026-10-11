class_name DrillRunner
extends Node

signal progress_changed(done: int, required: int)
signal instruction_changed(text: String)
signal feedback(text: String, positive: bool)
signal countdown_changed(text: String)
signal completed(id: String, elapsed_ms: int)

const DWELL: = 0.6
const COUNTDOWN: = 3.0

const MARKER_RED: = Color("ff4d4d")
const MARKER_YELLOW: = Color("ffd23d")
const MARKER_GREEN: = Color("46d160")
const COLUMN_ALPHA: = 0.75
const START: = Vector3(0.0, 0.0, 8.5)
const SPOTS: = [


	Vector3(-3.2, 0.0, 2.0), 
	Vector3(3.2, 0.0, 2.0), 
	Vector3(3.2, 0.0, 8.0), 
	Vector3(-3.2, 0.0, 8.0), 
	Vector3(0.0, 0.0, 5.0), 
]
const MARKER_COLORS: = [
	Color("ffd33d"), Color("3984ff"), Color("55dfa0"), 
	Color("ff6f91"), Color("a877ff"), Color("ff9f43"), 
]



const STRAFE_GAZE: = Vector3(0.0, 0.0, 2.6)
const STRAFE_GAZE_R: = 2.4
const STRAFE_SPOTS: = [
	Vector3(-3.2, 0.0, 7.4), 
	Vector3(3.2, 0.0, 7.4), 
	Vector3(-2.6, 0.0, 5.6), 
	Vector3(2.6, 0.0, 5.6), 
	Vector3(0.0, 0.0, 6.8), 
]









const JUMP_REPS: = [
	{"start": Vector3(-2.6, 0.0, 5.0), "target": Vector3(-2.6, 0.0, 2.0), "h": 3.3}, 
	{"start": Vector3(2.6, 0.0, 5.0), "target": Vector3(2.6, 0.0, 2.0), "h": 3.6}, 
	{"start": Vector3(0.0, 0.0, 5.6), "target": Vector3(0.0, 0.0, 1.9), "h": 4.3}, 
	{"start": Vector3(-1.4, 0.0, 5.2), "target": Vector3(-1.4, 0.0, 1.9), "h": 4.8}, 
]
const JUMP_START_R: = 0.85
const JUMP_ARM_LEASH: = 0.45

const JUMP_RING_H: = 2.2
const JUMP_RING_R: = 1.1


const OBJECTIVES: = {
	"serving_1": preload("res://game/drills/objectives/serve_objective.gd"), 
	"serving_2": preload("res://game/drills/objectives/serve_jump_objective.gd"), 
	"serving_3": preload("res://game/drills/objectives/serve_float_objective.gd"), 
	"receiving_1": preload("res://game/drills/objectives/receive_objective.gd"), 
	"receiving_2": preload("res://game/drills/objectives/receive_jump_objective.gd"), 
	"receiving_3": preload("res://game/drills/objectives/receive_float_objective.gd"), 
	"receiving_4": preload("res://game/drills/objectives/receive_mix_objective.gd"), 
	"spiking_1": preload("res://game/drills/objectives/spike_objective.gd"), 
	"spiking_2": preload("res://game/drills/objectives/spike_quick_objective.gd"), 
	"spiking_3": preload("res://game/drills/objectives/spike_any_objective.gd"), 
	"curving": preload("res://game/drills/objectives/curve_objective.gd"), 
	"setting_1": preload("res://game/drills/objectives/set_objective.gd"), 
	"setting_2": preload("res://game/drills/objectives/set_quick_objective.gd"), 
	"setting_3": preload("res://game/drills/objectives/set_any_objective.gd"), 
	"blocking_1": preload("res://game/drills/objectives/block_objective.gd"), 
	"blocking_2": preload("res://game/drills/objectives/block_timing_objective.gd"), 
	"blocking_3": preload("res://game/drills/objectives/block_read_objective.gd"), 

	"tutorial_jump": preload("res://game/drills/objectives/tutorial_jump_objective.gd"), 
	"tutorial_block": preload("res://game/drills/objectives/tutorial_block_objective.gd"), 
	"tutorial_dive": preload("res://game/drills/objectives/tutorial_dive_objective.gd"), 
	"tutorial_spike": preload("res://game/drills/objectives/tutorial_spike_objective.gd"), 
	"tutorial_set": preload("res://game/drills/objectives/tutorial_set_objective.gd"), 
	"tutorial_camera": preload("res://game/drills/objectives/tutorial_camera_objective.gd"), 
	"tutorial_rally": preload("res://game/drills/objectives/tutorial_rally_objective.gd"), 
}

var player: Player = null
var ball: Ball = null
var cam_rig = null
var drill_id: = ""
var active: = false
var finished: = false
var index: = 0
var dwell: = 0.0
var elapsed: = 0.0
var clock_started: = false
var countdown: = 0.0
var go_time: = 0.0
var epoch: = 0
var objective: DrillObjective = null
var sfx = null

var _ball_side: = 0.0
var _last_strike: = -1
var _markers: Array[Node3D] = []
var _gaze_marker: Node3D = null
var _strafe_mate: Player = null
var _jump_pads: Array[Node3D] = []
var _jump_targets: Array[Node3D] = []
var _jump_phase: = 0
var _jump_prev_grounded: = true
var _jump_armed: = false
var _jump_arm_leash: = 0.0
var _gaze_pulse: = 0.0

func setup(body: Player, drill_ball: Ball) -> void :
	player = body
	ball = drill_ball


	if not player.touched.is_connected(_on_touched):
		player.touched.connect(_on_touched)
		ball.bounced.connect(_on_bounced)
		ball.net_hit.connect(_on_net_hit)
		ball.wall_hit.connect(_on_wall_hit)



func start(id: String, instant: = false) -> void :
	cancel()
	drill_id = id
	active = true
	finished = false
	index = 0
	dwell = 0.0
	elapsed = 0.0
	clock_started = false
	countdown = COUNTDOWN
	go_time = 0.0
	epoch += 1
	_ball_side = 0.0
	_last_strike = ball.strike_seq
	_reset_actor()
	if OBJECTIVES.has(id):
		objective = (OBJECTIVES[id] as GDScript).new()
		objective.begin(self)
		progress_changed.emit(0, objective.required)
	elif id == "strafing":
		_build_strafe_markers()
		progress_changed.emit(0, STRAFE_SPOTS.size())
	elif id == "jumping":
		_jump_phase = 0
		_jump_prev_grounded = true
		_jump_armed = false
		_build_jump_markers()
		progress_changed.emit(0, JUMP_REPS.size())
	else:
		_build_markers()
		progress_changed.emit(0, SPOTS.size())
	if instant:
		countdown = 0.0
		go_time = 0.05
		return
	instruction_changed.emit("get ready")
	countdown_changed.emit("3")

func retry() -> void :
	start(drill_id)

func cancel() -> void :
	active = false
	finished = false
	if objective != null:
		objective.cancel()
		objective = null
	for marker in _markers:
		if is_instance_valid(marker):
			marker.queue_free()
	_markers.clear()
	if is_instance_valid(_strafe_mate):
		_strafe_mate.queue_free()
	_strafe_mate = null
	_gaze_marker = null
	_jump_pads.clear()
	_jump_targets.clear()
	_fades.clear()

func physics_tick(delta: float, paused: = false) -> void :
	if objective != null:


		objective.actors_tick(delta)
	_fade_tick(delta)
	if not active or finished or paused or player == null:
		return
	if countdown > 0.0:
		var before: = ceili(countdown)
		countdown = maxf(0.0, countdown - delta)
		var after: = ceili(countdown)
		if after != before:
			countdown_changed.emit("go" if after <= 0 else str(after))
			if after <= 0:
				go_time = 0.45
		if countdown > 0.0:
			return
		return
	if go_time > 0.0:
		go_time = maxf(0.0, go_time - delta)
		if go_time <= 0.0:
			countdown_changed.emit("")
			if objective != null:
				objective.on_go()
			elif drill_id == "strafing":
				instruction_changed.emit("hold strafe and move into the marker")
			elif drill_id == "jumping":
				instruction_changed.emit("start on the pad, then jump through the ring")
			else:
				instruction_changed.emit("move into the marker")
		return
	if objective != null:
		if clock_started:
			elapsed += delta
		_poll_crossing()
		if objective != null:
			objective.tick(delta)
		return
	if drill_id == "strafing":
		_strafe_tick(delta)
		return
	if drill_id == "jumping":
		_jump_tick(delta)
		return
	if index >= SPOTS.size():
		return
	var speed: = Vector2(player.velocity.x, player.velocity.z).length()
	if not clock_started and speed > 0.2:
		clock_started = true
	if clock_started:
		elapsed += delta
	var flat: = Vector2(player.global_position.x - SPOTS[index].x, 
		player.global_position.z - SPOTS[index].z)


	if flat.length() <= 0.72 and player.grounded()\
	and not player.knocked() and not player.diving():
		dwell += delta
		_drive_marker(dwell / DWELL)
		instruction_changed.emit("just stay there")
		if dwell >= DWELL:
			_fade_out(_markers[index])
			index += 1
			dwell = 0.0
			progress_changed.emit(index, SPOTS.size())
			if index >= SPOTS.size():
				finished = true
				active = false
				completed.emit(drill_id, maxi(1, int(elapsed * 1000.0)))
			else:
				_markers[index].visible = true
				instruction_changed.emit("move into the next marker")
	else:
		dwell = 0.0
		_drive_marker(0.0)
		instruction_changed.emit("move into the marker")




func _strafe_tick(delta: float) -> void :
	if is_instance_valid(_strafe_mate):
		_strafe_mate.puppet_tick(delta)

	if is_instance_valid(_gaze_marker):
		var ret: = _gaze_marker.get_node_or_null("reticle") as Sprite3D
		if ret != null:
			_gaze_pulse += delta
			ret.scale = Vector3.ONE * (1.0 + 0.14 * sin(_gaze_pulse * 4.0))
	if index >= STRAFE_SPOTS.size():
		return
	var speed: = Vector2(player.velocity.x, player.velocity.z).length()
	if not clock_started and speed > 0.2:
		clock_started = true
	if clock_started:
		elapsed += delta
	var spot: Vector3 = STRAFE_SPOTS[index]
	var flat: = Vector2(player.global_position.x - spot.x, player.global_position.z - spot.z)
	var at_marker: = flat.length() <= 0.72 and player.grounded()\
	and not player.knocked() and not player.diving()
	var strafing: = player.is_strafing()
	var aim_flat: = Vector2(player.aim_point.x - STRAFE_GAZE.x, player.aim_point.z - STRAFE_GAZE.z)
	var aim_ok: = aim_flat.length() <= STRAFE_GAZE_R
	if at_marker and strafing and aim_ok:
		dwell += delta
		_drive_marker(dwell / DWELL)
		instruction_changed.emit("stay there")
		if dwell >= DWELL:
			_fade_out(_markers[index])
			index += 1
			dwell = 0.0
			progress_changed.emit(index, STRAFE_SPOTS.size())
			if index >= STRAFE_SPOTS.size():
				finished = true
				active = false
				if is_instance_valid(_gaze_marker):
					_fade_out(_gaze_marker)
				completed.emit(drill_id, maxi(1, int(elapsed * 1000.0)))
			else:
				_markers[index].visible = true
				instruction_changed.emit("keep your cursor on your teammate")
	else:
		dwell = 0.0
		_drive_marker(0.0)
		if not strafing:
			instruction_changed.emit("hold strafe")
		elif not aim_ok:
			instruction_changed.emit("keep your cursor on your teammate")
		else:
			instruction_changed.emit("strafe into the marker")




func _jump_tick(delta: float) -> void :
	if index >= JUMP_REPS.size():
		return
	var rep: Dictionary = JUMP_REPS[index]
	var start_v: Vector3 = rep.start
	var target_v: Vector3 = rep.target
	var grounded: = player.grounded()
	var in_start: = Vector2(player.global_position.x - start_v.x, 
		player.global_position.z - start_v.z).length() <= JUMP_START_R
	if clock_started:
		elapsed += delta
	var took_off: = _jump_prev_grounded and not grounded
	var landed: = not _jump_prev_grounded and grounded
	if _jump_phase == 0:





		if grounded and in_start:
			_jump_armed = true
			_jump_arm_leash = JUMP_ARM_LEASH
		elif _jump_armed and grounded:
			_jump_arm_leash -= delta
			if _jump_arm_leash <= 0.0:
				_jump_armed = false
		if grounded:
			instruction_changed.emit("jump through the ring" if _jump_armed else "stand on the pad")
			_tint_marker(_jump_pads[index], MARKER_GREEN if _jump_armed else MARKER_RED)
		if took_off and _jump_armed:
			_jump_phase = 1
			clock_started = true
			instruction_changed.emit("through the ring!")
	elif _jump_phase == 1:


		var centre: Vector3 = _jump_targets[index].global_position
		var passed: = false


		for h in [0.9, 1.5, 2.1]:
			if (player.global_position + Vector3.UP * h).distance_to(centre) <= JUMP_RING_R:
				passed = true
				break
		if passed:
			_tint_marker(_jump_targets[index], MARKER_GREEN)
			_fade_out(_jump_targets[index])
			_fade_out(_jump_pads[index])
			index += 1
			_jump_phase = 0
			_jump_armed = false
			progress_changed.emit(index, JUMP_REPS.size())
			if index >= JUMP_REPS.size():
				finished = true
				active = false
				completed.emit(drill_id, maxi(1, int(elapsed * 1000.0)))
			else:
				_jump_pads[index].visible = true
				_jump_targets[index].visible = true
				instruction_changed.emit("stand on the pad")
		elif landed:
			_jump_phase = 0
			_jump_armed = false
			instruction_changed.emit("missed...")
	_jump_prev_grounded = grounded

func _build_jump_markers() -> void :
	_jump_pads.clear()
	_jump_targets.clear()
	for i in JUMP_REPS.size():

		var pad: = add_column_marker(JUMP_REPS[i].start, 0.7)
		pad.visible = i == 0
		_jump_pads.append(pad)
		var dir: Vector3 = (JUMP_REPS[i].target - JUMP_REPS[i].start)
		var hoop: = add_ring_hoop(JUMP_REPS[i].target, dir, 
			float(JUMP_REPS[i].get("h", JUMP_RING_H)))
		hoop.visible = i == 0
		_jump_targets.append(hoop)

const RING_GLOW_SHADER: = preload("res://game/fx/ring_glow.gdshader")





func add_ring_hoop(pos: Vector3, dir: Vector3, height: = JUMP_RING_H) -> Node3D:
	var marker: = Node3D.new()
	get_parent().add_child(marker)
	marker.global_position = pos + Vector3.UP * height


	var up: = dir
	up.y = 0.0
	up = up.normalized() if up.length() > 0.01 else Vector3.FORWARD
	var right: = up.cross(Vector3.UP)
	right = right.normalized() if right.length() > 0.01 else Vector3.RIGHT
	var fwd: = right.cross(up).normalized()
	marker.transform.basis = Basis(right, up, fwd)
	var mesh: = TorusMesh.new()
	mesh.inner_radius = JUMP_RING_R
	mesh.outer_radius = JUMP_RING_R + 0.28
	mesh.rings = 40
	mesh.ring_segments = 18
	var torus: = MeshInstance3D.new()
	torus.name = "torus"
	var mat: = ShaderMaterial.new()
	mat.shader = RING_GLOW_SHADER
	mat.render_priority = 2
	torus.mesh = mesh
	torus.material_override = mat
	torus.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.add_child(torus)
	_markers.append(marker)
	_tint_marker(marker, MARKER_RED)
	return marker

func _build_strafe_markers() -> void :
	for i in STRAFE_SPOTS.size():
		var marker: = add_column_marker(STRAFE_SPOTS[i], 0.7)
		marker.visible = i == 0



	_strafe_mate = DrillObjective.make_puppet(get_parent(), STRAFE_GAZE, 1, randi() % 4096)
	_gaze_marker = _arrow_over(STRAFE_GAZE + Vector3(0, 2.5, 0), Color("22d3ee"))
	_gaze_marker.visible = true

const GAZE_ICON: = preload("res://game/ui_icon/Game Icons/PNG/White/2x/target.png")



const WAYPOINT_ARROW: = preload("res://game/fx/waypoint_arrow.gdshader")


func _arrow_over(pos: Vector3, color: Color) -> Node3D:
	var m: = MeshInstance3D.new()
	get_parent().add_child(m)
	var quad: = QuadMesh.new()
	quad.size = Vector2(0.62, 0.88)
	var mat: = ShaderMaterial.new()
	mat.shader = WAYPOINT_ARROW
	mat.render_priority = 12
	mat.set_shader_parameter("tint", Color(color.r, color.g, color.b, 1.0))
	mat.set_shader_parameter("edge", Color(color.r, color.g, color.b, 0.94).darkened(0.88))
	quad.material = mat
	m.mesh = quad
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.global_position = pos
	_markers.append(m)
	return m

func add_gaze_target(pos: Vector3, color: Color) -> Node3D:
	var marker: = Node3D.new()
	get_parent().add_child(marker)
	marker.global_position = pos
	var spr: = Sprite3D.new()
	spr.name = "reticle"
	spr.texture = GAZE_ICON
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.shaded = false
	spr.no_depth_test = true
	spr.render_priority = 12
	spr.modulate = color
	spr.pixel_size = 0.009
	spr.position = Vector3(0.0, 1.35, 0.0)
	marker.add_child(spr)

	var ring: = MeshInstance3D.new()
	ring.name = "ring"
	var plane: = PlaneMesh.new()
	plane.size = Vector2.ONE * (0.4 / 0.31)
	var rmat: = ShaderMaterial.new()
	rmat.shader = RING_SHADER
	rmat.render_priority = 11
	rmat.set_shader_parameter("ring_radius", 0.62)
	rmat.set_shader_parameter("ring_width", 0.08)
	rmat.set_shader_parameter("outline", 0.05)
	rmat.set_shader_parameter("dot_radius", 0.28)
	rmat.set_shader_parameter("arrow_len", 0.0)
	rmat.set_shader_parameter("arrow_base", 0.6)
	rmat.set_shader_parameter("arrow_half", 0.17)
	rmat.set_shader_parameter("pulse", 0.0)
	rmat.set_shader_parameter("tint", Color(color.r, color.g, color.b, 1.0))
	rmat.set_shader_parameter("edge", Color(color.r, color.g, color.b, 0.94).darkened(0.88))
	plane.material = rmat
	ring.mesh = plane
	ring.position = Vector3(0.0, 0.02, 0.0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.add_child(ring)
	_markers.append(marker)
	return marker

func counting_down() -> bool:
	return active and (countdown > 0.0 or go_time > 0.0)



func touch_allowed() -> bool:
	return active and not finished and objective != null and not counting_down()

func start_clock() -> void :
	clock_started = true



func serve_wanted() -> bool:
	return objective != null and active and not finished and not counting_down() and objective.wants_serve()

func serve_tossed() -> void :
	if objective != null:
		objective.serve_tossed()

func objective_progress(done: int, required: int) -> void :
	progress_changed.emit(done, required)

func objective_say(text: String) -> void :
	instruction_changed.emit(text)

func objective_feedback(text: String, positive: bool) -> void :
	feedback.emit(text, positive)

func objective_complete() -> void :
	if finished or not active:
		return
	finished = true
	active = false
	completed.emit(drill_id, maxi(1, int(elapsed * 1000.0)))

func _poll_crossing() -> void :
	if ball.frozen:
		_ball_side = 0.0
		return
	var res: = Rules.net_crossing(ball.global_position.z, _ball_side)
	_ball_side = float(res.side)
	if bool(res.crossed):
		objective.on_cross()

func _objective_listening() -> bool:
	return objective != null and active and not finished and not counting_down()

func _on_touched(kind: int) -> void :
	if not _objective_listening():
		return


	if ball.strike_seq == _last_strike:
		return
	_last_strike = ball.strike_seq
	objective.on_touch(kind)

func _on_bounced() -> void :


	if _objective_listening():
		objective.on_bounce(ball.global_position)

func _on_net_hit() -> void :
	if _objective_listening():
		objective.on_net()

func _on_wall_hit() -> void :
	if _objective_listening():
		objective.on_wall()




const FADE_TIME: = 0.3

var _fades: Array[Dictionary] = []

func _fade_out(marker: Node3D) -> void :


	var mats: Array = []
	for part in ["ring", "column", "arrow"]:
		var mi: = marker.get_node_or_null(part) as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var mat: = (mi.mesh as PrimitiveMesh).material as ShaderMaterial
		if mat == null:
			continue
		var tint: Color = mat.get_shader_parameter("tint")
		var edge_v: Variant = mat.get_shader_parameter("edge")
		var e0: float = (edge_v as Color).a if edge_v != null else 0.0
		mats.append({"mat": mat, "a0": tint.a, "e0": e0})

	var torus: = marker.get_node_or_null("torus") as MeshInstance3D
	if torus != null and torus.material_override is ShaderMaterial:
		var tm: = torus.material_override as ShaderMaterial
		var tint: Color = tm.get_shader_parameter("tint")
		var edge_v: Variant = tm.get_shader_parameter("edge")
		var e0: float = (edge_v as Color).a if edge_v != null else 0.0
		mats.append({"mat": tm, "a0": tint.a, "e0": e0})
	_fades.append({"node": marker, "mats": mats, "t": 0.0})

func _fade_tick(delta: float) -> void :
	for entry in _fades.duplicate():
		var node: Node3D = entry.node
		if not is_instance_valid(node):
			_fades.erase(entry)
			continue
		entry.t = minf(float(entry.t) + delta / FADE_TIME, 1.0)
		var t: float = entry.t
		node.scale = Vector3.ONE * lerpf(1.12, 1.7, t)
		for m in entry.mats:
			if m.has("std"):
				var sm: = m.std as StandardMaterial3D
				sm.albedo_color.a = float(m.a0) * (1.0 - t)
				continue
			var mat: = m.mat as ShaderMaterial
			if mat == null:
				continue
			var tint: Color = mat.get_shader_parameter("tint")
			tint.a = float(m.a0) * (1.0 - t)
			mat.set_shader_parameter("tint", tint)
			if float(m.e0) > 0.0:
				var edge: Color = mat.get_shader_parameter("edge")
				edge.a = float(m.e0) * (1.0 - t)
				mat.set_shader_parameter("edge", edge)
		if t >= 1.0:
			node.visible = false
			_fades.erase(entry)

func _drive_marker(fill: float) -> void :
	if index >= _markers.size():
		return
	var marker: = _markers[index]
	var amount: = clampf(fill, 0.0, 1.0)
	marker.scale = Vector3.ONE * lerpf(1.0, 1.12, amount)


	_tint_marker(marker, _dwell_color(amount))
	var ring: = marker.get_node_or_null("ring") as MeshInstance3D
	if ring != null:
		var mat: = (ring.mesh as PlaneMesh).material as ShaderMaterial
		mat.set_shader_parameter("dot_radius", lerpf(0.115, 0.5, amount))

func _reset_actor() -> void :
	player.clear_action_state()
	player.global_position = START
	player.velocity = Vector3.ZERO
	player.team_side = 1



	player.face_net()
	player.reset_physics_interpolation()
	ball.frozen = true
	ball.vel = Vector3.ZERO
	ball.global_position = Vector3(0.0, -4.0, 0.0)
	ball.reset_physics_interpolation()

func _build_markers() -> void :
	for i in SPOTS.size():
		var marker: = add_column_marker(SPOTS[i], 0.7)
		marker.visible = i == 0

const RING_SHADER: = preload("res://game/fx/floor_ring.gdshader")



const ARROW_SHADER: = preload("res://game/fx/waypoint_arrow.gdshader")
const COLUMN_SHADER: = preload("res://game/fx/land_column.gdshader")





func add_column_marker(pos: Vector3, radius: float, color: = MARKER_RED) -> Node3D:
	var marker: = Node3D.new()
	get_parent().add_child(marker)
	marker.global_position = pos + Vector3.UP * 0.02



	var column: = MeshInstance3D.new()
	column.name = "column"
	var cyl: = CylinderMesh.new()
	cyl.top_radius = radius * 0.82
	cyl.bottom_radius = radius * 0.82
	cyl.height = 1.0
	cyl.cap_top = false
	cyl.cap_bottom = false
	cyl.radial_segments = 24
	cyl.rings = 1
	var cmat: = ShaderMaterial.new()
	cmat.shader = COLUMN_SHADER
	cmat.render_priority = 2
	cmat.set_shader_parameter("body_alpha", 0.85)
	cmat.set_shader_parameter("top_fade", 0.85)
	cyl.material = cmat
	column.mesh = cyl
	column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	column.position = Vector3(0.0, 0.75, 0.0)
	column.scale = Vector3(1.0, 1.5, 1.0)
	marker.add_child(column)

	var arrow: = MeshInstance3D.new()
	arrow.name = "arrow"
	var quad: = QuadMesh.new()
	quad.size = Vector2(0.62, 0.9)
	var amat: = ShaderMaterial.new()
	amat.shader = ARROW_SHADER
	amat.render_priority = 3
	quad.material = amat
	arrow.mesh = quad
	arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arrow.position = Vector3(0.0, 1.75, 0.0)
	marker.add_child(arrow)
	_markers.append(marker)
	_tint_marker(marker, color)
	return marker


func _tint_marker(marker: Node3D, col: Color) -> void :
	var ring: = marker.get_node_or_null("ring") as MeshInstance3D
	if ring != null:
		var m: = (ring.mesh as PlaneMesh).material as ShaderMaterial
		m.set_shader_parameter("tint", Color(col.r, col.g, col.b, 1.0))
		m.set_shader_parameter("edge", Color(col.r, col.g, col.b, 0.94).darkened(0.88))
	var column: = marker.get_node_or_null("column") as MeshInstance3D
	if column != null:
		var m: = (column.mesh as CylinderMesh).material as ShaderMaterial
		m.set_shader_parameter("tint", Color(col.r, col.g, col.b, COLUMN_ALPHA))
		m.set_shader_parameter("edge", Color(col.r, col.g, col.b, 0.94).darkened(0.85))
	var arrow: = marker.get_node_or_null("arrow") as MeshInstance3D
	if arrow != null:
		var m: = (arrow.mesh as QuadMesh).material as ShaderMaterial
		m.set_shader_parameter("tint", Color(col.r, col.g, col.b, 1.0))
		m.set_shader_parameter("edge", Color(col.r, col.g, col.b, 0.94).darkened(0.88))
	var torus: = marker.get_node_or_null("torus") as MeshInstance3D
	if torus != null and torus.material_override is ShaderMaterial:
		var tm: = torus.material_override as ShaderMaterial
		tm.set_shader_parameter("tint", Color(col.r, col.g, col.b, COLUMN_ALPHA))
		tm.set_shader_parameter("edge", Color(col.r, col.g, col.b, 0.94).darkened(0.85))


func _dwell_color(fill: float) -> Color:
	var f: = clampf(fill, 0.0, 1.0)
	if f < 0.5:
		return MARKER_RED.lerp(MARKER_YELLOW, f * 2.0)
	return MARKER_YELLOW.lerp(MARKER_GREEN, (f - 0.5) * 2.0)






func add_ring(pos: Vector3, radius: float, color: Color) -> Node3D:
	var marker: = Node3D.new()
	get_parent().add_child(marker)
	marker.global_position = pos + Vector3.UP * 0.02
	var ring: = MeshInstance3D.new()
	ring.name = "ring"
	var plane: = PlaneMesh.new()


	plane.size = Vector2.ONE * (radius / 0.31)
	var mat: = ShaderMaterial.new()
	mat.shader = RING_SHADER
	mat.render_priority = 11
	mat.set_shader_parameter("ring_radius", 0.62)
	mat.set_shader_parameter("ring_width", 0.075)
	mat.set_shader_parameter("outline", 0.05)
	mat.set_shader_parameter("dot_radius", 0.115)
	mat.set_shader_parameter("arrow_len", 0.0)
	mat.set_shader_parameter("arrow_base", 0.6)
	mat.set_shader_parameter("arrow_half", 0.17)
	mat.set_shader_parameter("pulse", 0.0)
	mat.set_shader_parameter("tint", Color(color.r, color.g, color.b, 1.0))
	mat.set_shader_parameter("edge", 
		Color(color.r, color.g, color.b, 0.94).darkened(0.88))
	plane.material = mat
	ring.mesh = plane
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.add_child(ring)
	var arrow: = MeshInstance3D.new()
	arrow.name = "arrow"
	var quad: = QuadMesh.new()
	quad.size = Vector2(0.62, 0.9)
	var arrow_mat: = ShaderMaterial.new()
	arrow_mat.shader = ARROW_SHADER
	arrow_mat.render_priority = 11
	arrow_mat.set_shader_parameter("tint", Color(color.r, color.g, color.b, 1.0))
	arrow_mat.set_shader_parameter("edge", 
		Color(color.r, color.g, color.b, 0.94).darkened(0.88))
	quad.material = arrow_mat
	arrow.mesh = quad
	arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arrow.position = Vector3(0.0, 1.25, 0.0)
	marker.add_child(arrow)
	_markers.append(marker)
	return marker
