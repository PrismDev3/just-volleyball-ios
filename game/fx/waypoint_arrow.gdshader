// WAYPOINT ARROW: a billboarded downward chevron that bobs on TIME (no per-
// frame code). used over drill markers and over the ball's predicted landing
// spot ("stand here"). same tint/edge language as the floor rings.
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, shadows_disabled;
uniform vec4 tint : source_color;
uniform vec4 edge : source_color;

// same isosceles-triangle SDF the floor markers use (iq)
float sd_tri(vec2 p, vec2 q) {
	p.x = abs(p.x);
	vec2 a = p - q * clamp(dot(p, q) / dot(q, q), 0.0, 1.0);
	vec2 b = p - q * vec2(clamp(p.x / q.x, 0.0, 1.0), 1.0);
	float s = -sign(q.y);
	vec2 d = min(vec2(dot(a, a), s * (p.x * q.y - p.y * q.x)),
		vec2(dot(b, b), s * (p.y - q.y)));
	return -sqrt(d.x) * sign(d.y);
}

void vertex() {
	// face the camera, keep world position and scale
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0],
		INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	uv.y = -uv.y;   // y up
	// the bounce lives in the shader: the whole chevron rides a TIME wave
	uv.y += 0.28 - abs(sin(TIME * 2.6)) * 0.42;
	// downward chevron: base up top, apex pointing at the ring. (confirmed
	// in the running game -- the billboard flips vertically vs the bench)
	float d = sd_tri(vec2(uv.x, uv.y - 0.1), vec2(0.42, 0.62));
	float aa = fwidth(d) + 0.004;
	float core = 1.0 - smoothstep(-aa, aa, d);
	float shell = 1.0 - smoothstep(0.1 - aa, 0.1 + aa, d);
	ALBEDO = mix(edge.rgb, tint.rgb, core);
	ALPHA = shell * mix(edge.a, tint.a, core);
}
