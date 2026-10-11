extends Node

# Stand-in destination for the transition test. Deliberately trivial: the point
# is to exercise the wipe's hold and the threaded load, not another 3D scene.

var ready_at: = 0

func _ready() -> void :
	ready_at = Time.get_ticks_msec()
	print("VERIFY TARGET READY")
