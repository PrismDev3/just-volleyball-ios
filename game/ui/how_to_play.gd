class_name HowToPlay
extends VBoxContainer




















const ACTION_LABELS: = [
	["move_forward", "move"], 
	["contact", "bump / set / spikehold to charge"], 
	["jump", "jumphold to charge"], 
	["dive", "dive"], 
	["strafe", "strafehold to brake and lock facing"], 
	["serve", "serve"], 
	["camera_toggle", "change camera"], 
	["stats", "hold for the scoreboard"], 
]

const MOVE_ACTIONS: = ["move_forward", "move_left", "move_back", "move_right"]



static func keys_for(action: String) -> String:
	if action == "move":
		return _keys_for_all(MOVE_ACTIONS)
	if action == "@mouse":
		return "mouse"
	return _keys_for(action)

func _ready() -> void :

	process_mode = Node.PROCESS_MODE_ALWAYS
	_fill_controls()


	UiStyle.wash(self)

func _fill_controls() -> void :



	var rows: = find_child("Rows", true, false)
	if rows == null:
		return
	for child in rows.get_children():
		child.queue_free()
	for entry in ACTION_LABELS:
		var action: String = entry[0]
		var keys: = _keys_for(action) if action != "move_forward"\
		else _keys_for_all(MOVE_ACTIONS)
		if keys == "":
			continue
		rows.add_child(_row(keys, String(entry[1])))

func _row(keys: String, what: String) -> HBoxContainer:
	var box: = HBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	var key: = Label.new()
	key.text = keys
	key.custom_minimum_size = Vector2(150.0, 0.0)
	key.add_theme_font_size_override("font_size", 18)
	key.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	box.add_child(key)
	var label: = Label.new()
	label.text = what
	label.add_theme_font_size_override("font_size", 18)
	box.add_child(label)
	return box



static func _keys_for_all(actions: Array) -> String:
	var out: Array[String] = []
	for a in actions:
		var k: = _keys_for(String(a))
		if k != "":
			out.append(k)
	return " ".join(out)



static func _keys_for(action: String) -> String:
	if not InputMap.has_action(action):
		return ""
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key: = event as InputEventKey
			var code: = key.physical_keycode if key.physical_keycode != 0\
			else key.keycode
			return OS.get_keycode_string(code).to_lower()
		if event is InputEventMouseButton:
			match (event as InputEventMouseButton).button_index:
				MOUSE_BUTTON_LEFT:
					return "lmb"
				MOUSE_BUTTON_RIGHT:
					return "rmb"
				MOUSE_BUTTON_MIDDLE:
					return "mmb"
	return ""
