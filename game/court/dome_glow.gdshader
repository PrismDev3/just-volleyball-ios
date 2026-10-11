shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

// Faint additive glow ring on the floor where the energy dome meets the ground --
// a cheap fake "volumetric" pool so the base blooms softly instead of hard-cutting
// into the terrain. Flat plane; the ring roughly follows the dome's footprint.

uniform vec3 tint : source_color = vec3(0.3, 0.65, 1.0);
uniform float inner = 0.72;      // ring radius as a fraction of the plane half-size
uniform float amt = 0.5;
uniform float pulse_speed = 0.7;

void fragment() {
	vec2 c = UV * 2.0 - 1.0;                 // -1..1 across the plane
	float r = length(c);
	float band = smoothstep(inner - 0.35, inner, r)
		* (1.0 - smoothstep(inner, inner + 0.3, r));
	float pulse = 0.85 + 0.15 * sin(TIME * pulse_speed);
	ALBEDO = tint;
	ALPHA = clamp(band * amt * pulse, 0.0, 1.0);
}
