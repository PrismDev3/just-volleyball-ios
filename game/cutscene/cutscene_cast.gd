class_name CutsceneCast
extends RefCounted









var _profiles: Array = []
var _pp: = 0
var _n: = 0
var _rng: = RandomNumberGenerator.new()

func _init() -> void :
	_rng.randomize()
	_profiles = _gather_profiles()

func _gather_profiles() -> Array:
	var out: Array = []

	var store = Engine.get_main_loop().root.get_node_or_null("/root/ProfileStore")\
	if Engine.get_main_loop() != null else null
	if store == null:
		return out
	var list = store.get("profiles")
	var active_i: = int(store.get("active_index"))
	if list == null:
		return out

	if active_i >= 0 and active_i < list.size():
		out.append(_cfg_of(list[active_i]))
	for i in list.size():
		if i == active_i:
			continue
		out.append(_cfg_of(list[i]))
	return out

func _cfg_of(profile) -> CharacterConfig:
	var d = profile.get("character") if profile != null else null
	if d is Dictionary:
		return CharacterConfig.from_dict(d)
	return CharacterConfig.random(_rng)


func next() -> Array:
	var have_profile: = _pp < _profiles.size()

	var pair: = (_n % 3 == 2) if have_profile else (_rng.randf() < 0.4)
	_n += 1
	var out: Array = []
	if pair:
		out.append({"cfg": CharacterConfig.random(_rng), "kit": _kit(true)})
		out.append({"cfg": CharacterConfig.random(_rng), "kit": _kit(false)})
		return out
	var cfg: CharacterConfig
	if have_profile:
		cfg = _profiles[_pp]
		_pp += 1
	else:
		cfg = CharacterConfig.random(_rng)
	out.append({"cfg": cfg, "kit": _kit(_n % 2 == 0)})
	return out

func _kit(home: bool) -> Array:

	if typeof(GameConfig) != TYPE_NIL and GameConfig.has_method("team_kit"):
		return GameConfig.team_kit(home)
	return []
