class_name AchievementCatalog
extends RefCounted






















static func all() -> Array:
	var timed: = func(a: AchievementDef) -> AchievementDef:
		a.unit = "sec"
		return a
	var mine_and: = func(key: String): return func(data: Dictionary):
		return bool(data.get("mine", false)) and bool(data.get(key, false))
	var won: = func(data: Dictionary): return bool(data.get("won", false))
	var lost: = func(data: Dictionary): return not bool(data.get("won", false))
	var deuce_won: = func(data: Dictionary):
		return bool(data.get("won", false)) and bool(data.get("deuce", false))
	var my_spike: = func(data: Dictionary):
		return bool(data.get("mine", false)) and String(data.get("kind", "")) == "spike"
	var high_assist: = func(data: Dictionary):
		return bool(data.get("assist", false)) and bool(data.get("assist_high", false))
	return [

		AchievementDef.new("from_the_concrete", "From the Concrete", 
			"open just volleyball for the first time", "global", "opened", 1, 0, 
			"FROM_THE_CONCRETE"), 
		AchievementDef.new("getting_better", "Getting Better", 
			"win your first match", "global", "match_end", 1, 0, 
			"GETTING_BETTER", won), 
		AchievementDef.new("eat_and_grow_stronger", "Eat and Grow Stronger", 
			"lose your first match", "global", "match_end", 1, 0, 
			"EAT_AND_GROW_STRONGER", lost), 
		AchievementDef.new("neck_and_neck", "Neck and Neck", 
			"win a deuce set", "global", "set_end", 1, 0, 
			"NECK_AND_NECK", deuce_won), 
		AchievementDef.new("ultimate_weapon", "Ultimate Weapon", 
			"score a quick attack", "global", "point", 1, 0, 
			"ULTIMATE_WEAPON", mine_and.call("quick")), 
		AchievementDef.new("planned", "Planned", 
			"score a point using your foot", "global", "point", 1, 0, 
			"PLANNED", mine_and.call("foot")), 
		AchievementDef.new("fly_high", "Fly High", 
			"score a point after performing a bam jump", "global", "point", 1, 0, 
			"FLY_HIGH", mine_and.call("bam")), 
		AchievementDef.new("rolling_thunder", "Rolling Thunder", 
			"save a ball while using the side roll", "global", "roll_save", 1, 0, 
			"ROLLING_THUNDER"), 
		AchievementDef.new("open", "Open!", 
			"set a high ball, resulting in a point", "global", "point", 1, 0, 
			"OPEN", high_assist), 
		AchievementDef.new("its_just_volleyball", "It's Just Volleyball", 
			"complete the tutorial", "global", "tutorial", 1, 0, 
			"ITS_JUST_VOLLEYBALL"), 

		AchievementDef.new("d_play_5", "Warm Up", 
			"play 5 matches", "daily", "match_end", 5, 50), 
		AchievementDef.new("d_spike_5", "Hammer Time", 
			"score 5 spikes", "daily", "point", 5, 50, "", my_spike), 
		AchievementDef.new("d_block_5", "Wall Up", 
			"block 5 attacks", "daily", "block", 5, 50), 
		AchievementDef.new("d_avatar", "New Look", 
			"change your avatar", "daily", "avatar", 1, 50), 
		timed.call(AchievementDef.new("d_time_15", "Court Time", 
			"play 15 minutes", "daily", "play_time", 15 * 60, 50)), 

		AchievementDef.new("w_play_20", "Regular", 
			"play 20 matches", "weekly", "match_end", 20, 50), 
		AchievementDef.new("w_spike_50", "Heavy Hitter", 
			"score 50 spikes", "weekly", "point", 50, 50, "", my_spike), 
		AchievementDef.new("w_block_50", "The Wall", 
			"block 50 attacks", "weekly", "block", 50, 50), 
		timed.call(AchievementDef.new("w_time_120", "Gym Rat", 
			"play 2 hours", "weekly", "play_time", 120 * 60, 50)), 
	]
