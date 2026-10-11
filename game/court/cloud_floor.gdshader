// CLOUD FLOOR: the "clouds" bonus stage ground -- a still mirror lake under the
// anime sky. The lake evaluates the SAME sky math as game/court/anime_sky.gdshader
// (uniforms + functions kept identical) for the view ray mirrored through the
// floor, so the reflection matches the sky pixel for pixel and the horizon has no
// seam. Unshaded on purpose: a lit metallic mirror picked up every scene light as
// a hot dot (the "lamp reflections") and the sky radiance cube smeared the
// clouds. Player/ball bodies come from the FloorReflector mirror pass
// (reflect_tex at SCREEN_UV, blurred + faded away from the feet, like the court
// floor). Footfalls stamp RIPPLES: expanding rings that bend the mirror normal,
// so the reflected sky wobbles outward from every step, plus a faint bright rim.
// cloud_ripples.gd pushes the ripple list (x, z, age, strength) + the feet.
shader_type spatial;
render_mode unshaded, cull_back;

// --- sky (mirror of anime_sky.gdshader; keep the two in step) ---
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
// WATER, not a flat mirror: looking steeply down, real water shows its own deep
// colour and only a little sky (fresnel); at grazing angles it becomes a pure
// mirror -- which is also what makes the far lake IDENTICAL to the sky at the
// horizon (no seam). A slow large-scale swell tilts the mirror a hair so the
// reflected gradient breathes instead of reading as one flat blue.
uniform vec3 deep_color : source_color = vec3(0.16, 0.42, 0.86);
uniform float fresnel_power : hint_range(1.0, 8.0) = 3.0;
uniform float fresnel_min : hint_range(0.0, 1.0) = 0.35;  // mirror share looking straight down
uniform float swell_amp : hint_range(0.0, 0.2) = 0.035;
uniform float swell_scale = 0.04;                          // 1/m: bigger = smaller swells
uniform float swell_speed = 0.12;
// horizon haze: the last stretch before the horizon eases into the sky's own
// horizon colour so lake and sky meet in a soft band, not a line
uniform float haze_start = 60.0;
uniform float haze_end = 900.0;

// --- baked sky (cloud_sky_bake.gdshader) ---
// the gradient+clouds evaluated once into an equirect texture so the lake
// SAMPLES the sky instead of running 3x fbm(5 octaves) per pixel every frame
// (the low-end fps killer). the sun is still added analytically below so it
// stays a sharp point. sky_baked flips on once cloud_ripples.gd has rendered it.
uniform sampler2D sky_tex : filter_linear, repeat_enable;
uniform bool sky_baked = false;

// --- bodies (FloorReflector) ---
uniform sampler2D reflect_tex : filter_linear;
uniform bool reflect_on = false;
uniform float reflectivity : hint_range(0.0, 1.0) = 0.85;
uniform float reflect_blur = 3.0;      // texels between blur taps
uniform float reflect_near = 0.6;      // full strength this close to a foot (m)
uniform float reflect_far = 2.6;       // gone this far from every foot (m)
uniform vec4 feet[8];                  // x,y,z,1 per body (0 = empty slot)

// --- ripples ---
const int MAX_RIPPLES = 40;
uniform int ripple_count = 0;
uniform vec4 ripples[40];          // x, z, age (s), strength
uniform float ripple_speed = 1.0;  // m/s the ring expands
uniform float ripple_width = 0.16; // ring thickness (m)
uniform float ripple_life = 1.5;   // seconds until a ring is gone
uniform float ripple_bend = 0.45;  // how hard a ring tilts the mirror
uniform float ripple_glow = 0.07;  // faint rim brightness

varying vec3 wpos;

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

// gradient + clouds, NO sun -- this is what the bake captures (cloud_sky_bake.gdshader,
// keep the two in step). the analytic fallback runs when the bake hasn't landed.
vec3 sky_body(vec3 dir) {
	float t = clamp(dir.y, 0.0, 1.0);
	vec3 col = mix(horizon_color, top_color, pow(t, 0.5));
	if (dir.y > 0.02) {
		vec2 uv = dir.xz / (dir.y + 0.32) * cloud_scale;
		uv += vec2(TIME * cloud_drift, TIME * cloud_drift * 0.4);
		vec2 warp = vec2(fbm(uv + vec2(1.7, 9.2)), fbm(uv + vec2(8.3, 2.8)));
		float d = fbm(uv + warp * 1.4);
		d = smoothstep(0.3, 0.8, d);
		float edge = 1.0 - cloud_cover;
		float mask = smoothstep(edge, edge + cloud_softness, d);
		mask *= smoothstep(0.02, 0.16, dir.y);
		vec3 cloud = mix(cloud_shade, cloud_color,
			smoothstep(edge + 0.06, edge + 0.14, d));
		col = mix(col, cloud, mask);
	}
	return col;
}

