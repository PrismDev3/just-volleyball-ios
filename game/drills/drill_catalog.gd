class_name DrillCatalog
extends RefCounted











const CATEGORIES: = [
	{"id": "movement", "name": "movement"}, 
	{"id": "serving", "name": "serving"}, 
	{"id": "receiving", "name": "receiving"}, 
	{"id": "attacking", "name": "attacking"}, 
	{"id": "blocking", "name": "blocking"}, 
]

const DRILLS: = [

	{"id": "movement", "category": "movement", "name": "movement", "objective": "move, then strafe", "thumbnail": "arrowRight", "available": true, 
		"inputs": [["move", "move"], ["strafe", "strafe"]]}, 
	{"id": "strafing", "category": "movement", "name": "strafing", "objective": "strafe between the markers", "thumbnail": "arrowRight", "available": true, 
		"inputs": [["move", "move"], ["strafe", "hold strafe"], ["@mouse", "aim"]], 
		"info": "strafing (hold strafe) locks your facing to your cursor, so you can move any direction while still facing your aim. keep your cursor on the target and shuffle into each marker. it is also how you stop on a dime."}, 
	{"id": "jumping", "category": "movement", "name": "jumping", "objective": "jump into each ring", "thumbnail": "arrowUp", "available": true, 
		"inputs": [["move", "move"], ["jump", "jump"], ["@mouse", "aim"]], 
		"info": "a jump carries your run momentum, so aim and move, then jump to send yourself where you are headed. start each rep on the pad and jump through the ring."}, 

	{"id": "serving_1", "category": "serving", "name": "serving 1", "objective": "land 3 basic serves", "thumbnail": "arrowUp", "available": true, 
		"inputs": [["@mouse", "aim"], ["contact", "hold to charge the toss, release to throw"], ["contact", "hit the ball at the top"]], 
		"info": "hold the touch button to charge your toss and release to throw the ball up. the longer you hold, the higher it goes. then hit it at the top of the toss toward your cursor. a basic serve from the ground is the safe one: easy to land, easy to receive."}, 
	{"id": "serving_2", "category": "serving", "name": "serving 2", "objective": "land 3 jump serves", "thumbnail": "star", "available": true, 
		"inputs": [["@mouse", "aim"], ["contact", "toss"], ["jump", "jump"], ["contact", "spike in the air"], ["move", "tilt in the air"]], 
		"info": "toss it high, jump, and swing at the top. a jump serve is a spike: strong, but easier to mess up. while you are in the air, your movement input tilts your body, and tilting sideways curves the ball. tilting back at contact turns it into a float."}, 
	{"id": "serving_3", "category": "serving", "name": "serving 3", "objective": "land 3 jump floats", "thumbnail": "star", "available": true, 
		"inputs": [["@mouse", "aim"], ["contact", "toss"], ["jump", "jump"], ["move", "tilt back as you hit"], ["contact", "hit"]], 
		"info": "jump, then tilt BACK as you hit the ball. a jump float has no spin, so it wanders on the way down and catches receivers off guard. the basic serve is safe, the jump serve is strong, the jump float is sneaky."}, 

	{"id": "receiving_1", "category": "receiving", "name": "receiving 1", "objective": "receive 3 basic serves to a teammate", "thumbnail": "arrowDown", "available": true, 
		"inputs": [["move", "move"], ["@mouse", "aim at your teammate"], ["contact", "bump"]], 
		"info": "get under the ball and bump it to the teammate at the net. your cursor is where the ball goes."}, 
	{"id": "receiving_2", "category": "receiving", "name": "receiving 2", "objective": "receive 3 jump serves to a teammate", "thumbnail": "arrowDown", "available": true, 
		"inputs": [["move", "move"], ["@mouse", "aim at your teammate"], ["contact", "bump"], ["dive", "dive (on the ground)"]], 
		"info": "jump serves come in fast. you have to be standing still when the ball arrives to receive it cleanly, so get to the spot early and plant. if you are not going to make it, dive: a dive auto targets where the ball is going to land and gets you there faster."}, 
	{"id": "receiving_3", "category": "receiving", "name": "receiving 3", "objective": "receive 3 jump floats to a teammate", "thumbnail": "arrowDown", "available": true, 
		"inputs": [["move", "move"], ["@mouse", "aim at your teammate"], ["contact", "bump"], ["dive", "dive (on the ground)"]], 
		"info": "a float serve has no spin and wanders on the way down. watch it all the way in, plant your feet before it arrives, and bump it to your teammate."}, 
	{"id": "receiving_4", "category": "receiving", "name": "receiving 4", "objective": "receive a basic, a jump and a float serve", "thumbnail": "multiplayer", "available": true, 
		"inputs": [["move", "move"], ["@mouse", "aim at your teammate"], ["contact", "bump"], ["dive", "dive (on the ground)"]], 
		"info": "one of each: a basic serve, a jump serve, then a jump float. read the toss to know which one is coming."}, 

	{"id": "spiking_1", "category": "attacking", "name": "spiking 1", "objective": "spike into 3 marked zones", "thumbnail": "target", "available": true, 
		"inputs": [["move", "move"], ["jump", "jump"], ["@mouse", "aim"], ["contact", "spike"]], 
		"info": "a teammate sets to you. run in, jump, and spike into the marked zone. one click queues the swing and it fires by itself when the ball reaches you. hold the button instead to charge the hit yourself."}, 
	{"id": "spiking_2", "category": "attacking", "name": "spiking 2", "objective": "hit 3 quick attacks", "thumbnail": "star", "available": true, 
		"inputs": [["move", "move"], ["jump", "jump"], ["@mouse", "aim"], ["contact", "spike"]], 
		"info": "a quick attack: stand right next to the setter and be in the air as they set. the ball is fast and low, so swing right after the set. blockers can not react to it."}, 
	{"id": "spiking_3", "category": "attacking", "name": "spiking 3", "objective": "spike 3 different sets over", "thumbnail": "star", "available": true, 
		"inputs": [["move", "move"], ["jump", "jump"], ["@mouse", "aim"], ["contact", "spike"]], 
		"info": "sets come in quick and slow. time your approach to each one and put it over the net, in bounds."}, 
	{"id": "curving", "category": "attacking", "name": "curving", "objective": "curve a spike left, then right", "thumbnail": "target", "available": true, 
		"inputs": [["move", "move"], ["jump", "jump"], ["@mouse", "aim"], ["contact", "spike"], ["move", "hold left/right in the air to curve"]], 
		"info": "in the air your movement tilts your body, and tilting sideways bends the ball that way. hold left or right as you swing to curve your spike around a block or drop it inside the line. curve it left, then right."}, 
	{"id": "setting_1", "category": "attacking", "name": "setting 1", "objective": "set a teammate 3 times so they can spike it over", "thumbnail": "arrowUp", "available": true, 
		"inputs": [["move", "move"], ["@mouse", "aim at your hitter"], ["set", "set (hold to charge)"]], 
		"info": "a set is a high, soft touch that puts the ball where a hitter can jump and swing at it. aim at your hitter and set. where the ball goes depends on where you are standing and where your cursor is. charging a set makes it faster and flatter, not further."}, 
	{"id": "setting_2", "category": "attacking", "name": "setting 2", "objective": "set 3 quick sets", "thumbnail": "arrowUp", "available": true, 
		"inputs": [["move", "move"], ["@mouse", "aim at your hitter"], ["set", "hold set fully to quick set"]], 
		"info": "a quick set is a fast, low set to a hitter who is already jumping. hold the set button all the way and release with your cursor on the hitter."}, 
	{"id": "setting_3", "category": "attacking", "name": "setting 3", "objective": "make 3 sets your hitter spikes over", "thumbnail": "arrowUp", "available": true, 
		"inputs": [["move", "move"], ["@mouse", "aim at your hitter"], ["set", "set"]], 
		"info": "any set counts, high or quick, as long as your hitter can spike it over."}, 

	{"id": "blocking_1", "category": "blocking", "name": "blocking 1", "objective": "get a touch on 3 spikes", "thumbnail": "multiplayer", "available": true, 
		"inputs": [["move", "move"], ["jump", "jump"], ["dive", "block (in the air)"], ["@mouse", "aim the rebound"]], 
		"info": "the other team will bump, set and spike. read the hitter, get in front of them, jump and block in the air. you do not need to stuff it: a touch slows the ball so your teammates behind you can pick it up."}, 
	{"id": "blocking_2", "category": "blocking", "name": "blocking 2", "objective": "stuff 3 spikes back over", "thumbnail": "multiplayer", "available": true, 
		"inputs": [["move", "move"], ["jump", "jump"], ["dive", "block (in the air)"], ["@mouse", "aim the rebound"]], 
		"info": "block timing: jump right after the hitter does, and press block as they swing. a block put up at the right moment stuffs the ball straight back down on their side."}, 
	{"id": "blocking_3", "category": "blocking", "name": "blocking 3", "objective": "block 3 random plays", "thumbnail": "multiplayer", "available": true, 
		"inputs": [["move", "move"], ["jump", "jump"], ["dive", "block (in the air)"], ["@mouse", "aim the rebound"]], 
		"info": "the setter can go left, middle or right. watch the set, move in front of the hitter, and get up."}, 
]

static func entry(id: String) -> Dictionary:
	for item in DRILLS:
		if String(item.id) == id:
			return item
	return {}

static func by_category(category: String) -> Array:
	var out: = []
	for item in DRILLS:
		if String(item.get("category", "")) == category:
			out.append(item)
	return out

static func category_of(id: String) -> String:
	return String(entry(id).get("category", ""))


static func next_available(id: String) -> String:
	var found: = false
	for item in DRILLS:
		if found and bool(item.get("available", false)):
			return String(item.id)
		if String(item.id) == id:
			found = true
	return ""


static func category_counts(category: String, progress: DrillProgress) -> Vector2i:
	var built: = 0
	var done: = 0
	for item in by_category(category):
		if not bool(item.get("available", false)):
			continue
		built += 1
		if progress != null and bool(progress.row(String(item.id)).get("complete", false)):
			done += 1
	return Vector2i(done, built)
