class_name Foley
extends RefCounted













var surface: = "court"





var water_x: = INF
var water_side: = 1.0




const STEP_PHASES: = [0.25, 0.75]

var _was_diving: = {}
var _was_planting: = {}
var _was_grounded: = {}
var _step_timers: = {}
var _stride_prev: = {}
var _step_gate_at: = {}




func _step_gate(member: Player, gap: float) -> bool:
	var now: = Time.get_ticks_msec()
	if now - int(_step_gate_at.get(member, -9999)) < int(gap * 1000.0):
		return false
	_step_gate_at[member] = now
	return true

func _step_bank() -> String:
	match surface:
		"sand":
			return "footstep_sand"
		"grass":
			return "footstep_grass"
	return "footstep"

func _in_water(member: Player) -> bool:
	return member.global_position.x * water_side > water_x




func _water_step(member: Player, sfx: Sfx, fx: Fx, db: float, pitch: = 1.0) -> bool:
	if not _in_water(member):
		return false

	sfx.play("footstep_water", member.global_position, db, pitch * randf_range(0.9, 1.1))
	fx.splash(Vector3(member.global_position.x, 0.05, member.global_position.z))
	return true



static func phase_crossed(prev: float, now: float, mark: float) -> bool:
	if prev == now:
		return false
	if now > prev:
		return prev < mark and mark <= now
	return mark > prev or mark <= now


func tick(bodies: Array, delta: float, sfx: Sfx, fx: Fx) -> void :
	var court: = surface == "court"
	for p in bodies:
		var member: Player = p
		if member == null or not is_instance_valid(member):
			continue


		if member.far_lod:
			continue


		var now: = member.diving()
		if now and not _was_diving.get(member, false):
			if not _water_step(member, sfx, fx, -6.0):
				sfx.play("squeak" if court else _step_bank(), 
					member.global_position, -6.0)
			sfx.play("whip", member.global_position, -8.0, 1.1)
		_was_diving[member] = now


		var skid: = member.planting()
		if skid and not _was_planting.get(member, false)\
		and _step_gate(member, 0.2):



			if _water_step(member, sfx, fx, -8.0, randf_range(0.85, 1.0)):
				pass
			elif court:
				sfx.play("squeak", member.global_position, -9.0, 
					randf_range(0.9, 1.15))
				fx.puff(member.global_position + Vector3(0, 0.1, 0))
			else:
				sfx.play(_step_bank(), member.global_position, -8.0, 
					randf_range(0.8, 0.95))
				fx.puff(member.global_position + Vector3(0, 0.1, 0))
		_was_planting[member] = skid

		var is_grounded: = member.grounded()
		if _was_grounded.get(member, true) and not is_grounded\
		and member.velocity.y > 3.0:
			sfx.play("jump", member.global_position, -8.0)
			fx.ring(member.global_position + Vector3(0, 0.08, 0), Vector3.UP, 0.35)
		elif not _was_grounded.get(member, true) and is_grounded:
			if not _water_step(member, sfx, fx, -3.0, 0.85):
				sfx.play(_step_bank(), member.global_position, -3.0, 0.85)
				fx.ring(member.global_position + Vector3(0, 0.08, 0), Vector3.UP, 0.5)
		_was_grounded[member] = is_grounded



		var speed: = Vector2(member.velocity.x, member.velocity.z).length()
		if is_grounded and speed > 2.0:
			var ph: = member.stride_phase()
			if ph >= 0.0:
				var prev: float = _stride_prev.get(member, ph)
				for mark in STEP_PHASES:


					if phase_crossed(prev, ph, float(mark))\
					and _step_gate(member, 0.16):
						if not _water_step(member, sfx, fx, -5.0):
							sfx.play(_step_bank(), member.global_position, -5.0)
							fx.puff(member.global_position + Vector3(0, 0.15, 0))
				_stride_prev[member] = ph
			else:
				_step_timers[member] = _step_timers.get(member, 0.0) - delta
				if _step_timers[member] <= 0.0:
					if not _water_step(member, sfx, fx, -5.0):
						sfx.play(_step_bank(), member.global_position, -5.0)
						fx.puff(member.global_position + Vector3(0, 0.15, 0))
					_step_timers[member] = clampf(2.1 / speed, 0.26, 0.5)
		else:
			_step_timers[member] = 0.12
			_stride_prev.erase(member)
