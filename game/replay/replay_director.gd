class_name ReplayDirector
extends RefCounted








var data: ReplayData = null
var bodies: Array = []
var ball: Node3D = null

var time: = 0.0
var speed: = 1.0
var playing: = true
var sweat: = 0.0



var clip_start: = 0.0

func setup(d: ReplayData, body_list: Array, ball_node: Node3D) -> void :
	data = d
	bodies = body_list
	ball = ball_node
	time = d.time_at(0) if d != null else 0.0
	clip_start = time

func seek_clip(from: float) -> void :
	seek(from)
	clip_start = time

func elapsed() -> float:
	return time - clip_start

func duration() -> float:
	return data.duration() if data != null else 0.0

func start_time() -> float:
	return data.time_at(0) if data != null else 0.0

func end_time() -> float:
	if data == null or data.frame_count() == 0:
		return 0.0
	return data.time_at(data.frame_count() - 1)

func advance(delta: float) -> void :
	if playing:
		time = minf(time + delta * speed, end_time())

func finished() -> bool:
	return time >= end_time() - 0.0001

func seek(t: float) -> void :
	time = clampf(t, start_time(), end_time())

func apply(snap: = false) -> void :

	if data == null or data.frame_count() == 0:
		return
	var i: = data.index_before(time)
	if i < 0:
		return
	var j: int = mini(i + 1, data.frame_count() - 1)
	var t0: = data.time_at(i)
	var t1: = data.time_at(j)
	var f: = 0.0 if j == i or t1 <= t0 else clampf((time - t0) / (t1 - t0), 0.0, 1.0)

	sweat = lerpf(data.sweat_at(i), data.sweat_at(j), f)

	var b0: = data.ball_at(i)
	var b1: = data.ball_at(j)
	if ball != null:
		ball.global_position = Vector3(
			lerpf(b0[0], b1[0], f), lerpf(b0[1], b1[1], f), lerpf(b0[2], b1[2], f))
		ball.vel = Vector3(b0[3], b0[4], b0[5])




		ball.net_puppet = true
		ball.frozen = b0[6] > 0.5


		ball.float_serve = b0[6] < -0.5
		ball.curve = b0[7]
		ball.visible = true

	for slot in mini(bodies.size(), data.slots.size()):
		var body: Player = bodies[slot]
		if body == null:
			continue
		var a0: = data.player_at(i, slot)
		var a1: = data.player_at(j, slot)
		var pos: = Vector3(
			lerpf(a0[0], a1[0], f), lerpf(a0[1], a1[1], f), lerpf(a0[2], a1[2], f))

		var rot: = a0[6] + wrapf(a1[6] - a0[6], - PI, PI) * f
		var blended: = a0.duplicate()
		blended[6] = rot



		var anim_i: = ReplayData.NET_PLAYER_FLOATS
		blended[anim_i] = a0[anim_i]\
		+ wrapf(a1[anim_i] - a0[anim_i], -0.5, 0.5) * f
		body.replay_apply(blended, pos, snap)

func pose_tick(delta: float) -> void :

	for b in bodies:
		if b != null:
			(b as Player).puppet_tick(delta)

func seek_anims(at: float) -> void :






	if data == null or data.frame_count() == 0:
		return
	var i: = data.index_before(at)
	if i < 0:
		return
	var j: int = mini(i + 1, data.frame_count() - 1)
	var t0: = data.time_at(i)
	var t1: = data.time_at(j)
	var f: = 0.0 if j == i or t1 <= t0 else clampf((at - t0) / (t1 - t0), 0.0, 1.0)
	var anim_i: = ReplayData.NET_PLAYER_FLOATS
	for slot in mini(bodies.size(), data.slots.size()):
		var body: Player = bodies[slot]
		if body == null:
			continue
		var a0: = data.player_at(i, slot)
		var a1: = data.player_at(j, slot)
		if a0.size() <= anim_i:
			continue
		var pv: = a0[anim_i] + wrapf(a1[anim_i] - a0[anim_i], -0.5, 0.5) * f
		body.seek_replay_anim(pv)
