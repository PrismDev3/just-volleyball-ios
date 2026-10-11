@tool
class_name StageLook
extends Resource







@export var key_dir: = Vector3(0.4, 0.75, 0.5)
@export_range(0.0, 1.0) var ambient: = 0.62
@export var sky_tint: = Color(1.0, 0.96, 0.85)
@export var floor_warm: = Color(1.0, 0.74, 0.5)
@export_range(0.0, 1.0) var floor_warm_amt: = 0.44
@export_range(0.0, 2.0) var saturation: = 1.12
@export_range(0.0, 2.0) var exposure: = 1.04
@export_range(0.0, 1.0) var haze_amt: = 0.24


@export var haze_color: = Color(0.83, 0.87, 0.93)


@export var warm_tint: = Color(1.0, 0.985, 0.95)




@export_group("Shine")
@export_range(0.0, 1.0) var rim: = 0.2
@export_range(0.0, 1.0) var floor_reflect: = 0.16
@export_range(0.0, 2.0) var spec_floor: = 0.6
@export_range(0.0, 2.0) var spec_wall: = 0.14



@export_group("Wall detail")
@export_range(0.0, 1.0) var wall_detail: = 0.0






@export_group("Palette")
@export_range(0.0, 1.0) var ceiling_neutral: = 0.0
@export var ceiling_tint: = Color(0.9, 0.88, 0.85)
@export_range(0.0, 1.0) var shade_cool: = 0.0
@export var shade_tint: = Color(0.8, 0.85, 1.0)
@export var ground_tint: = Color(0.68, 0.62, 0.58)


@export_range(0.0, 1.0) var tex_desat: = 0.0






@export_group("Gradients")
@export_range(0.0, 1.0) var key: = 0.55
@export_range(0.0, 1.0) var height_shade: = 0.34

@export var ceiling_y: = 10.5
@export_range(0.0, 1.5) var pool_strength: = 0.42
@export var pool_radius: = 15.0
@export_range(0.0, 1.0) var floor_vignette: = 0.46


@export_range(0.0, 1.0) var focus_dim: = 0.0
@export_range(0.5, 2.0) var contrast: = 1.0


func apply(painted: Dictionary) -> void :
	for mats in painted.values():
		for m in mats:
			var sm: = m as ShaderMaterial
			if sm == null:
				continue
			sm.set_shader_parameter("key_dir", key_dir)
			sm.set_shader_parameter("ambient", ambient)
			sm.set_shader_parameter("sky_tint", sky_tint)
			sm.set_shader_parameter("floor_warm", floor_warm)
			sm.set_shader_parameter("floor_warm_amt", floor_warm_amt)
			sm.set_shader_parameter("saturation", saturation)
			sm.set_shader_parameter("exposure", exposure)
			sm.set_shader_parameter("haze_amt", haze_amt)
			sm.set_shader_parameter("haze_color", haze_color)
			sm.set_shader_parameter("warm_tint", warm_tint)
			sm.set_shader_parameter("rim", rim)
			sm.set_shader_parameter("floor_reflect", floor_reflect)
			sm.set_shader_parameter("spec_floor", spec_floor)
			sm.set_shader_parameter("spec_wall", spec_wall)
			sm.set_shader_parameter("detail_amt", wall_detail)
			sm.set_shader_parameter("ceiling_neutral", ceiling_neutral)
			sm.set_shader_parameter("ceiling_tint", ceiling_tint)
			sm.set_shader_parameter("shade_cool", shade_cool)
			sm.set_shader_parameter("shade_tint", shade_tint)
			sm.set_shader_parameter("ground_tint", ground_tint)
			sm.set_shader_parameter("tex_desat", tex_desat)
			sm.set_shader_parameter("key", key)
			sm.set_shader_parameter("height_shade", height_shade)
			sm.set_shader_parameter("ceiling_y", ceiling_y)
			sm.set_shader_parameter("pool_strength", pool_strength)
			sm.set_shader_parameter("pool_radius", pool_radius)
			sm.set_shader_parameter("floor_vignette", floor_vignette)
			sm.set_shader_parameter("focus_dim", focus_dim)
			sm.set_shader_parameter("contrast", contrast)
