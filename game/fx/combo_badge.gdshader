// The combo multiplier badge: a filled disc with a heavy ink outline, sitting
// behind a "x2" label. Billboarded, so it reads the same from every camera
// angle -- the same trick charge_ring.gdshader uses.
//
// This replaced a plain "combo x2" text callout. Text is something you read;
// a badge is something you SEE, which is the whole point of a callout that
// fires mid-rally while you are watching the ball.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled,
	cull_disabled, shadows_disabled;

uniform vec4 fill : source_color = vec4(1.0, 0.35, 0.72, 1.0);
// the white rim between the colour and the ink. this is the whole difference
// between a coloured dot and a sticker -- it reads as a badge PLACED on the
// scene rather than a blob tinted into it, and it keeps the number legible
// whatever colour the fill has warmed to.
uniform vec4 rim : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 edge : source_color = vec4(0.09, 0.09, 0.13, 1.0);
// quad-half units; the quad only reaches 0.5 along its axes, so keep
// radius + rim_width + outline under that or the disc flat-tops at four points
uniform float radius = 0.30;
uniform float rim_width = 0.055;
uniform float outline = 0.035;
uniform float alpha = 1.0;

void vertex() {
	mat4 mv = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	mv = mv * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = mv;
}

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float r = length(uv);
	float aa = fwidth(r) + 0.002;
	// three bands out from the centre: colour, white rim, ink
	float core = 1.0 - smoothstep(radius - aa, radius + aa, r);
	float ring = 1.0 - smoothstep(
		radius + rim_width - aa, radius + rim_width + aa, r);
	float shell = 1.0 - smoothstep(
		radius + rim_width + outline - aa,
		radius + rim_width + outline + aa, r);
	if (shell <= 0.0) {
		discard;
	}
	vec3 col = mix(edge.rgb, rim.rgb, ring);
	col = mix(col, fill.rgb, core);
	float a = mix(edge.a, rim.a, ring);
	a = mix(a, fill.a, core);
	ALBEDO = col;
	ALPHA = shell * a * alpha;
}
