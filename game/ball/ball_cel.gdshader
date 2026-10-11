// the stage ball's cel material: the authored diffuse, flat and unlit, split
// by ONE hard camera-relative shade band -- the same fake-key language as the
// character shader (game/fx/toon.gdshader), so the ball reads like the anime
// ball from every angle: a crescent of shadow, not real lighting.
shader_type spatial;
render_mode unshaded, cull_back;

uniform sampler2D albedo_tex : source_color, hint_default_white, filter_linear_mipmap;
uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// view-space key: -x left, +y up, +z toward the camera (same as characters)
uniform vec3 key_dir = vec3(-0.45, 0.62, 0.65);
uniform float band_edge = 0.12;     // where the single band splits
uniform float shade = 0.32;         // how much darker the shaded crescent is
uniform float band_softness = 0.02; // a hair of AA on the terminator
// the ball's centre in this mesh's local space (ball.gd fills it in). The band
// follows the SPHERE'S direction field, never the surface normal: authored
// panel geometry has seams and inner shells, and shading those normals drew a
// separate broken terminator per panel -- the "two balls inside" look.
uniform vec3 local_center = vec3(0.0, 0.0, 0.0);

varying vec3 sphere_n;

void vertex() {
	sphere_n = (MODELVIEW_MATRIX * vec4(normalize(VERTEX - local_center), 0.0)).xyz;
}

void fragment() {
	vec3 base = texture(albedo_tex, UV).rgb * albedo_color.rgb;
	float lit = smoothstep(band_edge - band_softness, band_edge + band_softness,
		dot(normalize(sphere_n), normalize(key_dir)));
	ALBEDO = base * mix(1.0 - shade, 1.0, lit);
}
