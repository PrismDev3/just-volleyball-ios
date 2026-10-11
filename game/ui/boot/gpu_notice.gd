extends Control












const NEXT_SCENE: = "res://game/ui/boot/boot_intro.tscn"
const DRIVER_URLS: = {
	"amd": "https://www.amd.com/en/support", 
	"intel": "https://www.intel.com/content/www/us/en/download-center/home.html", 
	"nvidia": "https://www.nvidia.com/en-us/drivers/", 
}

var _dont_show: CheckBox = null

func _ready() -> void :
	# Desktop troubleshooting screen: it talks about graphics drivers and launch
	# flags. A phone has neither to offer, so boot straight past it there.
	if GameConfig.gpu_notice_dismissed or OS.has_feature("mobile"):
		GameConfig.goto_scene(NEXT_SCENE)
		return
	_build()

func _build() -> void :
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var back: = ColorRect.new()
	back.color = UiStyle.bg()
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)

	var center: = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card: = PanelContainer.new()
	UiStyle.style_panel(card, UiStyle._AUTO, UiStyle.RADIUS_SOFT)
	center.add_child(card)

	var margin: = MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + s, 24)
	card.add_child(margin)

	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size = Vector2(620, 0)
	margin.add_child(v)

	var title: = Label.new()
	title.text = "notice"
	UiStyle.style_label(title, "title")
	v.add_child(title)

	var intro: = Label.new()
	intro.text = "if you're having trouble entering the game, right click the game on steam, go to properties, and try any of the following launch commands."
	UiStyle.style_label(intro, "body")
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(intro)




	var box: = PanelContainer.new()
	UiStyle.style_panel(box, UiStyle.card().darkened(0.04), UiStyle.RADIUS)
	box.custom_minimum_size = Vector2(620, 300)
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(box)

	var pad: = MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + s, 14)
	box.add_child(pad)

	var scroll: = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pad.add_child(scroll)
	UiStyle.style_scroll(scroll.get_v_scroll_bar())

	var bbox: = VBoxContainer.new()
	bbox.add_theme_constant_override("separation", 8)
	bbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(bbox)

	var gpu: = _adapter_name()
	if gpu != "":
		var gl: = RichTextLabel.new()
		gl.bbcode_enabled = true
		gl.fit_content = true
		gl.scroll_active = false
		gl.add_theme_color_override("default_color", UiStyle.text())
		gl.add_theme_font_override("normal_font", UiStyle.font(UiStyle.FONT_SEMI))
		gl.add_theme_font_override("bold_font", UiStyle.font(UiStyle.FONT_XBOLD))
		gl.add_theme_font_size_override("normal_font_size", 15)
		gl.add_theme_font_size_override("bold_font_size", 15)
		gl.text = "[b]your GPU:[/b] %s" % gpu
		gl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bbox.add_child(gl)

	bbox.add_child(_subhead("amd gpu"))
	bbox.add_child(_cmd_row("--rendering-driver vulkan"))
	bbox.add_child(_subhead("amd / integrated / intel gpu"))
	bbox.add_child(_cmd_row("--rendering-driver opengl3"))
	bbox.add_child(_muted("this will cause the game to render incorrectly, but it will run"))

	var spc: = Control.new()
	spc.custom_minimum_size.y = 6
	bbox.add_child(spc)
	bbox.add_child(_subhead("alternative solutions"))
	var alt: = RichTextLabel.new()
	alt.bbcode_enabled = true
	alt.fit_content = true
	alt.scroll_active = false
	alt.add_theme_color_override("default_color", UiStyle.text())
	alt.add_theme_font_override("normal_font", UiStyle.font(UiStyle.FONT_SEMI))
	alt.add_theme_font_size_override("normal_font_size", 15)
	alt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var link: = UiStyle.SECONDARY.to_html(false)
	alt.text = """if a launch command doesn't help, try updating (or rolling back) your graphics drivers:
""" + "[color=#%s][url=amd]amd drivers[/url][/color]     " % link\
	+ "[color=#%s][url=intel]intel drivers[/url][/color]     " % link\
	+ "[color=#%s][url=nvidia]nvidia drivers[/url][/color]" % link
	alt.meta_clicked.connect(_on_link)
	bbox.add_child(alt)


	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size.y = 52
	_dont_show = CheckBox.new()
	_dont_show.text = "don't show this again"
	UiStyle.style_check(_dont_show)
	_dont_show.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_dont_show)
	var spacer: = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var cont: = Button.new()
	cont.text = "continue"
	UiStyle.style_button(cont, "primary", 16)
	cont.pressed.connect(_on_continue)
	row.add_child(cont)
	v.add_child(row)




	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	cont.grab_focus()
	UiStyle.sfx("open")
	UiStyle.pop_in(card)


func _subhead(text: String) -> Label:
	var l: = Label.new()
	l.text = text
	l.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", UiStyle.text())
	return l


func _muted(text: String) -> Label:
	var l: = Label.new()
	l.text = text
	l.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_SEMI))
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", UiStyle.muted())
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l




func _cmd_row(cmd: String) -> HBoxContainer:
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var lbl: = Label.new()
	lbl.text = cmd
	lbl.add_theme_font_override("font", UiStyle.font(UiStyle.FONT_XBOLD))
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", UiStyle.PRIMARY)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lbl)
	var btn: = Button.new()
	btn.text = "copy"
	UiStyle.style_button(btn, "secondary", 14)
	btn.custom_minimum_size.x = 104
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_on_copy.bind(cmd, btn))
	row.add_child(btn)
	return row

func _on_copy(cmd: String, btn: Button) -> void :
	DisplayServer.clipboard_set(cmd)
	UiStyle.sfx("confirm")
	btn.text = "copied!"
	var tw: = create_tween()
	tw.tween_interval(1.2)
	tw.tween_callback( func(): if is_instance_valid(btn): btn.text = "copy")



func _adapter_name() -> String:
	var n: = String(RenderingServer.get_video_adapter_name())
	if n.strip_edges() == "":
		var info: = OS.get_video_adapter_driver_info()
		if info.size() > 0:
			n = String(info[0])
	return n.strip_edges()

func _on_link(meta: Variant) -> void :
	var key: = String(meta)
	if DRIVER_URLS.has(key):
		OS.shell_open(DRIVER_URLS[key])

func _on_continue() -> void :
	if _dont_show != null and _dont_show.button_pressed:
		GameConfig.gpu_notice_dismissed = true
		GameConfig.save_settings()
	UiStyle.sfx("close")
	GameConfig.goto_scene(NEXT_SCENE)

func _unhandled_key_input(event: InputEvent) -> void :

	var k: = event as InputEventKey
	if k != null and k.pressed and not k.echo\
	and k.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		_on_continue()
