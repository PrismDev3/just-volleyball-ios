extends Node


















const DIM: = Color(0, 0, 0, 0.55)
const UNLOCK_GREEN: = Color(0.3, 0.72, 0.42)
const HINT_LOCKED: = "please read and scroll to the bottom to continue"
const HINT_UNLOCKED: = "after carefully reading, please accept or deny"

const TERMS_BODY: = "[b]just volleyball online agreement[/b]\n\nby playing online in just volleyball, you agree to the terms below, and confirm that you are at least 13 years of age, in accordance with the steam subscriber agreement. please read everything in detail, then choose whether or not you accept. if you disagree with these terms and are unable to play the game as a result, please contact steam support.\n\n[b]1. respect your fellow player[/b]\nno harassment, hate speech, or personal attacks of any kind, including those based on gender, sexual orientation, disability, appearance, ethnicity, or beliefs. sexually explicit, graphic, or otherwise inappropriate content is also not permitted. treat others with courtesy. use appropriate language, and respect people's boundaries and opinions. do not impersonate temkosoft, our staff, or other players in an attempt to mislead anyone. do not spam, advertise, or attempt to lead anyone off-platform for any reason. this applies everywhere online play reaches, including server and lobby names, the chat system, and anything you personalize, such as created characters and usernames.\n\n[b]2. fair play for all[/b]\ncheating, exploiting bugs, or doing anything to gain an unfair advantage or ruin the experience for others is strictly prohibited. this includes third-party tools, modifications, or scripts that interfere with normal play. play by the rules so everyone can have fun.\n\n[b]3. game modifications[/b]\nto avoid unexpected interference with online play, modifying the game is strictly prohibited while playing online. this keeps everyone on equal terms so the experience stays fair for all.\n\n[b]4. online connectivity[/b]\nthe quality and stability of online play depend on your internet connection and on the host staying online. sessions may end unexpectedly, freeze, or crash, and uninterrupted service is not guaranteed. a strong, stable connection is recommended, especially when hosting a server.\n\n[b]5. personal data[/b]\nduring online play, basic information such as your steam name, lobby activity, and in-game actions may be visible to other players and used to run multiplayer features and enforce these rules. if you have linked your discord account, the same applies to the information it shares.\n\n[b]6. change is good[/b]\nthese terms may be updated or changed at any time. when that happens, a notice will be issued and you will be asked to review this agreement again. continuing to play online after an update means you accept the updated terms.\n\n[b]7. enforcement & acceptance[/b]\nif you are found to be acting against this agreement, whether determined by temkosoft or by a party approved by temkosoft, you may face restrictions on online play. these restrictions may be temporary or permanent depending on the nature and severity of the breach. temkosoft, or any party approved by temkosoft, may also restrict or prohibit your access to online play for any reason deemed necessary, even if that reason is not explicitly stated in these terms. by pressing \"i accept these terms\", you confirm that you have read and agree to everything written above, and you acknowledge that you may lose access to online play as a result of your own actions.\n\nthank you for helping keep your fellow players safe. welcome to the just volleyball community!"


























var _popup: CanvasLayer = null
var _pending_accept: Callable = Callable()
var _card: PanelContainer = null
var _terms: RichTextLabel = null
var _hint: Label = null
var _accept_btn: Button = null
var _decline_btn: Button = null
var _unlocked: = false



func has_accepted() -> bool:
	return GameConfig.has_accepted_online_terms()






func require(on_accept: Callable) -> bool:
	if has_accepted():
		return true
	_pending_accept = on_accept
	_show()
	return false


func is_open() -> bool:
	return _popup != null and is_instance_valid(_popup)


