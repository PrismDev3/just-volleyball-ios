// radial charge indicator, botw sprint-wheel style: an annulus that fills
// clockwise from the top as the jump charges.
//
// This is the one round marker that is NOT flat on the floor -- it billboards
// over the player -- so it can't share floor_ring.gdshader. It wears the same
// dark shell for the same reason: a bright annulus over a bright court reads
// as a smear, and this one sits over a moving body as well as the floor.
shader_type spatial;
// depth_test_disabled: this is UI, not scenery. it used to lose the depth
// fight to the ball, the reticle and the player's own body, leaving the one
// meter that answers "how charged am I" half-buried mid-action.
render_mode unshaded, cull_disabled, depth_test_disabled;

uniform float fill = 0.0;
// 1 when the charge has actually maxed. A ring that only fills tells you how
// far along you are but never that you have ARRIVED -- so players let go early,
// never saw what a full charge does, and concluded charging was pointless.
// A wheel that visibly locks is the difference between a meter and a decision.
uniform float ready = 0.0;
// 1 while the BAM window is open: a full JUMP charge whose perfect release is
// still available. white-hot and fast, unmistakably different from `ready` --
// the shine IS the timing cue.
uniform float bam = 0.0;
uniform vec4 fill_color : source_color = vec4(0.4, 0.95, 0.35, 0.95);
uniform vec4 bg_color : source_color = vec4(0.05, 0.05, 0.08, 0.5);
uniform vec4 edge_color : source_color = vec4(0.02, 0.02, 0.04, 0.95);
// the quad only reaches r=0.5 along its axes, so band + outline has to stay
// inside that or the ring gets flat-topped at four points
uniform float r_inner = 0.28;
uniform float r_outer = 0.46;
uniform float outline = 0.035;

void vertex() {
	mat4 mv = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	mv = mv * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = mv;
}

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float r = length(uv);
	float aa = fwidth(r) + 0.002;
	if (r > r_outer + outline + aa || r < r_inner - outline - aa) {
		discard;
	}
	float band = min(smoothstep(r_inner - aa, r_inner + aa, r),
		1.0 - smoothstep(r_outer - aa, r_outer + aa, r));
	float shell = min(
		smoothstep(r_inner - outline - aa, r_inner - outline + aa, r),
		1.0 - smoothstep(r_outer + outline - aa, r_outer + outline + aa, r));
	float angle = atan(uv.x, -uv.y);          // 0 at top, clockwise positive
	float t = (angle + PI) / (2.0 * PI);
	t = fract(t + 0.5);                        // start the fill at the top
	vec4 lit = fill_color;
	if (bam > 0.5) {
		// the perfect window: near-white and strobing hard. this has to read
		// in peripheral vision while the player watches the ball, not the ring
		float pulse = 0.5 + 0.5 * sin(TIME * 22.0);
		lit = mix(vec4(1.0), fill_color, 0.15 + 0.25 * pulse);
		lit.a = 1.0;
	} else if (ready > 0.5) {
		// hot and breathing, not strobing: this sits under the player's eye for
		// as long as they hold, so it has to read instantly without nagging
		float pulse = 0.5 + 0.5 * sin(TIME * 12.0);
		lit = mix(fill_color, vec4(1.0), 0.3 + 0.35 * pulse);
		lit.a = 1.0;
	}
	vec4 col = t < fill ? lit : bg_color;
	ALBEDO = mix(edge_color.rgb, col.rgb, band);
	ALPHA = shell * mix(edge_color.a, col.a, band);
}
