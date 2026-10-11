// character cel shader: flat albedo split by exactly one hard shade band.
// the key light is FAKE and camera-relative -- it rides the viewer's shoulder
// instead of living in the world, so a character is lit identically from
// every angle and the band always falls the same way on screen. that's the
// whole point: readability is art direction here, not lighting (design doc:
// flat-color cel art, no textures on characters).
shader_type spatial;

uniform float hidden : hint_range(0.0, 1.0) = 0.0;
render_mode unshaded, cull_back;

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// view-space key: -x left, +y up, +z toward the camera
uniform vec3 key_dir = vec3(-0.45, 0.62, 0.65);
// how much the key is anchored to the world instead of the camera. 0 keeps
// characters perfectly readable from any angle; nudge up for a little
// form-following shading at the cost of dark backsides
uniform float world_mix = 0.0;
uniform vec3 world_key = vec3(-0.45, 0.78, 0.44);
uniform float band_edge = 0.12;    // where the single band splits
uniform float shade = 0.42;        // how much darker the shaded half is
uniform float band_softness = 0.02; // a hair of AA on the terminator
// unshaded means albedo goes straight to screen, so the lit half needs
// pulling down to sit in the court's exposure instead of glowing
uniform float level = 0.8;

void fragment() {
	// gear left at home (gym socks/kneepads off) simply is not there. discard
	// also removes it from the screen-space ink pass: no fragments, no
	// silhouette. the grown-shell outline is handled per surface in ModelRig.
	if (hidden > 0.5) {
		discard;
	}
	vec3 n = normalize(NORMAL);
	vec3 view_key = normalize(key_dir);
	vec3 l = view_key;
	if (world_mix > 0.001) {
		// NORMAL is view space, so a world-anchored key has to come along
		vec3 wk = normalize((VIEW_MATRIX * vec4(normalize(world_key), 0.0)).xyz);
		l = normalize(mix(view_key, wk, world_mix));
	}
	float lit = smoothstep(band_edge - band_softness, band_edge + band_softness,
		dot(n, l));
	ALBEDO = albedo.rgb * level * mix(1.0 - shade, 1.0, lit);
}
