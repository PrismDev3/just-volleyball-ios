class_name BubbleChat
extends Node3D












const HEAD_Y: = 2.3
const TEAM_COLOR: = Color(0.65, 0.85, 1.0)

@export var bubble_lifetime: = 4.5
@export var bubble_spacing: = 0.55
@export var max_bubbles: = 3
@export var fade_duration: = 0.25
@export var typing_animation_speed: = 0.4
@export var enable_typewriter: = true
@export var typewriter_speed: = 0.035


@export var max_characters: = 40
@export var font_size: = 26
@export var padding_horizontal: = 18
@export var padding_vertical: = 12
@export var corner_radius: = 20
@export var pixel_size: = 0.0058
@export var max_bubble_width: = 380
@export var arrow_width: = 18
@export var arrow_height: = 12

var active_bubbles: Array = []
var typing_bubble: Dictionary = {}
var _typing_timer: = 0.0
var _typing_dots: = 1
var _font: Font = null

static func attach(body: Node3D) -> BubbleChat:
	var existing: = body.get_node_or_null("BubbleChat")
	if existing is BubbleChat:
		return existing
	var b: = BubbleChat.new()
	b.name = "BubbleChat"
	b.position = Vector3(0.0, HEAD_Y, 0.0)
	body.add_child(b)
	return b

func _ready() -> void :
	_font = UiStyle.font(UiStyle.FONT_SEMI)

	top_level = false

func _process(delta: float) -> void :
	if not typing_bubble.is_empty() and typing_bubble.has("label"):
		var label: Label = typing_bubble.label
		if is_instance_valid(label):
			_typing_timer += delta
			if _typing_timer >= typing_animation_speed:
				_typing_timer = 0.0
				_typing_dots = _typing_dots % 3 + 1
				label.text = ".".repeat(_typing_dots)
	for i in range(active_bubbles.size() - 1, -1, -1):
		var b: Dictionary = active_bubbles[i]
		if not is_instance_valid(b.sprite):
			active_bubbles.remove_at(i)
			continue
		if enable_typewriter and b.is_typing:
			b.typewriter_timer += delta
			if b.typewriter_timer >= typewriter_speed:
				b.typewriter_timer = 0.0
				b.typewriter_progress += 1
				if b.typewriter_progress <= b.message.length():
					b.label.text = b.message.substr(0, b.typewriter_progress)
				else:
					b.is_typing = false
					b.label.text = b.message
		if not b.is_typing:


			if not b.get("frozen", false) and is_instance_valid(b.viewport):
				b.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
				b["frozen"] = true
			b.timer -= delta
			if b.timer <= fade_duration:
				b.sprite.modulate.a = maxf(b.timer / fade_duration, 0.0)
			if b.timer <= 0.0:
				b.sprite.queue_free()
				active_bubbles.remove_at(i)
				_reposition()






func add_message(message: String, team: = false) -> void :
	hide_typing()
	if message.length() > max_characters:
		message = message.substr(0, max_characters) + "..."
	if active_bubbles.size() >= max_bubbles:
		var oldest: Dictionary = active_bubbles.pop_front()
		if is_instance_valid(oldest.sprite):
			oldest.sprite.queue_free()
	var b: = _create_bubble(message, false, team)
	b["timer"] = bubble_lifetime
	b["typewriter_progress"] = 0
	b["typewriter_timer"] = 0.0
	b["is_typing"] = enable_typewriter
	active_bubbles.append(b)
	_reposition()

func show_typing() -> void :
	if not typing_bubble.is_empty():
		return
	typing_bubble = _create_bubble("...", true)
	_typing_timer = 0.0
	_typing_dots = 1
	_reposition()

func hide_typing() -> void :
	if typing_bubble.is_empty():
		return
	if is_instance_valid(typing_bubble.sprite):
		var sprite: Sprite3D = typing_bubble.sprite
		var t: = create_tween()
		t.tween_property(sprite, "modulate:a", 0.0, 0.2)
		t.tween_callback(sprite.queue_free)
	typing_bubble = {}
	_reposition()

func clear_all() -> void :
	hide_typing()
	for b in active_bubbles:
		if is_instance_valid(b.sprite):
			b.sprite.queue_free()
	active_bubbles.clear()



