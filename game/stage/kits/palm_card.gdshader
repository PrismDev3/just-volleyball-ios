// PALM CARD: a cheap camera-facing billboard of the baked 3D palm (palm_impostor.png),
// so a beach can spread many palms as flat quads (one MultiMesh, one draw call) instead
// of many 3D trees + LODs. Palms are ~radially symmetric, so a single view reads fine
// from any angle. A fake WIND sway rocks the crown (top of the card) so it isn't a dead
// cutout; the trunk base stays planted. Per-palm phase comes from world position, so
// they don't all sway in lockstep.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;

uniform sampler2D tex : filter_linear_mipmap, source_color;
uniform float card_h = 3.0;       // card height in metres (feet at the node origin)
uniform float wind_amp = 0.08;
uniform float wind_speed = 1.1;
uniform vec3 haze_color : source_color = vec3(0.72, 0.82, 0.92);
uniform float haze_start = 70.0;
uniform float haze_end = 190.0;
uniform float haze_amt : hint_range(0.0, 1.0) = 0.0;
// FAKE SHADING (same trick as the grass tree cards): a vertical gradient over
// the card, sunlit frond tips at the top, shaded frond undersides and a dark
// trunk below. shade_lo..shade_hi is the slice of the card height the gradient
// spans (the crown is the upper part of a palm card); the shade leans toward
// shade_tint so the underside reads cool, not muddy.
uniform float shade_top : hint_range(0.0, 1.5) = 1.15;
uniform float shade_bottom : hint_range(0.0, 1.0) = 0.45;
uniform float shade_lo : hint_range(0.0, 1.0) = 0.5;
uniform float shade_hi : hint_range(0.0, 1.0) = 0.95;
uniform float shade_power : hint_range(0.3, 4.0) = 1.0;
uniform vec3 shade_tint : source_color = vec3(0.5, 0.7, 0.9);
uniform float shade_tint_amt : hint_range(0.0, 1.0) = 0.55;

varying vec2 uv;
varying flat float vhaze;
varying float vup;

void vertex() {
	vec3 wpos = MODEL_MATRIX[3].xyz;
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 look = normalize(vec3(cam.x - wpos.x, 0.0, cam.z - wpos.z));
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), look));
	// 0 at the feet, 1 at the crown -- QuadMesh is centred, so lift by half height
	float up01 = clamp((VERTEX.y + card_h * 0.5) / card_h, 0.0, 1.0);
	float phase = wpos.x * 0.7 + wpos.z * 0.7;
	float sway = sin(TIME * wind_speed + phase) * wind_amp * up01 * up01;   // crown rocks most
	vec3 world = wpos + right * (VERTEX.x + sway) + vec3(0.0, 1.0, 0.0) * (VERTEX.y + card_h * 0.5);
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
	uv = UV;
	vhaze = haze_amt * smoothstep(haze_start, haze_end, distance(cam, wpos));
	vup = up01;
}

void fragment() {
	vec4 t = texture(tex, uv);
	float g = smoothstep(shade_lo, shade_hi, vup);
	float lit = mix(shade_bottom, shade_top, pow(g, shade_power));
	vec3 shade = mix(vec3(1.0), shade_tint, shade_tint_amt * (1.0 - lit));
	ALBEDO = mix(t.rgb * lit * shade, haze_color, vhaze);
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.4;
}
