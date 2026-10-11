extends Node





















signal device_changed(kind: int)
signal changed()

enum Kind{KBM, GAMEPAD}
enum Style{AUTO, XBOX, PLAYSTATION, SWITCH, STEAM_DECK, STEAM_CONTROLLER, GENERIC}




const MOUSE_WAKE: = 6.0
const JOY_WAKE: = 0.5

const _FOLDER: = {
	Style.PLAYSTATION: "PlayStation Series", 
	Style.XBOX: "Xbox Series", 
	Style.SWITCH: "Nintendo Switch", 
	Style.STEAM_DECK: "Steam Deck", 
	Style.STEAM_CONTROLLER: "Steam Controller", 
	Style.GENERIC: "Generic", 
}


const _JOY: = {
	"jump": "face_down", 
	"contact": "rt", 
	"set": "face_left", 
	"serve": "face_up", 
	"dive": "face_right", 
	"stats": "view", 
	"camera_toggle": "rstick_press", 
	"camera_zoom": "lb", 
	"aim_recenter": "rb", 
	"strafe": "lt", 
	"move": "lstick", 
	"aim": "rstick", 
	"callout_1": "dpad_up", 
	"callout_2": "dpad_right", 
	"callout_3": "dpad_down", 
	"callout_4": "dpad_left", 

	"tut_restart": "dpad_left", 
	"tut_skip": "dpad_right", 
}


const _KBM: = {
	"jump": "keyboard_space_icon", 
	"contact": "mouse_left", 
	"dive": "mouse_right", 
	"set": "keyboard_e", 
	"serve": "keyboard_r", 
	"stats": "keyboard_tab_icon", 
	"camera_toggle": "keyboard_c", 
	"camera_zoom": "keyboard_v", 
	"aim_recenter": "keyboard_q", 
	"strafe": "keyboard_shift_icon", 
	"chat_toggle": "keyboard_t", 
	"callout_1": "keyboard_1", 
	"callout_2": "keyboard_2", 
	"callout_3": "keyboard_3", 
	"callout_4": "keyboard_4", 
	"move": "keyboard_w", 
	"aim": "mouse", 

	"tut_restart": "keyboard_arrow_left", 
	"tut_skip": "keyboard_arrow_right", 
}





