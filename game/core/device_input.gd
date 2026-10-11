class_name DeviceInput
extends RefCounted


















const MERGED: = -2
const KBM: = -1
const AXIS_DEADZONE: = 0.5

var device: = MERGED

var exclude_pads: PackedInt32Array = []

var _now: = {}
var _was: = {}

func _init(dev: = MERGED) -> void :
	device = dev

func is_merged() -> bool:
	return device == MERGED


func _global() -> bool:
	return device == MERGED and exclude_pads.is_empty()


func poll(actions: PackedStringArray) -> void :
	if _global():
		return
	_was = _now
	_now = {}
	for a in actions:
		_now[a] = _device_strength(a)

func pressed(action: String) -> bool:
	if _global():
		return Input.is_action_pressed(action)
	return float(_now.get(action, 0.0)) > AXIS_DEADZONE

func just_pressed(action: String) -> bool:
	if _global():
		return Input.is_action_just_pressed(action)
	return float(_now.get(action, 0.0)) > AXIS_DEADZONE\
	and float(_was.get(action, 0.0)) <= AXIS_DEADZONE

func just_released(action: String) -> bool:
	if _global():
		return Input.is_action_just_released(action)
	return float(_now.get(action, 0.0)) <= AXIS_DEADZONE\
	and float(_was.get(action, 0.0)) > AXIS_DEADZONE

func strength(action: String) -> float:
	if _global():
		return Input.get_action_strength(action)
	return float(_now.get(action, 0.0))

func get_vector(neg_x: String, pos_x: String, neg_y: String, pos_y: String) -> Vector2:
	if _global():
		return Input.get_vector(neg_x, pos_x, neg_y, pos_y)
	var v: = Vector2(strength(pos_x) - strength(neg_x), strength(pos_y) - strength(neg_y))
	return v if v.length() <= 1.0 else v.normalized()



func _device_strength(action: String) -> float:
	if not InputMap.has_action(action):
		return 0.0
	var best: = 0.0
	for e in InputMap.action_get_events(action):
		best = maxf(best, _resolve_event(e))
	return best


func _resolve_event(e: InputEvent) -> float:
	if device == KBM:
		return _kbm_event_strength(e)
	if device >= 0:
		return _pad_event_strength(e, device)

	if e is InputEventKey or e is InputEventMouseButton:
		return _kbm_event_strength(e)
	var best: = 0.0
	for pad in Input.get_connected_joypads():
		if pad in exclude_pads:
			continue
		best = maxf(best, _pad_event_strength(e, pad))
	return best

func _pad_event_strength(e: InputEvent, pad: int) -> float:
	if e is InputEventJoypadButton:
		return 1.0 if Input.is_joy_button_pressed(
			pad, (e as InputEventJoypadButton).button_index) else 0.0
	if e is InputEventJoypadMotion:
		var m: = e as InputEventJoypadMotion
		var val: = Input.get_joy_axis(pad, m.axis)
		if signf(val) != signf(m.axis_value):
			return 0.0
		return clampf(absf(val), 0.0, 1.0)
	return 0.0

func _kbm_event_strength(e: InputEvent) -> float:
	if e is InputEventKey:
		var k: = e as InputEventKey
		if k.physical_keycode != 0:
			return 1.0 if Input.is_physical_key_pressed(k.physical_keycode) else 0.0
		return 1.0 if Input.is_key_pressed(k.keycode) else 0.0
	if e is InputEventMouseButton:
		var mb: = e as InputEventMouseButton
		var mask: = Input.get_mouse_button_mask()
		return 1.0 if (mask & (1 << (mb.button_index - 1))) != 0 else 0.0
	return 0.0
