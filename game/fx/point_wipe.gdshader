// THE POINT WIPE. cover: a FEW wide diagonal capsule stripes slide in from
// alternating ends (each its own delay, rounded caps) to build the field.
// reveal: a circular iris opens from the centre with a bright white ring rim.
// stripes drift on `scroll`. drawn on one full-screen ColorRect.
shader_type canvas_item;

uniform float cover : hint_range(0.0, 1.0) = 0.0;
uniform float reveal : hint_range(0.0, 1.0) = 0.0;
uniform float scroll = 0.0;
uniform vec2 res = vec2(1920.0, 1080.0);
uniform vec4 col_a : source_color = vec4(0.16, 0.55, 0.95, 1.0);   // blue
uniform vec4 col_b : source_color = vec4(1.0, 0.82, 0.20, 1.0);    // yellow
uniform vec4 line_col : source_color = vec4(1.0, 1.0, 1.0, 1.0);

const float FREQ = 4.0;      // stripes across the screen (few, wide)
const float STAGGER = 0.85;  // how spread out the arrivals are (higher = one by one)

float rand(float x) { return fract(sin(x * 12.9898) * 43758.5453); }

void fragment() {
	vec2 uv = UV;
	vec2 p = (uv - 0.5) * vec2(res.x / res.y, 1.0);
	// stripe space: bands run TOP-LEFT -> BOTTOM-RIGHT. `across` selects the
	// stripe, `along` runs down its length.
	float across = clamp((uv.x + uv.y) * 0.5, 0.0, 1.0);
	float along = (uv.x - uv.y) * 0.5 + 0.5;
	// two-tone bands + thin white separators
	float s = fract(across * FREQ - scroll);
	vec3 col = mix(col_a.rgb, col_b.rgb, step(0.5, s));
	float e = min(min(abs(s), abs(s - 1.0)), abs(s - 0.5));
	col = mix(col, line_col.rgb, smoothstep(0.02, 0.0, e) * 0.9);
	// COVER: each stripe slides in on its own delay, rounded cap, ALTERNATE
	// stripes entering from OPPOSITE ends so the field zips together.
	float sidx = floor(across * FREQ);
	float delay = rand(sidx) * STAGGER;
	float lp = clamp(cover * (1.0 + STAGGER) - delay, 0.0, 1.4);
	float within = fract(across * FREQ);
	float cap = 0.06 * sin(within * PI);
	float a = (mod(sidx, 2.0) < 1.0) ? along : (1.0 - along);
	float edge = lp + cap;
	float covered = smoothstep(edge + 0.008, edge - 0.03, a);
	// REVEAL: a circular iris of clear grows from the centre, edged by a bright
	// white ring (the dotted ring hands off into this on the way out).
	float iris = reveal * 1.4;
	float r = length(p);
	float hole = smoothstep(iris, iris - 0.05, r);
	float rim = smoothstep(iris + 0.07, iris + 0.01, r) * smoothstep(iris - 0.10, iris - 0.02, r);
	col = mix(col, vec3(1.0), rim * step(0.001, reveal));
	COLOR = vec4(col, covered * (1.0 - hole));
}
