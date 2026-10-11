shader_type canvas_item;

// pixelates the text texture into blocks and lets them burst outward
// pixel_size shrinks to resolve the text then scatter throws the blocks
// away from the center while each one winks out at its own moment

uniform float pixel_size : hint_range(1.0, 128.0) = 1.0;
uniform float scatter : hint_range(0.0, 1.5) = 0.0;
uniform float tint_white : hint_range(0.0, 1.0) = 0.0;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;

vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.103, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

void fragment() {
	vec2 ts = vec2(textureSize(TEXTURE, 0));
	vec2 px = UV * ts;
	float bs = max(pixel_size, 1.0);
	vec2 block = floor(px / bs);
	vec2 rnd = hash22(block);
	// blocks fly away from the texture center with a per block kick
	vec2 center = ts * 0.5;
	vec2 block_center = (block + 0.5) * bs;
	vec2 dir = normalize(block_center - center + (rnd - 0.5) * bs * 2.0 + vec2(0.001));
	vec2 offset = dir * scatter * scatter * (0.35 + rnd.x * 0.65) * ts.y * 1.2;
	// sampling behind the offset makes the content appear to move outward
	vec2 src_px = px - offset;
	// requantize the source so the moved chunks stay blocky while pixelated
	vec2 src_block_px = (floor(src_px / bs) + 0.5) * bs;
	vec2 src_sel = mix(src_block_px, src_px, step(bs, 1.5));
	vec2 src_uv = src_sel / ts;
	vec4 col = texture(TEXTURE, src_uv);
	// reads past the texture edge are empty space not smeared border pixels
	if (any(lessThan(src_uv, vec2(0.0))) || any(greaterThan(src_uv, vec2(1.0)))) {
		col = vec4(0.0);
	}
	col.rgb = mix(col.rgb, vec3(1.0), tint_white);
	// while chunky, harden soft edge alpha so blocks read solid not misty
	if (bs > 1.5) {
		col.a = smoothstep(0.12, 0.55, col.a);
	}
	// each block dies at a random point through the burst — every curve must
	// finish inside scatter 1.0 or stray blocks linger forever
	float die = smoothstep(rnd.y * 0.35 + 0.15, rnd.y * 0.35 + 0.55, scatter);
	col.a *= alpha * (1.0 - die);
	COLOR = col;
}
