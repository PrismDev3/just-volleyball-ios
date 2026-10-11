extends Node















const SPEED: = 1500.0
const DEADZONE: = 0.2

var enabled: = false
var _active: = false
var _pos: = Vector2.ZERO

func _process(delta: float) -> void :
	var want: = enabled and InputPrompts.using_gamepad()
	var vp: = get_viewport()
	if vp == null:
		return
	if want and not _active:
		_pos = vp.get_mouse_position()
	_active = want
	if not _active:
		return
	var stick: = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if stick.length() > DEADZONE:
		_pos += stick * SPEED * delta
		_pos = _pos.clamp(Vector2.ZERO, vp.get_visible_rect().size)
		vp.warp_mouse(_pos)

func _input(event: InputEvent) -> void :
	if not _active:
		return


	if event.is_action_pressed("ui_accept"):
		_mouse(true)
	elif event.is_action_released("ui_accept"):
		_mouse(false)

func _mouse(pressed: bool) -> void :
	var ev: = InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = _pos
	ev.global_position = _pos
	get_viewport().push_input(ev)
