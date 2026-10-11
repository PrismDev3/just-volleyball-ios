extends CanvasLayer










const LAYER: = 110
const DARKEN: = 0.55
const DARKEN_TIME: = 0.45
const LIFT: = 0.25



const HATCH_AFTER: = 20.0

static var _live: CanvasLayer = null

var _shot: TextureRect
var _dark: ColorRect
var _label: Label
var _hatch: Label
var _t: = 0.0
var _leaving: = false


static func hold(tree: SceneTree) -> void :
	if _live != null and is_instance_valid(_live):
		return
	var cover: CanvasLayer = (load("res://game/ui/migration_cover.gd") as GDScript).new()
	var img: Image = tree.root.get_viewport().get_texture().get_image()
	if img != null:
		cover.call("set_shot", ImageTexture.create_from_image(img))
	_live = cover
	tree.root.add_child(cover)


static func dismiss() -> bool:
	if _live == null or not is_instance_valid(_live):
		_live = null
		return false
	var cover: = _live
	_live = null
	cover.call("_lift")
	return true

static func is_up() -> bool:
	return _live != null and is_instance_valid(_live)

func _init() -> void :
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_shot = TextureRect.new()
	_shot.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shot.stretch_mode = TextureRect.STRETCH_SCALE
	_shot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shot)
	_dark = ColorRect.new()
	_dark.color = Color(0.0, 0.0, 0.0, 0.0)
	_dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dark)
	_label = Label.new()
	_label.text = "host has quit, migration in progress..."
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_label.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	_label.add_theme_font_size_override("font_size", 34)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("outline_size", 10)
	_label.modulate.a = 0.0
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_hatch = Label.new()
	_hatch.text = "taking too long? press esc to return to the menu"
	_hatch.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hatch.set_anchors_preset(Control.PRESET_CENTER)
	_hatch.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hatch.grow_vertical = Control.GROW_DIRECTION_BOTH
	_hatch.offset_top = 64.0
	_hatch.offset_bottom = 64.0
	_hatch.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	_hatch.add_theme_font_size_override("font_size", 18)
	_hatch.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_hatch.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_hatch.add_theme_constant_override("outline_size", 8)
	_hatch.modulate.a = 0.0
	_hatch.visible = false
	_hatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hatch)

func _process(delta: float) -> void :
	_t += delta
	if _t >= HATCH_AFTER and not _hatch.visible:
		_hatch.visible = true
		create_tween().set_ignore_time_scale(true)\
		.tween_property(_hatch, "modulate:a", 1.0, 0.4)

func _unhandled_input(event: InputEvent) -> void :
	if not _hatch.visible or _leaving:
		return
	if event.is_action_pressed("ui_cancel"):
		_leaving = true
		get_viewport().set_input_as_handled()

		if Net.active:
			Net.leave()
		GameConfig.migrate_carry = {}
		GameConfig.lobby_notice = "left the migration"
		_live = null
		_lift()
		GameConfig.call_deferred("goto_scene", "res://game/ui/menu.tscn")

func set_shot(tex: Texture2D) -> void :
	_shot.texture = tex

func _ready() -> void :


	var t: = create_tween().set_ignore_time_scale(true)
	t.tween_property(_dark, "color:a", DARKEN, DARKEN_TIME)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(_label, "modulate:a", 1.0, 0.3)

func _lift() -> void :
	var t: = create_tween().set_ignore_time_scale(true)
	t.tween_property(_shot, "modulate:a", 0.0, LIFT)
	t.parallel().tween_property(_dark, "color:a", 0.0, LIFT)
	t.parallel().tween_property(_label, "modulate:a", 0.0, LIFT)
	t.tween_callback(queue_free)
