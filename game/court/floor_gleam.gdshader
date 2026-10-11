// FLOOR GLEAM: a fake polished-floor reflection for a hand-painted gym. One
// additive quad laid over the boards. For each pixel it mirrors the camera below
// the floor and traces the mirrored ray on to (a) the two long walls, lighting
// the pixel where that ray lands in a window, and (b) the ceiling, lighting it
// where it lands on a light panel. That IS planar-mirror math, so the streaks
// sit exactly where a real polished floor would show them and slide correctly as
// the camera moves -- without a reflection probe, a second render, or a
// transparent floor (see the floor-reflection rule). Fresnel-weighted: strong at
// grazing angles, faint looking straight down. Pure decoration, no depth write.
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform float intensity : hint_range(0.0, 2.0) = 0.55;
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.2;
uniform float blur : hint_range(0.0, 1.5) = 0.9;         // edge softness, as a fraction of each feature's size
uniform float floor_y = 0.0;

// side windows: on the walls x = +-wall_x, a band from win_y0..win_y1, repeating
// panes along z (pitch) each pane_w wide, starting at win_z0 up to win_z1
uniform vec3 window_color : source_color = vec3(1.0, 0.94, 0.82);
uniform float window_amt : hint_range(0.0, 2.0) = 1.0;
uniform float wall_x = 32.4;
uniform float win_y0 = 8.7;
uniform float win_y1 = 10.7;
uniform float win_z0 = -35.0;
uniform float win_z1 = 22.0;
uniform float win_pitch = 8.1;
uniform float win_w = 3.6;

// ceiling light panels: a grid on the plane y = ceil_y
uniform vec3 panel_color : source_color = vec3(1.0, 0.97, 0.9);
uniform float panel_amt : hint_range(0.0, 2.0) = 0.8;
uniform float ceil_y = 14.5;
// squash: how much of the real ceiling height the MIRROR uses. 1 = physically
// exact (a 15 m ceiling throws its reflections far across the floor as soon as
// the camera tilts -- reads as "wildly displaced"); lower values hang a virtual
// ceiling closer to the boards so each reflection stays near its own fixture.
uniform float mirror_squash : hint_range(0.1, 1.0) = 0.35;
// looking straight down still shows some gleam (floor of the fresnel curve)
uniform float base_visible : hint_range(0.0, 1.0) = 0.45;
uniform vec2 panel_origin = vec2(-29.6, -22.3);
uniform vec2 panel_pitch = vec2(15.8, 10.9);
uniform vec2 panel_size = vec2(6.0, 3.6);
uniform vec2 panel_extent = vec2(57.5, 45.0);   // grid covers this much x/z from the origin

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float soft_in(float v, float lo, float hi, float b) {
	// 1 inside [lo, hi], feathered by b at both edges
	return smoothstep(lo - b, lo + b, v) * (1.0 - smoothstep(hi - b, hi + b, v));
}

float windows(vec3 from, vec3 p, float x_wall) {
	float dx = p.x - from.x;
	if (abs(dx) < 0.001) { return 0.0; }
	float t = (x_wall - from.x) / dx;
	if (t < 1.0) { return 0.0; }              // wall is behind the pixel, not beyond it
	vec3 hit = from + (p - from) * t;
	float bz = blur * win_w * 0.5 + 0.05;
	float by = blur * (win_y1 - win_y0) * 0.5 + 0.05;
	float band = soft_in(hit.y, win_y0, win_y1, by);
	float span = soft_in(hit.z, win_z0, win_z1, bz);
	float local = mod(hit.z - win_z0, win_pitch);
	float pane = soft_in(local, 0.0, win_w, bz);
	// distant hits spread out on a real floor: fade a little with reflected distance
	float dist = length(hit - p);
	float fade = 1.0 / (1.0 + dist * 0.02);
	return band * span * pane * fade;
}

float panels(vec3 from, vec3 p) {
	float dy = p.y - from.y;
	if (abs(dy) < 0.001) { return 0.0; }
	float plane_y = floor_y + (ceil_y - floor_y) * mirror_squash;
	float t = (plane_y - from.y) / dy;
	if (t < 1.0) { return 0.0; }
	vec3 hit = from + (p - from) * t;
	vec2 b = blur * panel_size * 0.5 + 0.05;
	vec2 rel = hit.xz - panel_origin;
	float inside = soft_in(rel.x, 0.0, panel_extent.x, b.x) * soft_in(rel.y, 0.0, panel_extent.y, b.y);
	vec2 local = mod(rel, panel_pitch);
	float cell = soft_in(local.x, 0.0, panel_size.x, b.x) * soft_in(local.y, 0.0, panel_size.y, b.y);
	float dist = length(hit - p);
	float fade = 1.0 / (1.0 + dist * 0.03);
	return inside * cell * fade;
}

void fragment() {
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	// the camera mirrored through the floor plane: what a mirror floor "sees".
	// the ceiling bounce uses a SQUASHED camera height too, so the virtual
	// ceiling and the virtual eye scale together and reflections land near
	// their fixtures instead of racing across the floor
	vec3 from = vec3(cam.x, 2.0 * floor_y - cam.y, cam.z);
	vec3 p = vec3(wpos.x, floor_y, wpos.z);
	vec3 col = vec3(0.0);
	float w = windows(from, p, wall_x) + windows(from, p, -wall_x);
	col += window_color * w * window_amt;
	vec3 from_sq = vec3(cam.x, floor_y - (cam.y - floor_y) * mirror_squash, cam.z);
	col += panel_color * panels(from_sq, p) * panel_amt;
	// fresnel: grazing views reflect, looking straight down barely does
	vec3 to_cam = normalize(cam - p);
	float grazing = pow(1.0 - clamp(to_cam.y, 0.0, 1.0), fresnel_power);
	col *= intensity * (base_visible + (1.0 - base_visible) * grazing);
	ALBEDO = col;
	ALPHA = clamp(max(col.r, max(col.g, col.b)), 0.0, 1.0);
}