const _GLYPH: = {
	Style.PLAYSTATION: {


		"face_down": "playstation_button_color_cross", 
		"face_right": "playstation_button_color_circle", 
		"face_left": "playstation_button_color_square", 
		"face_up": "playstation_button_color_triangle", 
		"lstick": "playstation_stick_l", 
		"rstick": "playstation_stick_r", 
		"lstick_press": "playstation_stick_l_press", 
		"rstick_press": "playstation_stick_r_press", 
		"lb": "playstation_trigger_l1", "rb": "playstation_trigger_r1", 
		"lt": "playstation_trigger_l2", "rt": "playstation_trigger_r2", 
		"view": "playstation4_button_share", "start": "playstation4_button_options", 
		"dpad_up": "playstation_dpad_up", "dpad_down": "playstation_dpad_down", 
		"dpad_left": "playstation_dpad_left", "dpad_right": "playstation_dpad_right", 
	}, 
	Style.XBOX: {

		"face_down": "xbox_button_color_a", 
		"face_right": "xbox_button_color_b", 
		"face_left": "xbox_button_color_x", 
		"face_up": "xbox_button_color_y", 
		"lstick": "xbox_stick_l", 
		"rstick": "xbox_stick_r", 
		"lstick_press": "xbox_stick_l_press", 
		"rstick_press": "xbox_stick_r_press", 
		"lb": "xbox_lb", "rb": "xbox_rb", 
		"lt": "xbox_lt", "rt": "xbox_rt", 
		"view": "xbox_button_view", "start": "xbox_button_menu", 
		"dpad_up": "xbox_dpad_up", "dpad_down": "xbox_dpad_down", 
		"dpad_left": "xbox_dpad_left", "dpad_right": "xbox_dpad_right", 
	}, 
	Style.SWITCH: {

		"face_down": "switch_button_b", 
		"face_right": "switch_button_a", 
		"face_left": "switch_button_y", 
		"face_up": "switch_button_x", 
		"lstick": "switch_stick_l", 
		"rstick": "switch_stick_r", 
		"lstick_press": "switch_stick_l_press", 
		"rstick_press": "switch_stick_r_press", 
		"lb": "switch_button_l", "rb": "switch_button_r", 
		"lt": "switch_button_zl", "rt": "switch_button_zr", 
		"view": "switch_button_minus", "start": "switch_button_plus", 
		"dpad_up": "switch_dpad_up", "dpad_down": "switch_dpad_down", 
		"dpad_left": "switch_dpad_left", "dpad_right": "switch_dpad_right", 
	}, 
	Style.STEAM_DECK: {
		"face_down": "steamdeck_button_a", 
		"face_right": "steamdeck_button_b", 
		"face_left": "steamdeck_button_x", 
		"face_up": "steamdeck_button_y", 
		"lstick": "steamdeck_stick_l", 
		"rstick": "steamdeck_stick_r", 
		"lstick_press": "steamdeck_stick_l_press", 
		"rstick_press": "steamdeck_stick_r_press", 
		"lb": "steamdeck_button_l1", "rb": "steamdeck_button_r1", 
		"lt": "steamdeck_button_l2", "rt": "steamdeck_button_r2", 
		"view": "steamdeck_button_view", "start": "steamdeck_button_options", 
		"dpad_up": "steamdeck_dpad_up", "dpad_down": "steamdeck_dpad_down", 
		"dpad_left": "steamdeck_dpad_left", "dpad_right": "steamdeck_dpad_right", 
	}, 
	Style.STEAM_CONTROLLER: {
		"face_down": "steam_button_color_a", 
		"face_right": "steam_button_color_b", 
		"face_left": "steam_button_color_x", 
		"face_up": "steam_button_color_y", 
		"lstick": "steam_stick", 
		"rstick": "steam_stick", 
		"lstick_press": "steam_stick_l_press", 
		"rstick_press": "steam_stick_l_press", 
		"lb": "steam_lb", "rb": "steam_rb", 
		"lt": "steam_lt", "rt": "steam_rt", 
		"view": "steam_button_back_icon", "start": "steam_button_start_icon", 
		"dpad_up": "steam_dpad_up", "dpad_down": "steam_dpad_down", 
		"dpad_left": "steam_dpad_left", "dpad_right": "steam_dpad_right", 
	}, 
}



var style_override: = Style.AUTO

var _kind: = Kind.KBM
var _brand: = Style.XBOX
var _device_id: = 0
var _cache: = {}





var _pointer: = true

func _ready() -> void :


	var pads: = Input.get_connected_joypads()
	if not pads.is_empty():
		_device_id = pads[0]
		_refresh_brand()
	Input.joy_connection_changed.connect(_on_joy_connection)



	get_viewport().gui_focus_changed.connect(_on_focus_changed)

func _input(event: InputEvent) -> void :
	var new_kind: = _kind
	if event is InputEventKey:
		new_kind = Kind.KBM
		_pointer = false
	elif event is InputEventMouseButton:
		new_kind = Kind.KBM
		_pointer = true
	elif event is InputEventMouseMotion:
		if (event as InputEventMouseMotion).relative.length() > MOUSE_WAKE:
			new_kind = Kind.KBM
			_pointer = true
	elif event is InputEventJoypadButton:
		if (event as InputEventJoypadButton).pressed:
			new_kind = Kind.GAMEPAD
			_pointer = false
			_use_device(event.device)
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) > JOY_WAKE:
			new_kind = Kind.GAMEPAD
			_pointer = false
			_use_device(event.device)
	if new_kind != _kind:
		_kind = new_kind
		_cache.clear()
		device_changed.emit(_kind)
		changed.emit()





