class_name StateCodec















const SCALE: = 100.0
const Q_MAX: = 327.67


const F_BALL: = 1
const F_BODIES: = 2
const F_CLOCKS: = 4

static func _q(v: float) -> int:
	return int(roundf(clampf(v, - Q_MAX, Q_MAX) * SCALE))

static func encode_snapshot(d: Dictionary) -> PackedByteArray:
	var buf: = StreamPeerBuffer.new()
	buf.big_endian = false
	var flags: = 0
	if d.has("b"):
		flags |= F_BALL
	if d.has("p"):
		flags |= F_BODIES
	if d.has("sc"):
		flags |= F_CLOCKS
	buf.put_u8(1)
	buf.put_u8(flags)
	buf.put_u8(int(d.get("ph", 0)))
	buf.put_u8(int(d.get("s1", 0)))
	buf.put_u8(int(d.get("s2", 0)))
	buf.put_u8(int(d.get("w1", 0)))
	buf.put_u8(int(d.get("w2", 0)))
	buf.put_u8(int(d.get("sn", 1)))
	buf.put_u32(int(d.get("sq", 0)))
	if flags & F_CLOCKS:
		buf.put_16(_q(float(d.get("sc", 0.0))))
		buf.put_16(_q(float(d.get("rt", 0.0))))
		buf.put_u8(int(d.get("tc", 0)))
		buf.put_u16(int(d.get("sv", 0)))
		buf.put_u16(int(d.get("lt", 0)))
		buf.put_u8(1 if bool(d.get("sd", false)) else 0)
	if flags & F_BALL:
		var b: PackedFloat32Array = d.b
		for i in 8:
			buf.put_16(_q(b[i]))
		buf.put_u32(int(b[8]))
	if flags & F_BODIES:
		var p: PackedFloat32Array = d.p
		var count: = p.size() / ReplayData.NET_PLAYER_FLOATS
		buf.put_u8(count)
		for i in p.size():



			if i % ReplayData.NET_PLAYER_FLOATS == 11 or i % ReplayData.NET_PLAYER_FLOATS == 24:
				buf.put_u32(int(p[i]))
			else:
				buf.put_16(_q(p[i]))
	var acks: Dictionary = d.get("ack", {})
	buf.put_u8(acks.size())
	for id in acks:
		buf.put_u32(int(id))
		buf.put_u32(int(acks[id]))
	return buf.data_array







static func encode_gym(d: Dictionary) -> PackedByteArray:
	var buf: = StreamPeerBuffer.new()
	buf.big_endian = false
	buf.put_u8(5)
	buf.put_u32(int(d.get("sq", 0)))
	buf.put_u8(int(d.get("grp", 0)))
	var bodies: Array = d.get("bodies", [])
	buf.put_u8(bodies.size())
	for pair in bodies:
		buf.put_u16(int(pair[0]))
		var st: PackedFloat32Array = pair[1]
		for i in st.size():
			if i == 11 or i == 24:
				buf.put_u32(int(st[i]))
			else:
				buf.put_16(_q(st[i]))
	var balls: Array = d.get("balls", [])
	buf.put_u8(balls.size())
	for pair in balls:
		buf.put_u8(int(pair[0]))
		var b: PackedFloat32Array = pair[1]
		for i in 8:
			buf.put_16(_q(b[i]))


		buf.put_u32(int(b[8]) if b.size() > 8 else 0)
	var courts: Array = d.get("courts", [])
	buf.put_u8(courts.size())
	for row in courts:
		buf.put_u8(int(row[0]))
		buf.put_u8(int(row[1]))
		buf.put_u8(int(row[2]))
		buf.put_u8(int(row[3]))


		var members: Array = row[4] if row.size() > 4 else []
		buf.put_u8(members.size())
		for pair in members:
			buf.put_u16(int(pair[0]))
			buf.put_8(int(pair[1]))
		buf.put_u16(int(row[5]) if row.size() > 5 else 0)
		buf.put_u8(int(row[6]) if row.size() > 6 else 0)


		buf.put_u8(int(clampf(float(row[7]) if row.size() > 7 else 0.0, 
			0.0, 1.0) * 200.0))




		buf.put_u8(int(row[8]) if row.size() > 8 else 0)
		buf.put_u8(int(row[9]) if row.size() > 9 else 0)
		buf.put_u16(int(row[10]) if row.size() > 10 else 0)
	var pads: Array = d.get("pads", [])
	buf.put_u8(pads.size())
	for i in pads:
		buf.put_u8(int(i))


	var acks: Dictionary = d.get("ack", {})
	buf.put_u8(acks.size())
	for id in acks:
		buf.put_u32(int(id))
		buf.put_u32(int(acks[id]))
	return buf.data_array

