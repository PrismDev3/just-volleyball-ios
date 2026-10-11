// varnished court floor. OPAQUE, unshaded -- so the flat cel colour is rock
// solid and never washes. the reflections are the mirrored player bodies
// (on REFLECT_LAYER) rendered into a small viewport by floor_reflector.gd;
// this shader samples that texture and its alpha is a perfect mask, so the
// mirror shows only where a body actually is and empty floor stays orange.
//
// sweat still collects late in a rally: droplet speckles fade in and the
// floor turns glassier where the droplets pool.
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec4 base_color : source_color = vec4(0.9, 0.53, 0.27, 1.0);
// OPTIONAL surface texture. Off by default, so every court that feeds a flat
// base_color (the painted arena floors) is byte-for-byte unchanged. A themed
// venue that owns a real floor -- the high-school gym's wood boards + its
// multi-sport line markings -- flips use_albedo_tex on and the sweat/sheen/
// mirror all composite over the sampled boards instead of a flat colour.
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform bool use_albedo_tex = false;
uniform float sweat = 0.0;
uniform sampler2D reflect_tex : filter_linear;
uniform bool reflect_on = false;
uniform float reflectivity : hint_range(0.0, 1.0) = 0.42;
// feet[i].xyz = a player's world position, .w = 1 when the slot is used. the
// reflection is full strength right under the feet and melts away past that,
// so only the near part of each mirrored body reads -- the far end (the head)
// fades into the varnish. if no feet are set the reflection shows everywhere.
uniform vec4 feet[8];
// the polish colour and how strong it gets. tinted toward the gym lights
// rather than pure white, so a soaked floor looks lit rather than bleached.
uniform vec4 gloss_tint : source_color = vec4(0.62, 0.72, 0.85, 1.0);
uniform float gloss_strength : hint_range(0.0, 1.5) = 0.55;
// LIT COURT gradient (faked, no real lights): a warm light POOL at centre court +
// an edge VIGNETTE, so the boards read as spotlit for the match -- bright middle,
// darker run-off -- instead of one flat colour. Same idea as the env_paint wood
// floor pool, so every stage's floor gets the same "lit court" look. main drives
// these; 0 strength/vignette = off, so a stage that doesn't set them is unchanged.
uniform vec3 pool_center = vec3(0.0, 0.0, 0.0);
uniform float pool_radius = 14.0;
uniform float pool_strength : hint_range(0.0, 2.0) = 0.0;
uniform vec3 pool_warm : source_color = vec3(1.0, 0.85, 0.6);
uniform float floor_vignette : hint_range(0.0, 1.0) = 0.0;
// CHECKERBOARD: a prototype grid over the flat colour (the training space).
// checker_size is the tile width in metres; checker_color the alternate tile.
uniform float checker_size : hint_range(0.0, 4.0) = 0.0;
uniform vec4 checker_color : source_color = vec4(0.66, 0.67, 0.69, 1.0);

