// WINDOW GLOW: the anime "blown-white glass in a black frame" look, driven off the
// window texture so we don't need separate frame/glass materials. Bright texels
// (the glass panes) become a strong pale emissive that overexposes + BLOOMS; dark
// texels (the mullions / frame bars) go to a flat near-black. One threshold splits
// the two, so the frame reads crisp black and the glass reads as pouring daylight.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D win_tex : source_color, filter_linear_mipmap;
uniform bool use_tex = true;
uniform vec4 glow : source_color = vec4(1.0, 0.94, 0.82, 1.0); // warm daylight glass
uniform float energy : hint_range(0.0, 8.0) = 3.0;            // >1 so it blooms
uniform vec3 frame_color : source_color = vec3(0.02, 0.02, 0.02); // black mullions
uniform float threshold : hint_range(0.0, 1.0) = 0.5;         // glass/frame split

void fragment() {
	float l = use_tex ? dot(texture(win_tex, UV).rgb, vec3(0.299, 0.587, 0.114)) : 1.0;
	float g = smoothstep(threshold - 0.12, threshold + 0.12, l);
	ALBEDO = mix(frame_color, glow.rgb * energy, g);
}