func glyph(action: String) -> Texture2D:
	var style: = active_style()
	var key: = "%s|%d|%d" % [action, _kind, style]
	if _cache.has(key):
		return _cache[key]
	var tex: = _resolve(action, style)
	_cache[key] = tex
	return tex

func device_kind() -> int:
	return _kind

func using_gamepad() -> bool:
	return _kind == Kind.GAMEPAD


func device_id() -> int:
	return _device_id


func active_style() -> int:
	if style_override != Style.AUTO:
		return style_override
	return _brand

func set_style_override(style: int) -> void :
	if style == style_override:
		return
	style_override = style
	_cache.clear()
	changed.emit()


func debug_string() -> String:
	var k: = "kbm" if _kind == Kind.KBM else "gamepad"
	return "%s / %s (%s)" % [k, Style.keys()[active_style()], 
		Input.get_joy_name(_device_id) if _kind == Kind.GAMEPAD else "-"]



func _use_device(device: int) -> void :
	if device == _device_id:
		return
	_device_id = device
	_refresh_brand()

func _refresh_brand() -> void :
	var b: = _brand_from_steam(_device_id)
	if b == Style.AUTO:
		b = _brand_from_name(Input.get_joy_name(_device_id))
	if b != _brand:
		_brand = b
		_cache.clear()
		changed.emit()




func _brand_from_steam(_device: int) -> int:
	if not Engine.has_singleton("Steam"):
		return Style.AUTO
	var s: Object = Engine.get_singleton("Steam")
	if s == null or not s.has_method("getInputTypeForHandle"):
		return Style.AUTO

	return Style.AUTO

func _brand_from_name(name: String) -> int:
	var n: = name.to_lower()
	if n.contains("dualsense") or n.contains("dualshock") or n.contains("playstation")\
	or n.contains("sony") or n.contains("ps3") or n.contains("ps4") or n.contains("ps5"):
		return Style.PLAYSTATION
	if n.contains("switch") or n.contains("nintendo") or n.contains("joy-con") or n.contains("joycon"):
		return Style.SWITCH

	if n.contains("steam deck") or n.contains("steamdeck") or n.contains("jupiter") or n.contains("galileo"):
		return Style.STEAM_DECK
	if n.contains("steam controller"):
		return Style.STEAM_CONTROLLER


	return Style.XBOX

func _resolve(action: String, style: int) -> Texture2D:
	if _kind == Kind.KBM:



		var file: = _kbm_file_for_bound(action)
		if file == "":
			file = String(_KBM.get(action, ""))
		return _load("Keyboard & Mouse", file)

	var token: = _joy_token_for_bound(action)
	if token == "":
		token = String(_JOY.get(action, ""))
	if token == "":
		return null
	var table: Dictionary = _GLYPH.get(style, _GLYPH[Style.XBOX])
	var file: = String(table.get(token, ""))
	var tex: = _load(String(_FOLDER.get(style, "Xbox Series")), file)

	if tex == null and style != Style.XBOX:
		tex = _load("Xbox Series", String(_GLYPH[Style.XBOX].get(token, "")))
	return tex

func _load(folder: String, filename: String) -> Texture2D:
	if filename == "":
		return null
	var path: = "res://game/ui_icon/%s/Default/%s.png" % [folder, filename]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D



func refresh() -> void :
	_cache.clear()
	changed.emit()



func _kbm_file_for_bound(action: String) -> String:
	if not InputMap.has_action(action):
		return ""
	for e in InputMap.action_get_events(action):
		if e is InputEventKey or e is InputEventMouseButton:
			return _kbm_file_for_event(e)
	return ""

func _joy_token_for_bound(action: String) -> String:
	if not InputMap.has_action(action):
		return ""
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton or e is InputEventJoypadMotion:
			return _joy_token_for_event(e)
	return ""

