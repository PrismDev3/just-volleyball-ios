// TRANSPARENT floor overlay -- for venues that own a real floor (the school
// gym's wood boards). It is the SAME sweat + mirror-reflection read as
// floor_sweat.gdshader, but it draws ONLY those effects over transparency, so
// the boards underneath show through and the two floors never z-fight. It sits
// a hair above the boards and, being court-sized, keeps sweat on the court
// instead of smearing it across the whole hall.
//
// The arena floors still use the OPAQUE floor_sweat -- the "never make the floor
// transparent" rule was about a floor over empty void; here real boards sit
// behind this, which is the whole point. Uniforms match floor_sweat so the match
// drives sweat / reflect_on / feet identically.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never;

uniform float sweat = 0.0;
uniform sampler2D reflect_tex : filter_linear;
uniform bool reflect_on = false;
uniform float reflectivity : hint_range(0.0, 1.0) = 0.42;
uniform vec4 feet[8];
uniform vec4 gloss_tint : source_color = vec4(0.62, 0.72, 0.85, 1.0);
uniform float gloss_strength : hint_range(0.0, 1.5) = 0.55;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += amp * vnoise(p);
		p *= 2.03;
		amp *= 0.5;
	}
	return v;
}

void fragment() {
	// --- sweat pools + sheen + sparkle: identical read to floor_sweat ---
	float n = fbm(world_pos.xz * 1.5);
	float cut = mix(1.02, 0.52, sweat * (2.0 - sweat));
	float pool = smoothstep(cut, cut + 0.42, n);

	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_pos);
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 m1 = normalize(reflect(-normalize(vec3(0.35, 0.9, 0.25)), up));
	vec3 m2 = normalize(reflect(-normalize(vec3(-0.4, 0.85, -0.3)), up));
	float sheen = pow(max(dot(m1, view_dir), 0.0), 5.0)
		+ 0.7 * pow(max(dot(m2, view_dir), 0.0), 8.0);

	float wet_gate = smoothstep(0.04, 0.30, sweat);

	vec2 gp = world_pos.xz * 5.0;
	vec2 gc = floor(gp);
	float g1 = hash21(gc + vec2(11.3, 2.7));
	float g2 = hash21(gc + vec2(4.9, 8.1));
	float g3 = hash21(gc + vec2(6.2, 13.5));
	vec2 gf = fract(gp) - vec2(0.5) - (vec2(g2, g3) - vec2(0.5)) * 0.72;
	float grad = mix(0.06, 0.17, g3);
	float glint = step(g1, wet_gate * 0.30)
		* (1.0 - smoothstep(grad * 0.3, grad, length(gf)))
		* (0.12 + pool * 0.88);

	float wetness = clamp(pool, 0.0, 1.0) * wet_gate;

	// a damp floor reads DARKER, not just glossier -- draw a dark translucent
	// layer where the sweat pools so it's visible from ANY angle (the old overlay
	// only added grazing-angle gloss, which was near-invisible on bright boards).
	// The gloss / sheen / sparkle below add the wet highlights on top. Dry, un-
	// reflected floor stays fully see-through (alpha 0).
	vec3 fx = vec3(0.10, 0.09, 0.07);
	float a = wetness * 0.5;

	float ndv = max(dot(up, view_dir), 0.0);
	float fresnel = pow(1.0 - ndv, 4.0);
	float gloss = fresnel * wetness * gloss_strength;
	fx += gloss_tint.rgb * gloss;
	a = max(a, gloss);

	float band = sheen * wetness * 1.5;
	fx += vec3(0.22, 0.26, 0.30) * band;
	a = max(a, band * 0.8);

	float spark = glint * wet_gate * (0.1 + smoothstep(0.03, 0.45, sheen) * 1.15);
	fx += vec3(0.85, 0.93, 1.0) * spark;
	a = max(a, spark);

	if (reflect_on) {
		vec2 texel = 1.0 / vec2(textureSize(reflect_tex, 0));
		vec4 refl = vec4(0.0);
		float wsum = 0.0;
		for (int x = -2; x <= 2; x++) {
			for (int y = -2; y <= 2; y++) {
				float w = 1.0 / (1.0 + float(x * x + y * y));
				refl += texture(reflect_tex,
					SCREEN_UV + vec2(float(x), float(y)) * texel * 4.0) * w;
				wsum += w;
			}
		}
		refl /= wsum;
		float fade = 0.0;
		bool any = false;
		for (int i = 0; i < 8; i++) {
			if (feet[i].w < 0.5) { continue; }
			any = true;
			float d = distance(world_pos.xz, vec2(feet[i].x, feet[i].z));
			fade = max(fade, 1.0 - smoothstep(0.35, 1.9, d));
		}
		if (!any) { fade = 1.0; }
		float strength = clamp(reflectivity + wetness * 0.9, 0.0, 0.98) * fade;
		// the mirrored bodies show over the boards; alpha is the reflection's
		// own coverage so empty floor stays clear
		fx = mix(fx, refl.rgb, refl.a * strength);
		a = max(a, refl.a * strength);
	}

	ALBEDO = fx;
	ALPHA = clamp(a, 0.0, 1.0);
}
