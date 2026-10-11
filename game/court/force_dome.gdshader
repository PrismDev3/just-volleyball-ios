shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

// A STYLIZED ENERGY DOME (Rocket League / sci-fi sports arena), not a boxy wall.
// The mesh is a rounded stadium dome (game/court/force_dome.gd). This shader keeps
// it MOSTLY INVISIBLE and only reveals it where light would catch a real shield:
//   - FRESNEL: near-invisible looking straight at it, glowing at the grazing
//     silhouette edges -> you notice it in peripheral vision, not head-on.
//   - large hexes, very low opacity, a slow shimmer + a gentle every-few-seconds
//     pulse + subtle noise so it never reads as a flat pasted texture.
//   - a soft blue RIM glow on the silhouette, and the bottom dissolving into fog.
//   - REACTION: the ball / players brighten nearby hexes and send a ripple out.

uniform vec3 tint : source_color = vec3(0.28, 0.62, 1.0);
uniform vec3 rim_color : source_color = vec3(0.72, 0.9, 1.0);
uniform vec2 hex_scale = vec2(30.0, 6.0);    // base cell count (set per-stage in code)
uniform float hex_density : hint_range(0.25, 3.0) = 1.0;   // tune hex SIZE live here
uniform float line_width : hint_range(0.0, 0.3) = 0.06;
uniform float base_opacity : hint_range(0.0, 1.0) = 0.3;    // slightly visible at rest
uniform float fresnel_power = 2.6;           // higher -> more edge-only
uniform float fresnel_bias = 0.2;            // faint but ALWAYS visible (even bright bg)
uniform float rim_amt = 0.9;
uniform float shimmer_speed = 0.25;
uniform float shimmer_amt = 0.3;
uniform float pulse_speed = 0.7;             // ~one breath every ~9s
uniform float pulse_amt = 0.35;
uniform float noise_amt = 0.25;
uniform float wall_height = 24.0;
uniform float bottom_fade = 0.12;            // dissolve the base into ground fog
uniform float top_fade = 0.78;               // soften the open top rim
// fully fade the dome where the CAMERA is close to it -- so when the camera pulls
// back through a near wall, that wall vanishes instead of filling the screen.
uniform float cam_fade_near = 3.0;
uniform float cam_fade_far = 12.0;
uniform float prox_amt = 2.2;
uniform float prox_radius = 8.0;
uniform float ripple_freq = 1.8;
uniform float ripple_speed = 5.0;
uniform int probe_count = 0;
const int MAXP = 16;
uniform vec3 probe_pos[MAXP];

varying vec3 v_wpos;

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hex_dist(vec2 p) {
	p = abs(p);
	return max(dot(p, normalize(vec2(1.0, 1.7320508))), p.x);
}
float hex_edge(vec2 uv) {
	vec2 r = vec2(1.0, 1.7320508);
	vec2 h = r * 0.5;
	vec2 a = mod(uv, r) - h;
	vec2 b = mod(uv - h, r) - h;
	vec2 gv = dot(a, a) < dot(b, b) ? a : b;
	return 0.5 - hex_dist(gv);
}
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
		mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec2 uv = UV * hex_scale * hex_density;
	float e = hex_edge(uv);
	float aa = fwidth(e) * 1.5 + 0.001;
	float edge = 1.0 - smoothstep(line_width - aa, line_width + aa, e);

	// FRESNEL -- the whole trick: invisible facing you, bright at grazing edges
	float fres = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), fresnel_power);
	float visfres = fresnel_bias + fres;

	float vfrac = clamp(v_wpos.y / wall_height, 0.0, 1.0);
	float shimmer = 1.0 + shimmer_amt * sin(uv.y * 0.6 + uv.x * 0.15 - TIME * shimmer_speed * 6.2831);
	float pulse = 1.0 + pulse_amt * (0.5 + 0.5 * sin(TIME * pulse_speed));
	float depth = 1.0 - noise_amt + noise_amt * vnoise(uv * 0.5 + vec2(0.0, TIME * 0.03));

	// proximity brighten + outward ripple from the ball / players
	float prox = 0.0;
	float ripple = 0.0;
	for (int i = 0; i < probe_count; i++) {
		// HORIZONTAL distance only: the player stands at the base but the wall arcs up
		// overhead, so use xz so the whole vertical wall SECTION near you lights up
		// (not just a tiny patch at your feet).
		float d = distance(v_wpos.xz, probe_pos[i].xz);
		float near = smoothstep(prox_radius, 0.0, d);
		prox += near;
		ripple += near * smoothstep(0.2, 0.9, sin(d * ripple_freq - TIME * ripple_speed));
	}
	prox = clamp(prox, 0.0, 1.5);
	ripple = clamp(ripple, 0.0, 1.5);

	float botf = smoothstep(0.0, bottom_fade, vfrac);
	float topf = 1.0 - smoothstep(top_fade, 1.0, vfrac);
	// vanish where the camera is right up against / pushing through the dome
	float camfade = smoothstep(cam_fade_near, cam_fade_far,
		distance(v_wpos, CAMERA_POSITION_WORLD));

	// AMBIENT (kept ~base_opacity) + REACTION (allowed to punch brighter)
	float ambient = (edge * shimmer * depth + fres * rim_amt * 0.3) * visfres * pulse;
	float reaction = (prox * prox_amt + ripple * 2.5) * (edge + 0.2);
	float amt = (ambient * base_opacity + reaction * 0.4) * botf * topf * camfade;

	// rim reads whiter/hotter at the silhouette, like a real shield edge
	ALBEDO = mix(tint, rim_color, clamp(fres, 0.0, 1.0));
	ALPHA = clamp(amt, 0.0, 1.0);
}
