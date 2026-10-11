// cartoon smoke puff: a billboarded white CLOUD with rounded lobes (a scalloped
// "poof"), not a plain disc. clusters of these read as classic platformer dust.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 tint : source_color = vec4(0.96, 0.97, 1.0, 0.85);
uniform float rot = 0.0;          // per-instance spin so stacked puffs don't align
uniform float lobes = 7.0;        // number of rounded bumps around the rim

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
	vec2 p = (UV - vec2(0.5)) * 2.0;           // -1..1
	float r = length(p);
	float a;
	if (lobes < 0.5) {
		// plain disc: the burst SHARDS share this shader and want a circle
		a = 1.0 - smoothstep(0.82, 1.0, r);
	} else {
		// cloud: the rim radius swells into fat, wide, rounded bumps with narrow
		// shallow dimples between them -- a plump poof, not a spiky star. pow()
		// on the raised cosine widens and rounds the peaks so the valleys become
		// small notches instead of deep points.
		float ang = atan(p.y, p.x) + rot;
		float c = 0.5 + 0.5 * cos(ang * lobes);   // 0 (dimple) .. 1 (bump)
		c = pow(c, 0.5);                            // fatten + round the bumps
		float edge = 0.62 + 0.13 * c;              // shallow dimples -> puffy, not spiky
		a = 1.0 - smoothstep(edge - 0.12, edge, r);   // wide soft rim = fluffy
	}
	ALBEDO = tint.rgb;
	ALPHA = a * tint.a;
}
