shader_type spatial;
// a soft-edged RECTANGULAR ground shadow (multiply blend), for boxy buildings --
// the radial shadow_blob read as an oval that didn't match a building's footprint.
// UV 0..1 across a flat FACE_Y quad; scale the quad to the footprint and this fills
// it as a rectangle with a feathered edge.
render_mode blend_mul, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 shadow_color : source_color = vec3(0.15, 0.15, 0.19);
uniform float strength : hint_range(0.0, 1.0) = 0.85;
uniform float softness : hint_range(0.0, 1.0) = 0.28;   // edge feather (fraction)
uniform float corner : hint_range(0.0, 0.5) = 0.12;     // round the corners a touch

void fragment() {
	// distance from centre toward the edges, 0..1 per axis
	vec2 p = abs(UV - 0.5) * 2.0;
	// rounded-box distance: square core, slightly rounded corners so it isn't a
	// hard-cornered rectangle (reads softer/more natural under a building)
	vec2 q = max(p - (1.0 - corner), vec2(0.0));
	float m = max(max(p.x, p.y) - corner, length(q));
	float a = (1.0 - smoothstep(1.0 - softness, 1.0, m)) * strength;
	ALBEDO = mix(vec3(1.0), shadow_color, a);
}
