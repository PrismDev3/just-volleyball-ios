// Shared body of the flat floor markers. Two shaders include this and differ
// ONLY in whether they depth-test:
//
//   floor_ring.gdshader          -- tests depth. For markers that lie on the
//                                   floor under a body: your own "that's me"
//                                   ring, the ball's landing ring. The player
//                                   standing in the ring must OCCLUDE it. When
//                                   these drew on top of everything, the ring
//                                   painted over the legs of the body standing
//                                   in it, and the chevron behind a body
//                                   facing away drew over that body too -- so
//                                   it read as pointing forwards when it was
//                                   pointing back. That is what "the arrow is
//                                   backwards" actually was.
//   floor_ring_overlay.gdshader  -- ignores depth. For the aim reticle only:
//                                   half the time it sits past the net or
//                                   under a jumping player, and a reticle you
//                                   cannot see is worse than none.
//
// Everything is in QUAD-HALF units -- 1.0 is the edge of the mesh -- so a
// marker is resized by its PlaneMesh, not by re-tuning six uniforms. Keep
// (radius + width + outline) under 1.0 or the band clips off the quad edge at
// the four axis points.

uniform vec4 tint : source_color = vec4(0.35, 1.0, 0.55, 1.0);
uniform vec4 edge : source_color = vec4(0.0, 0.06, 0.03, 0.92);
uniform float ring_radius = 0.62;
uniform float ring_width = 0.075;
uniform float outline = 0.05;
uniform float dot_radius = 0.115;   // 0 = no centre dot
uniform float arrow_len = 0.0;      // 0 = no facing chevron
uniform float arrow_base = 0.6;     // where the chevron starts, along forward
uniform float arrow_half = 0.17;    // half the chevron's width
uniform float pulse = 0.0;
// OUTER PROGRESS ARC -- the dive-cooldown wheel around the "that's me" ring.
// Fills clockwise from forward as `progress` climbs 0 -> 1. progress < 0 (the
// default) disables it entirely, so the ball's landing ring and the aim reticle
// -- which share this body -- are drawn exactly as before. Only the player's
// own indicator drives it.
uniform float progress = -1.0;
uniform vec4 progress_color : source_color = vec4(1.0, 0.82, 0.15, 1.0);
uniform float progress_radius = 0.82;   // sits OUTSIDE the ring, inside the quad
uniform float progress_width = 0.055;

// isosceles triangle SDF (iq). base centred on the origin spanning +/- q.x,
// apex at +q.y. negative inside, so one distance drives fill AND outline.
float sd_tri(vec2 p, vec2 q) {
	p.x = abs(p.x);
	vec2 a = p - q * clamp(dot(p, q) / dot(q, q), 0.0, 1.0);
	vec2 b = p - q * vec2(clamp(p.x / q.x, 0.0, 1.0), 1.0);
	float s = -sign(q.y);
	vec2 d = min(vec2(dot(a, a), s * (p.x * q.y - p.y * q.x)),
		vec2(dot(b, b), s * (p.y - q.y)));
	return -sqrt(d.x) * sign(d.y);
}

// returns rgb + alpha for a marker fragment
vec4 floor_ring_sample(vec2 raw_uv) {
	// PlaneMesh uv: u grows with +X, v grows with +Z. +v is therefore the
	// rig's FORWARD (this rig faces +Z, not Godot's usual -Z -- see
	// Player._turn), which is what points the chevron the right way.
	vec2 uv = raw_uv * 2.0 - 1.0;
	float r = length(uv);
	float rr = ring_radius + pulse;
	float aa = fwidth(r) + 0.004;

	// ONE signed distance for the whole marker -- the union of its parts,
	// negative inside -- and the outline comes off that. Outlining each part
	// separately and taking the max drew the chevron's own dark edge across
	// the ring where the two met, leaving a seam line through a shape that is
	// meant to read as a single object.
	float d = abs(r - rr) - ring_width;
	if (dot_radius > 0.0) {
		d = min(d, r - dot_radius);
	}
	if (arrow_len > 0.0) {
		// DO NOT "fix" this again. The orientation is settled and confirmed in
		// the running game: the chevron sits on the forward side of the ring
		// (+v is this rig's forward -- it faces +Z, see Player._turn) and is
		// flipped about its own span. It has been changed on the strength of a
		// bench render twice now and been wrong both times; the bench and the
		// match disagree about this shape, and the match is the authority.
		d = min(d, sd_tri(
			vec2(uv.x, (arrow_base + arrow_len) - uv.y),
			vec2(arrow_half, arrow_len)));
	}

	float core = 1.0 - smoothstep(-aa, aa, d);
	float shell = 1.0 - smoothstep(outline - aa, outline + aa, d);

	vec4 col = vec4(mix(edge.rgb, tint.rgb, core),
		shell * mix(edge.a, tint.a, core));
	// the cooldown wheel, laid over the marker. `ang` is 0 at the rig's forward
	// (+v) and grows clockwise. The WHOLE ring is drawn as a dim track so an
	// empty wheel (right after a dive) still reads, and the bright fill sweeps
	// clockwise up to `progress`.
	if (progress >= 0.0) {
		float ra = abs(r - progress_radius) - progress_width;
		float arc = 1.0 - smoothstep(-aa, aa, ra);
		if (arc > 0.001) {
			float ang = atan(uv.x, uv.y) / 6.2831853;
			if (ang < 0.0) ang += 1.0;
			// only the BOTTOM half of the ring (ang 0.25..0.75, centred on the
			// 6 o'clock point) -- a quiet half arc, not a full collar around the
			// player. Fills clockwise across that half as the cooldown returns.
			float in_band = step(0.25, ang) * step(ang, 0.75);
			float filled = step(ang, 0.25 + progress * 0.5);
			// track: same hue, dim + faint. fill: full colour + full alpha.
			float amt = mix(0.34, 1.0, filled) * in_band;
			col.rgb = mix(col.rgb, progress_color.rgb, arc * amt);
			col.a = max(col.a, arc * amt * progress_color.a);
		}
	}
	return col;
}
