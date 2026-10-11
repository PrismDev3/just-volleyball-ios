shader_type spatial;
// The authored reticle art on a camera-facing quad centred on the ball. One
// material, one texture -- the marker builds two of these: the outer white scope
// frame (ring + crosshair) and the inner state-coloured lock arcs. The art is a
// flat light mask on transparent, so the texture's own coverage draws the shape
// and `tint` paints it (white for the frame, the reticle state colour for the
// arcs), `glow` overdrives the arc colour, `alpha` fades the whole thing.
// Depth test OFF -- the reticle regularly sits past the net or under a jumper.
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled,
	cull_disabled, shadows_disabled;

uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 shell : source_color = vec4(0.03, 0.04, 0.06, 1.0);  // dark cel outline
uniform float alpha = 1.0;
uniform float glow = 1.0;
uniform float bold = 1.0;         // >1 solidifies thin marks so they read bold, not faint
uniform float fatten = 0.0;       // UV radius the coloured mark is dilated by
uniform float outline = 0.006;    // UV halo width -- readability over a busy court

// the art is a near-white luminance mask; coverage is alpha x mask value, which
// keeps the soft antialiased edges the artist drew in. `bold` overdrives thin,
// half-transparent strokes toward solid so the arcs don't look see-through.
float cover(vec2 uv) {
	vec4 t = texture(tex, uv);
	return clamp(t.a * max(max(t.r, t.g), t.b) * bold, 0.0, 1.0);
}

void fragment() {
	// FATTEN THE COLOUR. The inner arcs are thin, so even at full alpha they read
	// faint; dilate the coloured fill itself (not just the dark halo) so the
	// state colour has real body on the ball.
	float c = cover(UV);
	c = max(c, cover(UV + vec2(fatten, 0.0)));
	c = max(c, cover(UV + vec2(-fatten, 0.0)));
	c = max(c, cover(UV + vec2(0.0, fatten)));
	c = max(c, cover(UV + vec2(0.0, -fatten)));
	// DARK CEL OUTLINE. The flat art has no outline of its own, so the coloured
	// arcs vanished against the ball's green possession shell / a busy court. A
	// dilated dark halo under every mark makes the state colour read over anything
	// -- the same trick the old procedural reticle used.
	float o = 0.0;
	o = max(o, cover(UV + vec2(outline, 0.0)));
	o = max(o, cover(UV + vec2(-outline, 0.0)));
	o = max(o, cover(UV + vec2(0.0, outline)));
	o = max(o, cover(UV + vec2(0.0, -outline)));
	o = max(o, cover(UV + vec2(outline, outline)) * 0.9);
	o = max(o, cover(UV + vec2(-outline, outline)) * 0.9);
	o = max(o, cover(UV + vec2(outline, -outline)) * 0.9);
	o = max(o, cover(UV + vec2(-outline, -outline)) * 0.9);
	float shape = max(c, o);
	if (shape < 0.01) {
		discard;
	}
	// PRESERVE THE HUE. A plain tint*glow blows the bright channels of a saturated
	// state colour past 1 and clamps, so blue/green/red all wash to the same cyan
	// -- and the state colour is the whole message. Normalise back to a peak of 1
	// when it clips so the arc keeps its colour at full brightness; the white pop
	// on a state change rides in through `tint` (already lerped toward white).
	vec3 col = tint.rgb * glow;
	float m = max(max(col.r, col.g), col.b);
	if (m > 1.0) {
		col /= m;
	}
	// dark where only the dilated halo reaches, the state colour where the mark is
	ALBEDO = mix(shell.rgb, col, c);
	ALPHA = shape * alpha;
}
