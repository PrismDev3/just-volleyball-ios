// the landing spot on the floor: a soft-edged filled disc with a brighter rim
// ring, on a flat plane laid on the court. replaces the old hard translucent
// cylinder -- same red, but a clean anti-aliased circle that reads as a call
// marker instead of a flat coaster.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

uniform vec4 col : source_color = vec4(0.95, 0.22, 0.18, 1.0);
uniform float fill_a = 0.5;    // body opacity
uniform float rim_a = 1.0;     // rim opacity

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;   // 0 centre .. 1 edge
	if (r > 1.0) {
		discard;
	}
	float aa = fwidth(r) + 1e-4;
	// soft filled body, a touch stronger toward the rim so it reads as a disc
	float body = mix(0.72, 1.0, smoothstep(0.0, 0.85, r)) * (1.0 - smoothstep(0.72, 1.0, r)) * fill_a;
	// a bright, clean ring just inside the edge
	float rim = (1.0 - smoothstep(0.0, 0.05 + aa, abs(r - 0.88))) * rim_a;
	// crisp outer cut
	float outer = 1.0 - smoothstep(1.0 - aa * 2.0, 1.0, r);
	// THE EXACT-SPOT DOT: a small crisp WHITE dot dead centre, ringed by a thin
	// dark halo so it reads on the coloured disc AND on any court. this is the
	// "where exactly did the ball touch" mark -- the soft body only frames the
	// area, this pins the point.
	float dot  = 1.0 - smoothstep(0.10, 0.10 + aa * 2.0, r);
	float halo = (1.0 - smoothstep(0.10, 0.155 + aa * 2.0, r)) * (1.0 - dot);

	vec3 rgb = mix(col.rgb, vec3(1.0), rim * 0.45);
	rgb = mix(rgb, vec3(0.04, 0.05, 0.08), halo);   // dark ring around the dot
	rgb = mix(rgb, vec3(1.0), dot);                  // white core
	float a = clamp(max(max(body, rim), max(dot, halo)), 0.0, 1.0) * outer;
	ALBEDO = rgb;
	ALPHA = a;
	// keep the red honest over any court colour, and glow the rim + dot a little
	EMISSION = col.rgb * (body * 0.25 + rim * 0.55) + vec3(1.0) * dot * 0.5;
}
