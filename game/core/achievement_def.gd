class_name AchievementDef
extends RefCounted

















var id: = ""
var title: = ""
var desc: = ""
var kind: = "global"
var event: = ""
var target: = 1
var coins: = 0
var steam: = ""
var filter: = Callable()
var unit: = ""

func _init(id_in: String, title_in: String, desc_in: String, kind_in: String, 
		event_in: String, target_in: = 1, coins_in: = 0, steam_in: = "", 
		filter_in: = Callable()) -> void :
	id = id_in
	title = title_in
	desc = desc_in
	kind = kind_in
	event = event_in
	target = maxi(1, target_in)
	coins = coins_in
	steam = steam_in
	filter = filter_in


func progress_text(value: int) -> String:
	if unit == "sec":
		return "%dm / %dm" % [value / 60, target / 60]
	return "%d / %d" % [value, target]

func counts(data: Dictionary) -> bool:
	if not filter.is_valid():
		return true
	var r: Variant = filter.call(data)
	return r is bool and r
