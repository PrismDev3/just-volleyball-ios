// FAKE BEAM OF LIGHT. A self-contained stylized light shaft -- a soft, translucent
// warm beam that reads on its OWN (no bloom needed), purely for the vibe. It
// billboards around its beam axis so it always faces the camera, has a soft
// cylindrical core (bright down the centre line, fading to the sides) and fades
// at both ends. Cheap: one alpha-blended quad per beam, no depth write so it
// never occludes anything. Drag the SunShaft nodes in the editor to place them.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 beam : source_color = vec4(1.0, 0.95, 0.78, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.45;

void vertex() {
	// billboard around the beam axis: the WIDTH runs sideways (perpendicular to
	// both the beam and the view) so the quad's face turns toward the camera.
	vec3 axis = normalize((MODEL_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 to_cam = INV_VIEW_MATRIX[3].xyz - origin;
	vec3 right = cross(axis, to_cam);
	right = length(right) > 0.0001 ? normalize(right) : vec3(1.0, 0.0, 0.0);
	vec3 world = origin + right * VERTEX.x + axis * VERTEX.y;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
}

void fragment() {
	// soft cylindrical core: brightest down the centre, fading out to the sides
	float core = 1.0 - abs(UV.x - 0.5) * 2.0;
	core = pow(smoothstep(0.0, 1.0, core), 1.6);
	// gentle fade at both ends of the beam
	float ends = smoothstep(0.0, 0.22, UV.y) * smoothstep(1.0, 0.55, UV.y);
	ALBEDO = beam.rgb;
	ALPHA = clamp(core * ends * intensity, 0.0, 1.0);
}
