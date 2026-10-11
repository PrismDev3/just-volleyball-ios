extends Node



















const REBINDABLE: = [
	{"action": "move_forward", "label": "move up", "kb": true, "pad": false}, 
	{"action": "move_back", "label": "move down", "kb": true, "pad": false}, 
	{"action": "move_left", "label": "move left", "kb": true, "pad": false}, 
	{"action": "move_right", "label": "move right", "kb": true, "pad": false}, 
	{"action": "jump", "label": "jump / block", "kb": true, "pad": true}, 
	{"action": "contact", "label": "hit / receive", "kb": true, "pad": true}, 
	{"action": "set", "label": "set", "kb": true, "pad": true}, 
	{"action": "dive", "label": "dive", "kb": true, "pad": true}, 
	{"action": "serve", "label": "serve", "kb": true, "pad": true}, 
	{"action": "strafe", "label": "strafe", "kb": true, "pad": true}, 
	{"action": "aim_recenter", "label": "aim assist / recenter", "kb": true, "pad": true}, 
	{"action": "camera_toggle", "label": "camera", "kb": true, "pad": true}, 
	{"action": "camera_zoom", "label": "zoom", "kb": true, "pad": true}, 
	{"action": "stats", "label": "scoreboard", "kb": true, "pad": true}, 
	{"action": "chat_toggle", "label": "chat", "kb": true, "pad": false}, 
	{"action": "free_mouse", "label": "free mouse", "kb": true, "pad": false}, 
]


var _defaults: = {}

func _ready() -> void :
	_capture_defaults()




func _capture_defaults() -> void :




	if not _defaults.is_empty():
		return
	for entry in REBINDABLE:
		var action: String = entry.action
		if not InputMap.has_action(action):
			continue
		var kb: InputEvent = null
		var pad: InputEvent = null
		for e in InputMap.action_get_events(action):
			if (e is InputEventKey or e is InputEventMouseButton) and kb == null:
				kb = e
			elif (e is InputEventJoypadButton or e is InputEventJoypadMotion) and pad == null:
				pad = e
		_defaults[action] = {"kb": kb, "pad": pad}



func apply(bindings: Dictionary) -> void :



	if _defaults.is_empty():
		_capture_defaults()
	for entry in REBINDABLE:
		var action: String = entry.action
		if not InputMap.has_action(action):
			continue
		var over: Dictionary = bindings.get(action, {})
		var kb_ev: = _event_for(action, "kb", over)
		var pad_ev: = _event_for(action, "pad", over)
		InputMap.action_erase_events(action)
		if kb_ev != null:
			InputMap.action_add_event(action, kb_ev)
		if pad_ev != null:
			InputMap.action_add_event(action, pad_ev)



	if InputPrompts != null:
		InputPrompts.refresh()



func _event_for(action: String, slot: String, over: Dictionary) -> InputEvent:
	if over.has(slot):
		return event_from_data(over[slot])
	var d: Dictionary = _defaults.get(action, {})
	return d.get(slot, null)

func default_data(action: String, slot: String) -> Variant:
	var d: Dictionary = _defaults.get(action, {})
	var e: InputEvent = d.get(slot, null)
	return event_to_data(e) if e != null else null



func event_to_data(e: InputEvent) -> Variant:
	if e is InputEventKey:
		var k: = e as InputEventKey
		return {"t": "key", "c": int(k.physical_keycode if k.physical_keycode != 0 else k.keycode)}
	if e is InputEventMouseButton:
		return {"t": "mouse", "c": int((e as InputEventMouseButton).button_index)}
	if e is InputEventJoypadButton:
		return {"t": "joyb", "c": int((e as InputEventJoypadButton).button_index)}
	if e is InputEventJoypadMotion:
		var m: = e as InputEventJoypadMotion
		return {"t": "joym", "a": int(m.axis), "d": signf(m.axis_value)}
	return null

func event_from_data(d: Variant) -> InputEvent:
	if not (d is Dictionary):
		return null
	match String(d.get("t", "")):
		"key":
			var k: = InputEventKey.new()
			k.physical_keycode = int(d.get("c", 0))
			return k
		"mouse":
			var mb: = InputEventMouseButton.new()
			mb.button_index = int(d.get("c", 0))
			return mb
		"joyb":
			var jb: = InputEventJoypadButton.new()
			jb.button_index = int(d.get("c", 0))
			return jb
		"joym":
			var jm: = InputEventJoypadMotion.new()
			jm.axis = int(d.get("a", 0))
			jm.axis_value = float(d.get("d", 1.0))
			return jm
	return null



func event_matches_slot(e: InputEvent, slot: String) -> bool:
	if slot == "kb":
		return e is InputEventKey or e is InputEventMouseButton
	return e is InputEventJoypadButton or e is InputEventJoypadMotion



func label_for(action: String, slot: String, bindings: Dictionary) -> String:
	var over: Dictionary = bindings.get(action, {})
	var data: Variant = over[slot] if over.has(slot) else default_data(action, slot)
	return label_for_data(data)

func label_for_data(d: Variant) -> String:
	if not (d is Dictionary):
		return "—"
	match String(d.get("t", "")):
		"key":
			return OS.get_keycode_string(int(d.get("c", 0)))
		"mouse":
			match int(d.get("c", 0)):
				MOUSE_BUTTON_LEFT: return "LMB"
				MOUSE_BUTTON_RIGHT: return "RMB"
				MOUSE_BUTTON_MIDDLE: return "MMB"
				_: return "mouse %d" % int(d.get("c", 0))
		"joyb":
			return _JOY_BTN.get(int(d.get("c", 0)), "button %d" % int(d.get("c", 0)))
		"joym":
			var axis: = int(d.get("a", 0))
			var pos: bool = float(d.get("d", 1.0)) >= 0.0
			if axis == JOY_AXIS_TRIGGER_LEFT:
				return "LT"
			if axis == JOY_AXIS_TRIGGER_RIGHT:
				return "RT"
			return "%s %s" % [_AXIS.get(axis, "axis %d" % axis), "+" if pos else "-"]
	return "—"


const _JOY_BTN: = {
	JOY_BUTTON_A: "A / cross", 
	JOY_BUTTON_B: "B / circle", 
	JOY_BUTTON_X: "X / square", 
	JOY_BUTTON_Y: "Y / triangle", 
	JOY_BUTTON_LEFT_SHOULDER: "LB", 
	JOY_BUTTON_RIGHT_SHOULDER: "RB", 
	JOY_BUTTON_BACK: "select", 
	JOY_BUTTON_START: "start", 
	JOY_BUTTON_LEFT_STICK: "L3", 
	JOY_BUTTON_RIGHT_STICK: "R3", 
	JOY_BUTTON_DPAD_UP: "dpad up", 
	JOY_BUTTON_DPAD_DOWN: "dpad down", 
	JOY_BUTTON_DPAD_LEFT: "dpad left", 
	JOY_BUTTON_DPAD_RIGHT: "dpad right", 
}
const _AXIS: = {
	JOY_AXIS_LEFT_X: "L-stick x", 
	JOY_AXIS_LEFT_Y: "L-stick y", 
	JOY_AXIS_RIGHT_X: "R-stick x", 
	JOY_AXIS_RIGHT_Y: "R-stick y", 
}
