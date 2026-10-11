shader_type spatial;
// THE AIMING SCOPE. A haikyuu-style crosshair on the floor where you aim: a thin
// WHITE outer ring + white crosshair arms (the frame), a coloured centre dot and
// four coloured lock-on arcs (the action colour). Every mark carries a dark cel
// halo so it reads on the bright wood. Depth test OFF, same as the old reticle:
// it regularly sits past the net or under a jumper.
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled,
	cull_disabled, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.35, 1.0, 0.55, 1.0);  // the action colour
uniform float pulse = 0.0;        // slow breath, added to the radii
uniform vec4 shell : source_color = vec4(0.04, 0.05, 0.08, 1.0); // dark cel halo

// 1 inside a soft band around `rad`, feathered by `w`
float ring_band(float r, float rad, float w) {
	return 1.0 - smoothstep(w, w + 0.006, abs(r - rad));
}
// a crosshair arm along `axis`, from `inner` to `outer`, half-thickness `hw`
float arm(vec2 p, vec2 axis, float inner, float outer, float hw) {
	float along = dot(p, axis);
	float perp = abs(dot(p, vec2(-axis.y, axis.x)));
	float on = 1.0 - smoothstep(hw, hw + 0.005, perp);
	float span = step(inner, along) * step(along, outer);
	return on * span;
}

void fragment() {
	vec2 p = UV - vec2(0.5);
	float br = 1.0 + pulse;              // breathe the whole thing
	float r = length(p) / br;
	float a = atan(p.y, p.x);

	// WHITE FRAME: outer ring + four crosshair arms with a centre gap
	float white = ring_band(r, 0.43, 0.012);
	vec2 pr = p / br;
	white = max(white, arm(pr, vec2(1.0, 0.0), 0.13, 0.38, 0.012));
	white = max(white, arm(pr, vec2(-1.0, 0.0), 0.13, 0.38, 0.012));
	white = max(white, arm(pr, vec2(0.0, 1.0), 0.13, 0.38, 0.012));
	white = max(white, arm(pr, vec2(0.0, -1.0), 0.13, 0.38, 0.012));

	// COLOUR: centre dot + four lock-on arcs on the diagonals
	float col = 1.0 - smoothstep(0.05, 0.062, r);           // dot
	float arc_band = ring_band(r, 0.20, 0.022);
	float diag = cos(4.0 * (a - 0.7853982));                 // peaks at 45/135/225/315
	col = max(col, arc_band * smoothstep(0.45, 0.78, diag)); // 4 short arcs

	float mark = max(white, col);
	if (mark < 0.02) {
		discard;
	}
	// DARK HALO: a slightly wider silhouette of everything, drawn under the mark
	float halo = smoothstep(0.0, 0.35, mark);
	vec3 rgb = mix(shell.rgb, mix(vec3(1.0), tint.rgb, step(0.5, col)), mark);
	ALBEDO = rgb;
	ALPHA = max(mark, halo * 0.9);
}
