class_name DrillProgress
extends RefCounted

const VERSION: = 1

var records: Dictionary = {}
var _path: = ""

func _data_path() -> String:
	if _path == "":
		_path = AppData.migrate("user://drills.json", "drills.json")
	return _path

func load_local() -> void :
	records = {}
	if not FileAccess.file_exists(_data_path()):
		return
	var file: = FileAccess.open(_data_path(), FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	var saved: Variant = data.get("drills", {})
	if typeof(saved) == TYPE_DICTIONARY:
		records = (saved as Dictionary).duplicate(true)

func record_attempt(id: String) -> void :
	var row: Dictionary = records.get(id, {})
	row["attempts"] = int(row.get("attempts", 0)) + 1
	records[id] = row
	_save()

func record_complete(id: String, elapsed_ms: int) -> void :
	var row: Dictionary = records.get(id, {})
	row["complete"] = true
	var old: = int(row.get("best_ms", 0))
	if elapsed_ms > 0 and (old <= 0 or elapsed_ms < old):
		row["best_ms"] = elapsed_ms
	records[id] = row
	_save()

func row(id: String) -> Dictionary:
	return records.get(id, {})

func _save() -> void :
	var tmp: = _data_path() + ".tmp"
	var file: = FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"version": VERSION, "drills": records}, "\t"))
	file.close()
	var tmp_abs: = ProjectSettings.globalize_path(tmp)
	var path_abs: = ProjectSettings.globalize_path(_data_path())
	if FileAccess.file_exists(_data_path()):
		DirAccess.remove_absolute(path_abs)
	DirAccess.rename_absolute(tmp_abs, path_abs)
