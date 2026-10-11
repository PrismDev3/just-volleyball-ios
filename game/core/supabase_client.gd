extends Node

signal auth_ready(user_id: String)
signal auth_failed(reason: String)
signal lobbies_received(rows: Array)
signal room_message(kind: String, payload: Dictionary)
signal room_joined
signal lobby_created(row: Dictionary)
signal lobby_resolved(row: Dictionary)
signal lobby_error(reason: String)

const PROJECT_URL := "https://htpanugrdgzqqrqzzqby.supabase.co"
const PUBLISHABLE_KEY := "sb_publishable_h59b4u7e57pb4SjprtIDmw_zeLurSac"
const SESSION_PATH := "user://supabase_session.json"
const PROFILE_TABLE := "/rest/v1/profiles"
const LOBBY_TABLE := "/rest/v1/lobbies"
const MAX_LOBBIES := 50
const STALE_SECONDS := 45

var user_id := ""
var access_token := ""
var refresh_token := ""
var is_ready := false
var last_error := ""
var _loading_cloud := false
var _save_pending := false
var _save_due_msec := 0
var _lobby_heartbeat_msec := 0
var _lobby_room := ""
var _realtime: WebSocketPeer
var _realtime_topic := ""
var _realtime_joined := false
var _realtime_ref := 1
var _heartbeat_due_msec := 0
var _room_outbox: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ProfileStore.changed.connect(_on_profile_changed)
	call_deferred("_start")

func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	if _save_pending and now >= _save_due_msec and is_ready:
		_save_pending = false
		_cloud_save_profile()
	if _lobby_room != "" and is_ready and now >= _lobby_heartbeat_msec:
		_lobby_heartbeat_msec = now + 15000
		_touch_lobby()
	if _realtime != null:
		_poll_realtime(now)

func _start() -> void:
	if not _load_session() or not await _refresh_session():
		if not await _sign_in_guest():
			auth_failed.emit(last_error)
			return
	is_ready = true
	auth_ready.emit(user_id)
	await _load_cloud_profile_if_fresh()
	_cloud_save_profile()

func _headers(with_auth := true) -> PackedStringArray:
	var out := PackedStringArray([
		"apikey: " + PUBLISHABLE_KEY,
		"Content-Type: application/json",
	])
	if with_auth and access_token != "":
		out.append("Authorization: Bearer " + access_token)
	return out

func _http(method: int, path: String, data: Variant = null, extra_headers: PackedStringArray = PackedStringArray()) -> Dictionary:
	var req := HTTPRequest.new()
	req.timeout = 20.0
	add_child(req)
	var headers := _headers()
	headers.append_array(extra_headers)
	var body := "" if data == null else JSON.stringify(data)
	var err := req.request(PROJECT_URL + path, headers, method, body)
	if err != OK:
		req.queue_free()
		return {"code": 0, "body": {"message": "request start failed: %s" % error_string(err)}}
	var result: Array = await req.request_completed
	req.queue_free()
	var parsed: Variant = JSON.parse_string((result[3] as PackedByteArray).get_string_from_utf8())
	return {"code": int(result[1]), "body": parsed if parsed != null else {}}

func _load_session() -> bool:
	if not FileAccess.file_exists(SESSION_PATH):
		return false
	var file := FileAccess.open(SESSION_PATH, FileAccess.READ)
	if file == null:
		return false
	var value: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not value is Dictionary:
		return false
	access_token = String(value.get("access_token", ""))
	refresh_token = String(value.get("refresh_token", ""))
	user_id = String(value.get("user_id", ""))
	return refresh_token != "" and user_id != ""

func _persist_session() -> void:
	var file := FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({
			"access_token": access_token,
			"refresh_token": refresh_token,
			"user_id": user_id,
		}))
		file.close()

func _accept_auth(body: Dictionary) -> bool:
	access_token = String(body.get("access_token", ""))
	refresh_token = String(body.get("refresh_token", ""))
	var user: Variant = body.get("user", {})
	user_id = String(user.get("id", "")) if user is Dictionary else ""
	if access_token == "" or refresh_token == "" or user_id == "":
		last_error = String(body.get("msg", body.get("message", "Supabase returned an incomplete guest session")))
		return false
	_persist_session()
	return true

func _refresh_session() -> bool:
	if refresh_token == "":
		return false
	var result := await _http(HTTPClient.METHOD_POST,
		"/auth/v1/token?grant_type=refresh_token", {"refresh_token": refresh_token},
		PackedStringArray())
	if int(result.code) < 200 or int(result.code) >= 300:
		return false
	return _accept_auth(result.body as Dictionary)

