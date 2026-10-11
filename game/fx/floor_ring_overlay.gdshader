shader_type spatial;
// depth test OFF -- the aim reticle only. It regularly sits past the net or
// under a jumping player, and a reticle you cannot see is worse than none.
// Do NOT use this for a marker that lies under a body; see the header of
// floor_ring_core.gdshaderinc.
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled,
	cull_disabled, shadows_disabled;

// core rev 3 (arc is a bottom half now) -- bump to bust the shader disk cache,
// which keys on this file and not its includes. The reticle never sets
// `progress`, so its default of -1 keeps the arc off here.
#include "res://game/fx/floor_ring_core.gdshaderinc"

void fragment() {
	vec4 c = floor_ring_sample(UV);
	ALBEDO = c.rgb;
	ALPHA = c.a;
}
