// jersey back patch. only the digits draw -- every other pixel is discarded
// so the shirt underneath shows through untouched. a shaded patch would cut
// its own band across the body and read as a panel stitched on.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

uniform vec4 ink : source_color = vec4(0.07, 0.07, 0.09, 1.0);
uniform sampler2D number_tex : source_color, filter_linear;
uniform float level = 0.8;
uniform bool flip_u = false;
uniform float lift = 0.004;   // stand off the shirt so it can't z-fight

void vertex() {
	VERTEX += NORMAL * lift;
}

void fragment() {
	vec2 uv = UV;
	if (flip_u) {
		uv.x = 1.0 - uv.x;
	}
	if (texture(number_tex, uv).a < 0.5) {
		discard;
	}
	ALBEDO = ink.rgb * level;
}