func _sign_in_guest() -> bool:
	var local_name := "player"
	var profile: SavedProfile = ProfileStore.active()
	if profile != null:
		local_name = profile.name
	var result := await _http(HTTPClient.METHOD_POST, "/auth/v1/signup", {
		"data": {"display_name": local_name},
	})
	if int(result.code) < 200 or int(result.code) >= 300:
		last_error = String(result.body.get("msg", result.body.get("message", "Guest sign-in failed")))
		return false
	return _accept_auth(result.body as Dictionary)

func _profile_file_data() -> Dictionary:
	var path := AppData.path(ProfileStore.FILE)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return value if value is Dictionary else {}

func _on_profile_changed() -> void:
	if _loading_cloud or not is_ready:
		return
	_save_pending = true
	_save_due_msec = Time.get_ticks_msec() + 1800

func queue_profile_save() -> void:
	_on_profile_changed()

func _cloud_save_profile() -> void:
	if not is_ready or user_id == "":
		return
	var profile: SavedProfile = ProfileStore.active()
	var display_name := profile.name if profile != null else "player"
	var payload := {
		"user_id": user_id,
		"display_name": display_name,
		"save_data": {"format": 1, "profiles_file": _profile_file_data()},
		"updated_at": Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system()), true) + "+00:00",
	}
	var result := await _http(HTTPClient.METHOD_POST,
		PROFILE_TABLE + "?on_conflict=user_id", payload,
		PackedStringArray(["Prefer: resolution=merge-duplicates,return=minimal"]))
	if int(result.code) < 200 or int(result.code) >= 300:
		last_error = String(result.body.get("message", "cloud save failed"))

func _load_cloud_profile_if_fresh() -> void:
	if not ProfileStore.seeded_fresh:
		return
	var result := await _http(HTTPClient.METHOD_GET,
		PROFILE_TABLE + "?select=save_data&user_id=eq." + user_id.uri_encode() + "&limit=1")
	if int(result.code) < 200 or int(result.code) >= 300 or not result.body is Array or result.body.is_empty():
		return
	var save_data: Variant = result.body[0].get("save_data", {})
	if not save_data is Dictionary:
		return
	var snapshot: Variant = save_data.get("profiles_file", {})
	if not snapshot is Dictionary or snapshot.is_empty():
		return
	_loading_cloud = true
	AppData.ensure()
	var file := FileAccess.open(AppData.path(ProfileStore.FILE), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(snapshot, "\t"))
		file.close()
		ProfileStore._load()
		ProfileStore.seeded_fresh = false
		var active: SavedProfile = ProfileStore.active()
		if active != null:
			ProfileStore._apply_profile(active)
		ProfileStore.changed.emit()
	_loading_cloud = false

func list_lobbies() -> void:
	if not is_ready:
		lobbies_received.emit([])
		return
	var cutoff := Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system()) - STALE_SECONDS, true) + "+00:00"
	var query := "?select=id,owner,room,name,kind,state,stage,mode,humans,cap,priv,locked,proto,host_name,updated_at&updated_at=gte." + cutoff.uri_encode() + "&order=updated_at.desc&limit=" + str(MAX_LOBBIES)
	var result := await _http(HTTPClient.METHOD_GET, LOBBY_TABLE + query)
	if int(result.code) >= 200 and int(result.code) < 300 and result.body is Array:
		lobbies_received.emit(result.body)
	else:
		last_error = String(result.body.get("message", "lobby list failed"))
		lobbies_received.emit([])

func resolve_lobby(room: String) -> void:
	if not is_ready or room == "":
		lobby_resolved.emit({})
		return
	var result := await _http(HTTPClient.METHOD_GET,
		LOBBY_TABLE + "?select=room,owner&room=eq." + room.uri_encode() + "&limit=1")
	if int(result.code) >= 200 and int(result.code) < 300 and result.body is Array and not result.body.is_empty():
		lobby_resolved.emit(result.body[0])
	else:
		last_error = String(result.body.get("message", "court code not found"))
		lobby_resolved.emit({})

func publish_lobby(room: String, name: String, stage: String, mode: String, capacity: int, privacy: String) -> void:
	_lobby_room = room
	var result := await _http(HTTPClient.METHOD_POST, LOBBY_TABLE, {
		"room": room,
		"name": name,
		"kind": "custom",
		"state": "lobby",
		"stage": stage,
		"mode": mode,
		"humans": 1,
		"cap": capacity,
		"priv": privacy,
		"locked": false,
		"proto": 16,
		"host_name": name,
	}, PackedStringArray(["Prefer: return=representation"]))
	if int(result.code) >= 200 and int(result.code) < 300 and result.body is Array and not result.body.is_empty():
		lobby_created.emit(result.body[0])
		_lobby_heartbeat_msec = Time.get_ticks_msec() + 15000
	else:
		_lobby_room = ""
		last_error = String(result.body.get("message", "couldn't publish lobby"))
		lobby_error.emit(last_error)

