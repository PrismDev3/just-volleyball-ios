// anime impact ring: a DRAWN stroke, not a torus. a few arc segments with gaps
// between them, each thick in the middle and tapering to a point at both ends,
// two-tone (a white core with a coloured rim) so it speaks the same language as
// the combo capsules. the quad lies in the plane the effect happens in (the
// node's basis orients it); `spread` is the animation, driven by Fx.ring:
// the ring grows outward while the stroke thins and the ends pull in.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec4 core : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 rim : source_color = vec4(0.85, 0.92, 1.0, 1.0);
uniform float alpha = 1.0;
uniform float spread = 0.0;    // 0 just born .. 1 fully expanded
uniform float rot = 0.0;       // per-spawn spin so two rings never align
uniform float arcs = 3.0;      // stroke segments around the ring
uniform float gap = 0.24;      // fraction of each segment left empty
uniform float thick = 0.14;    // stroke thickness at birth (uv radius units)

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;   // -1..1
	float r = length(p);
	float ang = atan(p.y, p.x) + rot;
	// radius grows with spread; the stroke thins as it goes (ink running out)
	float radius = mix(0.30, 0.92, spread);
	float th = thick * mix(1.0, 0.45, spread);
	// where on its segment this pixel sits, 0..1
	float seg = fract((ang / 6.2831853) * arcs);
	// the visible part is the middle (1 - gap) of the segment; t runs 0..1
	// across it. the ends pull in a little as the ring spreads (the stroke
	// shortens), which reads as the ring letting go rather than dissolving
	float visible = (1.0 - gap) * mix(1.0, 0.8, spread);
	float t = (seg - 0.5) / visible + 0.5;
	if (t < 0.0 || t > 1.0) {
		discard;
	}
	// tapered ends: thickness follows a rounded hump across the segment
	float taper = sin(t * 3.1415926);
	taper = pow(taper, 0.55);          // fatten the middle, keep the points
	float half_w = th * taper;
	float d = abs(r - radius);
	float aa = fwidth(r) * 1.5;
	float body = 1.0 - smoothstep(half_w - aa, half_w + aa, d);
	if (body <= 0.001) {
		discard;
	}
	// two-tone: the inner ~55% of the stroke is the white core, the rest rim
	float core_w = half_w * 0.55;
	float is_core = 1.0 - smoothstep(core_w - aa, core_w + aa, d);
	vec3 col = mix(rim.rgb, core.rgb, is_core);
	ALBEDO = col;
	ALPHA = body * alpha;
}
