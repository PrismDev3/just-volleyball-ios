class_name CrowdField
extends MultiMeshInstance3D







static var _active: CrowdField = null

var _mat: ShaderMaterial = null
var _elapsed: = 999.0
var _live: = false

func bind(mat: ShaderMaterial) -> void :
	_mat = mat
	_active = self
	set_process(true)

func _process(delta: float) -> void :
	if not _live or _mat == null:
		return
	_elapsed += delta
	_mat.set_shader_parameter("cheer_elapsed", _elapsed)

	if _elapsed > 4.0:
		_live = false
		_mat.set_shader_parameter("cheer_intensity", 0.0)

func _exit_tree() -> void :
	if _active == self:
		_active = null

func _pulse(intensity: float) -> void :
	if _mat == null:
		return
	_elapsed = 0.0
	_live = true
	_mat.set_shader_parameter("cheer_elapsed", 0.0)
	_mat.set_shader_parameter("cheer_intensity", clampf(intensity, 0.0, 1.0))


static func cheer(intensity: float) -> void :
	if _active != null:
		_active._pulse(intensity)
