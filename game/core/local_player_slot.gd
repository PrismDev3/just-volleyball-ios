class_name LocalPlayerSlot
extends RefCounted





var device: = DeviceInput.MERGED
var profile: SavedProfile = null
var is_temp: = false
var team_side: = 0
var collector: InputCollector = null



func make_collector() -> InputCollector:
	collector = InputCollector.new()
	collector.set_device(device)
	return collector

func display_name() -> String:
	if profile != null:
		return profile.name
	return "Guest"
