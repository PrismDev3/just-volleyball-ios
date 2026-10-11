class_name ViewControls
extends HBoxContainer

















signal cam_pressed
signal follow_pressed
signal clean_pressed
signal ui_pressed

@onready var cam_btn: Button = $CamBtn
@onready var follow_btn: Button = $FollowBtn
@onready var clean_btn: Button = $CleanBtn
@onready var ui_btn: Button = $UiBtn

func _ready() -> void :


	process_mode = Node.PROCESS_MODE_ALWAYS
	cam_btn.pressed.connect( func(): cam_pressed.emit())
	follow_btn.pressed.connect( func(): follow_pressed.emit())
	clean_btn.pressed.connect( func(): clean_pressed.emit())
	ui_btn.pressed.connect( func(): ui_pressed.emit())
	for button in [cam_btn, follow_btn, clean_btn, ui_btn]:
		UiStyle.style_button(button, "secondary", 15)


func set_labels(cam: String, follow: String, clean: String, 
		ui_hidden: bool) -> void :
	cam_btn.text = "cam: " + cam
	follow_btn.text = "follow: " + follow
	clean_btn.text = "clean: " + clean



	ui_btn.text = "show ui" if ui_hidden else "hide ui  h"
