shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

// The court's boundary as a HEX FORCEFIELD (Frieren / sci-fi shield): thin glowing
// hex edges + faint translucent cell panels + a grazing rim shine, always on so it
// reads as the map's wall. Brightens where the ball/players near it. fog_disabled so
// the shield stays crisp + bright at any distance (the rest of the stage fogs, not
// this). One additive quad per wall; a per-frame probe list (force_wall.gd) drives
// the proximity flare. Blue by default; `tint` supports other colours.

uniform vec3 tint : source_color = vec3(0.25, 0.6, 1.0);
uniform vec2 uv_scale = vec2(8.0, 6.0);           // hex cells across (set per wall)
uniform float line_width : hint_range(0.0, 0.3) = 0.04;
uniform float glow_width : hint_range(0.0, 0.5) = 0.08;  // soft halo past the edge
uniform float edge_glow = 0.7;                     // edge brightness (gradient-shaped)
uniform float cell_fill = 0.006;                   // barely-there panel (see-through)
uniform float rim_amt = 0.35;                      // grazing-angle shield shine
uniform float base_vis = 1.0;
// slow overall PULSE so the field breathes
uniform float pulse_speed = 1.4;
uniform float pulse_amt = 0.18;
// vertical shape: dissolve the top so it fades into the sky (no hard ceiling cut)
uniform float wall_height = 14.0;
uniform float top_fade : hint_range(0.0, 1.0) = 0.4;
// STRONG vertical gradient: dense/bright at the base, thinning upward, so the field
// reads as a forcefield even from across the court. grad_top = brightness at the top.
uniform float grad_top : hint_range(0.0, 1.0) = 0.12;
// a slow energy sweep rolling up the field -- subtle, but alive if you watch it
uniform float sweep_freq = 5.0;
uniform float scroll_speed = 0.5;
uniform float sweep_amt : hint_range(0.0, 1.0) = 0.4;
// cross-fade each wall toward its side ends so the two walls meeting at a CORNER
// don't stack into a bright doubled seam
uniform float corner_fade : hint_range(0.0, 0.3) = 0.05;
// REACTION: when the ball / a player nears the wall, brighten + send an animated
// concentric RIPPLE (stepped, staircase-like) out from the contact point.
uniform float prox_amt = 1.0;
uniform float prox_radius = 7.0;
uniform float ripple_freq = 2.2;
uniform float ripple_speed = 5.0;
uniform float ripple_glow = 1.6;
uniform int probe_count = 0;
const int MAXP = 16;
uniform vec3 probe_pos[MAXP];

varying vec3 v_wpos;

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hex_dist(vec2 p) {
	p = abs(p);
	return max(dot(p, normalize(vec2(1.0, 1.7320508))), p.x);
}

// distance from a UV point to the nearest hex cell EDGE (0 at edge, ~0.5 centre)
float hex_edge(vec2 uv) {
	vec2 r = vec2(1.0, 1.7320508);
	vec2 h = r * 0.5;
	vec2 a = mod(uv, r) - h;
	vec2 b = mod(uv - h, r) - h;
	vec2 gv = dot(a, a) < dot(b, b) ? a : b;
	return 0.5 - hex_dist(gv);
}

void fragment() {
	float e = hex_edge(UV * uv_scale);
	float aa = fwidth(e) * 1.5 + 0.001;
	// sharp bright edge core + a soft glow halo bleeding into the cell (the "wire")
	float core = 1.0 - smoothstep(line_width, line_width + aa, e);
	float halo = 1.0 - smoothstep(line_width, line_width + glow_width, e);
	float edge = core + halo * halo * 0.5;

	// grazing-angle rim shine -> the shield surface catches light at its edges
	float fres = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.5);

	// proximity flare + animated ripple from anything near the wall
	float prox = 0.0;
	float ripple = 0.0;
	for (int i = 0; i < probe_count; i++) {
		float d = distance(v_wpos, probe_pos[i]);
		float near = smoothstep(prox_radius, 0.0, d);
		prox += near;
		// concentric wave rolling outward from the contact, sharpened into stepped
		// bands (the "staircase/ripple") and faded by distance
		float wave = sin(d * ripple_freq - TIME * ripple_speed);
		ripple += near * smoothstep(0.2, 0.9, wave);
	}
	prox = clamp(prox, 0.0, 1.5);
	ripple = clamp(ripple, 0.0, 1.5);

	// slow breathing pulse
	float pulse = 1.0 - pulse_amt + pulse_amt * sin(TIME * pulse_speed);
	float vis = (base_vis + prox * prox_amt) * pulse;

	// vertical height fraction (0 base -> 1 top), robust to UV orientation
	float vfrac = clamp(v_wpos.y / wall_height, 0.0, 1.0);
	// dissolve the top so it fades into the sky instead of a hard cut
	float fade = 1.0 - smoothstep(top_fade, 1.0, vfrac);
	// strong bottom-bright vertical gradient + a slow energy sweep rolling upward
	float vgrad = mix(1.0, grad_top, vfrac);
	float sweep = 0.5 + 0.5 * sin(vfrac * sweep_freq - TIME * scroll_speed);
	float shimmer = 1.0 + sweep_amt * sweep;
	// corner cross-fade (UV.x is the wall's along-length axis, 0..1 end to end)
	float cfade = smoothstep(0.0, corner_fade, min(UV.x, 1.0 - UV.x));

	float structure = edge * edge_glow + cell_fill + fres * rim_amt;
	// the ripple lights up the hex edges as it passes, like an impact shockwave
	float amt = (structure * vis * vgrad * shimmer + ripple * ripple_glow * edge)
		* fade * cfade;
	ALBEDO = tint + vec3(fres * 0.3);
	ALPHA = clamp(amt, 0.0, 1.0);
}
