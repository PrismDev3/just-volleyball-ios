// LANDING COLUMN: a soft translucent cylinder standing on the ball's predicted
// landing spot, rising to the ball's height. Reads as "the space to stand in"
// from any camera angle (a floor mark flattens away at low angles). Fades out
// toward the top and is strongest on the rim so it looks like a column of
// light, not a solid tube. Colour rides the landing marker's tint.
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.4, 1.0, 1.0, 0.22);
uniform float top_fade : hint_range(0.0, 1.0) = 0.6;    // where the fade finishes (0 floor .. 1 top)
uniform float rim_power = 1.6;
uniform float body_alpha : hint_range(0.0, 1.0) = 0.35; // fill through the middle vs the rim
uniform vec4 edge : source_color = vec4(0.05, 0.07, 0.11, 1.0);
uniform float edge_amt : hint_range(0.0, 1.0) = 0.55;

varying float vh;

void vertex() {
	// CylinderMesh is centred: y in -0.5..0.5 before the scale to full height
	vh = VERTEX.y + 0.5;
}

void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), rim_power);
	float fade = 1.0 - smoothstep(0.0, top_fade, vh);
	// a gentle upward drift of soft bands so the column reads alive but calm
	float bands = 0.85 + 0.15 * sin(vh * 18.0 - TIME * 2.2);
	// the rim carries a dark cel edge so the column still reads on a pale
	// floor (it vanished against the white training space)
	ALBEDO = mix(tint.rgb, edge.rgb, rim * edge_amt);
	ALPHA = tint.a * fade * mix(body_alpha, 1.0, rim) * bands;
}
