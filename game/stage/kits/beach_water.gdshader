shader_type spatial;
// 2000s-era stylized ocean with REAL geometry waves. The plane is subdivided and
// the VERTEX shader raises the points into rolling swells (three directional sine
// waves summed), with analytic normals so the lighting follows the humps. On top of
// that: a scrolling normal map for micro-ripple sparkle, a fake sun specular, a
// fresnel sky reflection, a wavy discard shoreline, and rolling shore foam.
//
// Amplitude tapers to ZERO at the shore (so waves never clip the beach) and the base
// height tapers too, so the flat shoreline meets the sand while the open sea swells.
// Troughs stay above the sand/land planes so no seabed pokes through.
render_mode unshaded, cull_disabled;

uniform sampler2D water_normal : hint_normal, repeat_enable, filter_linear_mipmap;

uniform vec4 water_deep : source_color = vec4(0.02, 0.20, 0.42, 1.0);
uniform vec4 water_shallow : source_color = vec4(0.10, 0.55, 0.68, 1.0);
uniform vec4 sky_col : source_color = vec4(0.60, 0.85, 0.95, 1.0);
uniform vec4 sun_col : source_color = vec4(1.0, 1.0, 0.95, 1.0);
uniform vec4 foam_col : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec3 sun_dir = vec3(-0.4, 0.75, 0.35);
uniform float nmap_scale = 0.045;
uniform float nmap_scale2 = 0.13;
uniform float wave_speed = 0.4;
uniform float normal_strength = 0.5;
uniform float shininess = 80.0;
uniform float spec_amount = 0.8;
uniform float wave_time = 0.0;

// GEOMETRY WAVES
uniform float wave_amp = 0.45;       // swell height in metres (open sea)
uniform float wave_len = 16.0;       // main swell wavelength in metres
uniform float sea_base = 0.5;        // water rest height out at sea (must exceed wave_amp so troughs clear the sand)
uniform float shore_base = 0.04;     // water height right at the shoreline (meets the sand)
uniform float wave_fade_dist = 24.0; // over how many metres the swell grows from shore to open sea

// shoreline
uniform float shore_x = 15.0;
uniform float shore_amp = 7.0;
uniform float shore_width = 8.0;
uniform float shore_foam_amount = 0.9;
// rolling breakers + swash
uniform float breaker_freq = 0.22;
uniform float breaker_speed = 1.6;
uniform float breaker_reach = 34.0;
uniform float swash = 0.30;

varying vec3 world_pos;
varying vec3 wave_normal;

// summed directional swells. returns height (~-1..1) and fills grad (dh/dx, dh/dz).
float wave_h(vec2 xz, float t, out vec2 grad) {
	float k = TAU / wave_len;
	grad = vec2(0.0);
	float h = 0.0;
	vec2 d1 = normalize(vec2(0.95, 0.31)); float ph1 = dot(xz, d1) * k + t * 1.0;
	h += 0.5 * sin(ph1);  grad += 0.5 * cos(ph1) * k * d1;
	vec2 d2 = normalize(vec2(-0.38, 0.92)); float ph2 = dot(xz, d2) * (k * 0.65) - t * 0.8;
	h += 0.32 * sin(ph2); grad += 0.32 * cos(ph2) * (k * 0.65) * d2;
	vec2 d3 = normalize(vec2(0.70, -0.71)); float ph3 = dot(xz, d3) * (k * 1.7) + t * 1.3;
	h += 0.18 * sin(ph3); grad += 0.18 * cos(ph3) * (k * 1.7) * d3;
	return h;
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;   // flat world pos
	// grow the swell from 0 at the shore to full out at sea; taper the rest height too
	float af = smoothstep(shore_x, shore_x + wave_fade_dist, wp.x);
	float base = mix(shore_base, sea_base, af);
	vec2 grad;
	float h = wave_h(wp.xz, wave_time * wave_speed, grad) * wave_amp * af;
	float target_y = base + h;
	VERTEX.y += target_y - wp.y;   // translation-only model: local delta == world delta
	world_pos = vec3(wp.x, target_y, wp.z);
	// analytic normal of the displaced surface (grad already scaled by amp*af below)
	vec2 g = grad * wave_amp * af;
	wave_normal = normalize(vec3(-g.x, 1.0, -g.y));
}

void fragment() {
	vec2 uv = world_pos.xz;
	float t = wave_time * wave_speed;

	// WAVY COASTLINE: discard the water on the beach side of a meandering line
	float c1 = texture(water_normal, vec2(world_pos.z * 0.012 + t * 0.004, 0.35)).x;
	float c2 = texture(water_normal, vec2(world_pos.z * 0.030 - t * 0.006, 0.70)).x;
	float shore_here = shore_x + ((c1 - 0.5) * 2.0 + (c2 - 0.5)) * shore_amp;
	if (world_pos.x < shore_here) {
		discard;
	}

	float dist = length(CAMERA_POSITION_WORLD - world_pos);
	float fade = clamp(1.0 - dist / 220.0, 0.0, 1.0);

	// micro-ripple detail from the scrolling normal map, layered on the wave normal
	vec3 n1 = texture(water_normal, uv * nmap_scale + vec2(t * 0.020, t * 0.015)).xyz * 2.0 - 1.0;
	vec3 n2 = texture(water_normal, uv * nmap_scale2 - vec2(t * 0.017, t * 0.030)).xyz * 2.0 - 1.0;
	vec2 micro = (n1.xy + n2.xy) * normal_strength * fade;
	vec3 N = normalize(wave_normal + vec3(micro.x, 0.0, micro.y));

	vec3 V = normalize(CAMERA_POSITION_WORLD - world_pos);
	vec3 L = normalize(sun_dir);

	// SMOOTH depth gradient by wave height + a fresnel sky reflection (the toon 3-band
	// version read as blocky/aliased at grazing angles -- this is the smoother look).
	float fres = pow(clamp(1.0 - dot(N, V), 0.0, 1.0), 3.0);
	float crest = clamp(0.5 + (world_pos.y - sea_base) * 1.2, 0.0, 1.0);
	vec3 base_col = mix(water_deep.rgb, water_shallow.rgb, crest);
	vec3 col = mix(base_col, sky_col.rgb, fres * 0.65);

	// soft sun glint
	vec3 Hh = normalize(L + V);
	float spec = pow(max(dot(N, Hh), 0.0), shininess);
	col += sun_col.rgb * spec * spec_amount * fade;

	// soft shoreline foam + rolling breakers washing in
	float wob = n1.x * 2.0;
	float d = (world_pos.x - shore_here) + wob;
	float wash = 1.0 + swash * sin(wave_time * 0.5 + world_pos.z * 0.04);
	float band = 1.0 - smoothstep(0.0, shore_width * wash, d);
	float lace = smoothstep(0.45, 0.8, texture(water_normal, uv * 0.25 + t * 0.05).x);
	float foam = band * (0.35 + 0.65 * lace);
	float from_shore = max(d, 0.0);
	float roll = sin(from_shore * breaker_freq - wave_time * breaker_speed + n1.x * 3.0);
	float breaker = smoothstep(0.55, 0.95, roll)
			* (1.0 - smoothstep(0.0, breaker_reach, from_shore));
	foam = clamp(max(foam, breaker * 0.7), 0.0, 1.0);
	col = mix(col, foam_col.rgb, foam * shore_foam_amount);

	ALBEDO = col;
}
