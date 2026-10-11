class_name CreditsData
extends RefCounted








static func sections() -> Array:
	return [
		{"gap": 60}, 
		{"title": "CHITTERPUTT VOLLEYBALL"}, 
		{"line": "a temkosoft game"}, 
		{"gap": 50}, 

		{"header": "Created by"}, 
		{"entries": [{"name": "temkosoft"}]}, 
		{"gap": 40}, 

		{"header": "Design & Code"}, 
		{"entries": [{"name": "temkosoft", "works": ["Game design", "Engineering", "Netcode"]}]}, 
		{"gap": 40}, 

		{"header": "Art & Models"}, 
		{"entries": [{"name": "temkosoft", "works": ["Characters", "Stages", "UI"]}]}, 
		{"gap": 40}, 

		{"header": "Music"}, 
		{"entries": [
			{"name": "TODO composer", "works": ["Menu Theme", "Match Score", "Credits Theme"]}, 
		]}, 
		{"gap": 40}, 

		{"header": "Sound Effects"}, 
		{"entries": [{"name": "TODO"}]}, 
		{"gap": 40}, 

		{"header": "Made with"}, 
		{"line": "Godot Engine"}, 
		{"gap": 60}, 

		{"title": "Thanks for playing!"}, 
		{"gap": 200}, 
	]
