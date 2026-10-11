shader_type spatial;
// BOTW-style field grass as cheap BILLBOARD CARDS. The source mesh is a single 2-tri
// quad; one shared material drives every MultiMesh chunk. Each quad cylindrical-
// billboards to the camera and an alpha-scissor TUFT (several tapered blades) is drawn
// procedurally in the fragment, so one 2-triangle instance still reads as a lush clump.
// ~6x less geometry than solid 3D blades, which is what makes a huge field affordable.
//
//   billboard   : quad faces the camera around the vertical axis (grass stays upright)
//   root/tip    : UV.y = height fraction; root (0) planted, tip (1) gets full bend
//   wind        : layered world-space waves (big gust + medium + local flutter)
//   interaction : up to MAX_INTERACT player points pushed in as one vec4[] uniform
//   tuft        : procedural alpha-cut blades (no texture asset), scissor not blend so
//                 it stays in the opaque pass -- no transparency sorting
//   color       : root->tip gradient + per-instance variation + screen-space wash
//
// LOD is on the CPU (grass_field.gd) via each chunk's visible_instance_count +
// visibility_range, so far/thinned cards never reach this shader. Grass casts no
// shadows (chunks are SHADOW_CASTING OFF) but still RECEIVES light via an up normal.

// unshaded so the blades render at exactly texture*tint*brightness regardless of scene
// light -- this is what keeps them matching the (also-unshaded) grass floor AND makes
// the editor preview match in-game (the game fakes all lighting anyway).
render_mode cull_disabled, unshaded, depth_draw_opaque;

const int MAX_INTERACT = 12;

// --- wind -------------------------------------------------------------------
uniform vec2 wind_direction = vec2(1.0, 0.35);
uniform float wind_strength : hint_range(0.0, 1.0) = 0.32;
uniform float wind_speed : hint_range(0.0, 4.0) = 1.1;
uniform float large_wave_scale : hint_range(1.0, 60.0) = 22.0;  // metres per big gust
uniform float small_wave_scale : hint_range(0.5, 20.0) = 6.0;   // metres per ripple
uniform float flutter_strength : hint_range(0.0, 0.5) = 0.06;
uniform float bend_curve : hint_range(1.0, 4.0) = 1.6;          // how root-weighted the bend is
uniform float freeze_wind = 0.0;                                // debug: 1.0 stops time
// FAKE shading (keeps editor==game since the grass is unshaded): broad wind gusts
// brighten/darken bands of the field as they roll through, giving the flat field form
// and motion. Coherent (large wave only), so it reads as light sweeping, not shimmer.
uniform float wind_shade : hint_range(0.0, 1.0) = 0.32;
// as the camera looks straight down, billboard cards turn edge-on and read as scattered
// triangles. Fade the blade HEIGHT toward the floor from a top-down view so it reads as
// the (matching) floor texture from above instead.
uniform float topdown_flatten : hint_range(0.0, 1.0) = 0.75;

// --- interaction (players) --------------------------------------------------
// xy = world xz of the point, z = strength (0 = slot unused), w = radius (m).
uniform vec4 interact_points[MAX_INTERACT];
uniform int interact_count = 0;

// --- recovery wake (grass_wake.gd) ------------------------------------------
// a top-down buffer whose .r is how flattened the grass is here; it FADES over time so
// a walked trail springs back smoothly instead of snapping upright. Off in the editor.
uniform sampler2D wake_tex : hint_default_black;
uniform vec2 wake_center = vec2(0.0);
uniform float wake_area = 24.0;
uniform bool wake_on = false;
uniform float wake_flatten : hint_range(0.0, 1.0) = 0.8;   // how far a press lies the grass down
uniform float wake_bend : hint_range(0.0, 1.0) = 0.5;      // how much it leans away from the press

// --- tuft silhouette (alpha scissor, no texture) ----------------------------
uniform int tuft_blades : hint_range(1, 6) = 4;                 // blades drawn per card
uniform float blade_thickness : hint_range(0.05, 0.6) = 0.32;   // base width of each blade
uniform float tip_narrow : hint_range(0.0, 1.0) = 0.9;          // how sharply blades taper

