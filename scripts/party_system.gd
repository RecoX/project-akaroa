## Party_System — mock party creation, member invitation, and party member list.
##
## All operations are local. Lives as a child of GameplayScene.
extends Node


const TAG := "PartySystem"
const MAX_PARTY_SIZE: int = 6


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when the party composition changes.
signal party_changed(members: Array)

## Emitted when a party invitation is sent.
signal invite_sent(target_name: String)

## Emitted when the party is disbanded.
signal party_disbanded()


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Whether the player is currently in a party.
var _in_party: bool = false

## Party leader name.
var _leader: String = ""

## Party member list. Each entry: { "name": String, "level": int, "class": String, "hp_percent": float }
var _members: Array = []


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	Log.info(TAG, "Party_System ready")


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


## Creates a new party with the player as leader.
func create_party() -> void:
	if _in_party:
		Log.info(TAG, "Already in a party")
		return

	var player_name: String = StateManager.player_data.get("name", "Player")
	_leader = player_name
	_members = [{
		"name": player_name,
		"level": StateManager.player_data.get("level", 1),
		"class": StateManager.player_data.get("class", "Warrior"),
		"hp_percent": 1.0,
	}]
	_in_party = true

	party_changed.emit(_members)
	Log.info(TAG, "Party created — leader: %s" % player_name)


## Invites a player to the party (mock — auto-accepts).
func invite_member(target_name: String) -> void:
	if not _in_party:
		create_party()

	if _members.size() >= MAX_PARTY_SIZE:
		Log.info(TAG, "Party is full (%d/%d)" % [_members.size(), MAX_PARTY_SIZE])
		return

	# Check if already in party.
	for member in _members:
		if member.get("name", "") == target_name:
			Log.info(TAG, "'%s' is already in the party" % target_name)
			return

	# Mock auto-accept.
	_members.append({
		"name": target_name,
		"level": randi_range(1, 50),
		"class": ["Warrior", "Mage", "Ranger", "Cleric"].pick_random(),
		"hp_percent": randf_range(0.5, 1.0),
	})

	invite_sent.emit(target_name)
	party_changed.emit(_members)
	Log.info(TAG, "'%s' joined the party (%d/%d)" % [target_name, _members.size(), MAX_PARTY_SIZE])


## Removes a member from the party.
func remove_member(member_name: String) -> void:
	for i in range(_members.size()):
		if _members[i].get("name", "") == member_name:
			_members.remove_at(i)
			party_changed.emit(_members)
			Log.info(TAG, "'%s' removed from party" % member_name)
			return


## Disbands the party.
func disband_party() -> void:
	_members.clear()
	_leader = ""
	_in_party = false
	party_disbanded.emit()
	Log.info(TAG, "Party disbanded")


## Returns the party member list.
func get_members() -> Array:
	return _members


## Returns whether the player is in a party.
func is_in_party() -> bool:
	return _in_party


## Returns the party leader name.
func get_leader() -> String:
	return _leader
