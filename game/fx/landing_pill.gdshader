// the "in" / "out" call pill: a clean white rounded-capsule panel that
// billboards to the camera and floats over the landing spot. drawn as a
// rounded-rect SDF with a crisp anti-aliased edge, a hairline border and a soft
// drop shadow, so it reads like a modern UI chip rather than a flat quad.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, blend_mix;

uniform float aspect = 2.4;            // quad width / height
uniform vec4 fill : source_color = vec4(0.97, 0.97, 0.96, 1.0);
uniform vec4 border : source_color = vec4(0.0, 0.0, 0.0, 0.16);
uniform vec4 shadow : source_color = vec4(0.0, 0.0, 0.0, 0.28);

void vertex() {
	// face the camera, keep the quad's own size
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

// signed distance to a rounded rectangle (b = half extents, r = corner radius)
float rrect(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - r;
}

void fragment() {
	// work centred, x scaled by aspect so corners stay circular
	vec2 p = (UV - vec2(0.5)) * vec2(aspect, 1.0);
	float m = 0.12;                       // margin so the shadow has room
	vec2 b = vec2(aspect * 0.5, 0.5) - vec2(m);
	float r = 0.5 - m;                    // full capsule: radius = half height
	float d = rrect(p, b, r);
	float aa = fwidth(d) + 1e-4;

	// soft drop shadow, offset down a touch
	float ds = rrect(p - vec2(0.0, 0.06), b, r);
	float sh = (1.0 - smoothstep(-0.02, 0.09, ds)) * shadow.a;

	float body = 1.0 - smoothstep(-aa, aa, d);            // white fill
	float edge = (1.0 - smoothstep(0.0, aa * 2.0, abs(d))) * border.a;  // hairline rim

	vec3 rgb = mix(fill.rgb, border.rgb, edge);
	float a = max(body, sh);
	rgb = mix(shadow.rgb, rgb, body);                     // shadow shows only outside the body
	ALBEDO = rgb;
	ALPHA = clamp(a, 0.0, 1.0);
}
