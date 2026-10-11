shader_type canvas_item;

// radial rainbow shockwave that floods the screen with color and settles
// into the menu cream behind the front. progress 0 = nothing, 1 = fully
// settled solid settle_color

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 settle_color : source_color = vec4(0.969, 0.976, 0.988, 1.0);
uniform float aspect = 1.777;
uniform float rainbow_sat : hint_range(0.0, 1.0) = 0.62;

vec3 hsv2rgb(vec3 c) {
	vec4 k = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + k.xyz) * 6.0 - k.www);
	return c.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec2 p = (UV - 0.5) * vec2(aspect, 1.0);
	float d = length(p);
	// the front reaches every corner comfortably before progress hits 1
	float front = progress * 2.4;
	float inside = 1.0 - smoothstep(front - 0.02, front, d);
	// swirled rainbow bands riding just behind the front. wide slow bands on
	// purpose — tight fast ones read as flicker and this runs on every boot
	float ang = atan(p.y, p.x);
	float hue = fract(ang / 6.2831853 + d * 1.1 - progress * 0.55);
	vec3 rainbow = hsv2rgb(vec3(hue, rainbow_sat, 1.0));
	// deeper behind the front the color calms down into the menu cream
	float settled = smoothstep(0.25, 0.9, front - d);
	vec3 col = mix(rainbow, settle_color.rgb, settled);
	COLOR = vec4(col, inside);
}