// --- DEFORMABLE SAND (beach). OFF for every other stage: sand_on gates the whole
// block, so a court that never sets it is byte-for-byte unchanged. The buffer's
// RED channel is depression height (0 flat .. 1 deepest), authored per client by
// sand_deform.gd over the court+apron -- feet drag trails, dives carve streaks,
// the ball punches craters. On the dedicated subdivided sand DECK (main builds it)
// vertex() displaces REAL geometry down into the dig + a subtle bumpy-sand ripple,
// and fragment() lights the true surface normal so the hollows read as scooped.
// repeat_disable is CRITICAL: the buffer only covers the court+apron, but this
// shader also runs on the whole ~117 m EnvFloor plane (reskinned to match). With
// the sampler repeating, every footprint tiled as ghost copies across the entire
// beach. Clamped, samples outside [0,1] read the empty edge (flat sand) instead.
uniform sampler2D sand_tex : filter_linear, repeat_disable;
uniform bool sand_on = false;
// set TRUE on the big EnvFloor only: it discards its fragments inside the deck's
// interior so the flat EnvFloor plane stops floating OVER the deck's dug dents
// (which sit just below sand level). The opaque deck fully covers that hole, so
// nothing shows through -- only the deck's own scooped hollows become visible.
uniform bool sand_cutout = false;
uniform vec2 sand_center = vec2(0.0);                    // world xz the buffer centres on
uniform float sand_area = 24.0;                          // full metres it spans
uniform float sand_depth : hint_range(0.0, 0.6) = 0.05;  // metres pushed down at full depth
uniform float sand_relief : hint_range(0.0, 3.0) = 1.15; // shading strength of the relief
// how strongly the height gradient bends the faked surface normal. This is what
// gives the dents real VOLUME -- lit far walls, shadowed near walls, like sand
// pushed aside -- instead of a flat darkening. 0 = albedo relief only.
uniform float sand_bump : hint_range(0.0, 4.0) = 2.0;
// the beach sand is a big triplanar-textured plane; sample its albedo in WORLD
// space (matching the triplanar top projection) so the deform surface reuses the
// exact same sand texture with no UV seams. = the source material's uv1_scale.
uniform float sand_albedo_scale = 0.22;
// the DECK's own BUMPY-SAND undulation (independent of any deform): fine wind ripples
// over a gentle swell, so the sand plane has real rolling volume before anyone digs in.
// amp = metres of +/- bump around the lifted baseline, scale = features per metre. Fades
// to 0 at the deck rim (edge_fade) so it meets the flat surround with no step.
uniform float sand_dune_amp : hint_range(0.0, 0.15) = 0.035;
uniform float sand_dune_scale : hint_range(0.2, 4.0) = 0.5;
// the whole sand DECK sits this many metres ABOVE the flat foot/court plane, so
// undisturbed sand rises around a standing player's feet (they read as planted IN the
// sand, not on a slab) and footprints dig DOWN into it. Keep it > sand_dune_amp so the
// lowest bump still sits above the feet -- then no dip ever exposes them. Court lines are
// raised to match (sand_deform.gd). Fades to 0 at the rim so the court is a gentle raised
// pad, not a stepped block.
uniform float sand_lift : hint_range(0.0, 0.2) = 0.05;

// SAND COLOUR GRADIENT (beach): tint the sand across a world-xz direction between two
// MULTIPLY colours, so it isn't one flat tone -- e.g. warm/dry inland fading to a
// cooler/damper tone toward the waterline. Off by default (other stages untouched).
uniform bool sand_grade = false;
uniform vec3 sand_grade_near : source_color = vec3(1.0, 1.0, 1.0);  // tint at the `from` end
uniform vec3 sand_grade_far : source_color = vec3(1.0, 1.0, 1.0);   // tint at the `to` end
uniform vec2 sand_grade_dir = vec2(1.0, 0.0);                       // world-xz ramp direction
uniform float sand_grade_from = -20.0;                             // proj distance: near end
uniform float sand_grade_to = 20.0;                                // proj distance: far end

varying vec3 world_pos;
varying vec2 uv;

// world xz -> sand buffer uv. must match sand_deform.gd's _add_stamp mapping.
vec2 sand_uv(vec2 world_xz) {
	return (world_xz - sand_center) / sand_area + vec2(0.5);
}

// sin-FREE hash. The old fract(sin(dot(p,..)) * 43758.5) form is precision-fragile:
// on Forward+ (D3D12/Vulkan HLSL/SPIRV) the huge sin argument collapses to near-constant,
// so all the sand noise went FLAT there while it looked fine on Compatibility (GLSL).
// This integer-mix hash (Dave Hoskins style) is stable across every renderer.
float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// smooth value noise -- the damp areas have to be irregular blobs. a plain
// per-cell dot mask reads as printed polka dots once coverage gets high.
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += amp * vnoise(p);
		p *= 2.03;
		amp *= 0.5;
	}
	return v;
}

// 1 in the deck interior, easing to 0 across the outer ring so the lift/bump/dig all
// vanish before the rim and the deck sits FLUSH with the flat EnvFloor around it. The
// fade must reach 0 INSIDE the EnvFloor cutout boundary (inset 0.8 m, see fragment) or
// the still-lifted deck meets the flat surround at a step -- that step is the "rectangle
// outline" bug. Completing the fade by ~1.2 m in leaves a flat overlap ring at height 0
// where both surfaces coincide, so the seam is invisible.
float sand_edge_fade(vec2 world_xz) {
	vec2 d = abs(world_xz - sand_center);
	float half_span = sand_area * 0.5;
	vec2 f = vec2(1.0) - smoothstep(vec2(half_span - 3.5), vec2(half_span - 1.2), d);
	return f.x * f.y;
}

