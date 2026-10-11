// halftone dot page -- the splash / title background, shared so the loading
// screen matches it. off-white page with a rising band of dots at the foot:
// tiny specks up top growing to distinct discs at the bottom, staggered rows
// crawling slowly right, a soft size wave breathing across. drive `t` from a
// script and set `page`/`dot`/`size_px`.
shader_type canvas_item;
uniform vec4 page : source_color;
uniform vec4 dot : source_color;
uniform float t = 0.0;
uniform float step_px = 24.0;     // dot pitch in pixels
uniform float band = 0.62;        // fraction of the height the dots climb
uniform float r_max = 0.42;       // max disc radius, fraction of pitch
uniform float r_gamma = 1.0;      // size ramp curve
uniform float fade_to = 0.12;     // opacity ease-in span (fraction of band)
uniform vec2 size_px = vec2(1920.0, 1080.0);
void fragment() {
	vec2 px = UV * size_px;
	float top = size_px.y * (1.0 - band);
	float f = clamp((px.y - top) / (size_px.y - top), 0.0, 1.0);
	float base_r = r_max * pow(f, r_gamma);
	float fade = smoothstep(0.0, max(fade_to, 0.001), f);
	float row_h = step_px * 0.87;
	float row = floor((size_px.y - px.y) / row_h);
	float x = px.x - t * 9.0 - (mod(row, 2.0) * 0.5 * step_px);
	vec2 cell = vec2(mod(x, step_px), mod(size_px.y - px.y, row_h)) - vec2(step_px * 0.5, row_h * 0.5);
	float breathe = 1.0 + 0.16 * sin(t * 1.4 + px.x * 0.012 + px.y * 0.02);
	float r = base_r * step_px * breathe;
	float d = length(cell);
	float a = (1.0 - smoothstep(r - 1.2, r + 1.2, d)) * fade * dot.a;
	COLOR = mix(page, vec4(dot.rgb, 1.0), a);
}
