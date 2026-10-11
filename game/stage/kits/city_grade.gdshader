shader_type spatial;
// a material_OVERLAY that blends buildings into the sky: a sky-tinted veil that is
// transparent at the base and fades in toward the top, so tall buildings melt into
// the haze instead of reading as hard solid cut-outs dropped on the sand. Cheap,
// unshaded; rides over each building's own material as a second pass.
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never;

uniform vec4 sky_tint : source_color = vec4(0.72, 0.85, 0.95, 1.0);
uniform float base_y = 6.0;     // world height where the veil starts
uniform float top_y = 48.0;     // world height where it reaches full strength
uniform float amount : hint_range(0.0, 1.0) = 0.35;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	ALBEDO = sky_tint.rgb;
	ALPHA = clamp(smoothstep(base_y, top_y, world_pos.y) * amount, 0.0, 1.0);
}
