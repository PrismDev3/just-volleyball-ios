class_name DevBadge
extends RefCounted










enum Tier{NONE, GOLD, SILVER}

const GOLD_SIDS: Array[int] = [
	76561198743870148, 
]


const SILVER_SIDS: Array[int] = [




]

static func tier_of(sid: int) -> int:
	if sid == 0:
		return Tier.NONE
	if GOLD_SIDS.has(sid):
		return Tier.GOLD
	if SILVER_SIDS.has(sid):
		return Tier.SILVER
	return Tier.NONE

static func is_sid(sid: int) -> bool:
	return tier_of(sid) != Tier.NONE


static func my_tier() -> int:
	return tier_of(Net.my_steam_id())




static func peer_tier(peer_id: int) -> int:
	if peer_id <= 0:
		return Tier.NONE
	if peer_id == Net.get_multiplayer().get_unique_id():
		return my_tier()
	return tier_of(int((Net.players.get(peer_id, {}) as Dictionary).get("sid", 0)))
