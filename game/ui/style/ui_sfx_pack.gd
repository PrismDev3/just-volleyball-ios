class_name UiSfxPack
extends Resource






@export var press: Array[AudioStream] = []
@export var confirm: Array[AudioStream] = []
@export var back: Array[AudioStream] = []
@export var toggle_on: Array[AudioStream] = []
@export var toggle_off: Array[AudioStream] = []
@export var open: Array[AudioStream] = []
@export var close: Array[AudioStream] = []
@export var celebrate: Array[AudioStream] = []
@export var wipe_in: Array[AudioStream] = []
@export var wipe_out: Array[AudioStream] = []
@export var tick: Array[AudioStream] = []
@export var slide: Array[AudioStream] = []
@export var hover: Array[AudioStream] = []

@export var volumes: = {
	"press": -10.0, "confirm": -8.0, "back": -12.0, 
	"toggle_on": -10.0, "toggle_off": -12.0, 
	"open": -10.0, "close": -12.0, "celebrate": -8.0, 
	"wipe_in": -10.0, "wipe_out": -12.0, 
	"tick": -16.0, "slide": -18.0, "hover": -15.0, 
}

func streams(role: String) -> Array:
	var v: Variant = get(role)
	return v if v is Array else []

func volume(role: String) -> float:
	return float(volumes.get(role, -10.0))
