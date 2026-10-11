class_name ChatBubbles
extends Node












var bodies: Callable = Callable()
var local: Callable = Callable()
var active: Callable = Callable()




var body_for_peer: Callable = Callable()
var _typing_names: Array = []

func _init(bodies_in: Callable, local_in: = Callable(), active_in: = Callable(), 
		body_for_peer_in: = Callable()) -> void :
	bodies = bodies_in
	local = local_in
	active = active_in
	body_for_peer = body_for_peer_in

func _on() -> bool:
	if not GameConfig.chat_enabled or not GameConfig.chat_bubbles:
		return false
	if active.is_valid():
		var r: Variant = active.call()
		return r is bool and r
	return true

func _local_body() -> Node3D:
	if not local.is_valid():
		return null
	var b: Variant = local.call()
	return b if (b is Node3D and is_instance_valid(b)) else null

func _ready() -> void :
	Net.chat.connect(_on_chat)
	Net.typing_changed.connect(_on_typing)

func _exit_tree() -> void :
	if Net.chat.is_connected(_on_chat):
		Net.chat.disconnect(_on_chat)
	if Net.typing_changed.is_connected(_on_typing):
		Net.typing_changed.disconnect(_on_typing)

func _body_named(name: String) -> Node3D:

	if name != "" and name == Net.my_name:
		var me: = _local_body()
		if me != null:
			return me
	if not bodies.is_valid() or name == "":
		return null
	var list: Variant = bodies.call()
	if not (list is Array):
		return null
	for b in list:
		if b == null or not is_instance_valid(b):
			continue
		if b.has_method("display_name") and String(b.display_name()) == name:
			return b
	return null

func _on_chat(entry: Dictionary) -> void :
	if not _on():
		return
	var body: Node3D = null
	var pid: = int(entry.get("p", -1))
	if pid == Net.multiplayer.get_unique_id():
		body = _local_body()


	if body == null and body_for_peer.is_valid() and pid >= 0:
		var b: Variant = body_for_peer.call(pid)
		if b is Node3D and is_instance_valid(b):
			body = b
	if body == null:
		body = _body_named(String(entry.get("n", "")))
	if body == null:
		return
	var msg: = String(entry.get("m", ""))
	if GameConfig.chat_filter:
		msg = ChatFilter.clean(msg)
	if msg.strip_edges() == "":
		return
	BubbleChat.attach(body).add_message(msg, String(entry.get("ch", "all")) == "team")

func _on_typing(names: Array) -> void :
	if not _on():
		names = []

	for n in _typing_names:
		if not n in names:
			var b: = _body_named(String(n))
			if b != null:
				BubbleChat.attach(b).hide_typing()
	for n in names:
		if not n in _typing_names:
			var b: = _body_named(String(n))
			if b != null:
				BubbleChat.attach(b).show_typing()
	_typing_names = names.duplicate()
