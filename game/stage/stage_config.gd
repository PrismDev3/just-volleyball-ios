@tool
class_name StageConfig
extends StageLook



















@export_group("Net & court colors")
@export var pad: = Color(0.2, 0.36, 0.82)
@export var pole: = Color(0.78, 0.8, 0.85)
@export var tape: = Color(0.97, 0.97, 0.95)
@export var cord: = Color(0.0, 0.0, 0.0)
@export var lines: = Color(0.95, 0.95, 0.95)
@export var floor_color: = Color(0.85, 0.5, 0.25)

@export_group("Surface & feel")
@export var barefoot: = false
@export var casual: = false
@export var reflect: = true
@export var owns_floor: = false
@export var hand_painted: = false
@export_enum("court", "sand", "grass") var surface: = "court"



@export_subgroup("Deformable sand")




@export_range(0.0, 0.6) var sand_depth: = 0.05
@export_range(0.0, 3.0) var sand_relief: = 1.15
@export_range(0.0, 4.0) var sand_bump: = 2.0
@export_range(8, 400) var sand_tess: = 200
@export_range(0.0, 0.2) var sand_lift: = 0.05
@export_range(0.0, 0.15) var sand_dune_amp: = 0.035
@export_range(0.2, 4.0) var sand_dune_scale: = 0.5

@export_group("Environment")
@export var anime_sky: = false


@export var sky_shader: Shader = null
@export var bloom: = false
@export var use_sky_color: = false
@export var sky_color: = Color(0.5, 0.74, 0.95)
@export_range(0.0, 3.0) var sun: = 1.0

@export_group("School accent")


@export var accents: Array[Color] = []
@export var accent_mats: Array[String] = []
@export var wall_mats: Array[String] = []
@export_range(0.0, 1.0) var wall_wash: = 0.11
@export var tape_by_accent: Array[Color] = []





@export_group("Recolours")
@export var recolors: Dictionary = {}



@export var emissive_mats: Dictionary = {}





@export_group("Collision")




@export var collision_box: = Vector3.ZERO






@export_group("Backdrop")
@export var backdrop: Dictionary = {}

@export_group("Crowd")
@export var seat_mats: Array[String] = []



@export var crowd_spacing: = 0.0
@export var crowd_max: = 0
@export_range(0.0, 1.0) var crowd_fill: = 0.0



@export var crowd_lift: = 0.15


@export var crowd_push: = 0.0


@export var crowd_tint: = Color(1, 1, 1)
