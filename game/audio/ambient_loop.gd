extends AudioStreamPlayer






func _ready() -> void :
	finished.connect(_replay)
	if autoplay and not playing:
		play()

func _replay() -> void :
	play()
