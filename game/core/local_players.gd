extends Node












signal roster_changed

const MAX_LOCAL: = 4

var slots: Array[LocalPlayerSlot] = []



var watch_joins: = false


var primary_device: = DeviceInput.KBM




const PRIMARY_ACTIONS: PackedStringArray = ["menu_start", "ui_cancel"]
var _primary_input: = DeviceInput.new()
var _start_prev: = {}

func _ready() -> void :
	_ensure_primary()

func _process(_dt: float) -> void :


	if watch_joins:
		_track_primary_device()
		_watch_for_joins()
	_primary_input.exclude_pads = claimed_pads()
	_primary_input.poll(PRIMARY_ACTIONS)



func primary_just_pressed(action: String) -> bool:
	return _primary_input.just_pressed(action)

func primary_pressed(action: String) -> bool:
	return _primary_input.pressed(action)


func claimed_pads() -> PackedInt32Array:
	var out: = PackedInt32Array()
	for s in slots:
		if s.device >= 0:
			out.append(s.device)
	return out

func _track_primary_device() -> void :

	if not InputPrompts.using_gamepad():
		primary_device = DeviceInput.KBM
		return

	for pad in Input.get_connected_joypads():
		if slot_for_device(pad) != null:
			continue
		if _pad_active(pad):
			primary_device = pad
			return

func _watch_for_joins() -> void :
	for pad in Input.get_connected_joypads():
		var down: bool = Input.is_joy_button_pressed(pad, JOY_BUTTON_START)
		var was: bool = _start_prev.get(pad, false)
		_start_prev[pad] = down
		if not down or was:
			continue
		if pad == primary_device:
			continue
		if slot_for_device(pad) != null:
			continue
		join(pad)

func _pad_active(pad: int) -> bool:
	if absf(Input.get_joy_axis(pad, JOY_AXIS_LEFT_X)) > 0.5:
		return true
	if absf(Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y)) > 0.5:
		return true
	for b in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y]:
		if Input.is_joy_button_pressed(pad, b):
			return true
	return false

func _ensure_primary() -> void :
	if not slots.is_empty():
		return
	var s: = LocalPlayerSlot.new()
	s.device = DeviceInput.MERGED
	s.profile = ProfileStore.active()
	slots.append(s)

func primary() -> LocalPlayerSlot:
	_ensure_primary()
	return slots[0]

func count() -> int:
	return slots.size()

func slot_for_device(device: int) -> LocalPlayerSlot:
	for s in slots:
		if s.device == device:
			return s
	return null




func join(device: int) -> LocalPlayerSlot:
	if device < 0:
		return null
	if slots.size() >= MAX_LOCAL:
		return null
	if slot_for_device(device) != null:
		return null
	var slot: = LocalPlayerSlot.new()
	slot.device = device
	slot.profile = _next_free_profile()
	if slot.profile == null:
		slot.profile = _temp_guest()
		slot.is_temp = true
	slots.append(slot)
	roster_changed.emit()
	return slot


func leave(device: int) -> void :
	for i in range(slots.size() - 1, 0, -1):
		if slots[i].device == device:
			slots.remove_at(i)
			roster_changed.emit()
			return


func reset_to_primary() -> void :
	if slots.size() <= 1:
		return
	slots.resize(1)
	roster_changed.emit()

func _profile_in_use(p: SavedProfile) -> bool:
	for s in slots:
		if s.profile == p:
			return true
	return false


func _next_free_profile() -> SavedProfile:
	for i in range(1, ProfileStore.profiles.size()):
		var p: SavedProfile = ProfileStore.profiles[i]
		if not _profile_in_use(p):
			return p
	return null



func _temp_guest() -> SavedProfile:
	var g: = SavedProfile.new()
	g.name = "Guest"
	g.character = CharacterConfig.random().to_dict()
	return g
