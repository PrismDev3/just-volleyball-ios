class_name AppData
extends RefCounted








static var DIR: = "user://data"
const REAL_DIR: = "user://data"
const DEV_DIR: = "user://data_dev"
const CACHE: = "user://cache"
const MANIFEST: = "manifest.json"


const SAVE_VERSION: = 1


const WIPE_ID: = "beta1"




static var did_wipe: = false



const WIPE_FILES: = ["profiles.json", "character.json", "character_slots.json"]
const LEGACY_CAREER: = "user://career.cfg"


const JUNK: = ["probe_ready.png", "probe_reticle.png", "probe_taken.png", 
	"sand_test_out.png", 
	"portrait_full.png", "portrait_upper.png", "portrait_head.png"]

static func ensure() -> void :
	DirAccess.make_dir_recursive_absolute(DIR)
	DirAccess.make_dir_recursive_absolute(CACHE)

static func path(name: String) -> String:
	return "%s/%s" % [DIR, name]

static func cache_path(name: String) -> String:
	return "%s/%s" % [CACHE, name]




static func migrate(old_path: String, name: String) -> String:
	ensure()
	var new_path: = path(name)
	if not FileAccess.file_exists(new_path) and FileAccess.file_exists(old_path):
		DirAccess.rename_absolute(old_path, new_path)
	return new_path


static func cache_migrate(old_path: String, name: String) -> String:
	ensure()
	var new_path: = cache_path(name)
	DirAccess.make_dir_recursive_absolute(new_path.get_base_dir())
	if not FileAccess.file_exists(new_path) and FileAccess.file_exists(old_path):
		DirAccess.rename_absolute(old_path, new_path)
	return new_path



static func init_appdata() -> void :
	_sandbox_for_harness()
	ensure()
	_cleanup_junk()


	cache_migrate("user://crowd_fan_array.res", "crowd_fan_array.res")
	_check_wipe()







static func is_harness() -> bool:
	if not OS.get_cmdline_user_args().is_empty():
		return true
	for a in OS.get_cmdline_args():
		var s: = String(a).replace("\\", "/")
		if s.contains("game/dev/") or s == "--script" or s == "-s":
			return true
	return false

static func _sandbox_for_harness() -> void :
	if not is_harness():
		return
	DIR = DEV_DIR
	_remove_dir_recursive(DEV_DIR)
	DirAccess.make_dir_recursive_absolute(DEV_DIR)
	var d: = DirAccess.open(REAL_DIR)
	if d == null:
		return
	d.list_dir_begin()
	var name: = d.get_next()
	while name != "":
		if not d.current_is_dir():
			DirAccess.copy_absolute(REAL_DIR + "/" + name, DEV_DIR + "/" + name)
		name = d.get_next()
	d.list_dir_end()



static func _cleanup_junk() -> void :
	for j in JUNK:
		if FileAccess.file_exists("user://" + j):
			DirAccess.remove_absolute("user://" + j)
	_remove_dir_recursive("user://chat")

static func _check_wipe() -> void :
	var stored: = ""
	var mpath: = path(MANIFEST)
	if FileAccess.file_exists(mpath):
		var f: = FileAccess.open(mpath, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			f.close()
			if parsed is Dictionary:
				stored = str((parsed as Dictionary).get("wipe_id", ""))
	if stored == WIPE_ID:
		return



	if stored != "":
		_wipe_saved_data()
		did_wipe = true
	_write_manifest()

static func _write_manifest() -> void :
	ensure()
	var f: = FileAccess.open(path(MANIFEST), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(
			{"save_version": SAVE_VERSION, "wipe_id": WIPE_ID}, "\t"))
		f.close()

static func _wipe_saved_data() -> void :
	for name in WIPE_FILES:
		DirAccess.remove_absolute(path(name))
		DirAccess.remove_absolute("user://" + name)
	DirAccess.remove_absolute(LEGACY_CAREER)
	push_warning("save data reset for new build id")

static func _remove_dir_recursive(dir_path: String) -> void :
	var d: = DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var name: = d.get_next()
	while name != "":
		var full: = dir_path + "/" + name
		if d.current_is_dir():
			_remove_dir_recursive(full)
		else:
			DirAccess.remove_absolute(full)
		name = d.get_next()
	d.list_dir_end()
	DirAccess.remove_absolute(dir_path)
