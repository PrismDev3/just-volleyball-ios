shader_type spatial;
// depth TEST stays on: a body standing in this marker occludes it. See the
// header of floor_ring_core.gdshaderinc for why that matters.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled,
	shadows_disabled;

// core rev 3: dive-cooldown arc is now a bottom half only (see the .gdshaderinc).
// Bump this comment whenever the include changes -- Godot's shader disk cache
// keys on THIS file's hash and not its includes, so an unchanged .gdshader keeps
// serving the old compile no matter what the include says.
#include "res://game/fx/floor_ring_core.gdshaderinc"

void fragment() {
	vec4 c = floor_ring_sample(UV);
	ALBEDO = c.rgb;
	ALPHA = c.a;
}
