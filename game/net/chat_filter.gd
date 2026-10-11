class_name ChatFilter
extends RefCounted
















const WORDS_PATH: = "res://game/net/chat_words.json"
const MASK: = "#"

static var _words: Array = []
static var _phrases: Array = []
static var _loaded: = false
static var _regex: RegEx = null

static func _load() -> void :
	if _loaded:
		return
	_loaded = true
	if not ResourceLoader.exists(WORDS_PATH) and not FileAccess.file_exists(WORDS_PATH):
		return
	var f: = FileAccess.open(WORDS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Array):
		return
	var single: = {}
	for w in parsed:
		var s: = String(w).strip_edges().to_lower()
		if s == "":
			continue
		if " " in s:
			_phrases.append(s)
		else:
			single[s] = true
	_words = single.keys()


	_words.sort_custom( func(a, b): return a.length() > b.length())
	var parts: = PackedStringArray()
	for w in _words:
		parts.append(_escape(w))
	if not parts.is_empty():
		_regex = RegEx.new()
		_regex.compile("(?i)\\b(" + "|".join(parts) + ")\\b")

static func _escape(s: String) -> String:
	var out: = ""
	for ch in s:
		if ch in "\\^$.|?*+()[]{}":
			out += "\\" + ch
		else:
			out += ch
	return out

static func has_list() -> bool:
	_load()
	return _regex != null or not _phrases.is_empty()


static func clean(text: String) -> String:
	_load()
	var out: = text
	if _regex != null:
		var matches: = _regex.search_all(out)

		for i in range(matches.size() - 1, -1, -1):
			var m: RegExMatch = matches[i]
			out = out.substr(0, m.get_start()) + MASK.repeat(m.get_end() - m.get_start())\
			+ out.substr(m.get_end())
	if not _phrases.is_empty():
		var low: = out.to_lower()
		for ph in _phrases:
			var at: = low.find(ph)
			while at >= 0:
				out = out.substr(0, at) + MASK.repeat(ph.length()) + out.substr(at + ph.length())
				low = out.to_lower()
				at = low.find(ph, at + ph.length())
	return out

static func is_clean(text: String) -> bool:
	return clean(text) == text