func _create_bubble(message: String, is_typing_indicator: bool, team: = false) -> Dictionary:
	var sprite: = Sprite3D.new()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.pixel_size = pixel_size
	sprite.transparent = true
	sprite.no_depth_test = true
	sprite.render_priority = 10
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sprite)
	var display_text: = "..." if is_typing_indicator else message
	var sz: = _calculate_size(display_text, is_typing_indicator)
	var viewport: = SubViewport.new()
	viewport.transparent_bg = true
	viewport.size = sz.viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sprite.add_child(viewport)
	var panel: = PanelContainer.new()
	panel.position = sz.panel_position
	panel.custom_minimum_size = sz.panel_size
	panel.size = sz.panel_size
	var bg: = Color.WHITE
	var ink: = Color.BLACK
	var sb: = StyleBoxFlat.new()
	sb.bg_color = bg
	if team:
		sb.border_color = TEAM_COLOR
		sb.set_border_width_all(4)
	sb.set_corner_radius_all(corner_radius)
	sb.content_margin_left = padding_horizontal
	sb.content_margin_right = padding_horizontal
	sb.content_margin_top = padding_vertical
	sb.content_margin_bottom = padding_vertical
	sb.shadow_color = Color(0, 0, 0, 0.14)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	panel.add_theme_stylebox_override("panel", sb)
	viewport.add_child(panel)
	var lbl: = Label.new()
	lbl.text = "" if ( not is_typing_indicator and enable_typewriter) else display_text
	lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", ink)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if sz.needs_wrap:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size.x = sz.text_width
	panel.add_child(lbl)
	if not is_typing_indicator:
		var cx: float = sz.panel_position.x + sz.panel_size.x / 2.0
		var top: float = sz.panel_position.y + sz.panel_size.y
		var tail: = Polygon2D.new()
		tail.polygon = PackedVector2Array([Vector2( - arrow_width / 2.0, 0), 
			Vector2(arrow_width / 2.0, 0), Vector2(0, arrow_height)])
		tail.position = Vector2(cx, top - 1.0)
		tail.color = bg
		viewport.add_child(tail)
	sprite.texture = viewport.get_texture()
	sprite.offset.y = - sz.viewport_size.y / 2.0
	var data: = {"sprite": sprite, "viewport": viewport, "panel": panel, 
		"label": lbl, "message": message}
	sprite.scale = Vector3.ZERO
	var t: = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(sprite, "scale", Vector3.ONE, 0.3)
	return data

func _calculate_size(text: String, is_typing: bool) -> Dictionary:
	if text.length() == 0:
		text = "..."
	var measured: = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var max_text_width: = max_bubble_width - padding_horizontal * 2
	var text_width: float
	var text_height: float
	var needs_wrap: = false
	if measured > max_text_width:
		needs_wrap = true
		text_width = float(max_text_width)
		var tmp: = Label.new()
		tmp.add_theme_font_override("font", _font)
		tmp.add_theme_font_size_override("font_size", font_size)
		tmp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tmp.custom_minimum_size.x = text_width
		tmp.text = text
		add_child(tmp)
		tmp.size.x = text_width
		var lines: = tmp.get_line_count()
		tmp.queue_free()
		text_height = font_size * 1.4 * lines
	else:
		text_width = measured
		text_height = font_size * 1.4
	var panel_size: = Vector2(text_width + padding_horizontal * 2, 
		text_height + padding_vertical * 2)
	var margin: = 24
	var extra: = 0 if is_typing else arrow_height
	var viewport_size: = Vector2i(int(panel_size.x) + margin * 2, 
		int(panel_size.y) + margin * 2 + extra)
	return {"text_width": text_width, "text_height": text_height, 
		"panel_size": panel_size, "viewport_size": viewport_size, 
		"panel_position": Vector2(margin, margin), "needs_wrap": needs_wrap}


func _reposition() -> void :
	var y: = 0.0
	if not typing_bubble.is_empty() and is_instance_valid(typing_bubble.sprite):
		typing_bubble.sprite.position.y = y
		y += bubble_spacing
	for i in range(active_bubbles.size() - 1, -1, -1):
		var b: Dictionary = active_bubbles[i]
		if is_instance_valid(b.sprite):
			b.sprite.position.y = y
			y += bubble_spacing
