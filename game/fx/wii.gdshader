// "Wii Sports" character shader: no outline at all, soft wrapped diffuse, a
// broad glossy specular and a fresnel rim. The opposite art direction to
// toon.gdshader, which splits the body with one hard cel band and leans on an
// ink line to separate it from the court.
//
// The separation here comes from LIGHT instead of ink: the fresnel rim lifts
// every silhouette off the background, and the specular gives the plastic-toy
// sheen those characters have. That is why the rim is not optional decoration
// -- with the outline gone it is the only thing keeping a dark-haired player
// readable against a dark hall.
//
// Like the cel shader, the key is FAKE and camera-relative, so a character is
// lit identically from every angle and the game never depends on where the
// court's lights happen to be. Readability stays art direction, not lighting.
shader_type spatial;

uniform float hidden : hint_range(0.0, 1.0) = 0.0;
render_mode unshaded, cull_back;

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// view-space key: -x left, +y up, +z toward the camera
uniform vec3 key_dir = vec3(-0.42, 0.55, 0.72);
uniform float world_mix = 0.0;
uniform vec3 world_key = vec3(-0.45, 0.78, 0.44);

// WRAPPED diffuse. a plain lambert leaves half the body in flat shadow, which
// on these round shapes reads as dirt. wrapping pushes the terminator around
// the back so the gradient stays gentle all the way across.
uniform float wrap : hint_range(0.0, 1.0) = 0.62;
uniform float ambient : hint_range(0.0, 1.0) = 0.72;
uniform float level = 1.06;

// broad and bright rather than tight and sharp -- vinyl, not polished metal
uniform vec4 spec_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float spec_power : hint_range(1.0, 128.0) = 14.0;
uniform float spec_intensity : hint_range(0.0, 2.0) = 0.5;

uniform vec4 fresnel_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float fresnel_power : hint_range(0.5, 8.0) = 3.2;
uniform float fresnel_intensity : hint_range(0.0, 2.0) = 0.42;

void fragment() {
	// gear left at home (gym socks/kneepads off) simply is not there. discard
	// also removes it from the screen-space ink pass: no fragments, no
	// silhouette. the grown-shell outline is handled per surface in ModelRig.
	if (hidden > 0.5) {
		discard;
	}
	vec3 n = normalize(NORMAL);
	vec3 l = normalize(key_dir);
	if (world_mix > 0.001) {
		// NORMAL is view space, so a world-anchored key has to come along
		vec3 wk = normalize((VIEW_MATRIX * vec4(normalize(world_key), 0.0)).xyz);
		l = normalize(mix(l, wk, world_mix));
	}
	// in view space the eye is straight down -z, so the view vector is +z
	vec3 v = normalize(VIEW);

	float ndl = dot(n, l);
	float diffuse = clamp((ndl + wrap) / (1.0 + wrap), 0.0, 1.0);
	float light = mix(ambient, 1.0, diffuse);

	vec3 h = normalize(l + v);
	float spec = pow(max(dot(n, h), 0.0), spec_power) * spec_intensity;

	// n.v -> 0 at the silhouette, so this is a rim
	float fres = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), fresnel_power)
		* fresnel_intensity;

	vec3 col = albedo.rgb * level * light;
	col += spec_color.rgb * spec;
	col += fresnel_color.rgb * fres;
	ALBEDO = col;
}
