class_name PresentationCharacter
extends Node3D












const PLAYER_SCENE: = preload("res://game/player/player.tscn")

var player: Player = null
var rig: ModelRig = null
var _hands_rested: = false
var _gaze_target: = Vector3.INF
var _clip: = ""
var _clip_loop: = true

func setup(cfg: CharacterConfig, kit: Array) -> void :
	player = PLAYER_SCENE.instantiate()
	player.enable_reflection = false
	player.is_bot = true
	add_child(player)


	player.set_character(cfg if cfg != null else CharacterConfig.new(), kit)




	player.set_physics_process(false)
	player.set_process(false)
	rig = _find_rig()


	_hide_shadow(player)


func face(yaw: float) -> void :
	if player != null and player.visual != null:
		player.visual.rotation.y = yaw


func gaze_at(world_point: Vector3) -> void :
	_gaze_target = world_point



func play_clip(name: String, loop: = true) -> String:
	_clip_loop = loop
	if rig == null:
		rig = _find_rig()
	var got: = rig.play_clip(name, loop) if rig != null else ""


	_clip = got
	return got


func clip_finished() -> bool:
	return rig != null and rig.clip_finished()


func clip_names() -> PackedStringArray:
	if rig == null:
		rig = _find_rig()
	return rig.clip_names() if rig != null else PackedStringArray()

func _process(delta: float) -> void :
	if rig == null:
		rig = _find_rig()
		if rig == null:
			return


	if _clip == "":
		rig.drive(0.0, true, 0.0)




	if rig.hands_animated():
		player.hand_l.position = rig.hand_local(false)
		player.hand_r.position = rig.hand_local(true)
	elif not _hands_rested and rig.hand_rest != Vector3.ZERO:
		var rest: Vector3 = rig.hand_rest
		player.hand_r.position = rest
		player.hand_l.position = Vector3( - rest.x, rest.y, rest.z)
		_hands_rested = true
	if _gaze_target != Vector3.INF:
		rig.gaze_at(_gaze_target, 1.0, delta)

func _hide_shadow(n: Node) -> void :
	if String(n.name).to_lower().contains("shadow") and n is Node3D:
		(n as Node3D).visible = false
	for c in n.get_children():
		_hide_shadow(c)

func _find_rig() -> ModelRig:
	if player == null:
		return null
	var r: = player.get_node_or_null("Visual/ModelRig")
	if r is ModelRig:
		return r
	if player.visual != null:
		for c in player.visual.get_children():
			if c is ModelRig:
				return c
	return null
