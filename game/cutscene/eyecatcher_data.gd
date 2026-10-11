class_name EyeCatcherData
extends RefCounted










const NEAR: = Vector3(1.4, 0.0, 4.6)
const FAR: = Vector3(-1.0, 0.0, -4.6)


const FACE_NET_NEAR: = PI
const FACE_NET_FAR: = 0.0

static func solo() -> Array:
	return [
		{
			"name": "bump", 
			"duration": 4.2, 
			"roles": [{"spot": NEAR, "yaw": FACE_NET_NEAR, "clip": "receive"}], 
			"ball_from": NEAR + Vector3(0.0, 1.3, -0.3), 
			"ball_to": FAR + Vector3(0.0, 1.5, 0.3), 
			"ball_arc": 2.8, "ball_period": 1.35, 
		}, 
		{
			"name": "serve", 
			"duration": 4.4, 
			"roles": [{"spot": NEAR + Vector3(0.0, 0.0, 1.4), "yaw": FACE_NET_NEAR, "clip": "serve"}], 
			"ball_from": NEAR + Vector3(0.0, 1.2, 1.2), 
			"ball_to": FAR + Vector3(0.0, 1.6, 0.0), 
			"ball_arc": 3.2, "ball_period": 1.6, 
		}, 
	]

static func pair() -> Array:
	return [
		{
			"name": "rally", 
			"duration": 4.6, 
			"roles": [
				{"spot": NEAR, "yaw": FACE_NET_NEAR, "clip": "spike"}, 
				{"spot": FAR, "yaw": FACE_NET_FAR, "clip": "receive"}, 
			], 
			"ball_from": NEAR + Vector3(0.0, 1.6, -0.3), 
			"ball_to": FAR + Vector3(0.0, 1.4, 0.3), 
			"ball_arc": 2.9, "ball_period": 1.25, 
		}, 
	]



static func resolve(cast: Array, rng: RandomNumberGenerator) -> Dictionary:
	var pool: = pair() if cast.size() >= 2 else solo()
	var tmpl: Dictionary = (pool[rng.randi() % pool.size()] as Dictionary).duplicate(true)
	var roles: Array = tmpl["roles"]
	for i in roles.size():
		var who: Dictionary = cast[i] if i < cast.size() else cast[0]
		roles[i]["cfg"] = who.get("cfg")
		roles[i]["kit"] = who.get("kit", [])
	return tmpl
