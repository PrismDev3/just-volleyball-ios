class_name StageCollision










const SKIP: = ["floor", "court", "glass", "cutter", "light", "exit"]












const SUPERELLIPSE_N: = 4.0
static func build_ring(parent: Node3D, extent: Vector3, segments: = 64) -> void :
	if parent == null or extent == Vector3.ZERO:
		return
	var hw: = extent.x
	var h: = extent.y
	var hl: = extent.z
	var t: = 0.6
	var body: = StaticBody3D.new()
	body.name = "CourtBarrier"



	body.collision_layer = 1
	parent.add_child(body)
	var prev: = _superellipse(0.0, hw, hl)
	for i in range(1, segments + 1):
		var cur: = _superellipse(TAU * float(i) / float(segments), hw, hl)
		var seg: = cur - prev
		var seg_len: = seg.length()
		if seg_len > 0.001:
			var cs: = CollisionShape3D.new()
			var box: = BoxShape3D.new()
			box.size = Vector3(seg_len + t, h, t)
			cs.shape = box
			var mid: = (prev + cur) * 0.5
			cs.position = Vector3(mid.x, h * 0.5, mid.y)


			cs.rotation.y = atan2( - seg.y, seg.x)
			body.add_child(cs)
		prev = cur

static func _superellipse(a: float, hw: float, hl: float) -> Vector2:
	var ca: = cos(a)
	var sa: = sin(a)
	var k: = 2.0 / SUPERELLIPSE_N
	return Vector2(pow(absf(ca), k) * signf(ca) * hw, pow(absf(sa), k) * signf(sa) * hl)

static func build_box(parent: Node3D, extent: Vector3) -> void :
	if parent == null or extent == Vector3.ZERO:
		return
	var hw: = extent.x
	var h: = extent.y
	var hl: = extent.z
	var t: = 0.5
	var body: = StaticBody3D.new()
	body.name = "CourtBarrier"
	body.collision_layer = 3
	parent.add_child(body)

	for w in [
		[Vector3(hw + t * 0.5, h * 0.5, 0.0), Vector3(t, h, hl * 2.0)], 
		[Vector3( - hw - t * 0.5, h * 0.5, 0.0), Vector3(t, h, hl * 2.0)], 
		[Vector3(0.0, h * 0.5, hl + t * 0.5), Vector3(hw * 2.0, h, t)], 
		[Vector3(0.0, h * 0.5, - hl - t * 0.5), Vector3(hw * 2.0, h, t)], 
	]:
		var cs: = CollisionShape3D.new()
		var box: = BoxShape3D.new()
		box.size = w[1]
		cs.shape = box
		cs.position = w[0]
		body.add_child(cs)

static func build(venue: Node) -> void :
	if venue == null:
		return
	for node in venue.find_children("*", "MeshInstance3D", true, false):
		var mi: = node as MeshInstance3D
		if mi == null or mi.mesh == null or not mi.visible:
			continue
		var low: = String(mi.name).to_lower()
		var skip: = false
		for s in SKIP:
			if low.contains(s):
				skip = true
				break
		if skip:
			continue

		if mi.find_children("*", "StaticBody3D", false, false).is_empty():
			mi.create_trimesh_collision()