func _show() -> void :
	if is_open():
		return
	var tree: = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	_unlocked = false
	_popup = CanvasLayer.new()
	_popup.layer = 97

	var scrim: = ColorRect.new()
	scrim.color = DIM
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_popup.add_child(scrim)

	var center: = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_popup.add_child(center)

	_card = PanelContainer.new()
	UiStyle.style_panel(_card, UiStyle._AUTO, UiStyle.RADIUS_SOFT)
	center.add_child(_card)

	var margin: = MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + s, 22)
	_card.add_child(margin)

	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size = Vector2(560, 0)
	margin.add_child(v)

	var title: = Label.new()
	title.text = "online play agreement"
	UiStyle.style_label(title, "title")
	v.add_child(title)


	var panel: = PanelContainer.new()
	UiStyle.style_panel(panel, UiStyle.card().darkened(0.04), UiStyle.RADIUS)
	panel.custom_minimum_size = Vector2(560, 320)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(panel)

	var pad: = MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + s, 12)
	panel.add_child(pad)

	_terms = RichTextLabel.new()
	_terms.bbcode_enabled = true
	_terms.fit_content = false
	_terms.scroll_active = true
	_terms.text = TERMS_BODY
	_terms.add_theme_color_override("default_color", UiStyle.text())
	_terms.add_theme_font_override("normal_font", UiStyle.font(UiStyle.FONT_SEMI))
	_terms.add_theme_font_override("bold_font", UiStyle.font(UiStyle.FONT_XBOLD))
	_terms.add_theme_font_size_override("normal_font_size", 15)
	_terms.add_theme_font_size_override("bold_font_size", 16)
	pad.add_child(_terms)
	var sb: = _terms.get_v_scroll_bar()
	if sb != null:
		UiStyle.style_scroll(sb)
		sb.value_changed.connect( func(_v): _check_bottom())

	_hint = Label.new()
	_hint.text = HINT_LOCKED
	UiStyle.style_label(_hint, "body")


	_hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	_hint.clip_text = true
	_hint.custom_minimum_size.y = 24
	v.add_child(_hint)

	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)




	row.custom_minimum_size.y = 56
	_decline_btn = Button.new()
	_decline_btn.text = "i do not accept"
	UiStyle.style_button(_decline_btn, "tertiary", 16)
	_decline_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_decline_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_decline_btn.pressed.connect(_on_decline)
	row.add_child(_decline_btn)
	_accept_btn = Button.new()
	_accept_btn.text = "i accept these terms"
	UiStyle.style_button(_accept_btn, "primary", 16)
	_accept_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_accept_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_accept_btn.pressed.connect(_on_accept)
	row.add_child(_accept_btn)
	v.add_child(row)

	tree.root.add_child(_popup)
	_set_unlocked(false)
	UiStyle.sfx("open")


	_check_bottom.call_deferred()
	await tree.process_frame
	await tree.process_frame
	if is_open():
		UiStyle.pop_in(_card)
		_check_bottom()


func _check_bottom() -> void :
	if _unlocked or not is_open() or _terms == null:
		return
	var sb: = _terms.get_v_scroll_bar()
	if sb == null:
		return
	var scrollable: bool = sb.max_value - sb.page > 1.0
	var at_bottom: bool = sb.value >= sb.max_value - sb.page - 4.0
	if not scrollable or at_bottom:
		_unlocked = true
		_set_unlocked(true)


func _set_unlocked(on: bool) -> void :
	if _accept_btn == null:
		return
	_accept_btn.disabled = not on
	_accept_btn.modulate.a = 1.0 if on else 0.45
	_accept_btn.mouse_default_cursor_shape = \
	Control.CURSOR_POINTING_HAND if on else Control.CURSOR_ARROW
	if _hint != null:
		if on:
			_hint.text = HINT_UNLOCKED
			_hint.add_theme_color_override("font_color", UNLOCK_GREEN)
		else:
			_hint.text = HINT_LOCKED
			_hint.add_theme_color_override("font_color", UiStyle.muted())


func _on_accept() -> void :
	if _accept_btn != null and _accept_btn.disabled:
		return
	var cb: = _pending_accept
	_close()
	GameConfig.accept_online_terms()
	if Achievements != null and Achievements.has_method("notify"):
		Achievements.notify("tos_accepted")
	if cb.is_valid():
		cb.call()


func _on_decline() -> void :

	_close()


func _close() -> void :
	UiStyle.sfx("close")
	_pending_accept = Callable()
	_unlocked = false
	_card = null
	_terms = null
	_hint = null
	_accept_btn = null
	_decline_btn = null
	if is_open():
		_popup.queue_free()
	_popup = null
