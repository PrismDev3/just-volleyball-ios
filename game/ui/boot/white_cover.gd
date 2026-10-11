extends CanvasLayer







const HOLD_FRAMES: = 3
const LIFT: = 0.45

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
	for i in HOLD_FRAMES:
		await get_tree().process_frame
	var t: = create_tween().set_ignore_time_scale(true)
	t.tween_property(_white, "color:a", 0.0, LIFT)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_callback(queue_free)
