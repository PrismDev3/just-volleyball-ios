// NET GRADIENT: the fake-lit look for the net posts and their pads. A vertical
// ramp (darker at the base, lighter toward the top) keeps the flat cylinders
// from reading as one tone; on top of that a FAKE METAL SHINE: a bright
// stripe where the surface faces a fixed world light, a soft second stripe
// opposite it (the environment bouncing back), and a dark rim at the
// silhouette. All view-independent by design -- a cel look that reads the
// same from every camera. Pads use a low shine (fabric), posts a high one.
shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.2, 0.4, 0.85);
uniform float grad_from = 0.0;    // world y (metres) where the ramp is darkest
uniform float grad_to = 3.0;      // world y where it's lightest
uniform float dark = 0.74;        // brightness multiplier at the bottom
uniform float light = 1.12;       // brightness multiplier at the top
uniform float roughness = 0.8;
uniform float shine : hint_range(0.0, 1.0) = 0.6;      // strength of the highlight stripe
uniform float shine_width : hint_range(0.02, 0.6) = 0.14;
uniform float rim_dark : hint_range(0.0, 1.0) = 0.35;  // darkening at the silhouette
uniform vec3 light_dir = vec3(-0.55, 0.35, 0.75);      // world, toward the light

varying float vy;
varying vec3 vnormal;

void vertex() {
	vy = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;   // world height of this vertex
	vnormal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float t = clamp((vy - grad_from) / max(grad_to - grad_from, 0.001), 0.0, 1.0);
	vec3 col = base_color * mix(dark, light, t);
	// the highlight: how squarely this bit of the cylinder faces the light
	vec3 n = normalize(vnormal);
	vec3 l = normalize(light_dir);
	float facing = dot(n, l);
	float hi = smoothstep(1.0 - shine_width * 1.6, 1.0 - shine_width * 0.4, facing);
	// a narrower hot core inside the stripe, so it reads as metal not paint
	float core = smoothstep(1.0 - shine_width * 0.5, 1.0, facing);
	// the bounce: a faint stripe on the far side
	float back = smoothstep(1.0 - shine_width * 1.2, 1.0, -facing) * 0.35;
	col += (hi * 0.45 + core * 0.35 + back) * shine * vec3(1.0);
	// the silhouette rim: the side of the cylinder facing neither the light
	// nor away from it goes darker, which is what rounds it off
	float side = 1.0 - abs(facing);
	col *= 1.0 - rim_dark * smoothstep(0.55, 1.0, side) * (1.0 - hi);
	ALBEDO = col;
	ROUGHNESS = roughness;
}
