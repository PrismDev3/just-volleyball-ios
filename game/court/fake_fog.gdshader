// FAKE FOG / DARKENER. A camera-facing soft dark haze patch. Hang a few up in the
// rafters (or in the back corners of the stands) to OBSCURE and darken the ceiling/
// roof so it stops reading bright and flat -- the cheap fake of atmosphere + a dark
// moody ceiling, no volumetrics. Billboards so it covers what's behind it from any
// angle. Alpha-blend so it just tints toward `fog_color`. Drop + scale in the editor.
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 fog_color : source_color = vec3(0.03, 0.03, 0.05); // near-black haze
uniform float density : hint_range(0.0, 1.0) = 0.6;            // peak opacity
uniform float softness : hint_range(0.0, 1.0) = 0.75;          // edge feather

void vertex() {
	// full billboard: face the camera, keep the node's scale + position. So one
	// patch reads as a soft round cloud no matter where the broadcast camera swings.
	mat4 mv = VIEW_MATRIX * MODEL_MATRIX;
	mv[0] = vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0);
	mv[1] = vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0);
	mv[2] = vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0);
	POSITION = PROJECTION_MATRIX * mv * vec4(VERTEX, 1.0);
}

void fragment() {
	// soft round falloff so the patch has no hard border
	float d = length((UV - 0.5) * 2.0);
	ALBEDO = fog_color;
	ALPHA = density * (1.0 - smoothstep(1.0 - softness, 1.0, d));
}
