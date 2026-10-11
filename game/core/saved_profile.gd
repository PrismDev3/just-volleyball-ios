class_name SavedProfile
extends RefCounted














const NAME_MAX: = 10

var name: = "Player"


var aim_assist: = false
var hardware_cursor: = false
var mouse_sensitivity: = 1.0
var stick_sensitivity: = 1.0
var rumble: = true
var default_camera: = 1


var camera_shake: = true
var aim_color_cue: = true
var touch_highlight: = true
var reach_marker: = true
var show_own_name: = false
var chat_enabled: = true
var chat_bubbles: = true


var menu_outfit: = "gym"
var menu_ball: = "nationals"





var stats: = {}





var xp: = 0
var level: = 1
var coins: = 0



var owned: = {}








var character: = {}
var character_slots: Array = []





var achievements: = {}





var bindings: = {}


static func clean_name(raw: String) -> String:
	var n: = raw.strip_edges()
	if n.length() > NAME_MAX:
		n = n.substr(0, NAME_MAX)
	return n if n != "" else "Player"

func set_name(raw: String) -> void :
	name = clean_name(raw)







func capture_from_config(cfg: Node) -> void :
	aim_assist = cfg.aim_assist
	hardware_cursor = cfg.hardware_cursor
	mouse_sensitivity = cfg.mouse_sensitivity
	stick_sensitivity = cfg.stick_sensitivity
	rumble = cfg.rumble
	default_camera = cfg.default_camera
	camera_shake = cfg.camera_shake
	aim_color_cue = cfg.aim_color_cue
	touch_highlight = cfg.touch_highlight
	reach_marker = cfg.reach_marker
	show_own_name = cfg.show_own_name
	chat_enabled = cfg.chat_enabled
	chat_bubbles = cfg.chat_bubbles
	menu_outfit = cfg.menu_outfit
	menu_ball = cfg.menu_ball

func apply_to_config(cfg: Node) -> void :
	cfg.aim_assist = aim_assist
	cfg.hardware_cursor = hardware_cursor
	cfg.mouse_sensitivity = clampf(mouse_sensitivity, 0.25, 3.0)
	cfg.stick_sensitivity = clampf(stick_sensitivity, 0.25, 3.0)
	cfg.rumble = rumble
	cfg.default_camera = clampi(default_camera, 0, 3)
	cfg.camera_shake = camera_shake
	cfg.aim_color_cue = aim_color_cue
	cfg.touch_highlight = touch_highlight
	cfg.reach_marker = reach_marker
	cfg.show_own_name = show_own_name
	cfg.chat_enabled = chat_enabled
	cfg.chat_bubbles = chat_bubbles
	cfg.menu_outfit = menu_outfit
	cfg.menu_ball = menu_ball



func to_dict() -> Dictionary:
	return {
		"name": name, 
		"aim_assist": aim_assist, 
		"hardware_cursor": hardware_cursor, 
		"mouse_sensitivity": mouse_sensitivity, 
		"stick_sensitivity": stick_sensitivity, 
		"rumble": rumble, 
		"default_camera": default_camera, 
		"camera_shake": camera_shake, 
		"aim_color_cue": aim_color_cue, 
		"touch_highlight": touch_highlight, 
		"reach_marker": reach_marker, 
		"show_own_name": show_own_name, 
		"chat_enabled": chat_enabled, 
		"chat_bubbles": chat_bubbles, 
		"menu_outfit": menu_outfit, 
		"menu_ball": menu_ball, 
		"stats": stats, 
		"xp": xp, 
		"level": level, 
		"coins": coins, 
		"owned": owned, 
		"character": character, 
		"character_slots": character_slots, 
		"achievements": achievements, 
		"bindings": bindings, 
	}

static func from_dict(d: Dictionary) -> SavedProfile:
	var p: = SavedProfile.new()
	p.name = SavedProfile.clean_name(String(d.get("name", "Player")))
	p.aim_assist = bool(d.get("aim_assist", false))
	p.hardware_cursor = bool(d.get("hardware_cursor", false))
	p.mouse_sensitivity = clampf(float(d.get("mouse_sensitivity", 1.0)), 0.25, 3.0)
	p.stick_sensitivity = clampf(float(d.get("stick_sensitivity", 1.0)), 0.25, 3.0)
	p.rumble = bool(d.get("rumble", true))
	p.default_camera = clampi(int(d.get("default_camera", 1)), 0, 3)
	p.camera_shake = bool(d.get("camera_shake", true))
	p.aim_color_cue = bool(d.get("aim_color_cue", true))
	p.touch_highlight = bool(d.get("touch_highlight", true))
	p.reach_marker = bool(d.get("reach_marker", true))
	p.show_own_name = bool(d.get("show_own_name", false))
	p.chat_enabled = bool(d.get("chat_enabled", true))


	p.chat_bubbles = bool(d.get("chat_bubbles", true))
	p.menu_outfit = String(d.get("menu_outfit", "gym"))
	p.menu_ball = String(d.get("menu_ball", "nationals"))
	var st: Variant = d.get("stats", {})
	p.stats = st.duplicate() if st is Dictionary else {}
	p.xp = maxi(0, int(d.get("xp", 0)))
	p.level = maxi(1, int(d.get("level", 1)))
	p.coins = maxi(0, int(d.get("coins", 0)))
	var ow: Variant = d.get("owned", {})
	p.owned = ow.duplicate() if ow is Dictionary else {}
	var ch: Variant = d.get("character", {})
	p.character = ch.duplicate() if ch is Dictionary else {}
	var sl: Variant = d.get("character_slots", [])
	p.character_slots = sl.duplicate() if sl is Array else []
	var ac: Variant = d.get("achievements", {})
	p.achievements = ac.duplicate(true) if ac is Dictionary else {}
	var bd: Variant = d.get("bindings", {})
	p.bindings = bd.duplicate(true) if bd is Dictionary else {}
	return p
