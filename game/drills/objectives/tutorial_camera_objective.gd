extends DrillObjective






const CYCLES: = 4

var toggles: = 0
var did_zoom: = false
var _zoom0: = 0.0
var _zoom_armed: = false

func _begin() -> void :
	required = CYCLES + 1
	park_ball()

func on_go() -> void :
	runner.start_clock()
	state = LIVE
	runner.objective_say("change your camera!")

func tick(_delta: float) -> void :
	if state != LIVE:
		return
	if toggles < CYCLES:
		if Input.is_action_just_pressed("camera_toggle"):
			toggles += 1
			done = toggles
			runner.objective_progress(done, required)
			if toggles < CYCLES:
				runner.objective_say("change your camera!")
			else:
				runner.objective_say("zoom!")


				_zoom_armed = true
				if runner.cam_rig != null:
					_zoom0 = runner.cam_rig.zoom_value()
		return
	if did_zoom:
		return


	var zoomed: = Input.is_action_just_pressed("camera_zoom")
	if not zoomed and _zoom_armed and runner.cam_rig != null:
		zoomed = absf(runner.cam_rig.zoom_value() - _zoom0) > 0.001
	if zoomed:
		did_zoom = true
		done = required
		runner.objective_progress(done, required)
		runner.objective_complete()
