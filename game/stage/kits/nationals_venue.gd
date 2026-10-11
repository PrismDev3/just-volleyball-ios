@tool
extends Node3D











const DARK: = Color(0.04, 0.045, 0.055)
const FRAME: = Color(0.12, 0.45, 0.24)

func _ready() -> void :
	_dress_background()
	_dress_banners()



func _dress_background() -> void :
	var bg: = find_child("Background", true, false)
	if bg == null:
		return
	for n in bg.find_children("*", "", true, false):
		var low: = String(n.name).to_lower()
		if n is Light3D or low.contains("probe") or low.contains("demo")\
		or low.contains("volleyball") or low.contains("reflection"):
			if n is Node3D:
				(n as Node3D).visible = false
			continue
		var mi: = n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue


		for s in mi.mesh.get_surface_count():
			var m: = mi.mesh.surface_get_material(s)
			if m is StandardMaterial3D:
				var sm: = m as StandardMaterial3D
				sm.albedo_color = DARK
				sm.emission_enabled = false




func _dress_banners() -> void :
	var banners: = find_child("Banners", true, false)
	if banners == null:
		return
	for n in banners.find_children("*", "MeshInstance3D", true, false):
		var mi: = n as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var m: = mi.mesh.surface_get_material(s)
			if m is StandardMaterial3D and m.resource_name == "RedMetalShader":
				(m as StandardMaterial3D).albedo_color = FRAME
