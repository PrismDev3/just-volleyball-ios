shader_type spatial;
// Flat, unshaded cartoon ground for the grass court. GrassField reskins the venue's
// EnvFloor with this so the floor and the grass blades share ONE brightness/tint and
// are both lighting-independent -- otherwise the lit StandardMaterial floor renders
// darker in-game (lower ambient) than the shader-bright blades, and they stop matching.
// Samples the same ground texture in world space (the floor is flat, so world xz IS
// the triplanar top face), then applies the field's tint * brightness.

render_mode unshaded, cull_back;

uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float world_scale = 1.0;                 // tiles per metre (matches the old triplanar)
uniform vec3 tint : source_color = vec3(1.0);
uniform float brightness : hint_range(0.0, 3.0) = 1.0;

// brighter-green patches, IDENTICAL function/inputs to grass.gdshader so the ground and
// the blades share the same patches.
uniform vec3 patch_color : source_color = vec3(0.62, 0.92, 0.34);
uniform float patch_scale : hint_range(1.0, 40.0) = 8.0;
uniform float patch_strength : hint_range(0.0, 1.0) = 0.25;

varying vec3 v_wpos;

float _hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float _vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(_hash(i), _hash(i + vec2(1.0, 0.0)), u.x),
		mix(_hash(i + vec2(0.0, 1.0)), _hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float _patch(vec2 w) {
	return smoothstep(0.5, 0.85, _vnoise(w / max(patch_scale, 0.001))) * patch_strength;
}

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 col = texture(tex, v_wpos.xz * world_scale).rgb * tint * brightness;
	col = mix(col, patch_color * brightness, _patch(v_wpos.xz));
	ALBEDO = col;
}
