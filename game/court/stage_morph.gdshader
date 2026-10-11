shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, shadows_disabled;

// WORLD-SPACE stage dissolve. Applied (as material_override) to a stage's meshes
// during a live transition. A plane sweeps along `dir`; as it passes each point the
// geometry breaks into glowing hexagonal cells and winks out (mode +1, dissolve OUT)
// -- or assembles the same way (mode -1, dissolve IN, for the incoming stage). The
// two run on the same `wave`, so the arena is digitally reconstructed in one pass.
// The camera never moves and the player stays visible: this is all on the geometry.

uniform float wave = -9999.0;                 // sweep position along dir (world units)
uniform vec3 dir = vec3(1.0, 0.0, 0.0);       // sweep direction (horizontal)
uniform float band = 5.0;                      // width of the glowing dissolve front
uniform float mode = 1.0;                      // +1 dissolve OUT, -1 materialize IN
uniform vec3 base_color : source_color = vec3(0.4, 0.7, 1.0);
uniform vec3 edge_color : source_color = vec3(0.65, 0.92, 1.0);
uniform float hex_size = 1.3;                  // world metres per hex cell
uniform float scatter = 4.0;                   // per-cell randomness at the front

varying vec3 v_wpos;

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float h11(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float hex_dist(vec2 p) { p = abs(p); return max(dot(p, normalize(vec2(1.0, 1.7320508))), p.x); }
// nearest hex cell: id in .xy, distance-to-edge (0 edge, ~0.5 centre) in .z
vec3 hex_cell(vec2 uv) {
	vec2 r = vec2(1.0, 1.7320508);
	vec2 h = r * 0.5;
	vec2 a = mod(uv, r) - h;
	vec2 b = mod(uv - h, r) - h;
	vec2 gv = dot(a, a) < dot(b, b) ? a : b;
	return vec3(uv - gv, 0.5 - hex_dist(gv));
}

void fragment() {
	vec3 hc = hex_cell(v_wpos.xz / hex_size);
	vec2 cell = hc.xy;
	float edge_d = hc.z;

	// per-CELL signed progress: <0 gone, 0..band glowing front, >band solid
	float along = dot(v_wpos, normalize(dir));
	float s = (along - wave) * mode + (h11(cell) - 0.5) * scatter;
	if (s < 0.0) {
		discard;   // this cell has dissolved (OUT) or not yet formed (IN)
	}
	float solid = smoothstep(0.0, band, s);      // 1 = fully re-formed, 0 = at front
	float front = 1.0 - solid;                    // hot at the reconstruction front
	float hexline = 1.0 - smoothstep(0.05, 0.12, edge_d);   // glowing cell borders

	vec3 col = mix(base_color, edge_color, front * (0.45 + hexline * 0.55));
	ALBEDO = col;
	// the front blooms as bright hex wireframe -> reads as energy cells
	EMISSION = edge_color * front * (0.4 + hexline * 2.2);
}