// the deck's surface height in METRES at a world xz: a subtle bumpy-sand RIPPLE base
// (fbm centred on 0, so no net lift) MINUS whatever the deform buffer has dug in
// there. One function so vertex displacement and the fragment normal agree exactly.
// The ripple must stay SHALLOW -- shallower than a footprint dig -- or it swamps the
// prints and the whole court reads as one lumpy blob.
float sand_height(vec2 world_xz) {
	float fade = sand_edge_fade(world_xz);
	// BASELINE BUMPY SAND -- real geometry, LIFTED above the foot plane: the deck sits
	// at +sand_lift, with fine wind ripples over a broad swell as symmetric +/-bumps on
	// top. So the whole surface is ABOVE a standing player's feet (sand_lift bigger than
	// the bump amp keeps even the lowest dip above 0), which is what makes sand rise
	// around the feet. Footprints/craters then dig DOWN into this raised surface.
	float ripple = fbm(world_xz * sand_dune_scale * 2.4);   // fine wind ripples
	float roll = fbm(world_xz * sand_dune_scale * 0.6);     // broad gentle swell
	float bumps = ((ripple * 0.55 + roll * 0.45) - 0.5) * 2.0 * sand_dune_amp;
	float base = sand_lift + bumps;
	// the DIG always applies when there's sand -- this is the whole point, the marks
	// feet/dives/the ball leave. (No sand_displace gate: it used to hide trails.)
	float dig = 0.0;
	vec2 suv = sand_uv(world_xz);
	if (all(greaterThanEqual(suv, vec2(0.0))) && all(lessThanEqual(suv, vec2(1.0)))) {
		dig = textureLod(sand_tex, suv, 0.0).r * sand_depth;
	}
	return (base - dig) * fade;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	uv = UV;
	// REAL DISPLACEMENT: push each vertex to the deck's sand height. On the dedicated
	// subdivided deck this gives actual bumpy sand you can see dug into; a coarse mesh
	// just won't resolve it (the fragment normal below still shades the relief).
	if (sand_on) {
		VERTEX.y += sand_height(world_pos.xz);
	}
}

