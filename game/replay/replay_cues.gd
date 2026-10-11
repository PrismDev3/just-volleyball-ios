class_name ReplayCues
extends RefCounted

const VISUAL_KINDS: = ["fx_impact", "burst", "ring", "lines", "gust", "puff", "splash", 
	"bigspike", "combo_burst", "crack", "pulse", "fsquash", "float", "combo", "callout"]

static func is_visual(c: Dictionary) -> bool:
	return String(c.get("k", "")) in VISUAL_KINDS



static func _rim(d: Dictionary) -> Color:
	var c: Variant = d.get("c")
	return c if c is Color else Color(0, 0, 0, 0)












static func play(c: Dictionary, sfx: Sfx, fx: Fx, crowd: CrowdAudio, 
		ball: Node, bodies: Array, show_messages: = true) -> void :
	var d: Dictionary = c.get("d", {})
	match String(c.get("k", "")):
		"sfx":
			if sfx != null:
				sfx.play(Net.ev_s(d, "n", "", 32), Net.ev_v3(d, "p"), Net.ev_f(d, "db"), Net.ev_f(d, "pt", 1.0))
		"cheer":
			if crowd != null:
				crowd.cheer(float(d.get("a", 0.5)))


		"shock":
			if crowd != null:
				crowd.shock(float(d.get("a", 0.8)))
		"fx_impact":
			if fx != null:
				fx.impact(Net.ev_v3(d, "p"), Net.ev_f(d, "s"), Net.ev_v3(d, "a", Vector3.UP), 
					Net.ev_b(d, "hv"), _rim(d))
		"burst":
			if fx != null:
				fx.burst(Net.ev_v3(d, "p"), Net.ev_f(d, "s"), Net.ev_v3(d, "d"), 
					Net.ev_f(d, "w"))
		"ring":
			if fx != null:
				fx.ring(Net.ev_v3(d, "p"), Net.ev_v3(d, "a", Vector3.UP), Net.ev_f(d, "s"), 
					_rim(d), Net.ev_f(d, "l", 0.26), Net.ev_f(d, "al", 1.0))
		"lines":
			if fx != null:
				fx.speed_lines(Net.ev_v3(d, "p"), Net.ev_v3(d, "d", Vector3.UP), 
					Net.ev_f(d, "s"), _rim(d))
		"puff":
			if fx != null:
				fx.puff(Net.ev_v3(d, "p"))
		"splash":
			if fx != null:
				fx.splash(Net.ev_v3(d, "p"))
		"combo_burst":
			if fx != null:
				fx.combo_burst(Net.ev_v3(d, "p"), Net.ev_v3(d, "d"), int(d.get("t", 3)))
		"bigspike":
			if fx != null:
				fx.big_spike(Net.ev_v3(d, "p"), Net.ev_v3(d, "d"), _rim(d), int(d.get("t", 0)))
		"gust":
			if fx != null:
				fx.floor_gust(Net.ev_v3(d, "p"), Net.ev_f(d, "h"))
		"fsquash":
			if ball != null:
				ball.floor_squash(Net.ev_f(d, "s"))
		"crack":

			if fx != null:
				fx.shield_crack(Net.ev_v3(d, "p"))
		"slowmo":
			if fx != null:
				fx.slowmo(float(d.get("r", 0.4)), float(d.get("d", 0.6)))
		"pulse":
			if ball != null:
				ball.pulse()
		"float":

			var fslot: = int(d.get("s", -1))
			if show_messages and fslot >= 0 and fslot < bodies.size():
				(bodies[fslot] as Player).show_float_text(
					String(d.get("t", "")), 
					Color.html(str(d.get("c", "ffffff"))), 
					bool(d.get("pr", false)))
		"combo":
			var cslot: = int(d.get("s", -1))
			if show_messages and cslot >= 0 and cslot < bodies.size():
				(bodies[cslot] as Player).show_combo_local(int(d.get("n", 2)), bool(d.get("f", false)))
		"callout":
			var slot: = int(d.get("s", -1))
			if show_messages and slot >= 0 and slot < bodies.size():
				(bodies[slot] as Player).show_callout(int(d.get("i", 0)), false)
