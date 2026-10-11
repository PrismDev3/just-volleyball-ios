// CLOUD SKY BAKE. Renders the clouds stage's sky (gradient + clouds, no sun)
// into an EQUIRECTANGULAR texture, once, so the mirror lake (cloud_floor.gdshader)
// can SAMPLE the sky instead of recomputing 3x fbm(5 octaves) per pixel every
// frame on a 6 km plane -- the low-end fps killer. cloud_ripples.gd renders one
// ColorRect with this shader into a 2D SubViewport, grabs the image, and feeds
// it back as `sky_tex` (+ sky_baked = true) on the floor.
//
// COLOUR SPACE: the floor is a spatial shader whose `source_color` uniforms are
// LINEARISED (3D), so its sky mixes in linear space. A 2D canvas renders in
// sRGB, so to match we take the colours as plain (sRGB) values and linearise
// them HERE, mix in linear like the floor, and output the linear result raw.
// The canvas viewport stores those bytes as-is and the floor samples the texture
// WITHOUT source_color, so no decode is applied -- linear in, linear out.
//
// The gradient + cloud math is a COPY of cloud_floor.gdshader's sky_body() (which
// mirrors anime_sky.gdshader). Keep the three in step. Sun is left OUT (the floor
// adds it analytically so it stays a sharp point). Drift frozen at t = 0.
shader_type canvas_item;

// plain (sRGB) colours -- linearised in sky_body below to match the 3D floor
uniform vec3 top_color = vec3(0.08, 0.40, 0.96);
uniform vec3 horizon_color = vec3(0.42, 0.72, 1.0);
uniform vec3 cloud_color = vec3(1.0, 1.0, 1.0);
uniform vec3 cloud_shade = vec3(0.74, 0.83, 0.96);
uniform float cloud_cover : hint_range(0.0, 1.0) = 0.6;
uniform float cloud_scale = 1.05;
uniform float cloud_softness : hint_range(0.01, 0.6) = 0.055;

vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

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

// gradient + clouds for a view direction, in LINEAR space; NO sun.
vec3 sky_body(vec3 dir) {
	vec3 top = srgb_to_linear(top_color);
	vec3 horizon = srgb_to_linear(horizon_color);
	vec3 c_col = srgb_to_linear(cloud_color);
	vec3 c_shade = srgb_to_linear(cloud_shade);
	float t = clamp(dir.y, 0.0, 1.0);
	vec3 col = mix(horizon, top, pow(t, 0.5));
	if (dir.y > 0.02) {
		vec2 puv = dir.xz / (dir.y + 0.32) * cloud_scale;   // drift frozen at t=0
		vec2 warp = vec2(fbm(puv + vec2(1.7, 9.2)), fbm(puv + vec2(8.3, 2.8)));
		float d = fbm(puv + warp * 1.4);
		d = smoothstep(0.3, 0.8, d);
		float edge = 1.0 - cloud_cover;
		float mask = smoothstep(edge, edge + cloud_softness, d);
		mask *= smoothstep(0.02, 0.16, dir.y);
		vec3 cloud = mix(c_shade, c_col,
			smoothstep(edge + 0.06, edge + 0.14, d));
		col = mix(col, cloud, mask);
	}
	return col;
}

void fragment() {
	// equirect: UV.x -> azimuth (-PI..PI), UV.y -> polar (0 = straight up).
	// inverse of the floor's sample: u = atan(z,x)/2PI + 0.5, v = acos(y)/PI
	float az = (UV.x - 0.5) * 6.28318531;
	float el = UV.y * 3.14159265;
	float sy = sin(el);
	vec3 dir = vec3(sy * cos(az), cos(el), sy * sin(az));
	COLOR = vec4(sky_body(dir), 1.0);   // linear, stored raw (floor samples without decode)
}