func update_lobby(fields: Dictionary) -> void:
	if _lobby_room == "" or not is_ready:
		return
	var result := await _http(HTTPClient.METHOD_PATCH,
		LOBBY_TABLE + "?owner=eq." + user_id.uri_encode() + "&room=eq." + _lobby_room.uri_encode(), fields)
	if int(result.code) < 200 or int(result.code) >= 300:
		last_error = String(result.body.get("message", "lobby update failed"))

func _touch_lobby() -> void:
	update_lobby({"updated_at": Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system()), true) + "+00:00"})

func close_lobby() -> void:
	if _lobby_room != "" and is_ready:
		var room := _lobby_room
		_lobby_room = ""
		_http(HTTPClient.METHOD_DELETE, LOBBY_TABLE + "?owner=eq." + user_id.uri_encode() + "&room=eq." + room.uri_encode())
	leave_room()

func join_room(room: String) -> void:
	leave_room()
	if not is_ready:
		return
	_realtime_topic = "realtime:" + room
	_realtime = WebSocketPeer.new()
	var ws_url := PROJECT_URL.replace("https://", "wss://") + "/realtime/v1/websocket?apikey=" + PUBLISHABLE_KEY.uri_encode() + "&vsn=1.0.0"
	var err := _realtime.connect_to_url(ws_url)
	if err != OK:
		_realtime = null
		last_error = "signaling connection failed: %s" % error_string(err)
		return
	_realtime_joined = false
	_room_outbox.clear()
	_realtime_ref = 1

func realtime_ready() -> bool:
	return _realtime_joined

func leave_room() -> void:
	if _realtime != null:
		if _realtime.get_ready_state() == WebSocketPeer.STATE_OPEN and _realtime_joined:
			_send_realtime({"topic": _realtime_topic, "event": "phx_leave", "payload": {}, "ref": str(_realtime_ref), "join_ref": "1"})
		_realtime.close()
	_realtime = null
	_realtime_joined = false
	_realtime_topic = ""
	_room_outbox.clear()

func send_room_message(kind: String, payload: Dictionary) -> void:
	if _realtime == null:
		return
	var message := {
		"topic": _realtime_topic,
		"event": "broadcast",
		"payload": {"type": "broadcast", "event": kind, "payload": payload},
		"ref": str(_realtime_ref),
		"join_ref": "1",
	}
	_realtime_ref += 1
	if not _realtime_joined:
		if _room_outbox.size() >= 256:
			_room_outbox.pop_front()
		_room_outbox.append(message)
		return
	_send_realtime(message)

func _flush_room_outbox() -> void:
	if not _realtime_joined:
		return
	for message in _room_outbox:
		_send_realtime(message)
	_room_outbox.clear()

func _send_realtime(message: Dictionary) -> void:
	if _realtime != null and _realtime.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_realtime.send_text(JSON.stringify(message))

func _poll_realtime(now: int) -> void:
	_realtime.poll()
	var state := _realtime.get_ready_state()
	if state == WebSocketPeer.STATE_CLOSED:
		_realtime = null
		_realtime_joined = false
		room_message.emit("signaling_closed", {})
		return
	if state == WebSocketPeer.STATE_OPEN and _realtime_topic != "" and not _realtime_joined and _realtime_ref == 1:
		_realtime_ref = 2
		_send_realtime({
			"topic": _realtime_topic,
			"event": "phx_join",
			"payload": {"config": {"broadcast": {"ack": false, "self": false}, "presence": {"enabled": false}, "postgres_changes": [], "private": false}, "access_token": access_token},
			"ref": "1",
			"join_ref": "1",
		})
		_realtime_joined = false
		_heartbeat_due_msec = now + 25000
	if state == WebSocketPeer.STATE_OPEN and now >= _heartbeat_due_msec:
		_send_realtime({"topic": "phoenix", "event": "heartbeat", "payload": {}, "ref": str(_realtime_ref)})
		_realtime_ref += 1
		_heartbeat_due_msec = now + 25000
	while _realtime.get_available_packet_count() > 0:
		var value: Variant = JSON.parse_string(_realtime.get_packet().get_string_from_utf8())
		if not value is Dictionary:
			continue
		var message: Dictionary = value
		var event := String(message.get("event", ""))
		var payload: Variant = message.get("payload", {})
		if event == "phx_reply":
			if String(message.get("ref", "")) != "1":
				continue
			if payload is Dictionary and String(payload.get("status", "")) == "ok":
				if not _realtime_joined:
					_realtime_joined = true
					_flush_room_outbox()
					room_joined.emit()
			elif payload is Dictionary:
				_realtime_joined = false
				last_error = "Supabase signaling channel join failed"
				lobby_error.emit(last_error)
				room_message.emit("signaling_closed", {})
		elif event == "broadcast" and payload is Dictionary:
			var kind := String(payload.get("event", ""))
			var data: Variant = payload.get("payload", {})
			if kind != "" and data is Dictionary:
				room_message.emit(kind, data)
