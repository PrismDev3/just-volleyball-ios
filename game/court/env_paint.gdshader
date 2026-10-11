// HAND-PAINTED ENVIRONMENT + FAKE LIGHTING. The venue has NO real lights (suits
// the flat look and is renderer-proof), so this shader fakes every cue a lit gym
// would give -- which is what stops a boxy imported room reading as dead paint:
//   * hemispheric ambient   -- warm sky from above, cool bounce from below.
//   * a fake KEY LIGHT       -- ONE chosen direction, so the four walls of a
//                               boxy hall stop reading as a single flat white
//                               tone. Half-lambert: no hard terminator, nothing
//                               crushes to black -- it just tilts brightness by
//                               which way a surface faces.
//   * baked AO via vertex COLOR -- multiplied in. COLOR is white until the mesh
//                               carries a bake, so this is a FREE hook: bake AO
//                               to vertex colours in Blender and contact shadows
//                               appear under the seats / bleachers / pillars.
//   * a vertical MOOD BAND   -- darker at the floor contact line and up in the
//                               rafters, brightest at eye level: vertical form
//                               on big flat walls for nothing.
//   * a floor LIGHT POOL     -- up-facing surfaces brighten toward centre court,
//                               like the house lights pool on the boards.
//   * screen-space cavity + a grazing rim (as before).
// Optional albedo_tex keeps the wood boards' / doors' image but still runs it
// through all of the above, so NOTHING in the gym is flat-lit. One albedo
// uniform so the school accent system just feeds a different colour to its mats.
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec4 albedo : source_color = vec4(0.8, 0.8, 0.8, 1.0);
// optional surface texture (wood boards, doors). off -> flat albedo colour.
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_tex = false;
uniform vec3 sky_tint : source_color = vec3(1.0, 0.96, 0.85);   // warm cream from above
uniform vec3 ground_tint : source_color = vec3(0.68, 0.62, 0.58); // warm bounce (was cold blue)
uniform float ambient : hint_range(0.0, 1.0) = 0.62;
uniform float cavity : hint_range(0.0, 2.0) = 1.0;
uniform float rim : hint_range(0.0, 1.0) = 0.2;
// cheerful cartoony grade -- pops the accent/wood/crowd and warms the greys so
// the hall reads bright and friendly instead of institutional concrete.
uniform float saturation : hint_range(0.0, 2.0) = 1.12;
uniform float exposure : hint_range(0.5, 2.0) = 1.04;
uniform vec3 warm_tint : source_color = vec3(1.0, 0.985, 0.95);
// fake key light
uniform vec3 key_dir = vec3(0.4, 0.75, 0.5);
uniform float key : hint_range(0.0, 1.0) = 0.55;
// vertical mood band (world Y). tune ceiling_y to the venue's real wall height.
uniform float floor_y = 0.0;
uniform float ceiling_y = 10.5;
uniform float height_shade : hint_range(0.0, 1.0) = 0.34;
// floor light pool + warmth + vignette (world XZ around court centre). the
// boards read as a spotlit, warm wood court instead of a flat pale sheet.
uniform vec3 pool_center = vec3(0.0, 0.0, 0.0);
uniform float pool_radius = 15.0;
uniform float pool_strength : hint_range(0.0, 1.5) = 0.42;
uniform vec3 floor_warm : source_color = vec3(1.0, 0.74, 0.5);
uniform float floor_warm_amt : hint_range(0.0, 1.0) = 0.44;
uniform float floor_vignette : hint_range(0.0, 1.0) = 0.46;
// FAKE SHINE -- specular hotspot + a cheap fresnel sky-reflection so surfaces
// catch light and read glossy (esp. the floor) instead of flat matte.
uniform float spec_wall : hint_range(0.0, 2.0) = 0.14;
uniform float spec_floor : hint_range(0.0, 2.0) = 0.6;
uniform float spec_sharp_wall = 22.0;
uniform float spec_sharp_floor = 70.0;
uniform float floor_reflect : hint_range(0.0, 1.0) = 0.16;
// atmospheric haze: distant architecture fades toward a soft haze so the big
// hall reads with air + depth instead of flat and uniform.
uniform vec3 haze_color : source_color = vec3(0.83, 0.87, 0.93);
uniform float haze_start = 15.0;
uniform float haze_end = 44.0;
uniform float haze_amt : hint_range(0.0, 1.0) = 0.24;
// PROCEDURAL WALL BREAKUP: a faint world-space mottle so the big flat plaster
// walls + ceiling stop reading as dead paint, with no texture asset. Floor and
// textured (wood boards / doors) surfaces are skipped -- they already have detail.
uniform float detail_amt : hint_range(0.0, 1.0) = 0.0;
// CEILING NEUTRALIZE: pull DOWN-facing surfaces (the ceiling) off the school
// accent toward a neutral, so the roof stops reading as one saturated slab of the
// school colour even when it shares the trim/seat material (which, facing side/up,
// stays accented). Node-agnostic -- keys off surface orientation, not mesh names.
uniform float ceiling_neutral : hint_range(0.0, 1.0) = 0.0;
uniform vec3 ceiling_tint : source_color = vec3(0.9, 0.88, 0.85);
// WARM KEY / COOL SHADE: tint the fake key light's shaded side cool so the warm
// hall gets classic temperature contrast instead of reading warm-on-warm + flat.
uniform float shade_cool : hint_range(0.0, 1.0) = 0.0;
uniform vec3 shade_tint : source_color = vec3(0.8, 0.85, 1.0);
// ALBEDO DESATURATION: pull the material's own colour toward its greyscale BEFORE
// lighting -- de-oranges a warm wood texture at the source (so it reads tan) while
// the key light + AO still shape it. Unlike `saturation` (a final grade that greys
// the whole frame), this only touches the venue's own paint. 0 = keep as authored.
uniform float tex_desat : hint_range(0.0, 1.0) = 0.0;
// COURT FOCUS: darken surfaces by horizontal distance from centre court so the
// court is the bright focal point and the periphery falls into mood shadow.
uniform float focus_dim : hint_range(0.0, 1.0) = 0.0;
// grade CONTRAST (1.0 = none): >1 deepens shadows + lifts highlights for punch.
uniform float contrast : hint_range(0.5, 2.0) = 1.0;