func _joy_token_for_event(e: InputEvent) -> String:
	if e is InputEventJoypadButton:
		return String(_BTN_TOKEN.get((e as InputEventJoypadButton).button_index, ""))
	if e is InputEventJoypadMotion:
		match (e as InputEventJoypadMotion).axis:
			JOY_AXIS_TRIGGER_LEFT: return "lt"
			JOY_AXIS_TRIGGER_RIGHT: return "rt"
			JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y: return "lstick"
			JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y: return "rstick"
	return ""

func _kbm_file_for_event(e: InputEvent) -> String:
	if e is InputEventMouseButton:
		match (e as InputEventMouseButton).button_index:
			MOUSE_BUTTON_LEFT: return "mouse_left"
			MOUSE_BUTTON_RIGHT: return "mouse_right"
			_: return "mouse"
	if e is InputEventKey:
		var k: = e as InputEventKey
		var kc: int = k.physical_keycode if k.physical_keycode != 0 else k.keycode
		if _KEY_FILE.has(kc):
			return String(_KEY_FILE[kc])
		if kc >= KEY_A and kc <= KEY_Z:
			return "keyboard_" + char(kc).to_lower()
		if kc >= KEY_0 and kc <= KEY_9:
			return "keyboard_" + char(kc)
		return "keyboard_any"
	return ""

const _BTN_TOKEN: = {
	JOY_BUTTON_A: "face_down", JOY_BUTTON_B: "face_right", 
	JOY_BUTTON_X: "face_left", JOY_BUTTON_Y: "face_up", 
	JOY_BUTTON_BACK: "view", JOY_BUTTON_START: "start", 
	JOY_BUTTON_LEFT_STICK: "lstick_press", JOY_BUTTON_RIGHT_STICK: "rstick_press", 
	JOY_BUTTON_LEFT_SHOULDER: "lb", JOY_BUTTON_RIGHT_SHOULDER: "rb", 
	JOY_BUTTON_DPAD_UP: "dpad_up", JOY_BUTTON_DPAD_DOWN: "dpad_down", 
	JOY_BUTTON_DPAD_LEFT: "dpad_left", JOY_BUTTON_DPAD_RIGHT: "dpad_right", 
}
const _KEY_FILE: = {
	KEY_SPACE: "keyboard_space_icon", KEY_SHIFT: "keyboard_shift_icon", 
	KEY_CTRL: "keyboard_ctrl", KEY_ALT: "keyboard_alt", KEY_TAB: "keyboard_tab_icon", 
	KEY_ENTER: "keyboard_enter", KEY_ESCAPE: "keyboard_escape", 
	KEY_BACKSPACE: "keyboard_backspace_icon", 
	KEY_UP: "keyboard_arrow_up", KEY_DOWN: "keyboard_arrow_down", 
	KEY_LEFT: "keyboard_arrow_left", KEY_RIGHT: "keyboard_arrow_right", 
	KEY_COMMA: "keyboard_comma", KEY_PERIOD: "keyboard_period", 
	KEY_SEMICOLON: "keyboard_semicolon", KEY_APOSTROPHE: "keyboard_apostrophe", 
	KEY_SLASH: "keyboard_slash_forward", KEY_BACKSLASH: "keyboard_slash_back", 
	KEY_MINUS: "keyboard_minus", KEY_EQUAL: "keyboard_equals", 
	KEY_BRACKETLEFT: "keyboard_bracket_open", KEY_BRACKETRIGHT: "keyboard_bracket_close", 
}





func _on_focus_changed(ctrl: Control) -> void :
	if ctrl == null or not _pointer:
		return
	if ctrl is LineEdit or ctrl is TextEdit:
		return
	ctrl.release_focus()

func _on_joy_connection(device: int, connected: bool) -> void :
	if connected and _kind == Kind.GAMEPAD:
		_use_device(device)