// --- color ------------------------------------------------------------------
// the base colour is SAMPLED from the ground texture (grasstielablecartoon.jpg) at the
// card's world position, so blades match the floor palette exactly. tex_scale is low so
// the colour varies smoothly across the field (broad mottling, not per-metre noise).
uniform sampler2D grass_tex : source_color, hint_default_white;
uniform bool use_tex = true;
uniform float tex_scale = 0.14;                          // world metres -> uv multiplier
uniform vec3 base_tint : source_color = vec3(1.0);       // ALWAYS multiplies the colour (tint)
uniform float brightness : hint_range(0.0, 3.0) = 1.0;   // overall brightness (raise to brighten)
// the blade ROOT renders as the floor colour (root_shade=1.0 -> exact match, so the base
// melts into the ground) and lerps toward tip_color up the blade so the blade still reads
// clearly against the floor. Raise tip_amount / brighten tip_color for more contrast.
uniform float root_shade : hint_range(0.0, 1.5) = 1.0;
uniform vec3 tip_color : source_color = vec3(0.72, 0.95, 0.40);   // brighter/yellower tips
uniform float tip_amount : hint_range(0.0, 1.0) = 0.5;
uniform float color_variation : hint_range(0.0, 1.0) = 0.18;

// random brighter-green patches across the field, coherent with the floor (both sample
// the SAME world-space value noise). patch_scale = metres per patch; patch_strength =
// how strongly patched areas take patch_color (0 = off).
uniform vec3 patch_color : source_color = vec3(0.62, 0.92, 0.34);
uniform float patch_scale : hint_range(1.0, 40.0) = 8.0;
uniform float patch_strength : hint_range(0.0, 1.0) = 0.25;

// screen-space gradient: a subtle vertical wash so the field reads as one clean mass.
// Kept gentle + green so it doesn't fight the sampled texture colour.
uniform vec3 grad_bottom : source_color = vec3(1.0, 1.02, 0.92);
uniform vec3 grad_top : source_color = vec3(0.82, 0.93, 0.86);
uniform float grad_strength : hint_range(0.0, 1.0) = 0.12;

varying float v_tint;
varying vec3 v_base;
varying float v_shade;   // fake wind-band brightness, applied in the fragment

