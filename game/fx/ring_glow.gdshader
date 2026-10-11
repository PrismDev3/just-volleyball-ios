// A soft, translucent, rim-lit ring/torus in the same family as the landing
// column (game/fx/land_column.gdshader): fills faintly through the body and
// brightens on the silhouette, with a dark cel edge so it reads on a pale
// floor. No vertical fade (a torus has no up). Colour rides `tint`, so a
// drill can charge it red -> green and dissipate it by dropping tint.a.
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.3, 0.3, 0.7);
uniform float rim_power = 1.5;
uniform float body_alpha : hint_range(0.0, 1.0) = 0.55;
uniform vec4 edge : source_color = vec4(0.05, 0.07, 0.11, 1.0);
uniform float edge_amt : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), rim_power);
	ALBEDO = mix(tint.rgb, edge.rgb, rim * edge_amt);
	ALPHA = tint.a * mix(body_alpha, 1.0, rim);
}
