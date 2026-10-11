// procedural impact flash: a soft radial glow on a billboarded quad.
// no textures -- the falloff is computed from uv distance.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void vertex() {
	// billboard that keeps the node's scale
	mat4 mv = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	mv = mv * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = mv;
}

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float a = pow(clamp(1.0 - d, 0.0, 1.0), 1.8);
	ALBEDO = tint.rgb;
	ALPHA = a * tint.a;
}
