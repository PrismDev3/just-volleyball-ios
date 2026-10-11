@tool
extends MeshInstance3D











var _t: = 0.0

func _process(delta: float) -> void :
	_t += delta
	var m: = material_override as ShaderMaterial
	if m != null:
		m.set_shader_parameter("wave_time", _t)
