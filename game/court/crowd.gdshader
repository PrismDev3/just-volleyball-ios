// CROWD BILLBOARDS. One MultiMesh of camera-facing quads over the seats, each
// instance a seated fan. All fans share ONE Texture2DArray (the baked portrait
// library); per-instance custom data picks the layer + a bob phase, so the whole
// crowd is a single draw call -- cheap enough for low-end hardware.
//   INSTANCE_CUSTOM.x = portrait layer index
//   INSTANCE_CUSTOM.y = bob phase (0..1)
//   INSTANCE_CUSTOM.z = wave coord (0..1 across the stands) -- staggers the hop
// Y-axis billboard: fans always face the viewer but stay upright, so no matter
// where the broadcast camera swings they read correctly and never tilt.
//
// CHEER WAVE: on a cheer, cheer_elapsed is reset to 0 and cheer_intensity set;
// each fan hops when the wave front (elapsed vs its wave coord * wave_span)
// reaches it -- so the crowd pops off in a rolling wave, not all at once.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;

uniform sampler2DArray fans : filter_linear_mipmap, source_color;
uniform float foot_lift = 1.0;      // half the quad height: lifts feet to the seat
uniform float bob_amp = 0.02;
uniform float bob_speed = 1.6;
// cheer wave (driven by CrowdField each frame)
uniform float cheer_elapsed = 999.0;
uniform float cheer_intensity = 0.0;
uniform float wave_span = 1.1;      // seconds for the wave to sweep the stands
uniform float hop_dur = 0.42;       // seconds of one fan's hop
uniform float hop_height = 0.34;
// SHADING (depth + mood): tint multiplies every fan (darken/cool the crowd to sit
// in a moody arena); shade_var darkens each fan a random amount for variation so
// they don't read as one flat sheet; depth_dim darkens the UPPER rows (world Y) so
// the stands recede into shadow instead of staying uniformly bright.
uniform vec3 tint : source_color = vec3(1.0);
uniform float shade_var = 0.0;
uniform float depth_dim = 0.0;
uniform float depth_hi = 30.0;
// DISTANCE HAZE: fade far fans toward haze_color by camera distance, so the crowd
// recedes from court to back rows (atmospheric depth) instead of one crisp wall.
uniform vec3 haze_color : source_color = vec3(0.83, 0.87, 0.93);
uniform float haze_start = 12.0;   // stands sit ~15-50m from the play camera, so the
uniform float haze_end = 48.0;     // haze must ramp across THAT range, not 25-90
uniform float haze_amt : hint_range(0.0, 1.0) = 0.0;
// MUTE: the baked portraits are bright + saturated + high-contrast, so a packed
// crowd reads as a field of shiny distracting speckles. desat pulls colour out and
// crowd_contrast (<1) softens the bright/dark spread, so it settles into a calm mass.
uniform float desat : hint_range(0.0, 1.0) = 0.0;
uniform float crowd_contrast : hint_range(0.5, 1.5) = 1.0;

varying flat float layer;
varying vec2 uv;
varying flat float vshade;
varying flat float vhaze;

void vertex() {
	vec3 wpos = MODEL_MATRIX[3].xyz;               // this instance's seat point
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 look = normalize(vec3(cam.x - wpos.x, 0.0, cam.z - wpos.z));
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), look));
	float bob = sin(TIME * bob_speed + INSTANCE_CUSTOM.y * 6.2831) * bob_amp;

	// staggered cheer hop: an up-and-down arc that fires when the wave reaches
	// this fan, plus a little sideways sway so it reads as "jumping around".
	float hop = 0.0;
	float sway = 0.0;
	if (cheer_intensity > 0.001) {
		float lt = cheer_elapsed - INSTANCE_CUSTOM.z * wave_span;
		if (lt > 0.0 && lt < hop_dur) {
			float u = lt / hop_dur;
			hop = sin(u * 3.14159) * hop_height * cheer_intensity;
			sway = sin(u * 6.2831 + INSTANCE_CUSTOM.y * 6.2831)
				* 0.035 * cheer_intensity;
		}
	}

	// QuadMesh is centred in XY; lift by foot_lift so the fan's feet sit at wpos
	vec3 world = wpos
		+ right * (VERTEX.x + sway)
		+ vec3(0.0, 1.0, 0.0) * (VERTEX.y + foot_lift + bob + hop);
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
	layer = INSTANCE_CUSTOM.x;
	uv = UV;
	// per-fan brightness: a random dim (reusing the bob-phase random) + a fade for
	// the upper rows, so the crowd has variation and depth instead of one flat tone.
	float vary = 1.0 - shade_var * INSTANCE_CUSTOM.y;
	float depth = 1.0 - depth_dim * clamp(wpos.y / max(depth_hi, 0.01), 0.0, 1.0);
	vshade = vary * depth;
	float cd = distance(cam, wpos);
	vhaze = haze_amt * smoothstep(haze_start, haze_end, cd);
}

void fragment() {
	vec4 tex = texture(fans, vec3(uv, layer));
	// mute: desaturate + soften contrast so the crowd stops reading as bright shiny
	// speckles, THEN darken/cool (tint), THEN haze-fade the far rows.
	vec3 c = tex.rgb;
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(luma), desat);
	c = clamp((c - vec3(0.5)) * crowd_contrast + vec3(0.5), 0.0, 1.0);
	c = c * tint * vshade;
	ALBEDO = mix(c, haze_color, vhaze);
	ALPHA = tex.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
