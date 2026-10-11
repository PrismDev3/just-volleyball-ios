#[compute]
#version 450


layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(push_constant, std430) uniform Params
{
    vec2 raster_size;
    float thickness;
    float pad_a;
    vec4 ink;
} params;

layout(set = 0, binding = 3) uniform sampler2D mask_tex;
layout(set = 0, binding = 4) uniform sampler2D acc_mask_tex;
layout(set = 0, binding = 0, rgba16f) uniform restrict image2D color_image;

float mask_at(vec2 uv)
{
    return textureLod(mask_tex, uv, 0.0).w;
}

float acc_at(vec2 uv)
{
    vec3 c = textureLod(acc_mask_tex, uv, 0.0).xyz;
    bool _44 = c.y > 0.85000002384185791015625;
    bool _52;
    if (_44)
    {
        _52 = c.x < 0.1500000059604644775390625;
    }
    else
    {
        _52 = _44;
    }
    bool _59;
    if (_52)
    {
        _59 = c.z < 0.1500000059604644775390625;
    }
    else
    {
        _59 = _52;
    }
    return float(_59);
}

void main()
{
    ivec2 px = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = ivec2(params.raster_size);
    bool _89 = px.x >= size.x;
    bool _98;
    if (!_89)
    {
        _98 = px.y >= size.y;
    }
    else
    {
        _98 = _89;
    }
    if (_98)
    {
        return;
    }
    vec2 texel = vec2(1.0) / params.raster_size;
    vec2 uv = (vec2(px) + vec2(0.5)) * texel;
    vec2 off = texel * params.thickness;
    vec2 uv_l = uv - vec2(off.x, 0.0);
    vec2 uv_r = uv + vec2(off.x, 0.0);
    vec2 uv_u = uv - vec2(0.0, off.y);
    vec2 uv_d = uv + vec2(0.0, off.y);
    vec2 uv_ul = uv + vec2(-off.x, -off.y);
    vec2 uv_ur = uv + vec2(off.x, -off.y);
    vec2 uv_dl = uv + vec2(-off.x, off.y);
    vec2 uv_dr = uv + vec2(off.x, off.y);
    vec2 param = uv;
    float m = mask_at(param);
    vec2 param_1 = uv_l;
    vec2 param_2 = uv_r;
    vec2 param_3 = uv_u;
    vec2 param_4 = uv_d;
    vec2 param_5 = uv_ul;
    vec2 param_6 = uv_ur;
    vec2 param_7 = uv_dl;
    vec2 param_8 = uv_dr;
    float m_around = max(max(max(mask_at(param_1), mask_at(param_2)), max(mask_at(param_3), mask_at(param_4))), max(max(mask_at(param_5), mask_at(param_6)), max(mask_at(param_7), mask_at(param_8))));
    vec2 core = texel * 2.0;
    vec2 param_9 = uv;
    float a = acc_at(param_9);
    vec2 param_10 = uv_l;
    vec2 param_11 = uv_r;
    vec2 param_12 = uv_u;
    vec2 param_13 = uv_d;
    vec2 param_14 = uv_ul;
    vec2 param_15 = uv_ur;
    vec2 param_16 = uv_dl;
    vec2 param_17 = uv_dr;
    float a_around = max(max(max(acc_at(param_10), acc_at(param_11)), max(acc_at(param_12), acc_at(param_13))), max(max(acc_at(param_14), acc_at(param_15)), max(acc_at(param_16), acc_at(param_17))));
    vec2 param_18 = uv - vec2(core.x, 0.0);
    vec2 param_19 = uv + vec2(core.x, 0.0);
    vec2 param_20 = uv - vec2(0.0, core.y);
    vec2 param_21 = uv + vec2(0.0, core.y);
    float acc_core = max(max(abs(acc_at(param_18) - a), abs(acc_at(param_19) - a)), max(abs(acc_at(param_20) - a), abs(acc_at(param_21) - a)));
    float acc_sil = max((1.0 - a) * a_around, acc_core);
    float sil = ((1.0 - step(0.64999997615814208984375, m)) * m_around) * (1.0 - a);
    float near_char = max(max(max(m, a), m_around), a_around);
    if (near_char < 0.00999999977648258209228515625)
    {
        return;
    }
    float edge = max(sil, acc_sil) * params.ink.w;
    if (edge < 0.0040000001899898052215576171875)
    {
        return;
    }
    vec4 col = imageLoad(color_image, px);
    vec4 _355 = col;
    vec3 _364 = mix(_355.xyz, params.ink.xyz, vec3(clamp(edge, 0.0, 1.0)));
    col.x = _364.x;
    col.y = _364.y;
    col.z = _364.z;
    imageStore(color_image, px, col);
}


