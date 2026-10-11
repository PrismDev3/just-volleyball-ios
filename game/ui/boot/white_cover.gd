extends CanvasLayer







const HOLD_FRAMES: = 3
const LIFT: = 0.45
# Ceiling on how long this cover waits for the scene behind it to arrive, so a
# load that never finishes cannot leave the player on a blank white screen.
const MAX_HOLD: = 20.0

var _white: ColorRect

func _init() -> void :
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_white = ColorRect.new()
	_white.color = Color.WHITE
	_white.set_anchors_preset(Control.PRESET_FULL_RECT)
	_white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_white)

func _ready() -> void :
	# The boot intro raises this cover and starts the scene change in the same
	# frame, so the cover is what the player looks at while the next scene loads.
	# Lifting after a fixed number of frames showed the intro's black last frame
	# for however long the load still had to run; hold until it has landed.
	var started: = Time.get_ticks_msec()
	for i in HOLD_FRAMES:
		await get_tree().process_frame
	while GameConfig.scene_change_pending()\
	and float(Time.get_ticks_msec() - started) / 1000.0 < MAX_HOLD:
		await get_tree().process_frame
	var t: = create_tween().set_ignore_time_scale(true)
	t.tween_property(_white, "color:a", 0.0, LIFT)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_callback(queue_free)
