// FAKE SHADOW. A flat soft-edged dark blob laid on the floor under a prop (bench,
// ref stand, net post, table) so it reads as grounded -- the cheap fake of a cast
// shadow, no real lights needed. MULTIPLY blend so it only ever DARKENS the surface
// under it (never lightens, never shows a hard quad edge). Drop it in the editor,
// scale/rotate to match the prop's footprint. Pairs with the env_paint look system.
shader_type spatial;
render_mode blend_mul, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 shadow_color : source_color = vec3(0.26, 0.26, 0.3); // how dark at core
uniform float strength : hint_range(0.0, 1.0) = 0.8;
uniform float softness : hint_range(0.0, 1.0) = 0.55;            // edge feather

void fragment() {
	// radial falloff: 0 at centre, 1 at the quad edge (an ellipse if scaled non-uniform)
	float d = length((UV - 0.5) * 2.0);
	float mask = (1.0 - smoothstep(1.0 - softness, 1.0, d)) * strength;
	// blend_mul: white = no change, shadow_color = darkened. Feather between them.
	ALBEDO = mix(vec3(1.0), shadow_color, mask);
}