static func decode_gym(bytes: PackedByteArray) -> Dictionary:
	var buf: = StreamPeerBuffer.new()
	buf.big_endian = false
	buf.data_array = bytes
	if buf.get_u8() != 5:
		return {}
	var d: = {"sq": buf.get_u32(), "grp": buf.get_u8()}
	var bodies: Array = []
	for n in buf.get_u8():
		var gid: = buf.get_u16()
		var st: = PackedFloat32Array()
		st.resize(ReplayData.NET_PLAYER_FLOATS)
		for i in st.size():
			if i == 11 or i == 24:
				st[i] = float(buf.get_u32())
			else:
				st[i] = buf.get_16() / SCALE
		bodies.append([gid, st])
	d["bodies"] = bodies
	var balls: Array = []
	for n in buf.get_u8():
		var bid: = buf.get_u8()
		var b: = PackedFloat32Array()
		b.resize(9)
		for i in 8:
			b[i] = buf.get_16() / SCALE
		b[8] = float(buf.get_u32())
		balls.append([bid, b])
	d["balls"] = balls
	var courts: Array = []
	for n in buf.get_u8():
		var row: = [buf.get_u8(), buf.get_u8(), buf.get_u8(), buf.get_u8()]
		var members: Array = []
		for k in buf.get_u8():
			members.append([buf.get_u16(), buf.get_8()])
		row.append(members)
		row.append(buf.get_u16())
		row.append(buf.get_u8())
		row.append(buf.get_u8() / 200.0)
		row.append(buf.get_u8())
		row.append(buf.get_u8())
		row.append(buf.get_u16())
		courts.append(row)
	d["courts"] = courts
	var pads: Array = []
	for k in buf.get_u8():
		pads.append(buf.get_u8())
	d["pads"] = pads
	var acks: = {}
	for i in buf.get_u8():
		var id: = buf.get_u32()
		acks[id] = buf.get_u32()
	d["ack"] = acks
	return d

static func decode_snapshot(bytes: PackedByteArray) -> Dictionary:
	var buf: = StreamPeerBuffer.new()
	buf.big_endian = false
	buf.data_array = bytes
	if buf.get_u8() != 1:
		return {}
	var flags: = buf.get_u8()
	var d: = {
		"ph": buf.get_u8(), 
		"s1": buf.get_u8(), "s2": buf.get_u8(), 
		"w1": buf.get_u8(), "w2": buf.get_u8(), 
		"sn": buf.get_u8(), 
		"sq": buf.get_u32(), 
	}
	if flags & F_CLOCKS:
		d["sc"] = buf.get_16() / SCALE
		d["rt"] = buf.get_16() / SCALE
		d["tc"] = buf.get_u8()
		d["sv"] = buf.get_u16()
		d["lt"] = buf.get_u16()
		d["sd"] = buf.get_u8() == 1
	if flags & F_BALL:
		var b: = PackedFloat32Array()
		b.resize(9)
		for i in 8:
			b[i] = buf.get_16() / SCALE
		b[8] = float(buf.get_u32())
		d["b"] = b
	if flags & F_BODIES:
		var count: = buf.get_u8()
		var p: = PackedFloat32Array()
		p.resize(count * ReplayData.NET_PLAYER_FLOATS)
		for i in p.size():
			if i % ReplayData.NET_PLAYER_FLOATS == 11 or i % ReplayData.NET_PLAYER_FLOATS == 24:
				p[i] = float(buf.get_u32())
			else:
				p[i] = buf.get_16() / SCALE
		d["p"] = p
	var acks: = {}
	for i in buf.get_u8():
		var id: = buf.get_u32()
		acks[id] = buf.get_u32()
	d["ack"] = acks
	return d
