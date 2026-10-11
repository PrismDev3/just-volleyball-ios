extends Node















signal changed

const FILE: = "profiles.json"
const PROFILE_MAX: = 12
const FORMAT: = 1

var profiles: Array[SavedProfile] = []
var active_index: = 0









var seeded_fresh: = false
var recently_deleted: Array[SavedProfile] = []
const DELETED_MAX: = 10

const LEGACY_CAREER: = "user://career.cfg"

func _ready() -> void :
	_load()
	_migrate_legacy_career()
	_migrate_legacy_character()




	var p: = active()
	if p != null:
		_apply_profile(p)


	if GameConfig.has_signal("settings_saved"):
		GameConfig.settings_saved.connect(_on_settings_saved)

func active() -> SavedProfile:
	if profiles.is_empty():
		return null
	active_index = clampi(active_index, 0, profiles.size() - 1)
	return profiles[active_index]



func create_profile(display_name: String) -> SavedProfile:
	if profiles.size() >= PROFILE_MAX:
		return null
	var p: = SavedProfile.new()
	p.set_name(display_name)
	p.character = CharacterConfig.random().to_dict()
	profiles.append(p)
	_save()
	changed.emit()
	return p

func switch_to(index: int) -> void :
	if index < 0 or index >= profiles.size() or index == active_index:
		return
	active_index = index
	var p: = active()
	if p != null:
		_apply_profile(p)
	_save()
	changed.emit()

func rename_profile(index: int, display_name: String) -> void :
	if index < 0 or index >= profiles.size():
		return
	profiles[index].set_name(display_name)
	_save()
	changed.emit()

func delete_profile(index: int) -> void :



	if index <= 0 or index >= profiles.size() or profiles.size() <= 1:
		return

	var gone: = profiles[index]
	profiles.remove_at(index)
	recently_deleted.push_front(gone)
	while recently_deleted.size() > DELETED_MAX:
		recently_deleted.pop_back()
	if active_index >= profiles.size():
		active_index = profiles.size() - 1
	var p: = active()
	if p != null:
		_apply_profile(p)
	_save()
	changed.emit()


func restore_profile(deleted_index: int) -> void :
	if deleted_index < 0 or deleted_index >= recently_deleted.size():
		return
	if profiles.size() >= PROFILE_MAX:
		return
	var p: SavedProfile = recently_deleted[deleted_index]
	recently_deleted.remove_at(deleted_index)
	profiles.append(p)
	_save()
	changed.emit()


func purge_deleted(deleted_index: int) -> void :
	if deleted_index < 0 or deleted_index >= recently_deleted.size():
		return
	recently_deleted.remove_at(deleted_index)
	_save()
	changed.emit()

func purge_all_deleted() -> void :
	if recently_deleted.is_empty():
		return
	recently_deleted.clear()
	_save()
	changed.emit()






func _apply_profile(p: SavedProfile) -> void :
	p.apply_to_config(GameConfig)
	InputBinds.apply(p.bindings)
	_apply_character(p)






func set_binding(action: String, slot: String, data: Variant) -> void :
	var p: = active()
	if p == null or data == null:
		return
	for other in InputBinds.REBINDABLE:
		var oa: String = other.action


		if oa != action and other.get(slot, false) and _binding_data(p, oa, slot) == data:
			var over: Dictionary = (p.bindings.get(oa, {}) as Dictionary).duplicate()
			over[slot] = {"t": "none"}
			p.bindings[oa] = over
	var cur: Dictionary = (p.bindings.get(action, {}) as Dictionary).duplicate()
	cur[slot] = data
	p.bindings[action] = cur
	InputBinds.apply(p.bindings)
	_save()


func _binding_data(p: SavedProfile, action: String, slot: String) -> Variant:
	var over: Dictionary = p.bindings.get(action, {})
	if over.has(slot):
		return over[slot]
	return InputBinds.default_data(action, slot)


func reset_bindings() -> void :
	var p: = active()
	if p == null:
		return
	p.bindings = {}
	InputBinds.apply(p.bindings)
	_save()


func reset_binding(action: String, slot: String) -> void :
	var p: = active()
	if p == null:
		return
	if p.bindings.has(action):
		var over: Dictionary = (p.bindings[action] as Dictionary).duplicate()
		over.erase(slot)
		if over.is_empty():
			p.bindings.erase(action)
		else:
			p.bindings[action] = over
	InputBinds.apply(p.bindings)
	_save()

