extends "res://game/drills/objectives/block_objective.gd"





const TEAMMATE_2V2: = Vector3(-2.4, 0.0, 7.4)



const HOP_TIMINGS: = [0.42, 0.66, 0.52]

func _begin() -> void :
	required = 3
	hop_early = HOP_TIMINGS[0]
	setter = spawn_actor(SETTER_SPOT, -1, randi() % 4096)
	for i in _lanes_used():
		hitters.append(spawn_actor(LANES[i].home, -1, randi() % 4096))
	spawn_actor(TEAMMATE_2V2, 1, randi() % 4096)
	player.global_position = PLAYER_START
	player.face_net()
	player.reset_physics_interpolation()

func _launch() -> void :
	hop_early = HOP_TIMINGS[done % HOP_TIMINGS.size()]
	play = PASS
	blocked = false
	hitter_reset()
	lane = _pick_lane()
	for i in hitters.size():
		var h: = hitters[i]
		h.global_position = LANES[_lanes_used()[i]].home
		actor_face(h, h.global_position + Vector3(0.0, 0.0, 3.0))
	actor_face(setter, FEED_FROM)
	feed_ball(FEED_FROM, actor_hands(setter), 1.6)
	runner.objective_say(_instruction())
