shader_type spatial;
// dirt-cheap beach towel: a flat quad with a two-colour STRIPE pattern. colours +
// stripe count are uniforms so each towel can be recoloured. lit like everything
// else (no unshaded) so it sits in the scene. one quad, no texture.
render_mode cull_disabled;

uniform vec4 color_a : source_color = vec4(0.90, 0.25, 0.25, 1.0);
uniform vec4 color_b : source_color = vec4(0.96, 0.95, 0.90, 1.0);
uniform float stripes = 6.0;
uniform float border : hint_range(0.0, 0.2) = 0.06;   // plain edge band

void fragment() {
	float s = step(0.5, fract(UV.x * stripes));
	vec3 c = mix(color_a.rgb, color_b.rgb, s);
	// a plain border so it reads as a towel, not just a striped card
	float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	if (edge < border) {
		c = color_b.rgb;
	}
	ALBEDO = c;
	ROUGHNESS = 0.95;
}