func _apply_character(p: SavedProfile) -> void :



	CharacterConfig.save_slots(_slots_from_data(p.character_slots))
	if p.character.is_empty():
		return
	var c: = CharacterConfig.from_dict(p.character)
	GameConfig.character = c
	c.save_local()







func capture_character() -> void :
	var p: = active()
	if p == null:
		return
	if GameConfig.character != null:
		p.character = GameConfig.character.to_dict()
	_save()



func active_slots() -> Array:
	var p: = active()
	var out: Array = _slots_from_data(p.character_slots) if p != null else CharacterConfig.load_slots()
	while out.size() < CharacterConfig.SLOT_COUNT:
		out.append(null)
	return out




func set_slots(slots: Array) -> void :
	CharacterConfig.save_slots(slots)
	var p: = active()
	if p == null:
		return
	p.character_slots = _slots_to_data(slots)
	_save()


func capture_slots() -> void :
	set_slots(CharacterConfig.load_slots())

func _slots_from_data(arr: Array) -> Array:
	var out: Array = []
	for e in arr:
		out.append(CharacterConfig.from_dict(e) if e is Dictionary else null)
	return out

func _slots_to_data(arr: Array) -> Array:
	var out: Array = []
	for e in arr:
		out.append((e as CharacterConfig).to_dict() if e is CharacterConfig else null)
	return out




func save() -> void :
	_save()

func _on_settings_saved() -> void :
	var p: = active()
	if p == null:
		return
	p.capture_from_config(GameConfig)
	_save()

func _load() -> void :
	var path: = AppData.path(FILE)
	if not FileAccess.file_exists(path):
		_migrate_from_config()
		return
	var f: = FileAccess.open(path, FileAccess.READ)
	if f == null:
		_migrate_from_config()
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		_migrate_from_config()
		return
	var data: Dictionary = parsed
	var raw: Array = data.get("profiles", [])
	profiles.clear()
	for entry in raw:
		if typeof(entry) == TYPE_DICTIONARY:
			profiles.append(SavedProfile.from_dict(entry))
	if profiles.is_empty():
		_migrate_from_config()
		return
	recently_deleted.clear()
	for entry in data.get("recently_deleted", []):
		if typeof(entry) == TYPE_DICTIONARY:
			recently_deleted.append(SavedProfile.from_dict(entry))
	active_index = clampi(int(data.get("active", 0)), 0, profiles.size() - 1)




func _migrate_from_config() -> void :
	seeded_fresh = true
	var p: = SavedProfile.new()
	p.name = "Profile 1"
	p.capture_from_config(GameConfig)
	if GameConfig.character != null:
		p.character = GameConfig.character.to_dict()
	p.character_slots = _slots_to_data(CharacterConfig.load_slots())
	profiles = [p]
	active_index = 0
	_save()




func _migrate_legacy_character() -> void :
	if profiles.is_empty() or not profiles[0].character.is_empty():
		return
	if GameConfig.character != null:
		profiles[0].character = GameConfig.character.to_dict()
	profiles[0].character_slots = _slots_to_data(CharacterConfig.load_slots())
	_save()






func _migrate_legacy_career() -> void :
	if profiles.is_empty():
		return
	if not FileAccess.file_exists(LEGACY_CAREER):
		return
	for p in profiles:
		if not p.stats.is_empty():
			return
	var cfg: = ConfigFile.new()
	if cfg.load(LEGACY_CAREER) != OK or not cfg.has_section("career"):
		return
	var seeded: = {}
	for key in cfg.get_section_keys("career"):
		seeded[key] = cfg.get_value("career", key)
	if seeded.is_empty():
		return
	profiles[0].stats = seeded
	_save()

func _save() -> void :
	AppData.ensure()
	var out: Array = []
	for p in profiles:
		out.append(p.to_dict())
	var gone: Array = []
	for p in recently_deleted:
		gone.append(p.to_dict())
	var data: = {
		"version": FORMAT, 
		"active": active_index, 
		"profiles": out, 
		"recently_deleted": gone, 
	}
	var f: = FileAccess.open(AppData.path(FILE), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()
	if is_instance_valid(SupabaseClient):
		SupabaseClient.queue_profile_save()
