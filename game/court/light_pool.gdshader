// FAKE SUNLIGHT ON THE FLOOR. A flat, additive, soft-edged patch laid on the
// boards where a window's light would land -- the warm streaks an anime gym floor
// catches. Pure fake: no real light, one additive quad, no depth write so it never
// occludes. Elongate + rotate the quad to make a streak; drag it under a window.
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 beam : source_color = vec4(1.0, 0.85, 0.55, 1.0); // warm sunlight
uniform float intensity : hint_range(0.0, 1.0) = 0.4;
uniform float softness : hint_range(0.0, 1.0) = 0.55;          // edge feather

void fragment() {
	// soft rectangle: fade toward all four edges so the patch has no hard border
	vec2 d = abs(UV - 0.5) * 2.0;
	float e = (1.0 - smoothstep(1.0 - softness, 1.0, d.x))
			* (1.0 - smoothstep(1.0 - softness, 1.0, d.y));
	ALBEDO = beam.rgb;
	ALPHA = clamp(e * intensity, 0.0, 1.0);
}
