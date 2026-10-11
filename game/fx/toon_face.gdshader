// cel shader for the head: skin albedo with the composited face texture
// (eyes, brows, nose, mouth, paint) blended on top by its alpha. this is
// the mii trick -- the face is a texture, never geometry.
shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D face_tex : source_color, filter_linear;

void fragment() {
	vec4 face = texture(face_tex, UV);
	ALBEDO = mix(albedo.rgb, face.rgb, face.a);
	ROUGHNESS = 0.9;
}
