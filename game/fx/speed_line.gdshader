// a single anime speed line: a streak along the quad's local X, tapered to a
// point at both ends and thin across. Fx orients the quad so X runs along the
// hit direction and the face turns toward the camera. flat colour, no texture.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float head = 0.35;   // where along the streak the thick part sits (0 tail .. 1 tip)

void fragment() {
	float u = UV.x;                 // along the line
	float v = (UV.y - 0.5) * 2.0;   // across, -1..1
	// thickness profile: a hump peaking at `head`, points at both ends
	float w = u < head ? smoothstep(0.0, head, u) : 1.0 - smoothstep(head, 1.0, u);
	w = pow(w, 0.6);
	float aa = fwidth(v) * 1.5;
	float a = 1.0 - smoothstep(w - aa, w + aa, abs(v));
	if (a <= 0.001) {
		discard;
	}
	ALBEDO = tint.rgb;
	ALPHA = a * tint.a;
}
