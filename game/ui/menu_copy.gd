class_name MenuCopy










const SUB: = {

	"online": "play matches worldwide", 
	"local": "play matches locally", 
	"practice": "guides & drills", 
	"settings": "controls, video, audio", 


	"quick_match": "find any online match available", 
	"open_gym": "socialize and play recreationally", 
	"server_browser": "online servers with custom rules", 
	"custom_lobby": "host your own lobby with custom rules", 
	"direct_join": "connect by ip address", 


	"custom_match": "pick the rules, sets and stage", 


	"freeplay": "practice in the open court", 
	"how_to_play": "volleyball & game rules", 


	"find_match": "queue up", 


	"crowd_noise": "the arena reacts to the rally", 
	"player_voices": "grunts and callouts", 


	"aim_assist": "auto aims on attacks and sticks to the court", 
	"camera_shake": "impacts rattle the view", 
	"last_touch": "reveal who touched the ball last with an outline", 
	"reach_marker": "shows when a ball is grabbable", 
	"in_game_chat": "show the chat panel", 
	"chat_filter": "censor inappropriate chat content", 
	"chat_bubbles": "speech bubbles over heads in freeplay and the gym", 
	"own_name": "display your own username during gameplay", 
	"hardware_cursor": "aim with the real pointer at its own speed; mouse sensitivity only applies to the in-game cursor", 
	"save_replays": "writes a file after each match", 


	"vsync": "off uncaps the frame rate, may tear", 
	"reflections": "the mirrored court floor", 
	"show_fps": "frame rate readout", 
}


static func sub(key: String) -> String:
	return String(SUB.get(key, ""))
