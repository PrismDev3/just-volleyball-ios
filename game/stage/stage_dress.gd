@tool
class_name StageDress
extends Node3D














const EnvPaintScript: = preload("res://game/court/env_paint.gd")
const CrowdScript: = preload("res://game/court/gym_crowd.gd")
const SKY_SHADER: = preload("res://game/court/anime_sky.gdshader")

@export var venue_path: NodePath = ^"../Gym"



@export var look: StageLook

@export_group("Accent (venue material names)")
@export var accent_mats: Array[String] = ["Blue", "Material"]
@export var wall_mats: Array[String] = ["White", "Gray", "Hallway floor"]

@export_group("Preview (editor only)")
@export var preview_crowd: = false: set = _set_preview_crowd
@export var preview_accent: = Color(0.14, 0.3, 0.68)


@export var preview_sky: = true: set = _set_preview_sky

var _preview_env: WorldEnvironment = null


var painted: = {}
var _crowd_seed: = 0

func _ready() -> void :



	if Engine.is_editor_hint():
		_dress()


func _dress() -> void :
	var venue: = get_node_or_null(venue_path)
	if venue == null:
		return

	for n in venue.find_children("*", "MeshInstance3D", true, false):
		if String(n.name).to_lower().contains("cutter"):
			(n as Node3D).visible = false
	painted = EnvPaintScript.apply(venue)
	push_params()
	if Engine.is_editor_hint():
		apply_accent(preview_accent)
		_refresh_crowd()
		_refresh_sky()



func push_params() -> void :
	if look != null:
		look.apply(painted)
		_apply_recolors()





func _apply_recolors() -> void :
	if look == null:
		return
	var recolors = look.get("recolors")
	if not (recolors is Dictionary):
		return
	for mname in recolors:
		for m in painted.get(mname, []):
			var sm: = m as ShaderMaterial
			sm.set_shader_parameter("albedo", recolors[mname])
			sm.set_shader_parameter("use_tex", false)



func apply_accent(accent: Color) -> void :
	for mname in accent_mats:
		for m in painted.get(mname, []):
			(m as ShaderMaterial).set_shader_parameter("albedo", accent)
	for mname in wall_mats:
		for m in painted.get(mname, []):
			var cur: Color = (m as ShaderMaterial).get_shader_parameter("albedo")
			(m as ShaderMaterial).set_shader_parameter("albedo", cur.lerp(accent, 0.11))

func _process(_dt: float) -> void :
	if Engine.is_editor_hint():
		push_params()

func _set_preview_crowd(v: bool) -> void :
	preview_crowd = v
	if Engine.is_editor_hint() and is_inside_tree():
		_refresh_crowd()

func _refresh_crowd() -> void :
	var venue: = get_node_or_null(venue_path)
	if venue == null:
		return
	for c in venue.find_children("*", "CrowdField", true, false):
		c.free()
	if preview_crowd:
		CrowdScript.fill(venue, _crowd_seed)

func _set_preview_sky(v: bool) -> void :
	preview_sky = v
	if Engine.is_editor_hint() and is_inside_tree():
		_refresh_sky()

func _refresh_sky() -> void :




	if not is_instance_valid(_preview_env):
		_preview_env = WorldEnvironment.new()
		add_child(_preview_env)
	var env: = Environment.new()
	if preview_sky:
		env.background_mode = Environment.BG_SKY
		var sky: = Sky.new()
		var sm: = ShaderMaterial.new()
		sm.shader = SKY_SHADER
		sky.sky_material = sm
		env.sky = sky
	else:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.62, 0.62, 0.64)
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_strength = 0.9
	env.glow_bloom = 0.08
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.glow_hdr_threshold = 1.0
	_preview_env.environment = env