// the sun: a tight disc + a wide warm glow. always analytic (cheap, and a baked
// point sun would alias into a blocky splotch)
vec3 sun_term(vec3 dir) {
	vec3 sd = normalize(sun_dir);
	float s = max(dot(dir, sd), 0.0);
	return sun_color * pow(s, 1500.0) * 4.0 + sun_color * pow(s, 6.0) * 0.16;
}

vec3 sky(vec3 dir) {
	vec3 base;
	if (sky_baked) {
		// equirect sample; repeat_enable makes the azimuth seam blend
		float u = atan(dir.z, dir.x) * 0.15915494 + 0.5;
		float v = acos(clamp(dir.y, -1.0, 1.0)) * 0.31830989;
		base = texture(sky_tex, vec2(u, v)).rgb;
	} else {
		base = sky_body(dir);
	}
	return base + sun_term(dir);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// ripples: sum of ring profiles, and their radial slope for the normal bend
	vec2 slope = vec2(0.0);
	float rim = 0.0;
	for (int i = 0; i < MAX_RIPPLES; i++) {
		if (i >= ripple_count) { break; }
		vec4 r = ripples[i];
		float age = r.z;
		if (age < 0.0 || age > ripple_life) { continue; }
		vec2 d = wpos.xz - r.xy;
		float dist = length(d);
		float radius = age * ripple_speed;
		float w = ripple_width * (1.0 + age * 0.6);
		float x = (dist - radius) / w;
		float ring = exp(-x * x);
		float fade = (1.0 - age / ripple_life);
		fade = fade * fade * fade;   // dies gently: near zero well before it's dropped
		float amp = ring * fade * r.w;
		slope += (d / max(dist, 0.001)) * (-2.0 * x / w) * amp;
		rim += amp;
	}
	// slow swell: two drifting noise lobes tilt the surface very slightly
	vec2 sp = wpos.xz * swell_scale + vec2(TIME * swell_speed, TIME * swell_speed * 0.7);
	vec2 sw = vec2(gnoise(sp) - 0.5, gnoise(sp + vec2(3.1, 7.7)) - 0.5) * swell_amp * 2.0;
	vec3 n_world = normalize(vec3(-slope.x * ripple_bend + sw.x, 1.0, -slope.y * ripple_bend + sw.y));
	// the view ray, mirrored through the (rippled) surface, sampled from the sky
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 to_p = wpos - cam;
	float dist = length(to_p);
	vec3 view = to_p / max(dist, 0.001);
	vec3 refl = reflect(view, n_world);
	refl.y = max(refl.y, 0.002);   // a ring can tip the ray under the horizon: clamp
	vec3 mirror = sky(normalize(refl));
	// fresnel: steep view = water's own colour shows through, grazing = pure mirror
	float cosv = clamp(-view.y, 0.0, 1.0);
	float fres = mix(fresnel_min, 1.0, pow(1.0 - cosv, fresnel_power));
	vec3 col = mix(deep_color, mirror, fres);
	// soft horizon: ease the far lake into the sky's horizon colour
	col = mix(col, horizon_color, smoothstep(haze_start, haze_end, dist) * 0.85);
	col += vec3(rim * ripple_glow);
	if (reflect_on) {
		// soft mirror: a box blur so the body reads like a reflection in water,
		// not a razor-sharp second sprite
		vec2 texel = 1.0 / vec2(textureSize(reflect_tex, 0));
		vec4 body = vec4(0.0);
		float wsum = 0.0;
		for (int x = -2; x <= 2; x++) {
			for (int y = -2; y <= 2; y++) {
				float w = 1.0 / (1.0 + float(x * x + y * y));
				body += texture(reflect_tex,
					SCREEN_UV + vec2(float(x), float(y)) * texel * reflect_blur) * w;
				wsum += w;
			}
		}
		body /= wsum;
		// fade with distance from the nearest body's feet: full right under
		// them, gone a couple of metres out (a real reflection dissolves as the
		// water's ripples and depth take over)
		float fade = 0.0;
		bool any = false;
		for (int i = 0; i < 8; i++) {
			if (feet[i].w < 0.5) { continue; }
			any = true;
			float d = distance(wpos.xz, vec2(feet[i].x, feet[i].z));
			fade = max(fade, 1.0 - smoothstep(reflect_near, reflect_far, d));
		}
		if (!any) { fade = 1.0; }
		col = mix(col, body.rgb, body.a * reflectivity * fade);
	}
	ALBEDO = col;
}
