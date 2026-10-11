// the serve-zone floor marker: a glowing rounded rectangle. a soft border glow
// that bleeds inward, bright WHITE L-brackets on the four corners (the "you
// can't leave these bounds" emphasis), a crisp rounded outline, and a subtle
// baseline (foot-fault) line across it. tinted by the scene (green = legal, red
// = would fault). unshaded floor paint.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;

uniform vec4 tint : source_color = vec4(0.35, 0.95, 0.42, 1.0);
uniform vec2 size = vec2(12.0, 7.0);   // world metres (matches the quad)
uniform float corner_radius = 0.7;     // rounded corner radius, metres
uniform float border = 0.07;           // crisp outline half-width, metres
uniform float glow_reach = 0.8;        // how far the border glow bleeds inward
uniform float bracket_len = 1.3;       // corner-bracket arm length, metres
uniform float bracket_w = 0.1;         // corner-bracket line half-width, metres

void fragment() {
	vec2 half = size * 0.5;
	vec2 p = (UV - vec2(0.5)) * size;              // metres from centre
	vec2 q = abs(p) - (half - vec2(corner_radius));
	float sd = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner_radius;
	if (sd > border) {                             // outside the rounded rect
		discard;
	}
	float aa = fwidth(sd) + 1e-4;
	float inner = max(-sd, 0.0);                   // metres inside the border

	// a subtle glow bleeding inward from the border, fading fast
	float glow = pow(clamp(1.0 - inner / glow_reach, 0.0, 1.0), 2.2);
	// the crisp rounded outline itself (anti-aliased, thin)
	float line = 1.0 - smoothstep(border, border + aa * 1.5, abs(sd));

	// WHITE corner brackets: the OUTLINE itself, within bracket_len of a corner,
	// so the bracket FOLLOWS the rounded corner as one continuous cap instead of
	// two straight arms that leave a notch at the curve (the "weird spot" at each
	// corner). corner_dist measures to the nearest corner along the edges.
	float distV = half.x - abs(p.x);               // to the left/right edge
	float distH = half.y - abs(p.y);               // to the top/bottom edge
	float corner_dist = length(vec2(max(distV, 0.0), max(distH, 0.0)));
	float on_line = 1.0 - smoothstep(bracket_w, bracket_w + aa * 1.5, abs(sd));
	float near_corner = 1.0 - smoothstep(bracket_len, bracket_len + aa * 2.0, corner_dist);
	float bracket = clamp(on_line * near_corner, 0.0, 1.0);

	vec3 rgb = mix(tint.rgb, vec3(1.0), bracket);
	float a = max(max(glow * 0.4, line), bracket);
	// additive blend: paint the light, the court shows through
	ALBEDO = rgb * clamp(a, 0.0, 1.0);
	ALPHA = 1.0;
}
