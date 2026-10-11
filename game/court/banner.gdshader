// HANGING GYM BANNER. A cheap procedural pennant so big empty walls read as a
// decorated hall -- no texture, one accent uniform so it matches the school the
// map rolled. UV: y=0 top, y=1 bottom. The bottom is a V-notch (pennant tail)
// carved with discard; a trim border, a top band and a ring emblem sit on the
// accent field. Slightly darker toward the tail so it reads as hanging cloth.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 accent : source_color = vec4(0.14, 0.30, 0.68, 1.0);
uniform vec4 trim : source_color = vec4(0.96, 0.96, 0.94, 1.0);

void fragment() {
	vec2 uv = UV;

	// pennant tail: carve a centred V out of the bottom slice
	float tail = 0.22;
	if (uv.y > 1.0 - tail) {
		float t = (uv.y - (1.0 - tail)) / tail;   // 0 at shoulder -> 1 at point
		if (abs(uv.x - 0.5) > (1.0 - t) * 0.5) {
			discard;
		}
	}

	vec3 col = accent.rgb;

	// ring emblem (placeholder crest)
	float d = distance(uv, vec2(0.5, 0.44));
	if (d < 0.20 && d > 0.13) {
		col = trim.rgb;
	}

	// trim border + a band under the top
	float b = 0.07;
	if (uv.x < b || uv.x > 1.0 - b || uv.y < b) {
		col = trim.rgb;
	}
	if (uv.y > 0.11 && uv.y < 0.17) {
		col = trim.rgb;
	}

	// gentle shade toward the hanging tail so it isn't a flat sticker
	col *= mix(1.0, 0.82, smoothstep(0.2, 1.0, uv.y));

	ALBEDO = col;
}