void fragment() {
	// CUTOUT (EnvFloor only): punch a hole where the deck lives so this flat plane
	// doesn't occlude the deck's dug hollows. Discard the deck INTERIOR (inset 0.8 m
	// from the deck rim); the deck's own faded edge covers the boundary ring, and the
	// surround beyond the deck keeps rendering normally.
	if (sand_cutout) {
		vec2 cd = abs(world_pos.xz - sand_center);
		float inner = sand_area * 0.5 - 0.8;
		if (cd.x < inner && cd.y < inner) {
			discard;
		}
	}
	// two scales. the old single layer was 2-4cm specks over at most 45% of
	// cells -- sub-pixel at play distance, so a soaked floor looked clean.
	// broad damp POOLS carry the read from the camera, finer SPECKLES on top
	// keep it looking like droplets when you're stood over it.
	//
	// pools: threshold an fbm field. as sweat rises the cut drops, so damp
	// areas spread and merge instead of more dots appearing on a lattice.
	float n = fbm(world_pos.xz * 1.5);
	// eased so damp areas appear early in the ramp -- most rallies never reach
	// full sweat, and a linear cut left them showing nothing but speckles.
	// stays above max fbm (~0.94) at sweat 0, so a fresh floor is bone dry.
	// the low end is 0.52, not 0.40: the game used to cap the level at 0.55,
	// and that capped look is the one that reads right. now that the level
	// runs the full 0..1 the curve has to be flattened to match, or a soaked
	// floor is twice as wet as anything that was ever approved.
	float cut = mix(1.02, 0.52, sweat * (2.0 - sweat));
	// WIDE edge band. A tight threshold gives damp areas a definite outline,
	// and an outlined lighter patch on a floor is a stain -- that is what a
	// spill looks like. Real sweat has no border; it just gets glossier toward
	// the middle. This is most of the difference.
	float pool = smoothstep(cut, cut + 0.42, n);

	// SHEEN, not stain. darkening the damp areas read as dirt on the court, so
	// sweat now only ever ADDS light: a wet floor is a shiny floor. the floor
	// is unshaded, so the specular is faked -- normal is +Y, so reflecting a
	// couple of fixed gym-light directions gives broad highlight bands that
	// slide across the boards as the camera moves.
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_pos);
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 m1 = normalize(reflect(-normalize(vec3(0.35, 0.9, 0.25)), up));
	vec3 m2 = normalize(reflect(-normalize(vec3(-0.4, 0.85, -0.3)), up));
	// low exponents on purpose: a tight highlight is invisible from the play
	// camera, a broad wash across the boards is what reads as "polished"
	float sheen = pow(max(dot(m1, view_dir), 0.0), 5.0)
		+ 0.7 * pow(max(dot(m2, view_dir), 0.0), 8.0);

	// hard gate. at sweat 0 EVERY sweat term must be exactly zero or a dry
	// court shows stray specks -- which read as dirt on the boards.
	float wet_gate = smoothstep(0.04, 0.30, sweat);

	// sparkles: sparse jittered points, clustered INTO the damp areas and lit
	// by the highlight bands. spread evenly at full brightness they just look
	// like printed polka dots.
	vec2 gp = world_pos.xz * 5.0;
	vec2 gc = floor(gp);
	float g1 = hash21(gc + vec2(11.3, 2.7));
	float g2 = hash21(gc + vec2(4.9, 8.1));
	float g3 = hash21(gc + vec2(6.2, 13.5));
	vec2 gf = fract(gp) - vec2(0.5) - (vec2(g2, g3) - vec2(0.5)) * 0.72;
	float grad = mix(0.06, 0.17, g3);
	float glint = step(g1, wet_gate * 0.30)
		* (1.0 - smoothstep(grad * 0.3, grad, length(gf)))
		* (0.12 + pool * 0.88);

	// wetness drives gloss only -- the base colour never darkens
	float wetness = clamp(pool, 0.0, 1.0) * wet_gate;
	// the boards (or the flat painted colour): everything below layers over this.
	// sand samples the albedo by WORLD xz so a flat plane matches the triplanar
	// beach texture; other textured floors (gym boards) keep their mesh UVs.
	vec3 col;
	if (use_albedo_tex) {
		col = sand_on
			? texture(albedo_tex, world_pos.xz * sand_albedo_scale).rgb
			: texture(albedo_tex, uv).rgb;
	} else {
		col = base_color.rgb;
		if (checker_size > 0.0) {
			vec2 cell = floor(world_pos.xz / checker_size);
			float odd = mod(cell.x + cell.y, 2.0);
			col = mix(col, checker_color.rgb, odd);
		}
	}

	// SAND COLOUR GRADIENT: ramp the base sand tint across the beach along a world
	// direction (default +x, toward the water). multiply so it keeps the texture detail.
	if (sand_grade) {
		float gp = dot(world_pos.xz, normalize(sand_grade_dir));
		float gg = smoothstep(sand_grade_from, sand_grade_to, gp);
		col *= mix(sand_grade_near, sand_grade_far, gg);
	}

	// LIT COURT: warm pool brightening toward centre court, vignette darkening the
	// edges -- a spotlit gradient so the floor isn't one flat slab.
	float pool_d = distance(world_pos.xz, pool_center.xz);
	float lit = 1.0 - smoothstep(0.0, pool_radius, pool_d);
	col += col * pool_warm * lit * pool_strength;
	col *= 1.0 - smoothstep(pool_radius * 0.5, pool_radius * 1.5, pool_d) * floor_vignette;

	// SAND LIGHTING: the deck's surface is genuinely displaced (dunes + dug-in
	// prints), so shade it from the REAL surface normal. We rebuild that normal from
	// sand_height() by central differences in world metres -- exactly the geometry
	// the vertex stage moved -- then light it with a fixed low beach sun plus flat
	// ambient. This is what gives bumpy sand its rolling volume and makes footprints/
	// craters read as scooped hollows, not painted-on smudges. sand_edge_fade zeroes
	// it at the rim, and sand_on gates it so non-sand courts are untouched.
	if (sand_on && sand_edge_fade(world_pos.xz) > 0.001) {
		float e = 0.03;   // metres; small step so footprint walls stay crisp
		float hL = sand_height(world_pos.xz - vec2(e, 0.0));
		float hR = sand_height(world_pos.xz + vec2(e, 0.0));
		float hD = sand_height(world_pos.xz - vec2(0.0, e));
		float hU = sand_height(world_pos.xz + vec2(0.0, e));
		vec3 snrm = normalize(vec3((hL - hR) * sand_bump, 2.0 * e, (hD - hU) * sand_bump));
		// a GRAZING sun (low on the horizon): shallow dents barely tilt the normal, so
		// only a near-horizontal light throws enough light/shadow across a footprint
		// wall to read. Steeper light washed the prints out to nothing.
		vec3 sun = normalize(vec3(-0.62, 0.42, -0.32));
		float up_lit = dot(vec3(0.0, 1.0, 0.0), sun);          // flat-sand reference
		float shade = (dot(snrm, sun) - up_lit) * sand_relief; // 0 on flat sand
		col += col * clamp(shade, -0.7, 0.7);                  // lit crests / shadowed hollows
		// a whisper of ambient occlusion in the dug hollows (the deform buffer only),
		// so a fresh footprint's floor reads a touch cooler/damper. Kept very light so
		// walked trails stay subtle -- the geometry, not darkening, tells the story.
		vec2 suv = sand_uv(world_pos.xz);
		if (all(greaterThanEqual(suv, vec2(0.0))) && all(lessThanEqual(suv, vec2(1.0)))) {
			col *= 1.0 - texture(sand_tex, suv).r * 0.09;
		}
	}

	// GRAZING-ANGLE POLISH is what actually reads as a wet floor, and it was
	// the missing piece. A damp patch used to brighten by a fixed amount
	// wherever it was, which is a flat pale blob -- a stain. Polish is
	// view-dependent: look straight down at wet varnish and you see the floor,
	// look along it and it lights up. Because it moves with the camera the eye
	// reads it as a surface property instead of a mark ON the surface.
	float ndv = max(dot(up, view_dir), 0.0);
	float fresnel = pow(1.0 - ndv, 4.0);
	col += gloss_tint.rgb * fresnel * wetness * gloss_strength;

	// the fixed light bands now only show where it is actually wet. the old
	// constant term meant the whole floor carried a sheen the moment anybody
	// broke a sweat, which flattened the whole effect out.
	col += vec3(0.22, 0.26, 0.30) * sheen * wetness * 1.5;
	col += vec3(0.85, 0.93, 1.0) * glint * wet_gate
		* (0.1 + smoothstep(0.03, 0.45, sheen) * 1.15);
	float drop = wetness;
	if (reflect_on) {
		// soft reflection: a wide box blur so the mirror reads like a
		// varnished floor smear, not a razor-sharp second image
		vec2 texel = 1.0 / vec2(textureSize(reflect_tex, 0));
		vec4 refl = vec4(0.0);
		float wsum = 0.0;
		for (int x = -2; x <= 2; x++) {
			for (int y = -2; y <= 2; y++) {
				// gaussian-ish weighting keeps the smear soft, not blocky
				float w = 1.0 / (1.0 + float(x * x + y * y));
				refl += texture(reflect_tex,
					SCREEN_UV + vec2(float(x), float(y)) * texel * 4.0) * w;
				wsum += w;
			}
		}
		refl /= wsum;
		// fade with floor distance from the nearest player's feet: strongest at
		// the feet, gone a couple metres out. defaults to full when no feet set.
		float fade = 0.0;
		bool any = false;
		for (int i = 0; i < 8; i++) {
			if (feet[i].w < 0.5) { continue; }
			any = true;
			float d = distance(world_pos.xz, vec2(feet[i].x, feet[i].z));
			fade = max(fade, 1.0 - smoothstep(0.35, 1.9, d));
		}
		if (!any) { fade = 1.0; }
		// wet patches mirror harder -- the gloss is most of what sells "slick"
		// wet patches mirror much harder than dry ones -- a stronger cue than
		// any amount of added brightness, because a real mirror-finish patch
		// shows the SCENE in it rather than just being paler
		float strength = clamp(reflectivity + drop * 0.9, 0.0, 0.98) * fade;
		col = mix(col, refl.rgb, refl.a * strength);
	}
	ALBEDO = col;
}
