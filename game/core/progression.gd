class_name Progression
extends RefCounted





















const XP_PER_RALLY: = 3
const XP_PER_SET: = 5
const WIN_BONUS_XP: = 15




const LEVEL_BASE: = 150
const LEVEL_STEP: = 50
const LEVEL_COST_CAP: = 800


const COINS_PER_RALLY: = 2
const COINS_PER_SET: = 3
const WIN_BONUS_COINS: = 10
const LEVELUP_COINS: = 150

static func xp_for_next(level: int) -> int:
	return mini(LEVEL_BASE + LEVEL_STEP * (maxi(1, level) - 1), LEVEL_COST_CAP)





static func grant_match(won: bool, sets_played: int, rallies: int) -> Dictionary:
	var p: = ProfileStore.active()
	if p == null:
		return {}
	var s: = maxi(1, sets_played)
	var r: = maxi(0, rallies)
	var xp_gain: = XP_PER_RALLY * r + XP_PER_SET * s + (WIN_BONUS_XP if won else 0)
	var coin_gain: = COINS_PER_RALLY * r + COINS_PER_SET * s + (WIN_BONUS_COINS if won else 0)
	var start_level: = p.level
	p.xp += xp_gain
	var levelup_coins: = 0


	while p.xp >= xp_for_next(p.level):
		p.xp -= xp_for_next(p.level)
		p.level += 1
		levelup_coins += LEVELUP_COINS
	p.coins += coin_gain + levelup_coins
	ProfileStore.save()
	return {
		"xp_gain": xp_gain, 
		"coins_gain": coin_gain + levelup_coins, 
		"levels_gained": p.level - start_level, 
		"level": p.level, 
		"xp_into_level": p.xp, 
		"xp_needed": xp_for_next(p.level), 
		"coins_total": p.coins, 
	}






static func add_coins(n: int) -> void :
	var p: = ProfileStore.active()
	if p == null or n <= 0:
		return
	p.coins += n
	ProfileStore.save()

static func is_free(price: int) -> bool:
	return price <= 0

static func owns(id: String, price: = 0) -> bool:
	if is_free(price):
		return true


	if LaunchGate.public_beta():
		return true
	var p: = ProfileStore.active()
	return p != null and p.owned.has(id)

static func can_afford(price: int) -> bool:
	var p: = ProfileStore.active()
	return p != null and p.coins >= price



static func purchase(id: String, price: int) -> bool:
	if is_free(price) or owns(id, price) or not can_afford(price):
		return false
	var p: = ProfileStore.active()
	if p == null:
		return false
	p.coins -= price
	p.owned[id] = true
	ProfileStore.save()
	return true
