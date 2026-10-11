// THE TETHER BEADS. Floating markers dropped from the ball down to its landing
// spot -- soft rounded pills, DENSE + OPAQUE near the floor (where the read
// matters) and SPREADING APART + FADING toward the ball. That puts the emphasis
// on where it lands, not the whole path.
//
// UV.y = 0 at the floor base, 1 at the ball; times the live world length it gives
// metres. A sub-linear warp (pow < 1) makes equal bead steps grow apart as they
// climb, so beads sit close near the landing and open up as they rise.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 0.95);
uniform float length_m = 3.0;   // world height the cylinder spans this frame
uniform float bead = 0.13;      // bead length
uniform float gap = 0.17;       // gap between beads
uniform float spread = 0.6;     // <1: beads spread farther apart going up
uniform float fade_pow = 1.5;   // higher = fades out toward the ball faster

void fragment() {
	float t = clamp(UV.y, 0.0, 1.0);
	float d = pow(t, spread) * length_m;
	// soft rounded bead: 1 at each bead's centre, feathering to 0 at its ends
	float phase = mod(d, bead + gap);
	float m = 1.0 - smoothstep(0.0, bead * 0.5, abs(phase - bead * 0.5));
	if (m <= 0.001) {
		discard;   // the gap between beads
	}
	float fade = pow(1.0 - t, fade_pow);   // 1 at the floor, ~0 at the ball
	ALBEDO = tint.rgb;
	ALPHA = tint.a * fade * m;
}
