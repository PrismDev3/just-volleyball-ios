class_name Haptics
extends RefCounted










enum Kind{BUMP, SET, SPIKE, SERVE, BLOCK, DIVE_LAND, KNOCKDOWN}



const _PULSE: = {
	Kind.BUMP: [0.46, 0.1, 0.11], 
	Kind.SET: [0.32, 0.05, 0.09], 
	Kind.SPIKE: [0.55, 0.75, 0.16], 
	Kind.SERVE: [0.45, 0.35, 0.13], 
	Kind.BLOCK: [0.5, 0.65, 0.15], 
	Kind.DIVE_LAND: [0.4, 0.55, 0.2], 
	Kind.KNOCKDOWN: [0.7, 0.95, 0.28], 
}




static func wire(player: Node, device: = -1) -> void :
	player.touched.connect( func(kind: int): _touch(kind, device))
	player.thumped.connect( func(_p: Vector3, strength: float):
		pulse(Kind.DIVE_LAND, device, strength))
	player.knock_started.connect( func(_p: Vector3, strength: float):
		pulse(Kind.KNOCKDOWN, device, strength))
	player.block_broken.connect( func(_p: Vector3): pulse(Kind.BLOCK, device))

static func _touch(kind: int, device: int) -> void :
	match kind:
		Player.TouchKind.SPIKE, Player.TouchKind.DUMP:
			pulse(Kind.SPIKE, device)
		Player.TouchKind.BUMP:
			pulse(Kind.BUMP, device)
		Player.TouchKind.SET:
			pulse(Kind.SET, device)
		Player.TouchKind.BLOCK:
			pulse(Kind.BLOCK, device)


static func pulse(kind: int, device: = -1, scale: = 1.0) -> void :
	if not GameConfig.rumble:
		return
	var p: Array = _PULSE.get(kind, [])
	if p.is_empty():
		return
	var s: = clampf(scale, 0.4, 1.0)
	var dev: = device if device >= 0 else _active_device()
	if dev < 0:
		# Phones have no controller to rumble, so the same moments come back as
		# the plain handheld buzz - it is coarser, but hits still land in the
		# hand instead of nowhere.
		if OS.has_feature("mobile"):
			Input.vibrate_handheld(maxi(int(float(p[2]) * 1000.0 * s), 20))
		return

	Input.start_joy_vibration(dev, float(p[0]) * s, float(p[1]) * s, float(p[2]))



static func stop(device: = -1) -> void :
	var dev: = device if device >= 0 else _active_device()
	if dev >= 0:
		Input.stop_joy_vibration(dev)

static func _active_device() -> int:
	if not InputPrompts.using_gamepad():
		return -1
	return InputPrompts.device_id()
