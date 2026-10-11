shader_type spatial;
// recolours the RED parts of a prop's texture (e.g. the parasol canopy) to a chosen
// `canopy` colour, keeping its shading, and leaves white / wood / neutral parts
// alone. lets one red-and-white parasol texture become any colour for variety.
render_mode cull_disabled;

uniform sampler2D albedo_tex : source_color;
uniform vec3 canopy : source_color = vec3(0.20, 0.55, 0.85);

void fragment() {
	vec4 t = texture(albedo_tex, UV);
	// how strongly "red/canopy" this texel is vs white/neutral/wood
	float redness = clamp((t.r - t.g) + (t.r - t.b), 0.0, 1.0);
	// recolour the canopy, preserving its brightness; keep everything else
	vec3 recol = canopy * (0.55 + 0.65 * t.r);
	ALBEDO = mix(t.rgb, recol, redness);
}