// cheap value noise for the brighter-green patches (shared, world-space -> the floor
// shader uses the identical function so patches line up between ground and grass).
float _hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float _vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(_hash(i), _hash(i + vec2(1.0, 0.0)), u.x),
		mix(_hash(i + vec2(0.0, 1.0)), _hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float _patch(vec2 w) {
	return smoothstep(0.5, 0.85, _vnoise(w / max(patch_scale, 0.001))) * patch_strength;
}

void vertex() {
	float bend = clamp(UV.y, 0.0, 1.0);      // 0 root .. 1 tip
	float bendw = pow(bend, bend_curve);

	// instance placement + width/height scale (rotation is ignored -- we billboard)
	vec3 origin = MODEL_MATRIX[3].xyz;
	float sw = length(MODEL_MATRIX[0].xyz);
	float sh = length(MODEL_MATRIX[1].xyz);

	// cylindrical billboard: face the camera around world-up so the card stays upright
	vec3 to_cam_full = CAMERA_POSITION_WORLD - origin;
	vec3 to_cam = vec3(to_cam_full.x, 0.0, to_cam_full.z);
	vec3 view = normalize(to_cam + vec3(0.0, 0.0, 1e-4));
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), view));

	// top-down fade: when the camera is above the card (billboards go edge-on), shrink
	// the blade -- BOTH height and horizontal bend (td) -- so from directly above the
	// field reads as the matching floor instead of long stretched-out streaks.
	float upness = normalize(to_cam_full).y;
	float topdown = smoothstep(0.55, 0.9, upness);
	float td = 1.0 - topdown * topdown_flatten;
	float hscale = td;

	// recovery wake: press the grass down where recently walked (fades back over time).
	vec2 wake_lean = vec2(0.0);
	if (wake_on) {
		vec2 wuv = (origin.xz - wake_center) / wake_area + 0.5;
		if (wuv.x > 0.0 && wuv.x < 1.0 && wuv.y > 0.0 && wuv.y < 1.0) {
			float wflat = texture(wake_tex, wuv).r;
			hscale *= (1.0 - wflat * wake_flatten);   // lie the blade down
			// lean away from the pressed centre (down the flatten gradient), CAPPED so a
			// steep stamp edge can't fling a blade into a long streak.
			float e = 0.006;
			float gx = texture(wake_tex, wuv + vec2(e, 0.0)).r - texture(wake_tex, wuv - vec2(e, 0.0)).r;
			float gy = texture(wake_tex, wuv + vec2(0.0, e)).r - texture(wake_tex, wuv - vec2(0.0, e)).r;
			wake_lean = clamp(-vec2(gx, gy) * wake_bend * 2.5, vec2(-0.35), vec2(0.35));
		}
	}

	// build the card in world space (VERTEX.x in [-0.5,0.5], VERTEX.y in [0,1])
	vec3 world = origin + right * (VERTEX.x * sw) + vec3(0.0, VERTEX.y * sh * hscale, 0.0);

	// per-instance randoms packed at build time
	float phase = INSTANCE_CUSTOM.x;   // 0..1 wind phase offset
	v_tint = INSTANCE_CUSTOM.y;        // 0..1 colour pick (to fragment)

	// sample the ground texture at this card's world xz so the blade matches the floor.
	// (textureLod: vertex has no derivatives.) One sample per card, constant up the blade.
	// base_tint (default white) always multiplies, and brightness scales overall, so both
	// work whether or not the texture is on -- brightness is the "make it brighter" knob.
	vec3 samp = use_tex ? textureLod(grass_tex, origin.xz * tex_scale, 0.0).rgb : vec3(0.30, 0.70, 0.28);
	v_base = samp * base_tint * brightness;
	// brighter-green patches: pull the base toward patch_color where the noise is high
	v_base = mix(v_base, patch_color * brightness, _patch(origin.xz));

	// ---- layered world-space wind -----------------------------------------
	vec2 wd = normalize(wind_direction);
	float t = TIME * wind_speed * (1.0 - freeze_wind);
	float big = sin(dot(origin.xz, wd) * (6.2831853 / large_wave_scale) - t);
	float med = sin(dot(origin.xz, wd) * (6.2831853 / small_wave_scale) - t * 1.9 + phase * 6.2831853);
	float flut = sin(t * 6.0 + phase * 12.566) * flutter_strength;
	float sway = (big * 0.6 + med * 0.4) * wind_strength + flut;
	vec3 disp = vec3(wd.x, 0.0, wd.y) * sway;
	disp.xz += wake_lean;   // lean of a walked-through (recovering) trail
	// fake shading: the broad gust (big) brightens crests / darkens troughs as it rolls,
	// so the flat unshaded field gets moving light bands. Coherent (big only, no flutter).
	v_shade = 1.0 + big * wind_shade;

	// ---- player interaction: push away + flatten --------------------------
	for (int i = 0; i < MAX_INTERACT; i++) {
		if (i >= interact_count) { break; }
		vec4 ip = interact_points[i];
		if (ip.z <= 0.0) { continue; }
		vec2 d = origin.xz - ip.xy;
		float dist = length(d);
		float infl = (1.0 - smoothstep(ip.w * 0.2, ip.w, dist)) * ip.z;
		disp.xz += (d / max(dist, 1e-3)) * infl;
		disp.y  -= infl * 0.55;   // flatten downward; dives (high strength) mash hardest
	}

	// scale the horizontal bend by td too: from a top-down view the tips don't fling out
	// into long streaks (they shrink toward the root along with the height).
	world += disp * bendw * td;   // only the upper card bends; the root stays planted
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
}

void fragment() {
	// procedural tuft: several tapered, slightly-leaning blades across the card width,
	// alpha-cut so the quad reads as a clump of blades instead of a rectangle.
	float N = float(tuft_blades);
	float u = UV.x * N;
	float bi = floor(u);
	float cell = fract(u);
	float r = fract(sin(bi * 127.1 + 3.7) * 43758.5);   // stable per-blade random
	float bh = mix(0.7, 1.0, r);                        // this blade's tip height
	float lean = (r - 0.5) * 0.35;                      // slight sideways lean with height
	float center = 0.5 + lean * UV.y;
	float halfw = 0.5 * blade_thickness * (1.0 - (UV.y / bh) * tip_narrow);
	if (UV.y > bh || abs(cell - center) > halfw) {
		discard;                                        // outside every blade in this cell
	}

	// root = the floor colour (v_base * root_shade); lerp toward tip_color up the blade
	// so the tip stands out from the ground while the base blends in.
	vec3 root = v_base * root_shade;
	vec3 g = mix(root, tip_color * brightness, clamp(UV.y * tip_amount, 0.0, 1.0));
	// subtle per-instance brightness variation so the field isn't a flat sheet
	g *= mix(1.0 - color_variation, 1.0 + color_variation, v_tint);
	g *= v_shade;   // fake wind-band light/dark, gives the flat field form + motion

	// gentle screen-space vertical wash (SCREEN_UV.y: 0 top .. 1 bottom)
	vec3 grad = mix(grad_top, grad_bottom, SCREEN_UV.y);
	ALBEDO = mix(g, g * grad, grad_strength);
}