varying vec3 world_normal;
varying vec3 world_pos;
varying vec2 uv;

// cheap hash-based value noise for the wall breakup (no texture needed)
float _hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}
float _vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(_hash13(i + vec3(0.0, 0.0, 0.0)), _hash13(i + vec3(1.0, 0.0, 0.0)), f.x),
			mix(_hash13(i + vec3(0.0, 1.0, 0.0)), _hash13(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(_hash13(i + vec3(0.0, 0.0, 1.0)), _hash13(i + vec3(1.0, 0.0, 1.0)), f.x),
			mix(_hash13(i + vec3(0.0, 1.0, 1.0)), _hash13(i + vec3(1.0, 1.0, 1.0)), f.x), f.y),
		f.z);
}

void vertex() {
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	uv = UV;
}

void fragment() {
	vec3 base = use_tex ? texture(albedo_tex, uv).rgb * albedo.rgb : albedo.rgb;

	// ALBEDO DESATURATE: take a saturated (orange wood) source toward tan at the
	// paint level, before any lighting -- keeps form, kills the orange.
	base = mix(base, vec3(dot(base, vec3(0.299, 0.587, 0.114))), tex_desat);

	// CEILING NEUTRALIZE: down-facing surfaces (the roof) drift off the accent
	// toward a light neutral, so a saturated school colour doesn't own the ceiling.
	float down_face = smoothstep(0.4, 0.85, -world_normal.y);
	base = mix(base, ceiling_tint, ceiling_neutral * down_face);

	// hemispheric ambient: up-facing catches the warm sky, down-facing the cool
	// bounce. this alone pulls flat white off pure 1.0 so it stops blowing out.
	float up = dot(world_normal, vec3(0.0, 1.0, 0.0)) * 0.5 + 0.5;
	vec3 amb = mix(ground_tint, sky_tint, up);
	vec3 col = base * mix(vec3(1.0), amb, ambient);

	// FAKE KEY LIGHT. half-lambert off one direction differentiates the walls
	// and pillars by facing -- the single biggest win for a boxy flat room. the
	// shaded side floors at ~0.55 so the contrast between facings really reads.
	float ndl = dot(world_normal, normalize(key_dir)) * 0.5 + 0.5;
	col *= mix(1.0, 0.55 + ndl * 0.8, key);

	// WARM KEY / COOL SHADE: cool the shaded side (low ndl) for temperature
	// contrast. Warm hall, cool shadows -- the classic lift out of warm-on-warm.
	col *= mix(vec3(1.0), shade_tint, shade_cool * (1.0 - ndl));

	// BAKED AO rides in vertex colour: multiply. white (no-op) until the user
	// bakes occlusion into the mesh -> free contact shadows on dense geometry.
	col *= COLOR.rgb;

	// screen-space cavity: darkens creases + silhouette edges on detailed geo.
	float crease = clamp(length(fwidth(NORMAL)) * 3.5 * cavity, 0.0, 1.0);
	col *= 1.0 - crease * 0.6;

	// vertical MOOD BAND: darkest at the floor contact line and near the ceiling,
	// lightest a third of the way up. gives tall flat walls form for free.
	float h = clamp((world_pos.y - floor_y) / max(ceiling_y - floor_y, 0.001), 0.0, 1.0);
	float band = 1.0 - height_shade
		* (smoothstep(0.3, 0.0, h) * 0.8 + smoothstep(0.65, 1.0, h) * 0.5);
	col *= band;

	// FLOOR treatment (up-facing surfaces only): warm the boards toward orange,
	// pool warm light at centre court, and vignette the edges -- together that's
	// a spotlit gradient instead of a flat pale sheet.
	float up_face = smoothstep(0.6, 0.95, world_normal.y);
	float pd = distance(world_pos.xz, pool_center.xz);
	if (up_face > 0.001) {
		col = mix(col, col * floor_warm, floor_warm_amt * up_face);
		float pool = (1.0 - smoothstep(0.0, pool_radius, pd)) * up_face;
		col += col * floor_warm * pool * pool_strength;
		float vig = smoothstep(pool_radius * 0.5, pool_radius * 1.4, pd) * up_face;
		col *= 1.0 - vig * floor_vignette;
	}

	// WALL BREAKUP: faint two-octave world-space mottle on the flat plaster walls
	// + ceiling (never the floor, never a textured surface) so they read as a real
	// painted surface with subtle variation instead of one dead flat tone.
	if (detail_amt > 0.001 && !use_tex && up_face < 0.5) {
		float big = _vnoise(world_pos * 0.6);
		float fine = _vnoise(world_pos * 3.5);
		float d = mix(big, fine, 0.35) - 0.5;
		col *= 1.0 + d * detail_amt * 0.6;
	}

	// ---- FAKE SHINE: gives surfaces depth without any real lights/probes ----
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_pos);

	// specular hotspot off the fake key light (Blinn-Phong). Sharper + stronger
	// on the floor's glossy boards than on the matte walls.
	vec3 half_v = normalize(normalize(key_dir) + view_dir);
	float ndh = max(dot(world_normal, half_v), 0.0);
	float sharp = mix(spec_sharp_wall, spec_sharp_floor, up_face);
	float spec = pow(ndh, sharp) * mix(spec_wall, spec_floor, up_face);
	col += sky_tint * spec;

	// cheap fake reflection on the floor: reflect the view and sample a simple
	// sky/ground gradient, fresnel-weighted -> the boards pick up a glossy sheen
	// with no reflection probe.
	vec3 rvec = reflect(-view_dir, world_normal);
	float sky_g = smoothstep(-0.15, 0.65, rvec.y);
	float fres_r = pow(1.0 - max(dot(world_normal, view_dir), 0.0), 3.5);
	col += mix(ground_tint, sky_tint, sky_g) * fres_r * floor_reflect * up_face;

	// grazing fresnel rim so edges + big flat faces get a lift (every surface)
	float fres = pow(1.0 - max(dot(world_normal, view_dir), 0.0), 3.0);
	col += sky_tint * fres * rim;

	// COURT FOCUS (the visual hierarchy): darken surfaces by their horizontal
	// distance from centre court, so the court reads as the bright focal point and
	// the walls / corners / far end fall into warm mood shadow. The floor pool
	// above re-lifts the court centre, so the eye lands exactly there.
	float court_d = distance(world_pos.xz, pool_center.xz);
	float fdim = smoothstep(pool_radius * 0.7, pool_radius * 2.0, court_d);
	col *= 1.0 - fdim * focus_dim;

	// atmospheric haze by camera distance: the far side of the hall softens and
	// cools a touch, giving the big volume air + depth.
	float cam_d = length(CAMERA_POSITION_WORLD - world_pos);
	col = mix(col, haze_color, smoothstep(haze_start, haze_end, cam_d) * haze_amt);

	// cheerful grade: warm + brighten, push CONTRAST (deeper shadows, brighter
	// highlights -- the punchy moody look), then saturation so colours pop. Greys
	// stay grey under saturation, so the warm tint is what lifts the walls.
	col *= exposure * warm_tint;
	col = max((col - vec3(0.5)) * contrast + vec3(0.5), vec3(0.0));
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	col = max(mix(vec3(luma), col, saturation), vec3(0.0));

	ALBEDO = col;
}
