// woven net: the cords come from discarding between grid lines, and ball
// contact sends a decaying ripple out from the hit point.
//
// A real volleyball net is a black cord mesh bound by white tape: a wide band
// along the top, a narrower one along the bottom, and a vertical band down
// each side onto the posts. This drew the cords alone, in a washed-out
// near-grey, with the top tape faked by a separate box in the scene -- so it
// read as a grey grid floating between two posts.
//
// The ripple is two motions: a broad SAG that pushes the whole area around the
// hit backwards -- the net actually taking the ball -- and the fast ripple
// riding on top of it. The sag spreads wider than the ripple, because cloth
// does. The bands are part of the same surface, so they deform with it.
shader_type spatial;
render_mode cull_disabled, unshaded;

uniform float wobble = 0.0;
uniform float hit_x = 0.0;
uniform float hit_y = 0.5;      // 0 at the bottom of the net, 1 at the tape
uniform vec2 grid = vec2(46.0, 7.0);
// tuned UP from 0.34/0.11: at those values a real spike into the tape read
// as a shiver. The net should visibly TAKE the ball.
uniform float sag = 0.58;       // how far the net gives way at full strength
uniform float ripple = 0.17;
// tape, as a fraction of the net's height / width
uniform float tape_top = 0.11;
uniform float tape_bottom = 0.06;
uniform float tape_side = 0.014;
// the side bands sit at the SIDELINE, not at the end of the mesh: the netting
// carries on past them as a bare wing to the posts (the top and bottom bands
// run the full width). fraction of the net width from each end to the band.
uniform float side_inset = 0.0213;   // 0.2 m of a 9.4 m net: the band sits on the sideline
uniform vec3 tape_color : source_color = vec3(0.97, 0.97, 0.95);
uniform vec3 cord_color : source_color = vec3(0.0, 0.0, 0.0);
// the tape's cel outline: a dark rim along every band edge (fraction of the
// net HEIGHT; the side bands scale it by aspect so it is the same thickness)
uniform vec3 ink_color : source_color = vec3(0.05, 0.05, 0.08);
uniform float tape_ink = 0.014;
uniform float aspect = 9.0;
// --- aiming see-through cutout (screen space) ---
// a soft-edged hole punched in the net around where you're aiming across it, so
// the cords never hide the far-court target. driven only in live play; a radius
// of 0 (the default) leaves the net solid, so it's inert everywhere it isn't fed
// and can never show up in a replay.
uniform vec2 cut_center = vec2(0.5);   // reticle position in screen UV
uniform float cut_radius = 0.0;        // hole radius in screen UV (0 = off)
uniform float cut_feather = 0.11;      // soft-edge width in screen UV
uniform float cut_aspect = 1.78;       // viewport w/h, so the hole stays round
uniform float cut_yscale = 0.6;        // <1 = taller than wide, to clear the net's
									   // full height (top + bottom tape) around the aim

void vertex() {
	float dx = VERTEX.x - hit_x;
	// the net is anchored top and bottom, so it can only give in the middle:
	// UV.y runs the height, and this pins the deflection at both edges
	float span = sin(UV.y * PI);
	float near = exp(-abs(dx) * 0.55);          // broad, for the sag
	float tight = exp(-abs(dx) * 1.35);         // narrow, for the ripple
	// weight the give toward where the ball actually struck
	float band = exp(-abs(UV.y - hit_y) * 2.2);
	VERTEX.z += wobble * span * (near * band * sag
		+ sin(VERTEX.x * 6.0 + TIME * 26.0) * tight * ripple);
}

void fragment() {
	// screen-space see-through hole around the aim reticle (see the uniforms): a
	// smooth ALPHA fade (not a dither) for a clean feathered edge, taller than wide
	// so the window clears the net's full height around the aim. cut_a is applied to
	// ALPHA at the end of the shader.
	float cut_a = 1.0;
	if (cut_radius > 0.0) {
		vec2 cd = (SCREEN_UV - cut_center) * vec2(cut_aspect, cut_yscale);
		cut_a = smoothstep(cut_radius - cut_feather, cut_radius, length(cd));
		if (cut_a <= 0.003) discard;   // fully inside the hole: nothing to draw
	}
	// UV.y is 0 at the tape and 1 at the bottom on this plane, so the top band
	// is the LOW end. Both are drawn from the same test either way.
	// how far inside each band this pixel is (positive = in that band)
	float d_top = tape_top - UV.y;
	float d_bot = UV.y - (1.0 - tape_bottom);
	float ink_x = tape_ink / aspect;
	// side bands: a strip of tape_side width starting side_inset in from each end
	float lx = UV.x - side_inset;
	float rx = (1.0 - side_inset) - UV.x;
	float d_left = min(lx, tape_side - lx) * aspect;
	float d_right = min(rx, tape_side - rx) * aspect;
	float inside = max(max(d_top, d_bot), max(d_left, d_right));
	bool in_tape = inside > 0.0;
	// the top and bottom edges of the plane are edges too; the wings just end
	bool outer = UV.y < tape_ink || UV.y > 1.0 - tape_ink;
	if (in_tape) {
		ALBEDO = (inside < tape_ink || outer) ? ink_color : tape_color;
	} else {
		vec2 cell = fract(UV * grid);
		if (cell.x > 0.16 && cell.y > 0.22) {
			discard;
		}
		ALBEDO = cord_color;
	}
	ALPHA = cut_a;   // the see-through fade (1 everywhere unless a cutout is active)
}
