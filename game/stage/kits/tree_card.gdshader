// TREE CARD: cheap camera-facing billboard of the baked trees (tree_impostor.png, a
// 2-cell grid), for ringing the grass court's border. One MultiMesh = one draw call.
// Per-instance picks which tree (INSTANCE_CUSTOM.x = 0 or 1) and a bob phase; a light
// wind sway rocks the crown so the tree line isn't dead. Alpha-scissor cutout.
//   INSTANCE_CUSTOM.x = tile (0..grid.x-1)
//   INSTANCE_CUSTOM.y = bob phase (0..1)
shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;

uniform sampler2D atlas : filter_linear_mipmap, source_color;
uniform vec2 grid = vec2(2.0, 1.0);
uniform float card_h = 7.0;
uniform float wind_amp = 0.06;
uniform float wind_speed = 0.9;
uniform vec3 haze_color : source_color = vec3(0.6, 0.75, 0.9);
uniform float haze_start = 60.0;
uniform float haze_end = 130.0;
uniform float haze_amt : hint_range(0.0, 1.0) = 0.0;
// FAKE SHADING: a vertical gradient over the card, lit crown at the top, shaded
// underside at the bottom (the bake is flat-lit). shade_bottom is the darkest
// multiplier, tinted toward shade_tint so the shadow reads cool, not muddy;
// shade_power bends the curve (higher = the dark stays low and the top stays lit).
// shade_lo..shade_hi is the slice of the card height the gradient spans (the
// canopy sits in the upper part of the card, the trunk below it): below lo is
// fully shaded, above hi fully lit.
uniform float shade_top : hint_range(0.0, 1.5) = 1.18;
uniform float shade_bottom : hint_range(0.0, 1.0) = 0.28;
uniform float shade_lo : hint_range(0.0, 1.0) = 0.3;
uniform float shade_hi : hint_range(0.0, 1.0) = 0.9;
uniform float shade_power : hint_range(0.3, 4.0) = 1.0;
uniform vec3 shade_tint : source_color = vec3(0.55, 0.75, 0.9);
uniform float shade_tint_amt : hint_range(0.0, 1.0) = 0.6;

varying vec2 uv;
varying flat float vtile;
varying flat float vhaze;
varying float vup;

void vertex() {
	vec3 wpos = MODEL_MATRIX[3].xyz;
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 look = normalize(vec3(cam.x - wpos.x, 0.0, cam.z - wpos.z));
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), look));
	float up01 = clamp((VERTEX.y + card_h * 0.5) / card_h, 0.0, 1.0);
	float phase = wpos.x * 0.5 + wpos.z * 0.5 + INSTANCE_CUSTOM.y * 6.2831;
	float sway = sin(TIME * wind_speed + phase) * wind_amp * up01 * up01;
	vec3 world = wpos + right * (VERTEX.x + sway) + vec3(0.0, 1.0, 0.0) * (VERTEX.y + card_h * 0.5);
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
	uv = UV;
	vtile = INSTANCE_CUSTOM.x;
	vhaze = haze_amt * smoothstep(haze_start, haze_end, distance(cam, wpos));
	vup = up01;
}

void fragment() {
	vec2 cell = vec2(1.0) / grid;
	vec2 tuv = (vec2(vtile, 0.0) + uv) * cell;
	vec4 t = texture(atlas, tuv);
	float g = smoothstep(shade_lo, shade_hi, vup);
	float lit = mix(shade_bottom, shade_top, pow(g, shade_power));
	vec3 shade = mix(vec3(1.0), shade_tint, shade_tint_amt * (1.0 - lit));
	vec3 col = t.rgb * lit * shade;
	ALBEDO = mix(col, haze_color, vhaze);
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.4;
}
