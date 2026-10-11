@tool
@icon("bounce.svg")
class_name GPUTrail3D extends GPUParticles3D




















@export var length: int = 100: set = _set_length
@export var length_seconds: float: set = _set_length

@export_category("Color / Texture")





@export var texture: Texture: set = _set_texture


@export var mask: Texture: set = _set_mask


@export var mask_strength: float = 1.0: set = _set_mask_strength


@export var scroll: Vector2: set = _set_scroll


@export var color_ramp: GradientTexture1D: set = _set_color_ramp


@export var curve: CurveTexture: set = _set_curve


@export var vertical_texture: = false: set = _set_vertical_texture


@export var use_red_as_alpha: = false: set = _set_use_red_as_alpha


@export_category("Mesh tweaks")


@export var billboard: = false: set = _set_billboard


@export var dewiggle: = true: set = _set_dewiggle


@export var clip_overlaps: = true: set = _set_clip_overlaps



@export var snap_to_transform: = false: set = _set_snap_to_transform




const _DEFAULT_TEXTURE = "defaults/texture.tres"
const _DEFAULT_CURVE = "defaults/curve.tres"

var _defaults_have_been_set = false
func _get_property_list():
	return [{"name": "_defaults_have_been_set", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_NO_EDITOR}]

func _ready():
	if not _defaults_have_been_set:
		_defaults_have_been_set = true


		amount = length
		lifetime = length
		explosiveness = 1


		fixed_fps = int(DisplayServer.screen_get_refresh_rate(DisplayServer.MAIN_WINDOW_ID))

		if DisplayServer.screen_get_refresh_rate(DisplayServer.MAIN_WINDOW_ID) < 0.0:
			push_warning("couldn't find refresh rate, using fixed_fps = 60")
			fixed_fps = 60

		process_material = ShaderMaterial.new()
		process_material.shader = preload("shaders/trail.gdshader")

		draw_pass_1 = QuadMesh.new()
		draw_pass_1.material = ShaderMaterial.new()
		draw_pass_1.material.shader = preload("shaders/trail_draw_pass.gdshader")

		color_ramp = preload(_DEFAULT_TEXTURE).duplicate(true)
		curve = preload(_DEFAULT_CURVE).duplicate(true)

		draw_pass_1.material.resource_local_to_scene = true

	length = length
	vertical_texture = vertical_texture
	use_red_as_alpha = use_red_as_alpha
	billboard = billboard
	dewiggle = dewiggle
	clip_overlaps = clip_overlaps
	snap_to_transform = snap_to_transform

func _set_length(value):
	if value is int:
		length = value
		length = max(length, 1)
		length_seconds = float(length) / get_fixed_fps()
	elif value is float:
		length = int(value * get_fixed_fps())
		length = max(length, 1)
		length_seconds = float(length) / get_fixed_fps()

	if _defaults_have_been_set:
		amount = length
		lifetime = length

	restart()

func _set_texture(value):
	texture = value
	_uv_offset = Vector2(0, 0)
	if value:
		draw_pass_1.material.set_shader_parameter("tex", texture)
	else:
		draw_pass_1.material.set_shader_parameter("tex", preload(_DEFAULT_TEXTURE))
func _set_mask(value):
	mask = value
	if value:
		draw_pass_1.material.set_shader_parameter("mask", mask)
	else:
		draw_pass_1.material.set_shader_parameter("mask", null)
func _set_mask_strength(value):
	mask_strength = clamp(value, 0.0, 1.0)
	if value:
		draw_pass_1.material.set_shader_parameter("mask_strength", mask_strength)
	else:
		draw_pass_1.material.set_shader_parameter("mask_strength", 1.0)
func _set_scroll(value):
	scroll = value
func _set_color_ramp(value):
	color_ramp = value
	draw_pass_1.material.set_shader_parameter("color_ramp", color_ramp)
func _set_curve(value):
	curve = value
	if value:
		draw_pass_1.material.set_shader_parameter("curve", curve)
	else:
		draw_pass_1.material.set_shader_parameter("curve", preload(_DEFAULT_CURVE))
func _set_vertical_texture(value):
	vertical_texture = value
	_flags = _set_flag(_flags, 0, value)
	draw_pass_1.material.set_shader_parameter("flags", _flags)
func _set_use_red_as_alpha(value):
	use_red_as_alpha = value
	_flags = _set_flag(_flags, 1, value)
	draw_pass_1.material.set_shader_parameter("flags", _flags)
func _set_billboard(value):
	billboard = value
	_flags = _set_flag(_flags, 2, value)
	draw_pass_1.material.set_shader_parameter("flags", _flags)
	if value && _defaults_have_been_set:
		_update_billboard_transform(global_transform.basis[0])

	restart()
func _set_dewiggle(value):
	dewiggle = value
	_flags = _set_flag(_flags, 3, value)
	draw_pass_1.material.set_shader_parameter("flags", _flags)
func _set_snap_to_transform(value):
	snap_to_transform = value
	_flags = _set_flag(_flags, 4, value)
	draw_pass_1.material.set_shader_parameter("flags", _flags)
func _set_clip_overlaps(value):
	clip_overlaps = value
	_flags = _set_flag(_flags, 5, value)
	draw_pass_1.material.set_shader_parameter("flags", _flags)


@onready var _old_pos: Vector3 = global_position
@onready var _billboard_transform: Transform3D = global_transform
var _uv_offset: Vector2
func _process(delta):
	if (snap_to_transform):
		draw_pass_1.material.set_shader_parameter("emmission_transform", global_transform)


	_uv_offset += scroll * delta
	_uv_offset = _uv_offset.posmod(1.0)
	draw_pass_1.material.set_shader_parameter("uv_offset", _uv_offset)

	await RenderingServer.frame_pre_draw




	if not is_inside_tree():
		return

	if (billboard):
		var delta_position = global_position - _old_pos

		if delta_position:
			var tangent = global_transform.basis[1].length() * (delta_position).normalized()
			_update_billboard_transform(tangent)

		RenderingServer.instance_set_transform(get_instance(), _billboard_transform)

	_old_pos = global_position

func _update_billboard_transform(tangent: Vector3):
	_billboard_transform = global_transform

	var p: Vector3 = _billboard_transform.basis[1]
	var x: Vector3 = tangent
	var angle: float = p.angle_to(x)
	var rotation_axis: Vector3 = p.cross(x).normalized()
	if rotation_axis != Vector3():
		_billboard_transform.basis = _billboard_transform.basis.rotated(rotation_axis, angle)

	_billboard_transform.basis = _billboard_transform.basis.scaled(Vector3(0.5, 0.5, 0.5))
	_billboard_transform.origin += _billboard_transform.basis[1]

var _flags = 0
func _set_flag(i, idx: int, value: bool):
	return (i & ~ (1 << idx)) | (int(value) << idx)
