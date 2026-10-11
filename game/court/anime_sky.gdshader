// REUSABLE STYLIZED ANIME SKY. A clean cartoon sky for any outdoor-facing stage
// -- the school gym's windows, and the beach / grass courts. All look is uniforms
// (gradient, sun, cloud coverage/tint/drift) so each stage can dress it
// differently. Cheap: the sky renders once per frame, no geometry.
//
// Clouds use GRADIENT (Perlin-style) noise + domain warping for soft, puffy
// shapes -- value noise showed its grid as blocks, and the old horizon projection
// stretched to infinity (the streaky look). Here the projection is clamped and
// clouds fade before the horizon so they never smear.
shader_type sky;

uniform vec3 top_color : source_color = vec3(0.08, 0.40, 0.96);
uniform vec3 horizon_color : source_color = vec3(0.42, 0.72, 1.0);
uniform vec3 cloud_color : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 cloud_shade : source_color = vec3(0.74, 0.83, 0.96);
uniform vec3 sun_color : source_color = vec3(1.0, 0.97, 0.88);
uniform vec3 sun_dir = vec3(-0.45, 0.62, 0.15);
uniform float cloud_cover : hint_range(0.0, 1.0) = 0.6;
uniform float cloud_scale = 1.05;
uniform float cloud_drift = 0.004;
uniform float cloud_softness : hint_range(0.01, 0.6) = 0.055;

// gradient (Perlin-style) noise -- smoother than value noise, no blocky grid
vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453) * 2.0 - 1.0;
}

float gnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = dot(hash2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0));
	float b = dot(hash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
	float c = dot(hash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
	float d = dot(hash2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y) * 0.5 + 0.5;
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 5; i++) {
		v += amp * gnoise(p);
		p *= 2.02;
		amp *= 0.5;
	}
	return v;
}

void sky() {
	vec3 dir = EYEDIR;

	// vertical gradient: deep blue overhead easing to a pale horizon
	float t = clamp(dir.y, 0.0, 1.0);
	vec3 col = mix(horizon_color, top_color, pow(t, 0.5));

	// sun: a soft disc plus a wide warm glow
	vec3 sd = normalize(sun_dir);
	float s = max(dot(dir, sd), 0.0);
	col += sun_color * pow(s, 1500.0) * 4.0;
	col += sun_color * pow(s, 6.0) * 0.16;

	// clouds -- upper hemisphere only. Clamped projection + horizon fade keep the
	// noise from stretching into blocks; domain warp makes soft puffy shapes.
	if (dir.y > 0.02) {
		vec2 uv = dir.xz / (dir.y + 0.32) * cloud_scale;
		uv += vec2(TIME * cloud_drift, TIME * cloud_drift * 0.4);
		vec2 warp = vec2(fbm(uv + vec2(1.7, 9.2)), fbm(uv + vec2(8.3, 2.8)));
		float d = fbm(uv + warp * 1.4);
		d = smoothstep(0.3, 0.8, d);     // more contrast -> defined toony bodies
		float edge = 1.0 - cloud_cover;
		// crisp cloud edge (toon), plus a hard-ish two-tone: a flat shaded rim
		// around a flat white core, so it reads as cel-shaded rather than blurry.
		float mask = smoothstep(edge, edge + cloud_softness, d);
		mask *= smoothstep(0.02, 0.16, dir.y);
		vec3 cloud = mix(cloud_shade, cloud_color,
			smoothstep(edge + 0.06, edge + 0.14, d));
		col = mix(col, cloud, mask);
	}

	COLOR = col;
}
