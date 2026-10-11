@tool
extends EditorPlugin

const MyCustomGizmoPlugin = preload("gizmos/gizmo.gd")
var gizmo_plugin = MyCustomGizmoPlugin.new(self)

func _enter_tree():


	add_custom_type("GPUTrail3D", "GPUParticles3D", preload("GPUTrail3D.gd"), preload("bounce.svg"))

	add_node_3d_gizmo_plugin(gizmo_plugin)

func _exit_tree():


	remove_custom_type("GPUTrail3D")

	remove_node_3d_gizmo_plugin(gizmo_plugin)
