// BEACH CROWD (view-dependent billboards). Cheap dense beachgoers in ONE MultiMesh,
// but they FACE FIXED WORLD DIRECTIONS (the ocean, each other, along the boardwalk) --
// not the camera. Trick: the quad still turns to the camera so it's never edge-on/thin,
// but the sprite it shows is the character baked from the angle the camera happens to
// see them at, given the direction they face. So a person "facing the sea" shows you
// their back; walk around and the sprite rotates with you. (Doom / Don't Starve style.)
//   INSTANCE_CUSTOM.x = character row (0..chars-1)
//   INSTANCE_CUSTOM.y = bob phase (0..1)
//   INSTANCE_CUSTOM.z = facing yaw / TAU (0..1) -- the world direction this person faces
// The atlas is a grid: `grid` = (angle columns, character rows); `angles` = column count.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;

uniform sampler2D atlas : filter_linear_mipmap, source_color;
uniform vec2 grid = vec2(8.0, 24.0);   // cols = baked angles, rows = characters
uniform float angles = 8.0;
uniform float angle_offset = 0.0;      // tune if front/back come out swapped
uniform float foot_lift = 1.0;
uniform float bob_amp = 0.03;
uniform float bob_speed = 1.0;
uniform vec3 haze_color : source_color = vec3(0.72, 0.82, 0.92);
uniform float haze_start = 40.0;
uniform float haze_end = 150.0;
uniform float haze_amt : hint_range(0.0, 1.0) = 0.0;
uniform float desat : hint_range(0.0, 1.0) = 0.0;

varying flat float vchar;
varying flat float vface;
varying vec2 uv;
varying flat float vhaze;
varying flat vec3 vwpos;

void vertex() {
	vec3 wpos = MODEL_MATRIX[3].xyz;
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	// Y-axis billboard: face the camera but stay upright, so the quad is never thin
	vec3 look = normalize(vec3(cam.x - wpos.x, 0.0, cam.z - wpos.z));
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), look));
	float bob = sin(TIME * bob_speed + INSTANCE_CUSTOM.y * 6.2831) * bob_amp;
	vec3 world = wpos + right * VERTEX.x + vec3(0.0, 1.0, 0.0) * (VERTEX.y + foot_lift + bob);
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
	vchar = INSTANCE_CUSTOM.x;
	vface = INSTANCE_CUSTOM.z * 6.2831853;
	uv = UV;
	vwpos = wpos;
	vhaze = haze_amt * smoothstep(haze_start, haze_end, distance(cam, wpos));
}

void fragment() {
	// which baked angle to show = how this person's FACING relates to where the CAMERA is
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec2 tocam = normalize(cam.xz - vwpos.xz);
	float cam_az = atan(tocam.x, tocam.y);        // atan2(x, z)
	float step = 6.2831853 / angles;
	float ai = floor(mod((vface - cam_az) / step + angle_offset + 0.5, angles));
	vec2 cell = vec2(1.0) / grid;
	vec2 tuv = (vec2(ai, floor(vchar)) + vec2(uv.x, uv.y)) * cell;
	vec4 t = texture(atlas, tuv);
	vec3 c = t.rgb;
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(luma), desat);
	ALBEDO = mix(c, haze_color, vhaze);
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
