// procedural volleyball panels: yellow with blue bands, computed from the
// object-space normal so the pattern spins with the ball. no texture assets.
// shading is the character cel shader's language (see game/fx/toon.gdshader):
// one hard camera-relative shade band so the ball reads like the anime ball
// from every angle -- a crescent of shadow, not real lighting.
shader_type spatial;
render_mode unshaded;

// hard hide for the placeholder once a stage ball model dresses over it. a
// shader discard works in EVERY renderer; GeometryInstance3D.transparency (the
// node property this replaced) is a no-op in the Compatibility/OpenGL fallback,
// which left the procedural sphere z-fighting the authored ball there.
uniform float hidden = 0.0;
uniform vec4 color_a : source_color = vec4(1.0, 0.87, 0.25, 1.0);
uniform vec4 color_b : source_color = vec4(0.16, 0.35, 0.85, 1.0);
uniform float spin = 0.0;
// view-space key: -x left, +y up, +z toward the camera (same as characters)
uniform vec3 key_dir = vec3(-0.45, 0.62, 0.65);
uniform float band_edge = 0.12;     // where the single band splits
uniform float shade = 0.34;         // how much darker the shaded crescent is
uniform float band_softness = 0.02; // a hair of AA on the terminator
uniform float level = 1.0;          // lit half stays at the diffuse's own level

varying vec3 obj_normal;

void vertex() {
	obj_normal = NORMAL;
}

void fragment() {
	if (hidden > 0.5) {
		discard;
	}
	vec3 n = normalize(obj_normal);
	// topspin: rotate the pattern head-over-heels around the local x axis
	float c = cos(spin);
	float s = sin(spin);
	n = vec3(n.x, c * n.y - s * n.z, s * n.y + c * n.z);
	float band_y = 1.0 - smoothstep(0.24, 0.3, abs(n.y));
	float band_x = 1.0 - smoothstep(0.24, 0.3, abs(n.x));
	float blue = clamp(band_y + band_x, 0.0, 1.0);
	vec3 base = mix(color_a.rgb, color_b.rgb, blue);
	// the haikyuu band: one hard terminator against the fake key
	float lit = smoothstep(band_edge - band_softness, band_edge + band_softness,
		dot(normalize(NORMAL), normalize(key_dir)));
	ALBEDO = base * level * mix(1.0 - shade, 1.0, lit);
}
